library(stringr)
library(tibble)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(aida)   # custom helpers: https://github.com/michael-franke/aida-package
library(faintr) # custom helpers: https://michael-franke.github.io/faintr/index.html
library(cspplot)


# use the CSP-theme for plotting
theme_set(theme_csp())

# global color scheme from CSP
project_colors = cspplot::list_colors() |> pull(hex)

# setting theme colors globally
scale_colour_discrete <- function(...) {
  scale_colour_manual(..., values = project_colors)
}
scale_fill_discrete <- function(...) {
  scale_fill_manual(..., values = project_colors)
}

source("EZ_lists_visualisation.R")

get_results <- function(models,dir, target) {
  df <- tibble(
    data = character(),
    model = character(),
    method = character(),
    layer = numeric(),
    bayes_factor = numeric(),
    log10_bf = numeric(),
    error = numeric()
  )
  for (i in 1:length(models)) {
    # i <- 1
    model <- models[[i]]
    a <- file.path(dir, model)
    files <- list.files(
      path = file.path(dir, model),
      pattern = paste0("^surprisal\\.json\\.BayesFactor\\.layer[0-9]*\\.",target,"$"),
      full.names = TRUE)

    for (file in files) {
      layer <- strsplit(str_split(file, "layer")[[1]][2], "\\.")[[1]][[1]]
      model <- strsplit(file, "/")[[1]][4]
      method <- strsplit(file, "/")[[1]][2]
      data_name <- gsub("^_|_$", "", paste(strsplit(file, "/")[[1]][3], target, sep = "_"))
      if (layer == 0) next

      result_text <- readLines(file)
      bayesFactor <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
      log10_bf <- as.numeric(strsplit(result_text[2], ": ")[[1]][2])
      error <- as.numeric(strsplit(result_text[3], ": ")[[1]][2])

      df <- df %>% add_row(
        data = data_name,
        model = model,
        method = method,
        layer = as.numeric(layer),
        bayes_factor = bayesFactor,
        log10_bf = log10_bf,
        error = error
      )
    }
  }


  df <- df %>%
    group_by(model) %>%
    mutate(
      max_layer = max(layer, na.rm = TRUE),
      min_layer = min(layer),
      normalized_layer = (layer - min_layer) / (max_layer - min_layer),
      measurement = data2method[data],
      name = data2stimuli[data],
      params = models2params[model],
      log_params = log10(models2params[model]),
    ) %>%
    ungroup()

  df <- df %>%
    group_by(model) %>%
    mutate(
      last_bf = bayes_factor[which.max(layer)],
      last_error = error[which.max(layer)],
      max_bf = max(bayes_factor, na.rm = TRUE)
    )
  return(df)
}

