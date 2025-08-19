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
  LogLik = numeric(),
  PPL = numeric()
)

dir <- "results_orig/logit-lens/NS"
target <- "time"


for (i in 1:length(models)) {
  # i <- 1
  model <- models[[i]]

  files <- list.files(
    path = file.path(dir, model),
    pattern = paste0("^.*surprisal.json.result.layer.*", target, ".*$"),
    full.names = TRUE)

  for (file in files) {
    layer <- strsplit(str_split(file, "layer")[[1]][2], "\\.")[[1]][[1]]
    model <- strsplit(file, "/")[[1]][4]
    data <- strsplit(file, "/")[[1]][3]
    method <- strsplit(file, "/")[[1]][2]
    data_name <- gsub("^_|_$", "", paste(ling_data, target, sep = "_"))
    if (layer == 0) next

    result_text <- readLines(file)
    logLik <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
    #TODO: here, I am working with the same seemingly incorrect value, this is average surprisal
    ppl <- as.numeric(strsplit(result_text[3], ": ")[[1]][2])

    all_data <- all_data %>% add_row(
      Data = data,
      Model = model,
      Method = method,
      Layer = as.numeric(layer),
      LogLik = logLik,
      PPL = ppl
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
    Last_ppl = PPL[which.max(Layer)],
    Last_ppp = LogLik[which.max(Layer)],
    Max_ppp = max(LogLik)
  )

ggplot(all_data[all_data$Model=="pythia-2.8b-deduped",], aes(x = Layer, y=LogLik, colour=Model))+
  geom_line()