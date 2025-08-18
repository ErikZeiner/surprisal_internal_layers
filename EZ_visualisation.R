library(stringr)
library(tibble)
library(dplyr)

source("EZ_lists_visualisation.R")
all_data <- tibble(
  Data = character(),
  Model = character(),
  Method = character(),
  Layer = numeric(),
  BayesFactor = numeric(),
  Error = numeric()
)

dir <- "results/logit-lens/DC"
target <- "time_last_token"


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
    ling_data <- strsplit(file, "/")[[1]][3]
    method <- strsplit(file, "/")[[1]][2]
    data_name <- gsub("^_|_$", "", paste(ling_data, target, sep = "_"))
    if (layer == 0) next

    result_text <- readLines(file)
    bayesFactor <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
    error <- as.numeric(strsplit(result_text[2], ": ")[[1]][2])

    all_data <- all_data %>% add_row(
      Data = file,
      Model = model,
      Method = method,
      Layer = as.numeric(layer),
      BayesFactor = bayesFactor,
      Error = error
    )
  }
}


df <- all_data %>%
  group_by(Model) %>%
  mutate(
    Max_layer = max(Layer),
    Min_layer = min(Layer),
    Normalized_layer = (Layer - Min_layer) / (Max_layer - Min_layer),
    Measurement = data2method[[data_name]],
    Name = data2stimuli[[data_name]],
    Params = models2params[Model],
    Log_params = log10(models2params[Model]),
    Last_bf = df[Layer == Max_layer,]$BayesFactor,
    Last_error = df[Layer == Max_layer,]$Error,
    Max_bf = max(BayesFactor)
  ) %>%
  ungroup()


### TABLE

# TODO: What is the blacklist for?

black_list <- c("M_N400_C3", "M_N400_C4", "M_N400_CP3", "M_N400_CP4", "M_N400_CPz", "M_N400_Cz", "M_N400_P3", "M_N400_P4", "M_N400_Pz", "UCL_RTreread", "UCL_RTreread_last_token", "UCL_PNP", "UCL_PNP_last_token", "UCL_LAN", "UCL_LAN_last_token", "UCL_EPNP", "UCL_EPNP_last_token", "UCL_ELAN", "UCL_ELAN_last_token", "Fillers_RRT", "UCL_P600", "UCL_P600_last_token", "UCL_RTgopast", "UCL_N400_last_token",
                "DC_time_last_token", "NS_time_last_token", "NS_MAZE_time_last_token", "Fillers_SPR_RT_last_token", "Fillers_FPRT_last_token", "Fillers_RRT_last_token", "Fillers_MAZE_RT_last_token", "UCL_RTfirstpass_last_token", "UCL_RTreread_last_token", "UCL_RTgopast_last_token", "UCL_self_paced_reading_time_last_token")
black_list <- c()

data <- setdiff(all_datasets, black_list)

for (d in data) {
  paste(d)
}