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
args$input_dir <- 'results_orig/logit-lens/DC'
args$data <- 'DC'
args$overwrite <- FALSE

df_original <- read_csv(paste0("data/", args$data, "/all.txt.averaged_rt.annotation"))
df_original <- df_original %>%
  arrange(article, sent_id, tokenN_in_sent)

if (args$data %in% c("DC", "NS", "NS_MAZE", "UCL", "Fillers", "ZuCO")) {
    is_clause_finals <- fromJSON(paste0("data/", args$data, "/clause_finals.json"))
} else {
    is_clause_finals <- NULL
  }


dummy_data <- tibble(
 X = rep(c("A", "B"), each = 50),
 Z = rnorm(100, mean = 5, sd = 1),
 response = c(rnorm(50, mean = 5, sd = 1), rnorm(50, mean = 6, sd = 1))
) |> as.data.frame()

model_full <- BayesFactor::regressionBF(response ~ X + Z, data = dummy_data)
# model_X1 <- BayesFactor::regressionBF(response ~ X1, data = dummy_data)
# model_X2 <- BayesFactor::regressionBF(response ~ X2, data = dummy_data)

model_classic <- lm(response ~ X + Z, data = dummy_data)


install.packages("optparse")