# data/

Nothing in this folder is committed to Git. The scripts fill it.

```
data/ibge/2022/    ← created by scripts/01_census2022_sectors.R
```

| File | Source |
|---|---|
| `Agregados_por_setores_basico_BR_*.zip` | IBGE, Censo Demográfico 2022, Agregados por setores censitários |
| `Agregados_por_setores_domicilios_indigenas_BR.zip` | same |
| `Agregados_por_setores_pessoas_indigenas_BR.zip` | same |

Source: <https://ftp.ibge.gov.br/Censos/Censo_Demografico_2022/Agregados_por_Setores_Censitarios/Agregados_por_Setor_csv/>

The 2010 microdata are cached by `censobr`, so no file is needed here.

No internet where you run the code? Download the three zips by hand and put them in
`data/ibge/2022/`.
