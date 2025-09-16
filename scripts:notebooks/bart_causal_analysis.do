
*********************************************
* Project: Causal Effect of Next Generation Fare Gates
* Author:  Austin Coffelt
* Date:    9/8/2025
* Desc:    This do-file runs my causal analysis on the effect the Next Generation Fare Gates on BART Ridership using Difference in Differences as the causal identification stratedy
*********************************************

**# 1. Set Up Environment
**************************
clear all       // Clears memory
set more off    // Prevents the -more- prompt
cap log close   // Capturally closes any open logs

// Define paths to main directories
global project"/Users/austincoffelt/Documents/bart_fare_gates_project"
global data    "$project/data"
global scripts "$project/scripts"
global results "$project/results"

// Start a log file to record all output
log using "$results/analysis_log_$S_DATE.smcl", replace


**# 2. Load Data
******************
use "$data/bart_ridership_2023_2025_with_treatment.dta"

list in 1/1

**# 3. Simple Diff in Diff Estimation
**************************************

* Create station pair
egen station_pair = group(origin destination)

* Count initial station pairs using egen method
egen temp = group(station_pair)
summarize temp
di "Initial station pairs: " r(max)
drop temp

* Count observations per station pair
bysort station_pair: gen pair_obs = _N

* Keep only pairs with complete data (all 945 days)
keep if pair_obs == 945

* Count remaining station pairs
egen temp2 = group(station_pair)
summarize temp2
di "Station pairs with complete data: " r(max)
drop temp2

* Verify total observations
count
di "Total observations: " r(N)
di "Expected observations: " r(max) * 945

* Set panel data and check
xtset station_pair date
xtdescribe

bacondecomp riders treated, ddetail

**# 4. Export & Save
************************************

// Close the log file
log close