print_table <- function(df, filter_model = c(), data, log=FALSE) {
  layer_results <- data.frame(
    data = character(),
    stimuli = character(),
    method = character(),
    measurement = character(),
    name = character(),
    range = character(),
    range_bf = numeric(),
    stringsAsFactors = FALSE
  )
  df <- df[!df$model %in% filter_model,]

  for (d in data) {
    print(d)

    #for (method in c("logit-lens", "tuned-lens")) {
    method <- "logit-lens"
    ranges <- list(c(0, 0.2), c(0.2, 0.4), c(0.4, 0.6), c(0.6, 0.8), c(0.8, 1))
    for (r in ranges) {
      sub_df <- df[df$data == d & df$method == method,]

      range_rows <- sub_df[sub_df$normalized_layer >= r[1] & sub_df$normalized_layer <= r[2],]

      if (log){
        layer_results <- rbind(layer_results, data.frame(
        data = d,
        stimuli = data2stimuli[[d]],
        method = method,
        measurement = data2method[[d]],
        name = paste0(data2method[[d]], data2cite[[d]]),
        range = paste0(r[1], "-", r[2]),
        range_bf = mean(range_rows$log10_bf, na.rm = TRUE),
        stringsAsFactors = FALSE
      ))
      }
      else{
      layer_results <- rbind(layer_results, data.frame(
        data = d,
        stimuli = data2stimuli[[d]],
        method = method,
        measurement = data2method[[d]],
        name = paste0(data2method[[d]], data2cite[[d]]),
        range = paste0(r[1], "-", r[2]),
        range_bf = mean(range_rows$bayes_factor, na.rm = TRUE),
        stringsAsFactors = FALSE
      ))
      }
    }
    #}
  }
  table <- data.frame(layer_results) %>%
    select(stimuli, name, measurement, method, range, range_bf) %>%
    filter(stimuli %in% c("NS", "DC", "UCL", "Fillers", "ZuCO", "Michaelov+,\\n2024",
                          "Federmeier+,\\n2007", "W&F,2012", "Hubbard+,\\n2019",
                          "S&F,2022", "Szewczyk+,\\n2022"))
  desired_order <- c("DC", "NS", "ZuCO", "UCL", "Fillers", "Michaelov+,\\n2024",
                     "Federmeier+,\\n2007", "W&F,2012", "Hubbard+,\\n2019",
                     "S&F,2022", "Szewczyk+,\\n2022")
  table$stimuli <- factor(table$stimuli, levels = desired_order, ordered = TRUE)

  # Sort by stimuli
  sorted_table <- table %>%
    arrange(stimuli)

  # Pivot wider to get the final structure
  final_table <- sorted_table %>%
    pivot_wider(
      id_cols = c(stimuli, name),
      names_from = range,
      values_from = range_bf,
      names_sep = "_"
    )
  return(final_table)
}

visualise <- function(models, dir, target, family) {


  # "../results/tuned-lens/DC", "surprisal", target="time", normalize_x=False, family=["gpt2"]
}


black_list <- c("M_N400_C3", "M_N400_C4", "M_N400_CP3", "M_N400_CP4", "M_N400_CPz", "M_N400_Cz", "M_N400_P3", "M_N400_P4", "M_N400_Pz", "UCL_RTreread", "UCL_RTreread_last_token", "UCL_PNP", "UCL_PNP_last_token", "UCL_LAN", "UCL_LAN_last_token", "UCL_EPNP", "UCL_EPNP_last_token", "UCL_ELAN", "UCL_ELAN_last_token", "Fillers_RRT", "UCL_P600", "UCL_P600_last_token", "UCL_RTgopast", "UCL_N400_last_token",
                "DC_time_last_token", "NS_time_last_token", "NS_MAZE_time_last_token", "Fillers_SPR_RT_last_token", "Fillers_FPRT_last_token", "Fillers_RRT_last_token", "Fillers_MAZE_RT_last_token", "UCL_RTfirstpass_last_token", "UCL_RTreread_last_token", "UCL_RTgopast_last_token", "UCL_self_paced_reading_time_last_token")




