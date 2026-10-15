# ------------------------------------------------------------------------------
# 05_census2010.R — Indigenous population and water access, Census 2010
# Replaces: Dados_gerais_2010.R
# Data come straight from IBGE via the censobr package (downloaded once and
# cached), so there are no local file paths at all.
# Fixes:
#   * population totals use the sample weight V0010 (the old code summed
#     `code_weighting`, which is the weighting-AREA CODE, not a weight)
#   * municipalities joined to the map by code_muni, not by name
#   * people are counted once each (person weight), not once per household join
# Output: output/Tabelas/censo2010_indigenas_municipio.xlsx
#         output/Graficos/mapa_indigenas_2010.png (if geobr is installed)
# ------------------------------------------------------------------------------

source(here::here("scripts", "00_setup.R"))
if (!requireNamespace("censobr", quietly = TRUE)) install.packages("censobr")

keys <- c("V0001", "code_muni", "V0300")   # state, municipality, household id

# Indigenous persons (V0606 == 5) with their sample weight
indigenous <- censobr::read_population(year = 2010, showProgress = FALSE) |>
  select(all_of(keys), V0606, V0010) |>
  collect() |>
  filter(as.character(V0606) == "5") |>
  mutate(peso = as.numeric(V0010))

# Water variables of their households
households <- censobr::read_households(year = 2010, showProgress = FALSE) |>
  select(all_of(keys), V0208, V0209) |>
  collect() |>
  semi_join(indigenous, by = keys)

n_people <- nrow(indigenous)
indigenous <- indigenous |>
  left_join(households, by = keys, relationship = "many-to-one") |>
  mutate(agua = classify_water_2010(V0208, V0209))
stopifnot(nrow(indigenous) == n_people)   # each person counted exactly once

muni_2010 <- indigenous |>
  group_by(code_muni, agua) |>
  summarise(pop = sum(peso, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = agua, values_from = pop, values_fill = 0) |>
  mutate(total_indigenas = rowSums(across(any_of(CATEGORY_LEVELS))),
         across(any_of(CATEGORY_LEVELS), \(x) 100 * x / total_indigenas, .names = "pct_{.col}"))

message("Indigenous population 2010 (weighted): ",
        fmt_br(round(sum(muni_2010$total_indigenas))))

writexl::write_xlsx(muni_2010, output_path("Tabelas", "censo2010_indigenas_municipio.xlsx"))
saveRDS(muni_2010, output_path("intermediarios", "municipios_2010.rds"))

# --- Map (optional) -------------------------------------------------------------
if (requireNamespace("geobr", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)) {
  map_df <- geobr::read_municipality(code_muni = "all", year = 2010, showProgress = FALSE) |>
    mutate(code_muni = as.numeric(code_muni)) |>
    left_join(mutate(muni_2010, code_muni = as.numeric(code_muni)), by = "code_muni")

  m <- ggplot(map_df) +
    geom_sf(aes(fill = total_indigenas), colour = NA) +
    scale_fill_viridis_c(option = "inferno", trans = "log10", na.value = "grey92",
                         labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
    labs(title = "População indígena por município — Censo 2010", fill = "Indígenas") +
    theme_void(base_size = 13) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))

  ggsave(output_path("Graficos", "mapa_indigenas_2010.png"), m, width = 9, height = 9, dpi = 300, bg = "white")
}
