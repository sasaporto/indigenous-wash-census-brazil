# ------------------------------------------------------------------------------
# 00_setup.R — load packages, paths, definitions and functions
# Every other script starts with: source(here::here("scripts", "00_setup.R"))
# ------------------------------------------------------------------------------

packages <- c("dplyr", "tidyr", "stringr", "stringi", "purrr", "ggplot2",
              "openxlsx", "writexl", "data.table", "scales", "here")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
})

source(here::here("R", "paths.R"))
source(here::here("R", "definitions.R"))
source(here::here("R", "functions.R"))
source(here::here("R", "ibge.R"))
