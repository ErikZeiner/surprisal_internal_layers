library(tidyverse)
library(BayesFactor)

dummy_data <- tibble(
 X = rep(c("A", "B"), each = 50),
 Z = rnorm(100, mean = 5, sd = 1),
 response = c(rnorm(50, mean = 5, sd = 1), rnorm(50, mean = 6, sd = 1))
) |> as.data.frame()

model_full <- BayesFactor::regressionBF(response ~ X + Z, data = dummy_data)
# model_X1 <- BayesFactor::regressionBF(response ~ X1, data = dummy_data)
# model_X2 <- BayesFactor::regressionBF(response ~ X2, data = dummy_data)

model_classic <- lm(response ~ X + Z, data = dummy_data)