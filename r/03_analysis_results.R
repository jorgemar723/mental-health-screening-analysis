suppressPackageStartupMessages({
  library(duckdb)
  library(DBI)
})

con <- dbConnect(duckdb::duckdb(), dbdir = "data/processed/nhanes.duckdb", read_only = FALSE)

sql <- paste(readLines("sql/01_build_analysis_table.sql"), collapse = "\n")
dbExecute(con, sql)

dbDisconnect(con, shutdown = TRUE)

cat("Done. Check data/processed/nhanes_analysis_table.csv\n")
