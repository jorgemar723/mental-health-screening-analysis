# Mental Health Screening Analysis

**A healthcare data analytics project examining depression severity and treatment access gaps using NHANES 2017–2018 data**

---

## Project Overview

This project analyzes mental health screening data from the National Health and Nutrition Examination Survey (NHANES) 2017–2018 to examine depression severity and gaps in mental health treatment access among U.S. adults. Using Patient Health Questionnaire-9 (PHQ-9) scores and healthcare utilization data, the analysis identifies disparities in mental health service access across demographic groups.

The analysis combines:
- **SQL (DuckDB)** for efficient data querying and analytic table construction
- **R** for statistical modeling, feature engineering, and regression analysis
- **Tableau** for interactive stakeholder dashboards and demographic breakdowns

---

## Key Findings

### Sample Characteristics

- **Analytic sample:** 5,068 U.S. adults aged 18+ with complete PHQ-9 data
- **Depression prevalence:**
  - 459 adults (9.1%) had clinically significant depressive symptoms (PHQ-9 ≥ 10)
  - 167 adults (3.3%) met high-risk criteria for severe depression (PHQ-9 ≥ 15)

### Treatment Access Gaps

Among adults with clinically significant depression:
- **68.4%** of those with PHQ-9 ≥ 10 reported no mental health professional contact in the past year
- **62.3%** of those with PHQ-9 ≥ 15 (high-risk) reported no mental health professional contact in the past year

---

## Statistical Analysis

### Regression Modeling

**Outcome variable:** Not receiving mental health treatment (binary)

**Covariates tested:**
- PHQ-9 severity category (minimal, mild, moderate, moderately severe, severe)
- Sex
- Age group
- Race/ethnicity

**Models compared:**
- **Baseline model:** Depression severity + sex + age group + race/ethnicity
- **Interaction model:** Depression severity × sex + age group + race/ethnicity

**Model selection:**
- Likelihood ratio test comparing baseline vs. interaction model: *p* = 0.57
- Interaction model showed higher AIC (worse fit)
- **Baseline model retained** (no evidence of severity-by-sex interaction)

### Key Results

**Depression severity** was strongly associated with treatment status:
- Compared to adults with mild symptoms (PHQ-9 5–9):
  - **Minimal symptoms** (PHQ-9 0–4): ~3× higher odds of being untreated (OR ≈ 3.05)
  - **Moderate, moderately severe, and severe categories were associated with lower odds of being untreated (OR < 1)

**Age** was a significant predictor:
- Adults aged **66+ had significantly higher odds of being untreated** (OR ≈ 2.10)

**Race/ethnicity** showed adjusted differences:
- Non-Hispanic White and Non-Hispanic Black adults had lower odds of being untreated compared to Mexican American adults

**Sex** was not a statistically significant predictor after adjustment for other covariates.

---

## Visualization & Dashboards

Interactive Tableau dashboards enable exploration of treatment gaps and depression severity across demographic subgroups. Users can filter by:
- PHQ-9 severity category
- Age group
- Sex
- Race/ethnicity

Dashboard screenshots are included in the `tableau/` folder for reference.

---

## Repository Structure
```
mental-health-screening-analysis/
├── r/                  # Data processing and statistical analysis scripts
├── sql/                # DuckDB queries for analytic table construction
├── outputs/            # Regression model results and summary tables
├── tableau/            # Dashboard screenshots
└── docs/               # Interpretation notes

```

---

## Reproducibility & Data Management

**Raw NHANES data files are not included in this repository.** 

All analytic datasets are generated locally using the provided SQL and R scripts.  
Processed outputs, regression results, and dashboard screenshots are included in the repository for transparency.


---

## Project Scope & Applications

This project demonstrates:
- **End-to-end healthcare data analytics** from raw survey data to stakeholder-ready dashboards
- **Mental health screening analysis** using validated psychiatric instruments (PHQ-9)
- **Applied statistical modeling** including logistic regression and interaction testing
- **Healthcare informatics skills** relevant to population health, health services research, and clinical analytics

This work is relevant for roles in healthcare analytics, health information management, public health informatics, and behavioral health data science.

---

## About

Developed as a portfolio project to demonstrate applied healthcare data science skills. This analysis uses publicly available NHANES data and follows best practices for reproducible research in health informatics.
