-- sql/01_build_analysis_table.sql
-- Build analysis-ready table for NHANES 2017-2018 PHQ-9 project
-- Input:  data/processed/nhanes_phq9_prepared.csv
-- Output: data/processed/nhanes_analysis_table.csv

-- 1) Create a view over the prepared CSV (read_csv_auto infers types)
create or replace view nhanes_prepared as
select *
from read_csv_auto('data/processed/nhanes_phq9_prepared.csv');

-- 2) Define the analytic cohort + derived fields in one place
create or replace table nhanes_analysis as
with base as (
  select
    -- identifiers
    cast(SEQN as bigint) as seqn,

    -- demographics
    cast(age_years as integer) as age_years,
    age_group,
    sex,
    race_ethnicity,

    -- phq data
    cast(phq9_complete as boolean) as phq9_complete,
    cast(phq9_total as integer) as phq9_total,
    phq9_severity,

    cast(moderate_plus as boolean) as moderate_plus,
    cast(high_risk as boolean) as high_risk,

    -- treatment proxy
    cast(in_treatment as boolean) as in_treatment,
    treatment_proxy_source

  from nhanes_prepared
)
select
  *,
  -- extra helpful groupings for BI / analysis
  case
    when phq9_total is null then null
    when phq9_total >= 20 then 'Severe (20-27)'
    when phq9_total >= 15 then 'Moderately Severe (15-19)'
    when phq9_total >= 10 then 'Moderate (10-14)'
    when phq9_total >= 5  then 'Mild (5-9)'
    else 'Minimal (0-4)'
  end as severity_bucket,

  case
    when phq9_total is null then null
    when phq9_total >= 10 then 'Clinically significant (>=10)'
    else 'Below clinical threshold (<10)'
  end as clinical_group

from base
where
  age_years >= 18
  and phq9_complete = true
  and phq9_total is not null;

-- 3) Export final table for Power BI Service
copy nhanes_analysis
to 'data/processed/nhanes_analysis_table.csv'
(header, delimiter ',');

-- 4) Produce a compact summary table (copy/paste into README)
--    NOTE: This prints to the SQL results output (does not export unless you want it to).
select
  count(*) as n_adults_phq_complete,
  sum(case when moderate_plus then 1 else 0 end) as n_moderate_plus,
  round(100.0 * sum(case when moderate_plus then 1 else 0 end) / count(*), 2) as pct_moderate_plus,
  sum(case when high_risk then 1 else 0 end) as n_high_risk,
  round(100.0 * sum(case when high_risk then 1 else 0 end) / count(*), 2) as pct_high_risk,
  sum(case when in_treatment then 1 else 0 end) as n_in_treatment,
  round(100.0 * sum(case when in_treatment then 1 else 0 end) / count(*), 2) as pct_in_treatment
from nhanes_analysis;

-- 5) Treatment gap among clinically significant cases (>=10)
select
  count(*) as n_clinical,
  sum(case when in_treatment then 1 else 0 end) as n_in_treatment,
  sum(case when not in_treatment then 1 else 0 end) as n_not_in_treatment,
  round(100.0 * sum(case when not in_treatment then 1 else 0 end) / count(*), 2) as pct_not_in_treatment
from nhanes_analysis
where moderate_plus = true;

-- 6) Treatment gap among high-risk cases (>=15)
select
  count(*) as n_high_risk,
  sum(case when in_treatment then 1 else 0 end) as n_in_treatment,
  sum(case when not in_treatment then 1 else 0 end) as n_not_in_treatment,
  round(100.0 * sum(case when not in_treatment then 1 else 0 end) / count(*), 2) as pct_not_in_treatment
from nhanes_analysis
where high_risk = true;
