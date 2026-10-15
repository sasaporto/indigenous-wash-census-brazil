# ------------------------------------------------------------------------------
# ibge.R — download and read Census 2022 sector aggregates straight from IBGE
# ------------------------------------------------------------------------------
# Files come from the IBGE FTP. They are downloaded once into data/ibge/2022/ and
# reused afterwards, so later runs work offline.
# IBGE sometimes republishes a file with a date in its name
# (e.g. ..._basico_BR_20260520.zip). We therefore look the name up in the folder
# listing instead of hard-coding it.
# ------------------------------------------------------------------------------

IBGE_2022_SECTORS_URL <- paste0(
  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/",
  "Agregados_por_Setores_Censitarios/Agregados_por_Setor_csv/"
)

# Datasets used here -> start of their file name on the FTP
IBGE_2022_DATASETS <- c(
  basico              = "Agregados_por_setores_basico_BR",
  domicilios_indigenas = "Agregados_por_setores_domicilios_indigenas_BR",
  pessoas_indigenas    = "Agregados_por_setores_pessoas_indigenas_BR"
)

# Most recent .zip in an FTP folder whose name starts with `prefix`
ibge_find_zip <- function(prefix, dir_url = IBGE_2022_SECTORS_URL) {
  # Read the folder page as raw bytes: the page may contain characters that
  # Windows R cannot convert ("unable to translate ... to a wide string").
  # File names are plain ASCII, so byte-level matching is safe.
  page <- tempfile(fileext = ".html")
  on.exit(unlink(page), add = TRUE)
  utils::download.file(dir_url, page, mode = "wb", quiet = TRUE)
  bytes <- readBin(page, what = "raw", n = file.info(page)$size)
  html <- rawToChar(bytes[bytes != as.raw(0)])
  Encoding(html) <- "bytes"

  links <- regmatches(html, gregexpr('href="[^"]+\\.zip"', html, useBytes = TRUE))[[1]]
  files <- unique(gsub('^href="|"$', "", links, useBytes = TRUE))
  files <- basename(files)
  hits <- files[startsWith(files, prefix)]
  if (!length(hits)) {
    stop("No file starting with ", prefix, " at ", dir_url,
         "\nWorkaround: download it by hand from that page and put the .zip in ",
         data_path("ibge", "2022"), call. = FALSE)
  }
  paste0(dir_url, sort(hits, decreasing = TRUE)[1])
}

# Download (if needed) and unzip one dataset; returns the path of its CSV.
ibge_get_2022 <- function(dataset, dest_dir = data_path("ibge", "2022")) {
  prefix <- IBGE_2022_DATASETS[[dataset]]
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  local_zip <- list.files(dest_dir, pattern = paste0("^", prefix, ".*\\.zip$"), full.names = TRUE)
  if (length(local_zip)) {
    zip_path <- sort(local_zip, decreasing = TRUE)[1]
  } else {
    url <- ibge_find_zip(prefix)
    zip_path <- file.path(dest_dir, basename(url))
    message("Downloading ", basename(url), " from IBGE ...")
    old <- options(timeout = max(1200, getOption("timeout")))
    on.exit(options(old), add = TRUE)
    utils::download.file(url, zip_path, mode = "wb", quiet = TRUE)
  }

  csv_name <- grep("\\.csv$", utils::unzip(zip_path, list = TRUE)$Name, value = TRUE, ignore.case = TRUE)[1]
  csv_path <- file.path(dest_dir, csv_name)
  if (!file.exists(csv_path)) utils::unzip(zip_path, files = csv_name, exdir = dest_dir)
  csv_path
}

# Read an IBGE aggregates CSV: ";" separated, "X" for suppressed values,
# encoding detected automatically (UTF-8 or Latin-1).
read_ibge_csv <- function(path) {
  first <- readLines(path, n = 200, warn = FALSE)
  enc <- if (all(validUTF8(first))) "UTF-8" else "Latin-1"
  df <- data.table::fread(path, sep = ";", colClasses = "character",
                          encoding = enc, na.strings = c("", "NA"), showProgress = FALSE)
  df <- as.data.frame(df)
  names(df)[tolower(names(df)) == "cd_setor"] <- "CD_SETOR"
  df$CD_SETOR <- as_sector_code(df$CD_SETOR)

  v_cols <- grep("^V\\d+$", names(df), value = TRUE)
  df[v_cols] <- lapply(df[v_cols], \(x) suppressWarnings(as.numeric(sub(",", ".", x, fixed = TRUE))))
  df
}

read_ibge_2022 <- function(dataset) read_ibge_csv(ibge_get_2022(dataset))
