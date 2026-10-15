# Builds a small FAKE data folder so the pipeline can be tested without
# downloading anything: IBGE 2022 zips in data/ibge/2022
# (";" separated, Latin-1, "X" = suppressed values).
set.seed(1)
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else file.path(tempdir(), "fake_data")
unlink(root, recursive = TRUE)
mk <- function(...) { p <- file.path(root, ...); dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE); p }

n <- 60
codes <- sprintf("%s%08d", rep(c("1302603", "2105302", "5003702"), length.out = n), 1:n)  # 15 digits

# --- IBGE public files -------------------------------------------------------------
write_ibge_zip <- function(df, zip_name) {
  dir <- mk("ibge", "2022", "x"); dir <- dirname(dir)
  csv <- file.path(tempdir(), sub("\\.zip$", ".csv", zip_name))
  con <- file(csv, open = "w", encoding = "latin1")
  utils::write.table(df, con, sep = ";", row.names = FALSE, quote = FALSE, na = "X")
  close(con)
  old <- setwd(dirname(csv)); on.exit(setwd(old))
  utils::zip(file.path(dir, zip_name), basename(csv), flags = "-q")
}

ufs <- data.frame(CD_UF = c("13", "21", "50"), NM_UF = c("Amazonas", "Maranhão", "Mato Grosso do Sul"),
                  NM_REGIAO = c("Norte", "Nordeste", "Centro-Oeste"), CD_MUN = c("1302603", "2105302", "5003702"),
                  NM_MUN = c("Manaus", "Imperatriz", "Dourados"))
idx <- ((seq_len(n) - 1) %% 3) + 1
basico <- data.frame(CD_SETOR = codes, SITUACAO = sample(c("Urbana", "Rural"), n, TRUE),
                     CD_TIPO = sample(c("0", "5"), n, TRUE), CD_REGIAO = "1",
                     NM_REGIAO = ufs$NM_REGIAO[idx], CD_UF = ufs$CD_UF[idx], NM_UF = ufs$NM_UF[idx],
                     CD_MUN = ufs$CD_MUN[idx], NM_MUN = ufs$NM_MUN[idx], V0001 = rpois(n, 500))
write_ibge_zip(basico, "Agregados_por_setores_basico_BR_20260520.zip")

dom <- data.frame(CD_setor = codes, V01501 = rpois(n, 80))
for (v in c(sprintf("V%05d", 1572:1595), sprintf("V%05d", 1656:1663), sprintf("V%05d", 1672:1677))) dom[[v]] <- rpois(n, 3)
dom$V01577[3] <- NA                                     # written as "X"
write_ibge_zip(dom, "Agregados_por_setores_domicilios_indigenas_BR.zip")

pes <- data.frame(CD_setor = codes, V01690 = rpois(n, 80))
for (v in sprintf("V%05d", 1866:2067)) pes[[v]] <- rpois(n, 1)
write_ibge_zip(pes, "Agregados_por_setores_pessoas_indigenas_BR.zip")

cat(root)
