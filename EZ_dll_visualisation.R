library(stringr)
library(tibble)
library(dplyr)
library(tidyverse)
library(ggplot2)

source("EZ_lists_visualisation.R")
all_data <- tibble(
  data = character(),
  model = character(),
  method = character(),
  layer = numeric(),
  logLik = numeric(),
  ppl = numeric()
)

dir <- "results_orig/logit-lens/DS"
target <- "time"


for (i in 1:length(models)) {
  # i <- 1
  model <- models[[i]]

  files <- list.files(
    path = file.path(dir, model),
    #TODO: needs to deal with different file names better
    pattern = paste0("^surprisal.json.result.*layer.*\\.", target,"$"),
    full.names = TRUE)

  for (file in files) {
    layer <- strsplit(str_split(file, "layer")[[1]][2], "\\.")[[1]][[1]]
    model <- strsplit(file, "/")[[1]][4]
    data <- strsplit(file, "/")[[1]][3]
    method <- strsplit(file, "/")[[1]][2]
    data_name <- gsub("^_|_$", "", paste(data, target, sep = "_"))
    if (layer == 0) next

    result_text <- readLines(file)
    logLik <- as.numeric(strsplit(result_text[1], ": ")[[1]][2])
    #TODO: here, I am working with the same seemingly incorrect value, this is average surprisal
    ppl <- as.numeric(strsplit(result_text[3], ": ")[[1]][2])

    all_data <- all_data %>% add_row(
      data = data,
      model = model,
      method = method,
      layer = as.numeric(layer),
      logLik = logLik,
      ppl = ppl
    )
  }
}

all_data <- all_data %>%
  group_by(model) %>%
  mutate(
    max_layer = max(layer),
    min_layer = min(layer),
    normalized_layer = (layer - min_layer) / (max_layer - min_layer),
    measurement = data2method[[data_name]],
    name = data2stimuli[[data_name]],
    params = models2params[model],
    log_params = log10(models2params[model]),
  ) %>%
  ungroup()

all_data <- all_data %>%
  group_by(model) %>%
  mutate(
    last_ppl = ppl[which.max(layer)],
    last_ppp = logLik[which.max(layer)],
    max_ppp = max(logLik)
  )

ggplot(all_data, aes(x = layer, y=logLik, colour=model))+
  geom_line() +
  ggtitle(target)