# Run the pipeline. Open indigenous-wash-census.Rproj first.

# Public part: IBGE data only, downloaded automatically. Anyone can run this.
public <- c(
  "01_census2022_sectors.R",   # downloads 2022 sector aggregates (~40 MB, first run only)
  "02_indicators_2022.R",
  "03_figures_2022.R",
  "04_population_2022.R",
  "05_census2010.R",           # downloads 2010 microdata via censobr (large, first run only)
  "06_change_2010_2022.R"
)

for (s in public) {
  message("\n==== ", s, " ====")
  source(here::here("scripts", s), local = new.env())
}
