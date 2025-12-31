# analysis_logistic_regression.R
# Logistic regression on depression treatment gap using NHANES-derived "prepared" table
#
# Models:
#   1) Baseline: severity + sex + age_group + race_ethnicity
#   2) Interaction: baseline + severity * sex
#
# Outcome:
#   not_in_treatment = 1 if NOT receiving treatment, 0 if receiving treatment
#
# Data source:
#   Expects an in-memory dataframe named `prepared` (created earlier in your pipeline).

suppressPackageStartupMessages({
  library(dplyr)
  library(broom)
  library(readr)
})

# -----------------------------
# 1) Load data
# -----------------------------
if (!exists("prepared")) {
  stop("Object `prepared` not found in environment. Run your ingest/duckdb scripts first.")
}

df_raw <- prepared

# -----------------------------
# 2) Column mapping (matches your 'prepared' columns)
# -----------------------------
COL_IN_TREATMENT    <- "in_treatment"     # 1 = in treatment, 0 = not in treatment
COL_SEVERITY        <- "phq9_severity"    # categories like Minimal/Mild/Moderate/...
COL_SEX             <- "sex"              # Male/Female
COL_AGE_GROUP       <- "age_group"        # 18-25, 26-35, ...
COL_RACE_ETHNICITY  <- "race_ethnicity"   # race/ethnicity labels

needed_cols <- c(COL_IN_TREATMENT, COL_SEVERITY, COL_SEX, COL_AGE_GROUP, COL_RACE_ETHNICITY)
missing_cols <- setdiff(needed_cols, names(df_raw))

if (length(missing_cols) > 0) {
  stop(paste0(
    "Missing required column(s): ", paste(missing_cols, collapse = ", "), "\n\n",
    "Available columns are:\n", paste(names(df_raw), collapse = ", ")
  ))
}

# -----------------------------
# 3) Prepare analysis dataset
# -----------------------------
df <- df_raw %>%
  mutate(
    # Convert in_treatment to integer 0/1 safely
    in_treatment_int = as.integer(.data[[COL_IN_TREATMENT]]),
    
    # Create outcome: 1 = not in treatment, 0 = in treatment
    not_in_treatment = 1L - in_treatment_int,
    
    # Standardize predictors as factors (categorical)
    severity       = factor(.data[[COL_SEVERITY]]),
    sex            = factor(.data[[COL_SEX]]),
    age_group      = factor(.data[[COL_AGE_GROUP]]),
    race_ethnicity = factor(.data[[COL_RACE_ETHNICITY]])
  ) %>%
  filter(
    !is.na(not_in_treatment),
    !is.na(severity),
    !is.na(sex),
    !is.na(age_group),
    !is.na(race_ethnicity)
  )

cat("\n--- Data Check ---\n")
cat("Rows used:", nrow(df), "\n")
cat("Outcome (not_in_treatment) distribution:\n")
print(table(df$not_in_treatment, useNA = "ifany"))
cat("\nSeverity levels:\n")
print(levels(df$severity))
cat("\nSex levels:\n")
print(levels(df$sex))
cat("\nAge group levels:\n")
print(levels(df$age_group))
cat("\nRace/ethnicity levels:\n")
print(levels(df$race_ethnicity))

# Optional: subgroup counts to sanity-check tiny groups (useful for README)
cat("\n--- Subgroup counts (severity x sex) ---\n")
print(with(df, table(severity, sex)))

# -----------------------------
# 4) Fit logistic regression models
# -----------------------------
m_baseline <- glm(
  not_in_treatment ~ severity + sex + age_group + race_ethnicity,
  data = df,
  family = binomial()
)

m_interaction <- glm(
  not_in_treatment ~ severity * sex + age_group + race_ethnicity,
  data = df,
  family = binomial()
)

cat("\n=============================\n")
cat("Baseline Model Summary\n")
cat("=============================\n")
print(summary(m_baseline))

cat("\n=============================\n")
cat("Interaction Model Summary\n")
cat("=============================\n")
print(summary(m_interaction))

# Likelihood ratio test: does adding severity*sex improve fit?
cat("\n=============================\n")
cat("Likelihood Ratio Test (Baseline vs Interaction)\n")
cat("=============================\n")
print(anova(m_baseline, m_interaction, test = "Chisq"))

# -----------------------------
# 5) Odds ratios + confidence intervals (tidy tables)
# -----------------------------
tidy_or <- function(model) {
  # Use confint.default for speed/stability; confint(model) is profile-likelihood and can be slow.
  ci <- suppressWarnings(confint.default(model))
  broom::tidy(model) %>%
    mutate(
      conf.low  = ci[, 1],
      conf.high = ci[, 2],
      odds_ratio = exp(estimate),
      or_low     = exp(conf.low),
      or_high    = exp(conf.high)
    ) %>%
    select(term, estimate, std.error, statistic, p.value, odds_ratio, or_low, or_high)
}

or_baseline <- tidy_or(m_baseline)
or_interaction <- tidy_or(m_interaction)

cat("\n=============================\n")
cat("Baseline Odds Ratios (exp(beta))\n")
cat("=============================\n")
print(or_baseline)

cat("\n=============================\n")
cat("Interaction Odds Ratios (exp(beta))\n")
cat("=============================\n")
print(or_interaction)

# -----------------------------
# 6) Export outputs (for README / portfolio)
# -----------------------------
out_dir <- "outputs"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

write_csv(or_baseline, file.path(out_dir, "logit_baseline_odds_ratios.csv"))
write_csv(or_interaction, file.path(out_dir, "logit_interaction_odds_ratios.csv"))

# Model fit stats (AIC + pseudo quick glance)
fit_stats <- tibble(
  model = c("baseline", "interaction"),
  n = c(nobs(m_baseline), nobs(m_interaction)),
  aic = c(AIC(m_baseline), AIC(m_interaction))
)
write_csv(fit_stats, file.path(out_dir, "logit_model_fit_stats.csv"))

cat("\nSaved outputs to:\n")
cat(" - outputs/logit_baseline_odds_ratios.csv\n")
cat(" - outputs/logit_interaction_odds_ratios.csv\n")
cat(" - outputs/logit_model_fit_stats.csv\n")

cat("\nDone.\n")
