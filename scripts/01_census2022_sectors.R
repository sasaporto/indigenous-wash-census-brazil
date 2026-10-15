# ------------------------------------------------------------------------------
# 01_census2022_sectors.R — download and prepare Census 2022 sector aggregates
# Public data only: IBGE "Agregados por setores censitários" (Indigenous
# households and people) plus the basic sector file for geography and type.
# Output: output/intermediarios/setores_2022_domicilios.rds
#         output/intermediarios/setores_2022_pessoas.rds
# ------------------------------------------------------------------------------

source(here::here("scripts", "00_setup.R"))

# Sector attributes: location, rural/urban, sector type (CD_TIPO 5 = Indigenous settlement)
basico <- read_ibge_2022("basico")
attr_cols <- intersect(
  c("CD_SETOR", "SITUACAO", "CD_SIT", "CD_TIPO", "AREA_KM2",
    "CD_REGIAO", "NM_REGIAO", "CD_UF", "NM_UF", "CD_MUN", "NM_MUN"),
  names(basico)
)
basico <- basico[, attr_cols]

attach_attributes <- function(df) {
  out <- left_join(select(df, CD_SETOR, matches("^V\\d+$")), basico, by = "CD_SETOR")
  missing_attr <- sum(is.na(out$NM_UF))
  if (missing_attr) warning(missing_attr, " sector(s) not found in the basic sector file.", call. = FALSE)
  add_territorial_category(out)
}

households <- attach_attributes(read_ibge_2022("domicilios_indigenas"))
people     <- attach_attributes(read_ibge_2022("pessoas_indigenas"))
check_unique_sectors(households)

message("Sectors with Indigenous households: ", fmt_br(nrow(households)),
        " | Indigenous residents (V01501): ", fmt_br(sum(households$V01501, na.rm = TRUE)))
print(count(households, NM_REGIAO, Categoria_Territorial))

saveRDS(households, output_path("intermediarios", "setores_2022_domicilios.rds"))
saveRDS(people,     output_path("intermediarios", "setores_2022_pessoas.rds"))
