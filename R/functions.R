# ------------------------------------------------------------------------------
# functions.R — reusable steps of the pipeline
# ------------------------------------------------------------------------------

# --- Reading -------------------------------------------------------------------

# Census sector codes have 15 digits. Excel/openxlsx often read them as numbers
# (and sometimes print them as 2.1e+14). This always returns clean text codes.
as_sector_code <- function(x) {
  if (is.numeric(x)) x <- format(x, scientific = FALSE, trim = TRUE)
  x <- trimws(as.character(x))
  sub("\\.0+$", "", x)
}

# Read an IBGE sector table and standardise it:
#   * CD_setor / cd_setor  ->  CD_SETOR (text)
#   * all V0xxxx columns   ->  numeric ("X" and other suppression codes become NA)
read_sector_table <- function(path, sheet = 1) {
  df <- openxlsx::read.xlsx(path, sheet = sheet)
  names(df)[tolower(names(df)) == "cd_setor"] <- "CD_SETOR"
  if (!"CD_SETOR" %in% names(df)) stop("No CD_SETOR column in ", path, call. = FALSE)
  df$CD_SETOR <- as_sector_code(df$CD_SETOR)

  v_cols <- grep("^V\\d+$", names(df), value = TRUE)
  df[v_cols] <- lapply(df[v_cols], function(col) suppressWarnings(as.numeric(col)))
  df
}

# --- Checks ----------------------------------------------------------------------

# Warn if a sector appears more than once (would double-count people).
check_unique_sectors <- function(sectors) {
  dup <- sectors$CD_SETOR[duplicated(sectors$CD_SETOR)]
  if (length(dup)) {
    warning(length(unique(dup)), " sector(s) appear more than once, e.g. ",
            toString(head(unique(dup), 5)), call. = FALSE)
  }
  invisible(dup)
}

# --- Classification -----------------------------------------------------------

# Add one column per category (Adequado, Inadequado, Sem_atendimento) by summing
# the variables listed in the definition. Missing values count as 0.
classify_access <- function(df, definition) {
  needed <- unlist(definition$categories, use.names = FALSE)
  missing_vars <- setdiff(needed, names(df))
  if (length(missing_vars)) {
    stop("Variables missing for '", definition$label, "': ", toString(missing_vars), call. = FALSE)
  }
  for (cat_name in names(definition$categories)) {
    vars <- definition$categories[[cat_name]]
    df[[cat_name]] <- rowSums(df[, vars, drop = FALSE], na.rm = TRUE)
  }
  df
}

# Territorial category (from "3.R") and rural/urban label.
#   Em TI                             : sector inside an Indigenous land
#   Agrupamento tipo 5 fora de TI     : Indigenous settlement (CD_TIPO 5) outside a TI
#   Fora de TI e fora de agrupamento  : everything else
# Public IBGE data have no Indigenous-land column (Situacao_TI needs a spatial
# overlay with Indigenous-land boundaries); then only sector type is used:
#   Agrupamento indígena (tipo 5) / Outros setores
add_territorial_category <- function(df) {
  df$Rural_Urbana <- ifelse(df$SITUACAO %in% c("Rural", "Urbana"), df$SITUACAO, NA_character_)
  tipo5 <- as.character(df$CD_TIPO) == "5"

  if (!"Situacao_TI" %in% names(df)) {
    df$Categoria_Territorial <- ifelse(tipo5, "Agrupamento indígena (tipo 5)", "Outros setores")
    return(df)
  }
  # Compare without accents/case, so encoding differences between computers
  # ("indígena" vs "indÃ­gena") never silently drop sectors
  inside_ti <- startsWith(toupper(stringi::stri_trans_general(df$Situacao_TI, "Latin-ASCII")), "DENTRO")
  df$Categoria_Territorial <- dplyr::case_when(
    inside_ti                                    ~ "Em TI",
    tipo5                                        ~ "Agrupamento tipo 5 fora de TI",
    TRUE                                         ~ "Fora de TI e fora de agrupamento"
  )
  df
}

