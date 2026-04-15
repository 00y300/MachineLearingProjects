# PUE Forecasting and Classification — ESIF Data Center

This repository contains machine learning experiments focused on Power Usage Effectiveness (PUE) forecasting and classification for the [Energy Systems Integration Facility (ESIF)](https://www.nrel.gov/esif/) HPC Data Center at NREL. The project analyzes high-resolution telemetry data to predict efficiency tiers and detect high-consumption anomalies, emphasizing robust validation frameworks over headline accuracy metrics.

## Dataset Source

**NLR HPC Facility Power Usage Effectiveness (PUE) Data**
- **Publisher**: National Laboratory of the Rockies / NREL
- **Dataset License**: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **Data Catalog**: [data.gov](https://catalog.data.gov/dataset/nlr-hpc-facility-power-usage-effectiveness-pue-data)
- **Contact**: Struan Clark (Struan.Clark@nlr.gov)

### ESIF Data Center Background
The ESIF houses a petascale HPC data center engineered for exceptional energy efficiency, featuring warm water liquid cooling and waste heat capture/re-use. The facility achieved an annualized PUE rating of **1.036**, making it one of the world's most energy-efficient data centers (recognized with Data Center Dynamics Eco-Sustainability Awards).

### Data Specifications

**Collection Frequency**: 5-minute intervals  
**Format**: Parquet and compressed CSV available from NREL  
**Time Range**: Multi-year timeseries (check actual data coverage after download)

#### Power Metrics Fields
| Field | Unit | Description |
|-------|------|-------------|
| `ts` | timestamp | Timestamp |
| `pue` | ratio | Power Usage Effectiveness |
| `it_power_kw` | kW | IT equipment power consumption |
| `cooling_kw` | kW | Cooling load (fans, pipe trace heaters, tower filter pump) |
| `hvac_kw` | kW | HVAC systems (fan walls, fan coils, make-up air unit) |
| `pump_kw` | kW | Pumps (energy recovery water loop, tower water loops, boost pumps) |
| `plug_and_light_kw` | kW | Lights and utility plugs (includes crank-case heater) |
| `energyReuse` | ratio | Energy Reuse Effectiveness |

#### Weather Station Fields
| Field | Unit | Description |
|-------|------|-------------|
| `ts` | timestamp | Timestamp |
| `outside_air_temp` | °F | Outside air temperature |
| `outside_air_humidity` | % | Relative humidity percent |

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
    *   `LinearRegression.qmd` / `.ipynb`: PUE forecasting models (5min, 1h, 24h horizons).
    *   `Classification.qmd` / `.ipynb`: Efficiency tier classification and anomaly detection classifiers.
*   **`datasets/`**: SQLite database (`power_data.db`) containing cleaned telemetry data.
*   **`models/`**: Serialized model artifacts (`.pkl`) and feature column definitions.
*   **`plots/`**: Generated visualizations for analysis reports.

## Analysis Workflows

The project is divided into two primary analytical pipelines:

### 1. Forecasting Pipeline
- **Models**: Linear Regression and RidgeCV (tree-based models underperform on this dataset)
- **Metrics**: MAE (Mean Absolute Error) prioritized over R² (R² can be misleading for low-variance targets)
- **Validation**: Walk-forward cross-validation simulating monthly retraining scenarios
- **Horizons**: 5-minute, 1-hour, and 24-hour prediction windows

### 2. Classification Pipeline
- **Tasks**: Multiclass efficiency tier classification + binary anomaly detection
- **Validation Framework**:
  - Persistence baselines (predicting previous state)
  - Walk-forward CV
  - Feature ablation studies
  - Threshold tuning for operational use
- **Key Insight**: Short-horizon autocorrelation often drives accuracy more than learned features

## Key Findings

*   **Linear Models Outperform Trees**: Simple linear regression achieved better results than XGBoost or HistGBM across all prediction horizons on this dataset.
*   **Baseline Shift**: A significant operational baseline shift occurred in late March 2024, requiring careful handling of training windows and model retraining.
*   **Persistence Baselines**: For time-series classification, predicting the previous state (persistence) often outperforms trained models on short horizons due to high autocorrelation in PUE readings.
*   **MAE > R²**: At longer horizons (24h), MAE remained stable (~0.008 PUE units) even when R² was near zero, making it a more honest metric for this low-variance dataset.

## Data Management

### Downloading Raw Data
Raw data is available from NREL in two formats:
- **Parquet**: [ESIF Power Metrics](https://data.nrel.gov/system/files/300/1757103411-esif.influx.buildingData.PUE.combined.parquet)
- **CSV (zipped)**: [ESIF Power Metrics](https://data.nrel.gov/system/files/300/1757105566-esif.influx.buildingData.PUE.combined.csv.zip)
- **Weather Data**: [Outside Weather Station](https://data.nrel.gov/system/files/300/1757105566-esif.influx.buildingData.outside.combined.csv.zip)

### Automated Processing
Running the notebooks will:
1. Download raw data from NREL (if not already present)
2. Clean physically impossible PUE values
3. Convert to SQLite database (`datasets/power_data.db`)
4. Train models and save artifacts
5. Generate visualizations

After notebook execution, the following directories will be populated:
*   **`datasets/`**: SQLite database containing cleaned telemetry data
*   **`models/`**: Serialized model artifacts (`.pkl`) and feature lists
*   **`plots/`**: Generated visualizations for analysis reports

Models expect features in `models/feature_columns.json`.

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
