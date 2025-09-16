# BART_Fare_Gates

Project Title: Estimating the Causal Effect of New Fare Gates on Public Transit Ridership
📖 Project Overview
This repository contains the code and data for a causal inference project analyzing the impact of installing new fare gate technology on public transit ridership. The goal is to determine whether the modernization effort (e.g., tap-to-pay systems) caused a statistically significant change in the number of riders, using methods like Difference-in-Differences (DiD) or Causal Impact Analysis.

🛠️ Status: Work in Progress
This project is currently under active development.

Data Acquisition & Cleaning

Descriptive Statistics & Exploratory Data Analysis

Causal Analysis (e.g., DiD Model)

Model Validation & Robustness Checks

Final Results & Visualization

Conclusion & Report Writing

❓ Research Question
Did the installation of new fare gates at [Agency Name, e.g., "WMATA"] stations in [Year/Time Period] cause a significant change in average daily ridership, after controlling for confounding factors?

📁 Repository Structure
text
├── data/
│   ├── raw/                   # Original, immutable data
│   │   ├── ridership_raw.csv
│   │   └── fare_gates_deployment.csv
│   └── processed/             # Cleaned, analysis-ready data
│       └── analysis_dataset.csv
├── notebooks/
│   ├── 01_data_cleaning.ipynb  # Scripts for processing raw data
│   ├── 02_descriptive_stats.ipynb # EDA and summary statistics
│   └── 03_analysis.ipynb      # Placeholder for causal analysis (TBD)
├── outputs/
│   ├── figures/               # Generated plots and charts
│   └── tables/                # Summary tables
├── README.md                  # This file
└── requirements.txt           # Python dependencies
🗃️ Data Sources
Ridership Data: [Briefly describe source, e.g., "GTFS feed from [Agency]", "APIs", or "public CSV downloads from [Website]"]. Covers the period [Start Date] to [End Date].

Fare Gate Deployment Data: [Describe source, e.g., "Press releases compiled into a CSV", "Internal dataset"]. Includes dates and stations for the rollout of new gates.

Other Data (Potential Confounders): [Mention if you have or plan to get other data, e.g., "Local weather data", "Holiday calendars", "Economic indicators"].

🧹 Data Cleaning & Processing (Completed)
The work completed so far includes:

Merging ridership and fare gate deployment data on station and date.

Handling missing values and outliers in the ridership time series.

Creating key variables such as:

treatment_date: The date the new fare gates were activated at each station.

post_treatment: A binary flag indicating pre- and post-installation periods.

treatment_group: A binary flag for stations that received the new gates.

Aggregating data to a daily/weekly level for analysis.

📊 Preliminary Descriptive Statistics
Initial exploratory data analysis has been conducted. Key observations include:

The treatment was rolled out to [X] stations between [Date] and [Date].

control stations were identified that did not receive new gates during the study period.

Summary statistics (mean, median, standard deviation) for ridership in the pre-treatment period for both treatment and control groups suggest [briefly note if they look similar or different, e.g., "treatment stations have higher average ridership"].

Preliminary plots (available in outputs/figures/) show the ridership trends over time for both groups.

(See notebooks/02_descriptive_stats.ipynb for detailed charts and tables.)

🔬 Proposed Methodology (Planned)
The causal effect will be estimated using a Difference-in-Differences (DiD) design. The model is anticipated to be:

ridership_it = β0 + β1 * treatment_group_i + β2 * post_treatment_t + β3 * (treatment_group_i * post_treatment_t) + ε_it

Where:

ridership_it is the ridership at station i on day t.

β3 is the coefficient of interest, representing the average treatment effect on the treated (ATT).

Next Steps:

Validate the parallel trends assumption visually and statistically.

Run the DiD regression model.

Conduct robustness checks (e.g., placebo tests, alternative model specifications).

🚀 Getting Started
Prerequisites
Python 3.8+

pip

Installation
Clone this repository:

bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
(Recommended) Create a virtual environment.

Install the required packages:

bash
pip install -r requirements.txt
Running the Code
The analysis is conducted in Jupyter notebooks. Execute them in order:

01_data_cleaning.ipynb: Reproduces the processed dataset.

02_descriptive_stats.ipynb: Generates all descriptive statistics and plots.

03_analysis.ipynb: [To be completed] Will contain the causal analysis.

👤 Author
Your Name

GitHub: @your-username

LinkedIn: Your Profile

📜 License
This project is licensed under the MIT License - see the LICENSE.md file for details (if you add one).

🙏 Acknowledgments
Data provided by [Transit Agency Name].

Inspired by similar studies on infrastructure upgrades.

Thanks to [X] for helpful feedback.

