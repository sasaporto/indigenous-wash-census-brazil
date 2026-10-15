# ------------------------------------------------------------------------------
# 06_change_2010_2022.R — Indigenous population by municipality, 2010 vs 2022
# Needs: 04_population_2022.R and 05_census2010.R to have run.
#
# Caution when interpreting: the 2022 Census asked "você se considera indígena?"
# in more areas than 2010 and covered more Indigenous lands, so part of the change
# is MEASUREMENT, not demographic growth. The 2010 figures are survey-weighted
# estimates from the sample microdata; the 2022 figures are counts.
# Output: output/Tabelas/mudanca_populacao_indigena_2010_2022.xlsx
#         output/Graficos/populacao_indigena_2010_vs_2022.png
# ------------------------------------------------------------------------------

source(here::here("scripts", "00_setup.R"))

muni_2010 <- readRDS(output_path("intermediarios", "municipios_2010.rds")) |>
  transmute(CD_MUN = as.character(code_muni), total_indigenas_2010 = total_indigenas)
muni_2022 <- readRDS(output_path("intermediarios", "municipios_2022.rds")) |>
  mutate(CD_MUN = as.character(CD_MUN))

change <- full_join(muni_2010, muni_2022, by = "CD_MUN") |>
  mutate(
    across(c(total_indigenas_2010, total_indigenas_2022), \(x) coalesce(x, 0)),
    diferenca = total_indigenas_2022 - total_indigenas_2010,
    variacao_pct = ifelse(total_indigenas_2010 > 0,
                          100 * diferenca / total_indigenas_2010, NA_real_),
    situacao = case_when(
      total_indigenas_2010 == 0 ~ "Sem indígenas em 2010",
      total_indigenas_2022 == 0 ~ "Sem indígenas em 2022",
      TRUE                      ~ "Indígenas nos dois censos"
    )
  ) |>
  arrange(desc(abs(diferenca)))

national <- change |>
  summarise(across(c(total_indigenas_2010, total_indigenas_2022), sum)) |>
  mutate(variacao_pct = 100 * (total_indigenas_2022 / total_indigenas_2010 - 1))
print(national)
print(count(change, situacao))

writexl::write_xlsx(list(Municipios = change, Brasil = national),
                    output_path("Tabelas", "mudanca_populacao_indigena_2010_2022.xlsx"))

p <- change |>
  filter(total_indigenas_2010 > 0, total_indigenas_2022 > 0) |>
  ggplot(aes(total_indigenas_2010, total_indigenas_2022)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(alpha = 0.35, size = 1.2, colour = "#004A7C") +
  scale_x_log10(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  scale_y_log10(labels = scales::label_number(big.mark = ".", decimal.mark = ",")) +
  labs(title = "População indígena por município: Censo 2010 vs Censo 2022",
       subtitle = "Acima da linha tracejada: mais pessoas indígenas em 2022 (escalas logarítmicas)",
       x = "2010 (estimativa da amostra)", y = "2022 (contagem)") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

ggsave(output_path("Graficos", "populacao_indigena_2010_vs_2022.png"),
       p, width = 8, height = 7, dpi = 300, bg = "white")
