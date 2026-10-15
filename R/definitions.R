# ------------------------------------------------------------------------------
# definitions.R — how each WASH indicator is built from Census 2022 variables
# ------------------------------------------------------------------------------
# Each definition lists which sector-aggregate variables (counts of Indigenous
# residents) go into each category. Keeping them here, in ONE place, means:
#   * every table and chart uses exactly the same rule;
#   * alternative rules can be compared side by side (sensitivity analysis).
#
# !! CHECK BEFORE USING !!
# Your scripts used two different water definitions:
#   - "Dados_gerais.R":          V01573 counted as ADEQUATE
#   - "Gráficos.R" and others:   V01573 counted as INADEQUATE (precarious)
# Both are kept below. `water_2022` points to the later version; change it if
# the PNSI report used the other one.
# ------------------------------------------------------------------------------

definitions <- list(

  water_2022_v1 = list(
    label = "Abastecimento de água (V01573 = adequado)",
    categories = list(
      Adequado        = c("V01572", "V01573", "V01575", "V01581"),
      Inadequado      = c("V01574", "V01576", "V01578", "V01579", "V01582",
                          "V01584", "V01585", "V01587", "V01588", "V01590", "V01591"),
      Sem_atendimento = c("V01577", "V01580", "V01583", "V01586", "V01589",
                          "V01592", "V01593", "V01594", "V01595")
    )
  ),

  water_2022_v2 = list(
    label = "Abastecimento de água (V01573 = inadequado)",
    categories = list(
      Adequado        = c("V01572", "V01575", "V01581"),
      Inadequado      = c("V01573", "V01574", "V01576", "V01578", "V01579", "V01582",
                          "V01584", "V01585", "V01587", "V01588", "V01590", "V01591"),
      Sem_atendimento = c("V01577", "V01580", "V01583", "V01586", "V01589",
                          "V01592", "V01593", "V01594", "V01595")
    )
  ),

  sewage_2022 = list(
    label = "Esgotamento sanitário",
    categories = list(
      Adequado        = c("V01656", "V01657", "V01658"),
      Inadequado      = c("V01659", "V01660"),
      Sem_atendimento = c("V01661", "V01662", "V01663")
    )
  ),

  waste_2022 = list(
    label = "Resíduos sólidos",
    categories = list(
      Adequado        = c("V01672", "V01673"),
      Sem_atendimento = c("V01674", "V01675", "V01676", "V01677")
    )
  )
)

# The definitions used in the main tables and figures
MAIN_DEFINITIONS <- c(
  agua       = "water_2022_v2",
  esgoto     = "sewage_2022",
  residuos   = "waste_2022"
)

# Order and colours of the categories in every chart
CATEGORY_LEVELS <- c("Adequado", "Inadequado", "Sem_atendimento")
CATEGORY_COLOURS <- c(
  Adequado        = "#004A7C",
  Inadequado      = "#BDBDBD",
  Sem_atendimento = "#4A4A4A"
)

# Territorial groups used to split the results (see add_territorial_category())
# Public IBGE data: sector type only
TERRITORIAL_GROUPS_PUBLIC <- list(
  "Todos os setores"              = c("Agrupamento indígena (tipo 5)", "Outros setores"),
  "Agrupamento indígena (tipo 5)" = c("Agrupamento indígena (tipo 5)"),
  "Outros setores"                = c("Outros setores")
)
