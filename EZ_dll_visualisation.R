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
target <- "time_last_token"


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
    ling_data <- strsplit(file, "/")[[1]][3]
    method <- strsplit(file, "/")[[1]][2]
    data_name <- gsub("^_|_$", "", paste(ling_data, target, sep = "_"))
    if (layer == 0) next

    result_text <- readLines(file)
    logLik <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
    #TODO: here, I am working with the same seemingly incorrect value, this is average surprisal
    ppl <- as.numeric(strsplit(result_text[3], ": ")[[1]][2])

    all_data <- all_data %>% add_row(
      Data = ling_data,
      Model = model,
      Method = method,
      Layer = as.numeric(layer),
      LogLik = logLik,
      PPL = ppl
    )
  }
}


ggplot(all_data[all_data$Model=="pythia-2.8b-deduped",], aes(x = Layer, y=LogLik, colour=Model))+
  geom_line()