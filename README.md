# BART_Fare_Gates

# Project Title: Estimating the Causal Effect of New Fare Gates on Public Transit Ridership

## 📖 Project Overview

This repository contains the code and data for a causal inference project analyzing the impact of installing new fare gate technology on BART ridership. The goal is to determine whether the fare enforcement effort caused a statistically significant change in the number of riders, using Difference-in-Differences (DiD).

> **🛠️ Status: Work in Progress**
> This project is currently under active development.
> - [x] **Data Acquisition & Cleaning**
> - [x] **Descriptive Statistics & Exploratory Data Analysis**
> - [ ] **Causal Analysis (e.g., DiD Model)**
> - [ ] **Model Validation & Robustness Checks**
> - [ ] **Final Results & Visualization**
> - [ ] **Conclusion & Report Writing**

## ❓ Research Question

Did the recent installation of new fare gates at BART stations cause a significant change in average daily ridership?

## 📁 Repository Structure

## 🗃️ Data Sources

*   **Ridership Data:** Public CSV Data from BART's Website. Covers the period 1/1/2023 to 8/2/2025. (Not in this repository due to size)
*   **Fare Gate Deployment Data:** Compliled from BART website and press releases. Includes dates and stations for the rollout of new gates.
*   **Other Data (Potential Confounders):** Characteristics of BART stations (like whether there is parking, where the station is located) compiled from BART website.

## 🧹 Data Cleaning & Processing (Completed)

The work completed so far includes:
1.  **Merging** ridership and fare gate deployment data on station and date.
2.  **Handling missing values** and balancing the ridership panel.
3.  **Creating key variables** such as:
    *   `treatment_date`: The date the new fare gates were activated at each station.
    *   `post_treatment`: A binary flag indicating pre- and post-installation periods.
    *   `treatment_group`: A binary flag for stations that received the new gates.
4.  **Aggregating** data to a daily/weekly level for analysis.

## 📊 Preliminary Descriptive Statistics

Initial exploratory data analysis has been conducted. Key observations include:
*   The treatment was rolled out to all 50 stations between 12/18/2023 and 8/27/2025.
*   Summary statistics (mean, median, standard deviation) for ridership in the pre-treatment period for both treatment and control groups suggest that BART targeted the most used stations first.
*   Preliminary plots (available in `outputs/figures/`) show the ridership trends over time for both groups.

*(See `notebooks/02_bart_descriptive_stats.do` for detailed charts and tables.)*

## 🔬 Proposed Methodology (Planned)

The causal effect will be estimated using a **Difference-in-Differences (DiD)** design. The model is anticipated to be:

`ridership_it = β0 + β1 * treatment_group_i + β2 * post_treatment_t + β3 * (treatment_group_i * post_treatment_t) + XΠ + ε_it`

Where:
*   `ridership_it` is the ridership at station `i` on day `t`.
*   `β3` is the coefficient of interest, representing the average treatment effect on the treated (ATT).
*   'XΠ' is a matrix of covariates to give better counterfactuals

**Next Steps:**
1.  Validate the parallel trends assumption visually and statistically.
2.  Run the DiD regression model.
3.  Conduct robustness checks (e.g., placebo tests, alternative model specifications).

## 🚀 Getting Started

### Prerequisites

*   Python 3.8+
*   Stata/SE
*   `pip`

### Installation

1.  Clone this repository:
    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```
2.  (Recommended) Create a virtual environment.
3.  Install the required packages:
    ```bash
    pip install -r requirements.txt
    ```

### Running the Code

The analysis is conducted in Jupyter notebooks. Execute them in order:
1.  `01_bart_data_cleaning.do`: Reproduces the processed dataset (Need to get BART Data from website).
2.  `02_bart_descriptive_stats.do`: Generates all descriptive statistics and plots.
3.  `03_Regression_analysis.ipynb`: *[To be completed]* Will contain the causal analysis.

## 👤 Author

**Your Name**
*   GitHub: austin7384 (https://github.com/austin7384)
*   LinkedIn: Austin Coffelt (https://linkedin.com/in/austincoffelt)


## 🙏 Acknowledgments

*   Data provided by BART.
*   Inspired by similar studies on Optimal Transport and Public Transit demand.
*   Thanks to Professor Jesse Anttila-Hughes for helpful feedback.
