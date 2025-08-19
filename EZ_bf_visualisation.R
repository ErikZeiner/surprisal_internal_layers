library(stringr)
library(tibble)
library(dplyr)
library(tidyverse)
library(ggplot2)

source("EZ_lists_visualisation.R")
all_data <- tibble(
  Data = character(),
  Model = character(),
  Method = character(),
  Layer = numeric(),
  BayesFactor = numeric(),
  Error = numeric()
)

dir <- "results_orig/logit-lens/NS"
target <- "time"



for (i in 1:length(models)) {
  # i <- 1
  model <- models[[i]]

  files <- list.files(
    path = file.path(dir, model),
    pattern = paste0("^.*surprisal.json.BayesFactor.layer.*", target, ".*$"),
    full.names = TRUE)

  for (file in files) {
    # file <- "results/logit-lens/DC/gpt2/helix_surprisal.json.BayesFactor.layer0..time_last_token"
    layer <- strsplit(str_split(file, "layer")[[1]][2], "\\.")[[1]][[1]]
    model <- strsplit(file, "/")[[1]][4]
    data <- strsplit(file, "/")[[1]][3]
    method <- strsplit(file, "/")[[1]][2]
    data_name <- gsub("^_|_$", "", paste(ling_data, target, sep = "_"))
    if (layer == 0) next

    result_text <- readLines(file)
    bayesFactor <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
    error <- as.numeric(strsplit(result_text[2], ": ")[[1]][2])

    all_data <- all_data %>% add_row(
      Data = data,
      Model = model,
      Method = method,
      Layer = as.numeric(layer),
      BayesFactor = bayesFactor,
      Error = error
    )
  }
}


all_data <- all_data %>%
  group_by(Model) %>%
  mutate(
    Max_layer = max(Layer),
    Min_layer = min(Layer),
    Normalized_layer = (Layer - Min_layer) / (Max_layer - Min_layer),
    Measurement = data2method[[data_name]],
    Name = data2stimuli[[data_name]],
    Params = models2params[Model],
    Log_params = log10(models2params[Model]),
  ) %>%
  ungroup()

all_data <- all_data %>%
  group_by(Model) %>%
  mutate(
    Last_bf = BayesFactor[which.max(Layer)],
    Last_error = Error[which.max(Layer)],
    Max_bf = max(BayesFactor)
  )


ggplot(df, aes(x = Layer, y=BayesFactor, colour=Model))+
  geom_point()+
  geom_line()

black_list <-c()
data <- all_datasets[!all_datasets %in% black_list]
data <- c("DC_time",)
layer_results <- data.frame(
  data = character(),
  stimuli = character(),
  method = character(),
  measurement = character(),
  name = character(),
  range = character(),
  PPP = numeric(),
  stringsAsFactors = FALSE
)

df <- df[!df$model %in% filter_model, ]

for (d in data) {
  print(d)
  for (method in c("logit-lens", "tuned-lens")) {
    ranges <- list(c(0, 0.2), c(0.2, 0.4), c(0.4, 0.6), c(0.6, 0.8), c(0.8, 1))
    for (r in ranges) {
      sub_df <- df[df$data == d & df$method == method, ]

      # Filter rows where normalized_layer is between r[1] and r[2]
      filtered_rows <- sub_df[sub_df$normalized_layer >= r[1] & sub_df$normalized_layer <= r[2], ]

      # Add row directly to dataframe
      layer_results <- rbind(layer_results, data.frame(
        data = d,
        stimuli = data2stimuli[[d]],
        method = method,
        measurement = data2method[[d]],
        name = paste0(data2method[[d]], data2cite[[d]]),
        range = paste0(r[1], "-", r[2]),
        PPP = mean(filtered_rows$loglik, na.rm = TRUE) * 1000,
        stringsAsFactors = FALSE
      ))
    }
  }
}



### TABLE

# TODO: What is the blacklist for?

black_list <- c("M_N400_C3", "M_N400_C4", "M_N400_CP3", "M_N400_CP4", "M_N400_CPz", "M_N400_Cz", "M_N400_P3", "M_N400_P4", "M_N400_Pz", "UCL_RTreread", "UCL_RTreread_last_token", "UCL_PNP", "UCL_PNP_last_token", "UCL_LAN", "UCL_LAN_last_token", "UCL_EPNP", "UCL_EPNP_last_token", "UCL_ELAN", "UCL_ELAN_last_token", "Fillers_RRT", "UCL_P600", "UCL_P600_last_token", "UCL_RTgopast", "UCL_N400_last_token",
                "DC_time_last_token", "NS_time_last_token", "NS_MAZE_time_last_token", "Fillers_SPR_RT_last_token", "Fillers_FPRT_last_token", "Fillers_RRT_last_token", "Fillers_MAZE_RT_last_token", "UCL_RTfirstpass_last_token", "UCL_RTreread_last_token", "UCL_RTgopast_last_token", "UCL_self_paced_reading_time_last_token")
black_list <- c()

data <- setdiff(all_datasets, black_list)

for (d in data) {
  paste(d)
}