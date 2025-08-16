library(tidyverse)
library(BayesFactor)
library(optparse)
library(dplyr)
library(readr)
library(jsonlite)
library(fs)

# option_list <- list(
#   make_option(c("-i", "--input-dir"), type="character", help="Input directory", metavar="DIR"),
#   make_option(c("-d", "--data"), type="character", default="DC", help="Data type [default %default]"),
#   make_option(c("-o", "--overwrite"), action="store_true", default=FALSE, help="Overwrite existing files")
# )
#
# opt_parser <- OptionParser(option_list=option_list)
# args <- parse_args(opt_parser)

args <- list()
args$input_dir <- "results/logit-lens/DC/"
args$data <- 'DC'

args$overwrite <- TRUE

data2targets <- list(
  DC = list("time", "time_last_token"),
  NS = list("time", "time_last_token"),
  NS_MAZE = list("time", "time_last_token"),
  UCL = list("ELAN", "LAN", "N400", "EPNP", "P600", "PNP",
             "RTfirstpass", "RTreread", "RTgopast", "self_paced_reading_time",
             "RTfirstpass_last_token", "RTreread_last_token", "RTgopast_last_token",
             "self_paced_reading_time_last_token", "N400_last_token", "P600_last_token",
             "EPNP_last_token", "PNP_last_token", "ELAN_last_token", "LAN_last_token"),
  Fillers = list("SPR_RT", "MAZE_RT", "FPRT", "SPR_RT_last_token", "MAZE_RT_last_token", "FPRT_last_token"),
  S_N400 = list('Federmeier et al. (2007)', 'Hubbard et al. (2019)', 'Szewczyk & Federmeier (2022)',
                'Szewczyk et al. (2022)', 'Wlotko & Federmeier (2012)'),
  M_N400 = list('C3', 'C4', 'CP3', 'CP4', 'CPz', 'Cz', 'P3', 'P4', 'Pz', 'all'),
  `MECO/du` = list("time"),
  `MECO/ee` = list("time"),
  `MECO/en` = list("time"),
  `MECO/fi` = list("time"),
  `MECO/ge` = list("time"),
  `MECO/gr` = list("time"),
  `MECO/he` = list("time"),
  `MECO/it` = list("time"),
  `MECO/ko` = list("time"),
  `MECO/no` = list("time"),
  `MECO/ru` = list("time"),
  `MECO/sp` = list("time"),
  `MECO/tr` = list("time"),
  ZuCO = list("time", "N400", "time_last_token", "N400_last_token")
)


modelling <- function(data, layer_id, target_file, df_original, is_clause_finals) {

}

df_original <- read_csv(paste0("data/", args$data, "/all.txt.averaged_rt.annotation"))
df_original <- df_original %>%
  arrange(article, sent_id, tokenN_in_sent)

if (args$data %in% c("DC", "NS", "NS_MAZE", "UCL", "Fillers", "ZuCO")) {
  is_clause_finals <- fromJSON(paste0("data/", args$data, "/clause_finals.json"))
} else {
  is_clause_finals <- NULL
}
#??????
target_files <- dir_ls(args$input_dir, recurse = TRUE, glob = "*.json")

length(target_files)
target_files <- target_files[grepl("surprisal\\.json$", target_files)]
length(target_files)

# is > 0?
stopifnot(length(target_files) > 0)

# for (target_file in target_files) {
#   if (args$data == "NS_MAZE") {
#     if (grepl("NS", target_file) == FALSE){
#       print("issue")
#     }
#   } else {
#     if(grepl(args$data, target_file)==FALSE){
#       print("issue")
#     }
#   }
#
#   print(target_file)
#   article2interest <- fromJSON(target_file)
#
#   for (layer_id in names(article2interest)) {
#     data <- article2interest[[layer_id]]
#     modeling(data, layer_id, target_file, df_original, is_clause_finals)
#   }
# }
target_file <- "results/logit-lens/DC/opt-125m/surprisal.json"
article2interest <- fromJSON(target_file)
layer_id <- "0"

data <- article2interest[[layer_id]]


# # Iterate over the dictionary items sorted by integer keys
# for _, sents_sups in sorted(data.items(), key=lambda x: int(x[0])):
#     # Iterate over each list of "sentence supports"
#     for sent_sups in sents_sups:
#         # Iterate over each item in the sentence supports
#         for sup in sent_sups:
#             all_interests.append(sup)


all_interests <- unlist(lapply(data[order(as.numeric(names(data)))], function(sents_sups) {
  lapply(sents_sups, function(sent_sups) { sent_sups }) }), recursive = TRUE, use.names = FALSE)
length(all_interests)
mean_surprisal <- mean(all_interests)

df <- df_original


row <- df_original[1,]
article = row$article
sent_id = row$sent_id + 1
tokenN_in_sent = row$tokenN_in_sent + 1
print(row)
data[[as.character(row$article)]][[sent_id]][[tokenN_in_sent]]

