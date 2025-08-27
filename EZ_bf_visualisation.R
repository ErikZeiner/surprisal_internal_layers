library(stringr)
library(tibble)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(patchwork)
library(aida)   # custom helpers: https://github.com/michael-franke/aida-package
library(faintr) # custom helpers: https://michael-franke.github.io/faintr/index.html
library(cspplot)
library(readr)
library(grid)
library(gridExtra)
library(xtable)

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

get_results <- function(models, dir, tar) {
  df <- tibble(
    data = character(),
    target = character(),
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
      pattern = paste0("^surprisal\\.json\\.BayesFactor\\.layer[0-9]*\\.", tar, "$"),
      full.names = TRUE)

    for (file in files) {
      layer <- strsplit(str_split(file, "layer")[[1]][2], "\\.")[[1]][[1]]
      model <- strsplit(file, "/")[[1]][4]
      method <- strsplit(file, "/")[[1]][2]
      data_name <- gsub("^_|_$", "", paste(strsplit(file, "/")[[1]][3], tar, sep = "_"))
      if (layer == 0) next

      result_text <- readLines(file)
      bayesFactor <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
      log10_bf <- as.numeric(strsplit(result_text[2], ": ")[[1]][2])
      error <- as.numeric(strsplit(result_text[3], ": ")[[1]][2])

      df <- df %>% add_row(
        data = data_name,
        target = tar,
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

print_table <- function(df, filter_model = c(), data, log = FALSE) {
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

      if (log) {
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
      else {
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

black_list <- c("M_N400_C3", "M_N400_C4", "M_N400_CP3", "M_N400_CP4", "M_N400_CPz", "M_N400_Cz", "M_N400_P3", "M_N400_P4", "M_N400_Pz", "UCL_RTreread", "UCL_RTreread_last_token", "UCL_PNP", "UCL_PNP_last_token", "UCL_LAN", "UCL_LAN_last_token", "UCL_EPNP", "UCL_EPNP_last_token", "UCL_ELAN", "UCL_ELAN_last_token", "Fillers_RRT", "UCL_P600", "UCL_P600_last_token", "UCL_RTgopast", "UCL_N400_last_token",
                "DC_time_last_token", "NS_time_last_token", "NS_MAZE_time_last_token", "Fillers_SPR_RT_last_token", "Fillers_FPRT_last_token", "Fillers_RRT_last_token", "Fillers_MAZE_RT_last_token", "UCL_RTfirstpass_last_token", "UCL_RTreread_last_token", "UCL_RTgopast_last_token", "UCL_self_paced_reading_time_last_token")


logit_lens_results <- list(
  # logit lens
  get_results(models, "results_orig/logit-lens/DC", tar = "time"),
  get_results(models, "results_orig/logit-lens/DC", tar = "time_last_token"),
  get_results(models, "results_orig/logit-lens/NS", tar = "time"),
  get_results(models, "results_orig/logit-lens/NS", tar = "time_last_token"),
  get_results(models, "results_orig/logit-lens/NS", tar = "MAZE_time"),
  get_results(models, "results_orig/logit-lens/NS", tar = "MAZE_time_last_token"),
  get_results(models, "results_orig/logit-lens/Fillers", tar = "SPR_RT"),
  get_results(models, "results_orig/logit-lens/Fillers", tar = "FPRT"),
  get_results(models, "results_orig/logit-lens/Fillers", tar = "MAZE_RT"),
  get_results(models, "results_orig/logit-lens/Fillers", tar = "SPR_RT_last_token"),
  get_results(models, "results_orig/logit-lens/Fillers", tar = "FPRT_last_token"),
  get_results(models, "results_orig/logit-lens/Fillers", tar = "MAZE_RT_last_token"),
  get_results(models, "results_orig/logit-lens/M_N400", tar = "all"),
  get_results(models, "results_orig/logit-lens/S_N400", tar = "Federmeier_et_al._(2007)"),
  get_results(models, "results_orig/logit-lens/S_N400", tar = "Hubbard_et_al._(2019)"),
  get_results(models, "results_orig/logit-lens/S_N400", tar = "Szewczyk_&_Federmeier_(2022)"),
  get_results(models, "results_orig/logit-lens/S_N400", tar = "Szewczyk_et_al._(2022)"),
  get_results(models, "results_orig/logit-lens/S_N400", tar = "Wlotko_&_Federmeier_(2012)"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "ELAN"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "ELAN_last_token"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "EPNP"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "EPNP_last_token"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "LAN"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "LAN_last_token"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "N400"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "N400_last_token"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "P600"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "PNP"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "RTfirstpass"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "RTfirstpass_last_token"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "RTreread"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "RTgopast"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "self_paced_reading_time"),
  get_results(models, "results_orig/logit-lens/UCL", tar = "self_paced_reading_time_last_token"),

  # get_results(multilingual_models, "results_orig/logit-lens/MECO/du", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/ee", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/en", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/fi", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/ge", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/gr", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/he", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/it", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/ko", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/no", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/ru", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/sp", tar="time"),
  # get_results(multilingual_models, "results_orig/logit-lens/MECO/tr", tar="time"),
  get_results(models, "results_orig/logit-lens/ZuCO", tar = "time"),
  get_results(models, "results_orig/logit-lens/ZuCO", tar = "N400")
)

bf_df <- bind_rows(logit_lens_results)

dll_df <- as.data.frame(read_csv('results_orig/all_results.csv'))

# a <- bf_df %>%
#   count(measurement, name)
#   filter(measurement %in% c("FPGD", "SPR", "MAZE"))


# VISUALISATION

# a <- df[df$model %in% df$model[startsWith(df$model, "pythia")],]
#df[grepl("example", df$col_name), ]

# selected_df <- bf_df %>%
#   filter(method=="logit-lens") %>%
#   filter(grepl("pythia", model)) %>%
#   filter(name %in% c("NS", "DC"))
#
# # ggplot(selected_df, aes(x = layer, y = log10(bayes_factor), colour = model, shape=data)) +
# #   geom_point()+
# #   geom_line()+
# #   facet_grid(.~data)
#
# ggplot(selected_df, aes(x = layer, y = log10(bayes_factor), colour = data, shape=data)) +
#   facet_grid(~measurement)+
#   geom_point(size=3)+
#   geom_line(aes(group = interaction(model, data)))
#
# dll <- ddl_df %>%
#   filter(method=="logit-lens") %>%
#   filter(grepl("pythia", model)) %>%
#   filter(name %in% c("DC"))
#
# ggplot(dll, aes(x = layer, y = loglik, colour = model, shape=data)) +
#   facet_grid(~measurement)+
#   geom_point(size=3)+
#   geom_line(aes(group = interaction(model, data)))



bf_plot <- function(bf_df,filt_measurement,fam){
   filtered_bf <- bf_df %>%
    filter(grepl(fam, model)) %>%
    filter(name %in% c("DC", "NS")) %>%
    filter(measurement == filt_measurement) %>%
    # filter(grepl("^[A-Za-z]*(MAZE_)?time(_last_token)?$",target))%>%
    mutate(target = str_replace_all(target, "_", " "))

  bf_plot <- ggplot(filtered_bf, aes(x = layer, y = log10_bf, color = model)) +
    facet_grid(target ~ ., scales = 'free') +
    geom_point(size=0.5) +
    geom_line() +
    geom_hline(yintercept = 3, linetype = "dashed", color = "red",size=0.3) +
    theme(panel.spacing = unit(1.5, "lines")) +
    labs(y = "log10(Bayes Factor)")+
    ggtitle(filt_measurement)+
    theme(plot.title = element_text(size = 15))
  return(bf_plot)
}

dll_plot <- function(dll_df,filt_measurement,fam){
  filtered_dll <- dll_df %>%
    filter(method == "logit-lens") %>%
    filter(grepl(fam, model)) %>%
    filter(name %in% c("DC", "NS")) %>%
    filter(measurement == filt_measurement) %>%
    mutate(target = str_match(data, "^[A-Za-z]*_(.*)$")[, 2]) %>%
    # filter(grepl("^[A-Za-z]*_(MAZE_)?time(_last_token)?$",data))
    mutate(target = str_replace_all(target, "_", " "))

  dll_plot <- ggplot(filtered_dll, aes(x = layer, y = loglik, color = model)) +
    facet_grid(target ~ ., scales = 'free') +
    geom_point(size=0.5) +
    geom_line() +
    theme(panel.spacing = unit(1.5, "lines")) +
    labs(y = expression(paste(Delta, "LL")))
  return(dll_plot)
}




visualise <- function(bf_df, dll_df, fam) {
#FPGD
  fpgd_bf <- bf_plot(bf_df,"FPGD",fam)
  fpgd_dll <- dll_plot(dll_df,"FPGD",fam)
#SPR
  spr_bf <- bf_plot(bf_df,"SPR",fam)
  spr_dll <- dll_plot(dll_df,"SPR",fam)
#MAZE
  maze_bf <- bf_plot(bf_df,"MAZE",fam)
  maze_dll <- dll_plot(dll_df,"MAZE",fam)



  final_plot <-
    ((fpgd_bf|fpgd_dll)/
      (spr_bf|spr_dll)/
      ( maze_bf|maze_dll)) + plot_layout(guides = "collect"
    )& theme(
    legend.position = "bottom", legend.box = "horizontal",
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10),
    axis.text.x = element_text(size = 10),
    axis.text.y = element_text(size = 10),
    strip.text = element_text(size = 6),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 10)
  ) &guides(
      fill = guide_legend(nrow = 1),
         color = guide_legend(nrow = 1),
         shape = guide_legend(nrow = 1))

  return(final_plot)
}

final_plot <- visualise(bf_df,dll_df,'opt')
final_plot
quartz(width = 4, height = 6)
ggsave("../Internship/images/opt.png", plot = final_plot, width = 8, height = 10, dpi = 300)


# TABLE
data <- setdiff(all_datasets, black_list)
table <- print_table(bf_df, c(), data, log = TRUE)

latex_table <- xtable(table)

# Print LaTeX code to console
print(latex_table)