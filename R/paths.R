# ------------------------------------------------------------------------------
# paths.R — where the data and results are, for ANY user on ANY computer
# ------------------------------------------------------------------------------
# All paths are relative to the project folder (the one with the .Rproj file),
# found automatically by the `here` package. Nobody needs to edit a path.
#
#   <project>/data/     input files   (see data/README.md for what goes where)
#   <project>/output/   tables, figures and intermediate files (created automatically)
#
# Keeping the data somewhere else (e.g. a shared OneDrive or a server)?
# Set DATA_DIR once in your ~/.Renviron file — usethis::edit_r_environ() — and restart R:
#   DATA_DIR="C:/path/to/data"
# Optionally OUTPUT_DIR as well. The code itself never changes.
# ------------------------------------------------------------------------------

resolve_dir <- function(env_var, default) {
  custom <- Sys.getenv(env_var)
  dir <- if (nzchar(custom)) custom else default
  normalizePath(dir, winslash = "/", mustWork = FALSE)
}

DATA_DIR   <- resolve_dir("DATA_DIR",   here::here("data"))
OUTPUT_DIR <- resolve_dir("OUTPUT_DIR", here::here("output"))

if (!dir.exists(DATA_DIR)) {
  if (nzchar(Sys.getenv("DATA_DIR"))) {
    stop("DATA_DIR is set but the folder does not exist: ", DATA_DIR,
         "\nFix the path in ~/.Renviron (usethis::edit_r_environ()).", call. = FALSE)
  }
  dir.create(DATA_DIR, recursive = TRUE)
}

# Path inside the data folder: data_path("ibge", "2022")
data_path <- function(...) file.path(DATA_DIR, ...)

# Path inside the output folder; creates subfolders as needed
output_path <- function(...) {
  p <- file.path(OUTPUT_DIR, ...)
  dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
  p
}

message("Data:    ", DATA_DIR, "\nResults: ", OUTPUT_DIR)