# Census 2010 microdata: water access from V0208 (source) and V0209 (piped water),
# following the rule in "Dados_gerais_2010.R".
classify_water_2010 <- function(V0208, V0209) {
  s <- as.character(V0208)
  p <- as.character(V0209)
  dplyr::case_when(
    s %in% c("1", "2", "9") & p == "1"                    ~ "Adequado",
    s %in% c("1", "2", "9") & p == "2"                    ~ "Inadequado",
    s == "3" & p %in% c("2", "3")                         ~ "Inadequado",
    s %in% as.character(4:8) & p %in% c("1", "2", "3")    ~ "Inadequado",
    s == "9" & p == "3"                                   ~ "Inadequado",
    TRUE                                                  ~ "Sem_atendimento"
  )
}

# --- Summaries ---------------------------------------------------------------------

# Sum each category by group and add percentages. Also adds a "Total" row per
# group that combines rural and urban, when Rural_Urbana is a grouping variable.
#   extra: other columns to sum alongside (e.g. "V01501", total Indigenous residents)
summarise_access <- function(df, by, categories = CATEGORY_LEVELS, extra = NULL) {
  categories <- intersect(categories, names(df))
  extra <- intersect(extra, names(df))

  sum_up <- function(d, groups) {
    d |>
      dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
      dplyr::summarise(dplyr::across(dplyr::all_of(c(extra, categories)), \(x) sum(x, na.rm = TRUE)),
                       .groups = "drop")
  }

  out <- sum_up(df, by)
  if ("Rural_Urbana" %in% by) {
    total <- sum_up(df, setdiff(by, "Rural_Urbana"))
    total$Rural_Urbana <- "Total"
    out <- dplyr::bind_rows(out |> dplyr::filter(!is.na(Rural_Urbana)), total)
    out$Rural_Urbana <- factor(out$Rural_Urbana, levels = c("Rural", "Urbana", "Total"))
  }

  out$Total <- rowSums(out[, categories, drop = FALSE])
  for (cat_name in categories) {
    out[[paste0("pct_", cat_name)]] <- ifelse(out$Total > 0, 100 * out[[cat_name]] / out$Total, NA_real_)
  }
  dplyr::arrange(out, dplyr::across(dplyr::all_of(by)))
}

# Compare two definitions of the same indicator on the same data:
# how many people change category when the rule changes?
compare_definitions <- function(df, def_a, def_b, by = NULL) {
  a <- summarise_access(classify_access(df, def_a), by = by)
  b <- summarise_access(classify_access(df, def_b), by = by)
  a$definicao <- def_a$label
  b$definicao <- def_b$label
  dplyr::bind_rows(a, b)
}

# --- Figures ---------------------------------------------------------------------

# 100% stacked bars of access, one bar per unit (state, municipality...) and one panel
# each for Rural / Urbana / Total.
plot_access <- function(summary_df, x, title, x_label = x) {
  long <- summary_df |>
    tidyr::pivot_longer(dplyr::starts_with("pct_"), names_to = "Categoria", values_to = "pct") |>
    dplyr::mutate(Categoria = factor(sub("^pct_", "", Categoria), levels = rev(CATEGORY_LEVELS)))

  ggplot2::ggplot(long, ggplot2::aes(x = .data[[x]], y = pct, fill = Categoria)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::facet_wrap(~ Rural_Urbana) +
    ggplot2::scale_y_continuous(labels = \(x) paste0(x, "%"), expand = c(0, 0)) +
    ggplot2::scale_fill_manual(values = CATEGORY_COLOURS, drop = TRUE,
                               labels = \(x) gsub("_", " ", x)) +
    ggplot2::labs(title = title, x = x_label, y = "Proporção da população indígena", fill = NULL) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1),
      legend.position = "top",
      panel.grid.major.x = ggplot2::element_blank()
    )
}

# Brazilian number format: 4.733 / 12,5
fmt_br <- function(x) format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE)

# Safe file name from a label ("Em TI ou agrupamento" -> "Em_TI_ou_agrupamento")
slug <- function(x) {
  x <- gsub("[^[:alnum:]]+", "_", stringi::stri_trans_general(x, "Latin-ASCII"))
  gsub("^_+|_+$", "", x)
}
