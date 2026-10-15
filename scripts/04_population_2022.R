# ------------------------------------------------------------------------------
# 04_population_2022.R — Indigenous population by municipality and age pyramid
# Replaces: Dados_gerais_2022.R, the pyramid part of Juntar.R, População_total.R
# Uses public IBGE data prepared by 01_census2022_sectors.R
# Fixes:
#   * municipalities joined by CODE (CD_MUN), not by name — names repeat across states
#   * age groups: 0–4 now really means ages 0–4 (old breaks put age 4 in "5-9")
#   * relative pyramid: shares computed on the real total (old code summed
#     negative male values, which distorted the total)
# Output: output/Tabelas/populacao_indigena_municipio_2022.xlsx
#         output/Tabelas/populacao_idade_sexo_2022.xlsx
#         output/Graficos/piramide_etaria_indigena_2022.png
# ------------------------------------------------------------------------------

source(here::here("scripts", "00_setup.R"))

people <- readRDS(output_path("intermediarios", "setores_2022_pessoas.rds"))

# --- Municipality totals (V01690 = Indigenous residents) -----------------------
muni <- people |>
  group_by(CD_MUN, NM_MUN, NM_UF) |>
  summarise(total_indigenas_2022 = sum(V01690, na.rm = TRUE), .groups = "drop") |>
  filter(total_indigenas_2022 > 0) |>
  arrange(desc(total_indigenas_2022))

writexl::write_xlsx(muni, output_path("Tabelas", "populacao_indigena_municipio_2022.xlsx"))
saveRDS(muni, output_path("intermediarios", "municipios_2022.rds"))
message("Indigenous population 2022 (V01690): ", fmt_br(sum(muni$total_indigenas_2022)))

# --- Age–sex structure ----------------------------------------------------------
# Single ages 0–100: men V01866–V01966, women V01967–V02067
age_vars <- tibble(
  variavel = c(sprintf("V%05d", 1866:1966), sprintf("V%05d", 1967:2067)),
  Sexo     = rep(c("Masculino", "Feminino"), each = 101),
  Idade    = rep(0:100, times = 2)
)

age_sex <- people |>
  select(any_of(age_vars$variavel)) |>
  summarise(across(everything(), \(x) sum(x, na.rm = TRUE))) |>
  pivot_longer(everything(), names_to = "variavel", values_to = "Pop") |>
  inner_join(age_vars, by = "variavel") |>
  mutate(Faixa_Etaria = cut(Idade,
                            breaks = c(seq(0, 70, by = 5), Inf),
                            labels = c(paste(seq(0, 65, 5), seq(4, 69, 5), sep = "-"), "70+"),
                            right = FALSE)) |>
  group_by(Faixa_Etaria, Sexo) |>
  summarise(Pop = sum(Pop), .groups = "drop") |>
  mutate(Pct = 100 * Pop / sum(Pop))

writexl::write_xlsx(age_sex, output_path("Tabelas", "populacao_idade_sexo_2022.xlsx"))

pyramid <- ggplot(age_sex, aes(x = Faixa_Etaria,
                               y = ifelse(Sexo == "Masculino", -Pct, Pct),
                               fill = Sexo)) +
  geom_col(width = 0.9) +
  coord_flip() +
  scale_y_continuous(labels = \(x) paste0(abs(x), "%")) +
  scale_fill_manual(values = c(Masculino = "#2C7FB8", Feminino = "#D95F0E")) +
  labs(title = "Pirâmide etária da população indígena — Censo 2022",
       x = "Faixa etária", y = "% da população indígena total", fill = NULL) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"))

ggsave(output_path("Graficos", "piramide_etaria_indigena_2022.png"),
       pyramid, width = 8, height = 7, dpi = 300, bg = "white")
