# r/01_ingest_nhanes.R
# NHANES 2017-2018:
#   - DPQ_J (Depression Screener: PHQ-9 items)
#   - DEMO_J (Demographics)
#   - HUQ_J (Hospital Utilization & Access to Care: includes HUQ090 mental health professional contact)
#
# Output:
#   data/processed/nhanes_phq9_prepared.csv
#
# Notes:
# - We filter to adults (age >= 18).
# - "in_treatment" is a proxy: HUQ090 (seen/talked to a mental health professional in past 12 months).

suppressPackageStartupMessages({
  library(haven)   # read_xpt
  library(dplyr)
  library(tidyr)
  library(readr)   # write_csv
})

# ----------------------------
# 1) File paths
# ----------------------------
raw_dir <- file.path("data", "raw", "nhanes_2017_2018")
out_dir <- file.path("data", "processed")
out_csv <- file.path(out_dir, "nhanes_phq9_prepared.csv")

dpq_path  <- file.path(raw_dir, "DPQ_J.XPT")
demo_path <- file.path(raw_dir, "DEMO_J.XPT")
huq_path  <- file.path(raw_dir, "HUQ_J.XPT")

# Safety checks
required_files <- c(dpq_path, demo_path, huq_path)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  msg <- paste(
    "Missing file(s). Make sure these exist in data/raw/nhanes_2017_2018/:",
    paste0(" - ", missing_files, collapse = "\n"),
    sep = "\n"
  )
  stop(msg)
}
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ----------------------------
# 2) Read XPT files
# ----------------------------
dpq  <- read_xpt(dpq_path)
demo <- read_xpt(demo_path)
huq  <- read_xpt(huq_path)

# ----------------------------
# 3) Prep DPQ: compute PHQ-9 total + severity
# ----------------------------
# PHQ-9 items in DPQ are DPQ010 ... DPQ090 (0-3), with special codes like 7/9 for missing.
phq_items <- c("DPQ010","DPQ020","DPQ030","DPQ040","DPQ050","DPQ060","DPQ070","DPQ080","DPQ090")

missing_phq <- setdiff(phq_items, names(dpq))
if (length(missing_phq) > 0) {
  msg <- paste(
    "DPQ file doesn't contain expected PHQ item columns:",
    paste0(" - ", missing_phq, collapse = "\n"),
    "Tip: run names(dpq) to inspect available columns.",
    sep = "\n"
  )
  stop(msg)
}

dpq_clean <- dpq %>%
  select(SEQN, all_of(phq_items)) %>%
  mutate(across(all_of(phq_items), ~ as.numeric(.x))) %>%
  # NHANES often uses 7=Refused, 9=Don't know
  mutate(across(all_of(phq_items), ~ ifelse(.x %in% c(7, 9), NA_real_, .x))) %>%
  mutate(
    phq9_complete = if_else(if_all(all_of(phq_items), ~ !is.na(.x)), TRUE, FALSE),
    phq9_total = if_else(phq9_complete, rowSums(across(all_of(phq_items))), NA_real_)
  ) %>%
  mutate(
    phq9_severity = case_when(
      is.na(phq9_total) ~ NA_character_,
      phq9_total <= 4  ~ "Minimal (0-4)",
      phq9_total <= 9  ~ "Mild (5-9)",
      phq9_total <= 14 ~ "Moderate (10-14)",
      phq9_total <= 19 ~ "Moderately Severe (15-19)",
      TRUE             ~ "Severe (20-27)"
    ),
    # common high-risk cutoff for more severe depression
    high_risk = case_when(
      is.na(phq9_total) ~ NA,
      phq9_total >= 15  ~ TRUE,
      TRUE              ~ FALSE
    ),
    # convenient flag for "clinically significant" symptoms
    moderate_plus = case_when(
      is.na(phq9_total) ~ NA,
      phq9_total >= 10  ~ TRUE,
      TRUE              ~ FALSE
    )
  )

# ----------------------------
# 4) Prep DEMO: demographics
# ----------------------------
demo_clean <- demo %>%
  select(SEQN, RIDAGEYR, RIAGENDR, RIDRETH1) %>%
  mutate(
    age_years = as.numeric(RIDAGEYR),
    sex = case_when(
      as.numeric(RIAGENDR) == 1 ~ "Male",
      as.numeric(RIAGENDR) == 2 ~ "Female",
      TRUE ~ "Unknown"
    ),
    race_ethnicity = case_when(
      as.numeric(RIDRETH1) == 1 ~ "Mexican American",
      as.numeric(RIDRETH1) == 2 ~ "Other Hispanic",
      as.numeric(RIDRETH1) == 3 ~ "Non-Hispanic White",
      as.numeric(RIDRETH1) == 4 ~ "Non-Hispanic Black",
      as.numeric(RIDRETH1) == 5 ~ "Other Race / Multi-Racial",
      TRUE ~ "Unknown"
    ),
    age_group = case_when(
      is.na(age_years) ~ "Unknown",
      age_years < 18   ~ "<18",
      age_years <= 25  ~ "18-25",
      age_years <= 35  ~ "26-35",
      age_years <= 45  ~ "36-45",
      age_years <= 55  ~ "46-55",
      age_years <= 65  ~ "56-65",
      TRUE             ~ "66+"
    )
  ) %>%
  select(SEQN, age_years, age_group, sex, race_ethnicity)

# ----------------------------
# 5) Prep HUQ: treatment proxy (mental health professional contact)
# ----------------------------
# HUQ090 = Seen mental health professional/past year
# Coding typically: 1=Yes, 2=No, 7=Refused, 9=Don't know
if (!("HUQ090" %in% names(huq))) {
  stop("HUQ090 not found in HUQ_J.XPT. Run names(huq) to inspect available columns.")
}

huq_clean <- huq %>%
  mutate(across(where(is.labelled), ~ as.numeric(.x))) %>%
  transmute(
    SEQN,
    in_treatment_raw = as.numeric(HUQ090),
    in_treatment = case_when(
      in_treatment_raw == 1 ~ TRUE,
      in_treatment_raw == 2 ~ FALSE,
      in_treatment_raw %in% c(7, 9) ~ NA,
      TRUE ~ NA
    ),
    treatment_proxy_source = "HUQ:HUQ090"
  )

# ----------------------------
# 6) Join tables and export prepared dataset
# ----------------------------
prepared <- dpq_clean %>%
  left_join(demo_clean, by = "SEQN") %>%
  left_join(huq_clean,  by = "SEQN") %>%
  # Adults only for this project
  filter(!is.na(age_years) & age_years >= 18)

# Quick sanity summaries
message("\nPrepared dataset summary:")
message("  Rows: ", nrow(prepared))
message("  PHQ-9 complete: ", sum(prepared$phq9_complete, na.rm = TRUE))
message("  Moderate+ (>=10): ", sum(prepared$moderate_plus == TRUE, na.rm = TRUE))
message("  High risk (>=15): ", sum(prepared$high_risk == TRUE, na.rm = TRUE))
message("  In treatment TRUE: ", sum(prepared$in_treatment == TRUE, na.rm = TRUE))
message("  In treatment FALSE: ", sum(prepared$in_treatment == FALSE, na.rm = TRUE))
message("  In treatment NA: ", sum(is.na(prepared$in_treatment)))

# Export
write_csv(prepared, out_csv, na = "")
message("\nWrote prepared CSV to: ", out_csv)
message("Next: open data/processed/nhanes_phq9_prepared.csv and confirm columns look good.")