logit_lens_results <-list(
    # logit lens
get_results(models, "results_orig/logit-lens/DC", target="time"),
get_results(models, "results_orig/logit-lens/DC", target="time_last_token"),
get_results(models, "results_orig/logit-lens/NS", target="time"),
get_results(models, "results_orig/logit-lens/NS", target="time_last_token"),
get_results(models, "results_orig/logit-lens/NS", target="MAZE_time"),
get_results(models, "results_orig/logit-lens/NS", target="MAZE_time_last_token"),
get_results(models, "results_orig/logit-lens/Fillers", target="SPR_RT"),
get_results(models, "results_orig/logit-lens/Fillers", target="FPRT"),
get_results(models, "results_orig/logit-lens/Fillers", target="MAZE_RT"),
get_results(models, "results_orig/logit-lens/Fillers", target="SPR_RT_last_token"),
get_results(models, "results_orig/logit-lens/Fillers", target="FPRT_last_token"),
get_results(models, "results_orig/logit-lens/Fillers", target="MAZE_RT_last_token"),
get_results(models, "results_orig/logit-lens/M_N400", target="all"),
get_results(models, "results_orig/logit-lens/S_N400", target="Federmeier_et_al._(2007)"),
get_results(models, "results_orig/logit-lens/S_N400", target="Hubbard_et_al._(2019)"),
get_results(models, "results_orig/logit-lens/S_N400", target="Szewczyk_&_Federmeier_(2022)"),
get_results(models, "results_orig/logit-lens/S_N400", target="Szewczyk_et_al._(2022)"),
get_results(models, "results_orig/logit-lens/S_N400", target="Wlotko_&_Federmeier_(2012)"),
get_results(models, "results_orig/logit-lens/UCL", target="ELAN"),
get_results(models, "results_orig/logit-lens/UCL", target="ELAN_last_token"),
get_results(models, "results_orig/logit-lens/UCL", target="EPNP"),
get_results(models, "results_orig/logit-lens/UCL", target="EPNP_last_token"),
get_results(models, "results_orig/logit-lens/UCL", target="LAN"),
get_results(models, "results_orig/logit-lens/UCL", target="LAN_last_token"),
get_results(models, "results_orig/logit-lens/UCL", target="N400"),
get_results(models, "results_orig/logit-lens/UCL", target="N400_last_token"),
get_results(models, "results_orig/logit-lens/UCL", target="P600"),
get_results(models, "results_orig/logit-lens/UCL", target="PNP"),
get_results(models, "results_orig/logit-lens/UCL", target="RTfirstpass"),
get_results(models, "results_orig/logit-lens/UCL", target="RTfirstpass_last_token"),
get_results(models, "results_orig/logit-lens/UCL", target="RTreread"),
get_results(models, "results_orig/logit-lens/UCL", target="RTgopast"),
get_results(models, "results_orig/logit-lens/UCL", target="self_paced_reading_time"),
get_results(models, "results_orig/logit-lens/UCL", target="self_paced_reading_time_last_token"),

# get_results(multilingual_models, "results_orig/logit-lens/MECO/du", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/ee", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/en", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/fi", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/ge", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/gr", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/he", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/it", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/ko", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/no", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/ru", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/sp", target="time"),
# get_results(multilingual_models, "results_orig/logit-lens/MECO/tr", target="time"),
get_results(models, "results_orig/logit-lens/ZuCO", target="time"),
get_results(models, "results_orig/logit-lens/ZuCO", target="N400")
)

df <- bind_rows(logit_lens_results)


target <- "MAZE_time"

a<-df[df$data=="DC_time_last_token" & df$model == "gpt2", ]
# a <- df[df$model %in% df$model[startsWith(df$model, "pythia")],]
#df[grepl("example", df$col_name), ]

selected_df <- df %>%
  filter(method=="logit-lens") %>%
  filter(grepl("gpt", model)) %>%
  filter(name %in% c("DC"))

# ggplot(selected_df, aes(x = layer, y = log10(bayes_factor), colour = model, shape=data)) +
#   geom_point()+
#   geom_line()+
#   facet_grid(.~data)

ggplot(selected_df, aes(x = layer, y = log10(bayes_factor), colour = model, shape=data)) +
  facet_grid(~measurement)+
  geom_point(size=3)+
  geom_line(aes(group = interaction(model, data)))


dll <- read.csv('results_orig/all_results.csv')

dll <- dll %>%
  filter(method=="logit-lens") %>%
  filter(grepl("gpt", model)) %>%
  filter(name %in% c("DC"))

ggplot(dll, aes(x = layer, y = loglik, colour = model, shape=data)) +
  facet_grid(~measurement)+
  geom_point(size=3)+
  geom_line(aes(group = interaction(model, data)))

df <- rbind(df,get_results(models,dir = "results_orig/logit-lens/DC", target = "time"))
df <- rbind(df,get_results(models,dir = "results_orig/logit-lens/DC", target = "time"))
data <- setdiff(all_datasets, black_list)
table <- print_table(df, c(), data,log=TRUE)
