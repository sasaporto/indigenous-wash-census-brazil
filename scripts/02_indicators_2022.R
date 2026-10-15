# ------------------------------------------------------------------------------
# 02_indicators_2022.R — water, sewage and waste for Indigenous residents, 2022
# Output: output/Tabelas/<indicator>_2022.xlsx (sheets: Brasil, região, UF, município)
#         output/Tabelas/sensibilidade_definicao_agua_2022.xlsx
# ------------------------------------------------------------------------------

source(here::here("scripts", "00_setup.R"))

households <- readRDS(output_path("intermediarios", "setores_2022_domicilios.rds"))

breakdowns <- list(
  brasil    = c("Categoria_Territorial", "Rural_Urbana"),
  regiao    = c("NM_REGIAO", "Categoria_Territorial", "Rural_Urbana"),
  uf        = c("CD_UF", "NM_UF", "Categoria_Territorial", "Rural_Urbana"),
  municipio = c("CD_MUN", "NM_MUN", "NM_UF", "Rural_Urbana")
)

for (indicator in names(MAIN_DEFINITIONS)) {
  def <- definitions[[MAIN_DEFINITIONS[[indicator]]]]
  classified <- classify_access(households, def)
  sheets <- lapply(breakdowns, \(by) summarise_access(classified, by = by, extra = "V01501"))
  writexl::write_xlsx(sheets, output_path("Tabelas", paste0(indicator, "_2022.xlsx")))
  message("Saved table: ", def$label)
}

# Sensitivity: how much does the V01573 decision change the water picture?
sens <- compare_definitions(households, definitions$water_2022_v1, definitions$water_2022_v2,
                            by = c("Categoria_Territorial", "Rural_Urbana"))
writexl::write_xlsx(sens, output_path("Tabelas", "sensibilidade_definicao_agua_2022.xlsx"))

sens |>
  filter(Rural_Urbana == "Total") |>
  select(definicao, Categoria_Territorial, starts_with("pct_")) |>
  print(n = Inf)
