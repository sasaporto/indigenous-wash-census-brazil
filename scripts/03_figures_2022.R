# ------------------------------------------------------------------------------
# 03_figures_2022.R — access by state, for each indicator and territorial group
# Output: output/Graficos/<indicator>/<territorial group>/<Região>.png
#         output/Graficos/<indicator>/<territorial group>/Brasil_por_UF.png
# ------------------------------------------------------------------------------

source(here::here("scripts", "00_setup.R"))

households <- readRDS(output_path("intermediarios", "setores_2022_domicilios.rds"))

for (indicator in names(MAIN_DEFINITIONS)) {
  def <- definitions[[MAIN_DEFINITIONS[[indicator]]]]
  classified <- classify_access(households, def)

  for (group_name in names(TERRITORIAL_GROUPS_PUBLIC)) {
    subset_df <- filter(classified, Categoria_Territorial %in% TERRITORIAL_GROUPS_PUBLIC[[group_name]])
    if (nrow(subset_df) == 0) next
    folder <- c("Graficos", indicator, slug(group_name))

    # All states together
    summ <- summarise_access(subset_df, by = c("NM_UF", "Rural_Urbana"))
    p <- plot_access(summ, x = "NM_UF", x_label = "UF",
                     title = paste0(def$label, " — Brasil\n", group_name))
    ggsave(do.call(output_path, as.list(c(folder, "Brasil_por_UF.png"))),
           p, width = 14, height = 7, dpi = 300, bg = "white")

    # One chart per region
    for (region in sort(unique(subset_df$NM_REGIAO))) {
      summ <- subset_df |>
        filter(NM_REGIAO == region) |>
        summarise_access(by = c("NM_UF", "Rural_Urbana"))
      p <- plot_access(summ, x = "NM_UF", x_label = "UF",
                       title = paste0(def$label, " — ", region, "\n", group_name))
      ggsave(do.call(output_path, as.list(c(folder, paste0(slug(region), ".png")))),
             p, width = 10, height = 7, dpi = 300, bg = "white")
    }
  }
  message("Saved figures: ", def$label)
}
