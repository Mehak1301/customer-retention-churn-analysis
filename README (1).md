# Customer Retention Analysis & Churn Prediction

End-to-end analysis of customer retention using SQL for data engineering, Python for churn prediction, and Power BI for visualization.

## Overview

This project analyzes customer purchase behavior on the Online Retail II dataset to understand retention patterns, segment customers by value, and predict churn. It combines SQL Server for data cleaning and cohort/RFM engineering, Python (scikit-learn) for predictive modeling, and Power BI for an interactive dashboard.

## Tools & Tech

- **SQL Server** — data cleaning, cohort analysis, RFM segmentation
- **Python (pandas, scikit-learn)** — churn prediction modeling
- **Power BI** — interactive retention dashboard

## Dataset

[Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (UCI Machine Learning Repository) — UK-based online retail transactions from 2009–2011.

## Methodology

1. **Data Cleaning** — removed cancelled orders, missing customer IDs, and invalid quantity/price values.
2. **Cohort Analysis** — grouped customers by month of first purchase, tracked retention over subsequent months.
3. **RFM Segmentation** — scored customers on Recency, Frequency, and Monetary value; segmented into groups (Champions, Loyal, At Risk, Lost, etc.).
4. **Churn Prediction** — trained Logistic Regression and Random Forest models using frequency and monetary features to predict churn.
5. **Dashboard** — built an interactive Power BI dashboard to visualize cohort retention trends and RFM segments.

## Key Findings

- The top customer segment (**Champions**, 22.9% of customers) generated **68.9%** of total revenue.
- Month-1 retention averaged **21.2%** across cohorts.
- Overall churn rate (90+ days inactive): **50.9%**.
- Logistic Regression predicted churn with **68.7% accuracy** and **0.77 AUC-ROC**, using purchase frequency and monetary value as features.

## Project Structure

```
├── sql/
│   └── customer_retention_analysis.sql     # cleaning, cohort, RFM, churn labeling
├── python/
│   └── churn_prediction_model.py           # churn prediction model
├── dashboard/
│   └── retention_dashboard.pbix            # Power BI dashboard (or screenshots)
└── README.md
```

## How to Run

1. Run `sql/customer_retention_analysis.sql` in SQL Server to build the cleaned tables, cohorts, RFM segments, and churn labels.
2. Export the `churn_flagged` table as CSV.
3. Run `python/churn_prediction_model.py` (or open in Google Colab) with the exported CSV to train and evaluate the churn model.
4. Open `dashboard/retention_dashboard.pbix` in Power BI to explore the interactive dashboard.

## Dashboard Preview

*(Add a screenshot of your Power BI dashboard here)*
