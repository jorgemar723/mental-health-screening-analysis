### Mental Health Screening Analysis (NHANES 2017–2018)

# Overview

This project analyzes nationally representative U.S. survey data to examine the prevalence of depressive symptoms and gaps in mental health treatment access among adults. Using validated screening tools and healthcare utilization data, the analysis focuses on identifying treatment gaps among individuals with clinically significant and high-risk depressive symptoms.

The goal of this project is to demonstrate an end-to-end healthcare data analytics workflow, from raw data ingestion to analytic dataset construction, statistical analysis, and stakeholder-ready reporting.

# Data Source

National Health and Nutrition Examination Survey (NHANES) 2017–2018

Publicly available data collected by the Centers for Disease Control and Prevention (CDC)

Population: U.S. adults aged 18 years and older

Key NHANES files used:

DPQ_J: Depression Screener (PHQ-9)

DEMO_J: Demographics

HUQ_J: Health Care Utilization

All data used in this project are de-identified and publicly accessible.

# Methods

Depression Screening

Depressive symptom severity was measured using the Patient Health Questionnaire-9 (PHQ-9), a validated mental health screening instrument widely used in clinical and public health settings.

Severity categories:

Minimal: 0–4

Mild: 5–9

Moderate: 10–14

Moderately Severe: 15–19

Severe: 20–27

Two clinically relevant groups were defined:

Clinically significant symptoms: PHQ-9 ≥ 10

High-risk symptoms: PHQ-9 ≥ 15

Only participants with complete PHQ-9 responses were included in the analytic sample.

# Treatment Access Proxy

Mental health treatment access was proxied using self-reported contact with a mental health professional in the past 12 months (NHANES variable HUQ090).

This measure captures recent mental health service contact but does not reflect treatment quality, diagnosis, or continuity of care.

# Analytic Sample

Adults aged 18+

Complete PHQ-9 data

Final sample size: 5,068 individuals

# Key Findings

Depression Severity

459 adults (9.1%) had clinically significant depressive symptoms (PHQ-9 ≥ 10)

167 adults (3.3%) met high-risk criteria (PHQ-9 ≥ 15)

# Treatment Gaps

Among adults with PHQ-9 ≥ 10:

68.4% reported no mental health professional contact in the past year

Among adults with PHQ-9 ≥ 15:

62.3% reported no mental health professional contact in the past year

These results indicate that a majority of adults with moderate to severe depressive symptoms are not receiving mental health care, highlighting a substantial treatment access gap.

# Tools and Technologies

R: Data ingestion, cleaning, feature engineering, and statistical analysis

DuckDB SQL: Analytic dataset construction and transformation

Power BI: Interactive dashboards and stakeholder-focused visualizations

GitHub: Version control and project documentation

# Limitations

PHQ-9 is a screening tool and does not constitute a clinical diagnosis

Treatment access is based on self-reported survey responses

Cross-sectional survey data limits causal interpretation

# Project Purpose

This project was developed as a portfolio piece to demonstrate applied healthcare data analytics skills, with a focus on mental health screening, data quality, and treatment access analysis.