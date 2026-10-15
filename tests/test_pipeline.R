# Run from the project folder:  Rscript tests/test_pipeline.R
# Uses fake data only: nothing is downloaded.
fake_root <- file.path(tempdir(), "fake")
fake <- system2("Rscript", c(shQuote(here::here("tests", "make_fake_data.R")), shQuote(fake_root)), stdout = TRUE)
Sys.setenv(DATA_DIR = tail(fake, 1), OUTPUT_DIR = file.path(tempdir(), "fake_output"))

source(here::here("scripts", "00_setup.R"))

# --- Unit checks ---------------------------------------------------------------
stopifnot(as_sector_code(211230810000022) == "211230810000022")
stopifnot(identical(classify_water_2010(c(1, 3, 4, 9), c(1, 2, 3, 3)),
                    c("Adequado", "Inadequado", "Inadequado", "Inadequado")))
toy <- data.frame(V1 = c(1, NA), V2 = c(2, 3), V3 = c(0, 5))
d <- list(label = "toy", categories = list(Adequado = c("V1", "V2"), Sem_atendimento = "V3"))
out <- classify_access(toy, d)
stopifnot(out$Adequado == c(3, 3), out$Sem_atendimento == c(0, 5))

run <- function(folder, s) { message("\n==== ", folder, "/", s, " ===="); source(here::here(folder, s), local = new.env()) }

# --- Public pipeline (05_census2010.R needs censobr + internet: replaced by a fake table)
for (s in c("01_census2022_sectors.R", "02_indicators_2022.R", "03_figures_2022.R", "04_population_2022.R")) run("scripts", s)
saveRDS(data.frame(code_muni = c(1302603, 2105302, 5003702, 1100015), total_indigenas = c(1500, 900, 1200, 40)),
        output_path("intermediarios", "municipios_2010.rds"))
run("scripts", "06_change_2010_2022.R")

h <- readRDS(output_path("intermediarios", "setores_2022_domicilios.rds"))
stopifnot(nchar(h$CD_SETOR) == 15, !anyNA(h$NM_UF), is.na(h$V01577[3]),
          "Maranhão" %in% h$NM_UF)   # Latin-1 accents read correctly

message("\nAll checks passed. Outputs in: ", OUTPUT_DIR)
print(list.files(OUTPUT_DIR, recursive = TRUE))