df$interest <- mapply(
  function(article, sent_id, tokenN_in_sent) {
    data[[as.character(article)]][[sent_id]][[tokenN_in_sent]]
  },
  article = df_original$article,
  sent_id = df_original$sent_id + 1,
  tokenN_in_sent = df_original$tokenN_in_sent + 1
)
df$interest_prev_1 <- c(mean_surprisal, head(df$interest, -1))
df$interest_prev_1 <- ifelse(
  df$tokenN_in_sent > 0,
  df$interest_prev_1,
  mean_surprisal
)
df$interest_prev_2 <- c(mean_surprisal, mean_surprisal, head(df$interest, -2))
df$interest_prev_2 <- ifelse(
  df$tokenN_in_sent > 1,
  df$interest_prev_2,
  mean_surprisal
)
if (args$data %in% c("DC", "NS", "NS_MAZE", "UCL", "Fillers", "ZuCO")) {
  df$is_clause_final <- mapply(
    function(article, sent_id, tokenN_in_sent) {
      is_clause_finals[[as.character(article)]][[sent_id]][[tokenN_in_sent]]
    },
    article = df_original$article,
    sent_id = df_original$sent_id + 1,
    tokenN_in_sent = df_original$tokenN_in_sent + 1
  )
}

for (target_name in unlist(data2targets[[args$data]])) {
  if (args$data == "NS_MAZE") {
    output_path <- paste0(target_file, ".BayesFactor.layer", layer_id, ".MAZE_", target_name)
  } else {
    output_path <- paste0(target_file, ".BayesFactor.layer", layer_id, ".", gsub(" ", "_", target_name))
  }

  if (any(file.exists(output_path)) && !args$overwrite) {
    cat("skip!\n")
  }

  if (grepl("last_token", target_name)) {
    target_df <- subset(df, is_clause_final)
    stopifnot(nrow(target_df) > 0)
    cat(nrow(target_df), "\n")
    target <- gsub("_last_token", "", target_name)
  } else {
    target_df <- df
    target <- target_name
  }

  if (!(target %in% c("RTreread", "RTreread_last_token", "RRT", "RRT_last_token",
                      "ELAN", "LAN", "N400", "EPNP", "P600", "PNP", "N400_last_token",
                      "P600_last_token", "PNP_last_token", "ELAN_last_token", "LAN_last_token",
                      "Federmeier et al. (2007)", "Hubbard et al. (2019)",
                      "Szewczyk & Federmeier (2022)", "Szewczyk et al. (2022)",
                      "Wlotko & Federmeier (2012)",
                      "C3", "C4", "CP3", "CP4", "CPz", "Cz", "P3", "P4", "Pz", "all"))) {
    target_df <- target_df[target_df[[target]] > 0,]
  }

  if (args$data == "S_N400") {
    target_df <- subset(target_df, dataset == target)
    target <- "time"
  }

  if (args$data == "M_N400") {
    if (target != "all") {
      target_df <- subset(target_df, Electrode == target)
    }
    target <- "time"
  }

  if (args$data == "ZuCO" && target_name == "N400") {
    formula <- paste0(target, " ~ interest + interest_prev_1 + interest_prev_2 + length + log_gmean_freq + ",
                      "length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + N400_baseline")
    baseline_formula <- paste0(target, " ~ interest_prev_1 + interest_prev_2 + length + log_gmean_freq + ",
                               "length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + N400_baseline")
  } else if (args$data == "S_N400") {
    formula <- paste0(target, " ~ interest + interest_prev_1 + interest_prev_2 + length + log_gmean_freq + ",
                      "length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + bline")
    baseline_formula <- paste0(target, " ~ interest_prev_1 + interest_prev_2 + length + log_gmean_freq + ",
                               "length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + bline")
  } else {
    formula <- paste0(target, " ~ interest + interest_prev_1 + interest_prev_2 + length + log_gmean_freq + ",
                      "length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2")
    baseline_formula <- paste0(target, " ~ interest_prev_1 + interest_prev_2 + length + log_gmean_freq + ",
                               "length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2")
  }
}


if (args$data == "M_N400" && target == "all") {
  #mixedlm
} else {
  #orig had OLS
  bfInterest = lmBF(formula = as.formula(paste(formula)), data = as.data.frame(target_df))
  bfBaseline = lmBF(formula = as.formula(paste(baseline_formula)), data = as.data.frame(target_df))

  bf = bfInterest / bfBaseline
  bf_df <- as.data.frame(bf)
  print(paste(output_path))
  writeLines(c(
    paste("bayes factor:", bf_df$bf),
    paste("error:", bf_df$error),
    capture.output(bf)
  ), output_path)
}

# dummy_data <- tibble(
#   X = rep(c("A", "B"), each = 50),
#   Z = rnorm(100, mean = 5, sd = 1),
#   response = c(rnorm(50, mean = 5, sd = 1), rnorm(50, mean = 6, sd = 1))
# ) |> as.data.frame()
#
# model_full <- BayesFactor::regressionBF(response ~ X + Z, data = dummy_data)
# # model_X1 <- BayesFactor::regressionBF(response ~ X1, data = dummy_data)
# # model_X2 <- BayesFactor::regressionBF(response ~ X2, data = dummy_data)
#
# model_classic <- lm(response ~ X + Z, data = dummy_data)
# model_classic

