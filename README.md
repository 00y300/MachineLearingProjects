# PUE Forecasting and Classification — ESIF Data Center

This repository contains machine learning experiments focused on Power Usage Effectiveness (PUE) forecasting and classification for the Energy Systems Integration Facility (ESIF) Data Center. The project analyzes two years of 5-minute interval telemetry data to predict efficiency tiers and detect high-consumption anomalies. It emphasizes robust validation frameworks over headline accuracy metrics.

## Environment Setup

The project uses Nix Flakes for reproducible development environments. This configuration includes Python 3.13, PyTorch, scikit-learn, Jupyter/Quarto tools, and SQLite.

To activate the Nix environment:
```zsh
nix develop --command zsh
```

Alternatively, create a virtual environment and install dependencies:
```zsh
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Directory Structure

*   **`notebooks/`**: Analysis scripts available in both Quarto (`.qmd`) and Jupyter (`.ipynb`) formats.
    *   `LinearRegression.qmd` / `.ipynb`: PUE forecasting models (5min, 1h, 24h).
    *   `Classification.qmd` / `.ipynb`: Efficiency tier and anomaly detection classifiers.
*   **`datasets/`**: SQLite database (`power_data.db`) containing cleaned telemetry data.
*   **`models/`**: Serialized model artifacts (`.pkl`) and feature lists.
*   **`plots/`**: Generated visualizations for analysis reports.

## Analysis Workflows

The project is divided into two primary analytical pipelines:

1.  **Forecasting**: Uses Linear Regression and RidgeCV rather than tree-based models. Focuses on MAE (Mean Absolute Error) as the primary metric, noting that R² can be misleading for low-variance targets. Includes walk-forward cross-validation to simulate monthly retraining scenarios.
2.  **Classification**: Multiclass efficiency tier classification and binary anomaly detection. Implements a four-part validation framework: persistence baselines, walk-forward CV, feature ablation, and threshold tuning. Demonstrates that short-horizon autocorrelation often drives accuracy more than learned signal.

## Key Findings

*   **Linear Models Outperform Trees**: Simple linear regression achieved better results than XGBoost or HistGBM across all prediction horizons.
*   **Baseline Shift**: A significant operational baseline shift occurred in late March 2024, requiring careful handling of training windows.
*   **Persistence Baselines**: For time-series classification, predicting the previous state (persistence) often outperforms trained models on short horizons due to high autocorrelation.
*   **MAE > R²**: At longer horizons (24h), MAE remained stable (~0.008 PUE units) even when R² was near zero, making it a more honest metric for this dataset.

## Data Management

Raw data is downloaded from NREL and processed into a SQLite database (`power_data.db`) automatically when running the notebooks. The cleaning logic ensures physically impossible PUE values are removed before model training. Models expect features in `models/feature_columns.json`.

To generate the dataset, train models, and create visualizations:
```bash
# Using Quarto (requires quarto installed in PATH)
quarto render notebooks/LinearRegression.qmd --to html
quarto render notebooks/Classification.qmd --to html

# Or using Jupyter directly within the nix shell or venv
jupyter lab notebooks/Classification.ipynb
jupyter lab notebooks/LinearRegression.ipynb
```

## Running Notebooks

You can execute these analyses using either Quarto or Jupyter Notebook formats.

### Option 1: Quarto (Recommended)
Render the `.qmd` files to HTML:
```bash
quarto render notebooks/Classification.qmd --to html
quarto render notebooks/LinearRegression.qmd --to html
```

### Option 2: Jupyter Notebooks
Open the `.ipynb` files directly in VS Code (with the Python extension) or launch Jupyter Lab within the nix shell:
```bash
jupyter lab notebooks/Classification.ipynb
jupyter lab notebooks/LinearRegression.ipynb
```

---
