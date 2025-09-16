*********************************************
* Project: Causal Effect of Next Generation Fare Gates
* Author:  Austin Coffelt
* Date:    9/8/2025
* Desc:    This do-file collects and outputs all relevant descriptive statistics as well as important and illuminating graphs into the results file
*********************************************

**# 1. Set Up Environment
**************************
clear all       // Clears memory
set more off    // Prevents the -more- prompt
cap log close   // Capturally closes any open logs

// Define paths to main directories
global project "/Users/austincoffelt/Documents/bart_fare_gates_project"
global data    "$project/data"
global scripts "$project/scripts"
global results "$project/results"

// Start a log file to record all output
log using "$results/analysis_log_$S_DATE.smcl", replace


**# 2. Load Data
******************
use "$data/bart_ridership_2023_2025_with_treatment.dta"


**# 3. Tables and Graphs
*************************

// 1.) Table of Descriptive Stats
preserve
// a.) Full dataset
sum riders
eststo full: estpost summarize riders

// b.) Just observations where either origin_parking or destination_parking == 0
keep if origin_parking == 0 | destination_parking == 0
eststo no_parking: estpost summarize riders

// Reload data for next subset
restore
preserve

// c.) Observations where stops <=5 (short trips)
keep if stops <= 5 & stops != 999
eststo short_trips: estpost summarize riders

// d.) Observations where stops >=5 and <=10 (medium trips)
restore
preserve
keep if stops >= 5 & stops <= 10 & stops != 999
eststo medium_trips: estpost summarize riders

// e.) Observations where stops >10 (long trips)
restore
preserve
keep if stops > 10 & stops != 999
eststo long_trips: estpost summarize riders

// Create table
esttab full no_parking short_trips medium_trips long_trips using "$results/descriptive_stats.rtf", ///
    cells("mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.0f)) max(fmt(%9.0f)) count(fmt(%9.0f))") ///
    title("Descriptive Statistics of Ridership by Route Type") ///
    replace label

restore

// 2.) Histogram of ridership for the full dataset
histogram riders, ///
    title("Distribution of Ridership - Full Dataset") ///
    xtitle("Daily Ridership") ///
    ytitle("Frequency") ///
    graphregion(color(white)) ///
    saving("$results/hist_ridership_full.gph", replace)
graph export "$results/hist_ridership_full.png", replace

// 3.) Histogram of stops between stations (removing stops == 999)
preserve
drop if stops == 999
histogram stops, ///
    title("Distribution of Stops Between Stations") ///
    xtitle("Number of Stops") ///
    ytitle("Frequency") ///
    graphregion(color(white)) ///
    saving("$results/hist_stops.gph", replace)
graph export "$results/hist_stops.png", replace
restore

// 4.) Table of the 10 most taken routes by average daily ridership
preserve
// Create a combined route identifier that shows actual station names
gen route_label = origin + " to " + destination

collapse (mean) avg_ridership=riders (firstnm) stops transfer_needed origin_parking destination_parking, by(origin destination route_label)

// Sort by average ridership descending for top 10
gsort -avg_ridership

// Display and export top 10 routes
list route_label avg_ridership stops transfer_needed origin_parking destination_parking in 1/10, clean noobs
export excel route_label avg_ridership stops transfer_needed origin_parking destination_parking in 1/10 using "$results/top10_routes.xlsx", firstrow(variables) replace

// 5.) Table of the 10 least taken routes by average daily ridership
// Sort by average ridership ascending for bottom 10
gsort avg_ridership

// Display and export bottom 10 routes
list route_label avg_ridership stops transfer_needed origin_parking destination_parking in 1/10, clean noobs
export excel route_label avg_ridership stops transfer_needed origin_parking destination_parking in 1/10 using "$results/bottom10_routes.xlsx", firstrow(variables) replace

restore

// 6.) Graph of weekly ridership for the whole system comparing 2023 to 2024
preserve
gen year = year(date)
gen week_of_year = week(date)

collapse (sum) weekly_ridership=riders, by(week_of_year year)

// Reshape to wide format to have 2023 and 2024 as separate variables
reshape wide weekly_ridership, i(week_of_year) j(year)

twoway (line weekly_ridership2023 week_of_year, lcolor(blue)) ///
       (line weekly_ridership2024 week_of_year, lcolor(red)), ///
    title("Weekly Ridership: 2023 vs 2024") ///
    xtitle("Week of Year (1-52)") ///
    ytitle("Weekly Ridership") ///
    legend(order(1 "2023" 2 "2024")) ///
    xlabel(1(4)52, labsize(small)) ///
    graphregion(color(white)) ///
    saving("$results/weekly_ridership_2023_2024.gph", replace)
graph export "$results/weekly_ridership_2023_2024.png", replace
restore

// 7.) Graph of average daily riders for treatment groups around treatment time
// (Indexed to remove day-of-week effects)
preserve

// Calculate average ridership by day of week for the pre-treatment period
gen pre_treatment = (time_to_treatment < -7) // Use data more than 7 days before treatment
bysort dow: egen dow_mean = mean(riders) if pre_treatment == 1
bysort dow: egen overall_dow_mean = mean(dow_mean) // Get the average for each day of week

// Create indexed ridership (ridership divided by day-of-week average)
gen indexed_riders = riders / overall_dow_mean

// Create treatment groups based on actual treatment dates
gen treatment_group = .
replace treatment_group = 1 if earliest_completion_route <= td(30nov2024) // Early treated (before Dec 2024)
replace treatment_group = 2 if earliest_completion_route > td(30nov2024) & earliest_completion_route <= td(31mar2025) // Middle treated (Dec 2024 - Mar 2025)
replace treatment_group = 3 if earliest_completion_route > td(31mar2025) & !missing(earliest_completion_route) // Late treated (After Apr 2025)
replace treatment_group = 4 if missing(earliest_completion_route) // Never treated (pure control)

// Label the values for better interpretation
label define treatment_groups 1 "Early Treated (Pre-Dec 2024)" 2 "Middle Treated (Dec 2024-Mar 2025)" 3 "Late Treated (Post-Apr 2025)" 4 "Never Treated"
label values treatment_group treatment_groups

// Check the distribution
tab treatment_group, mi

// Use the new treatment groups based on completion date
keep if time_to_treatment >= -25 & time_to_treatment <= 25 & !missing(treatment_group)

// Collapse the indexed ridership
collapse (mean) avg_indexed_riders=indexed_riders, by(time_to_treatment treatment_group)

// Create the graph with indexed ridership
twoway (line avg_indexed_riders time_to_treatment if treatment_group == 1, lcolor(blue)) ///
       (line avg_indexed_riders time_to_treatment if treatment_group == 2, lcolor(red)) ///
       (line avg_indexed_riders time_to_treatment if treatment_group == 3, lcolor(green)) ///
       (line avg_indexed_riders time_to_treatment if treatment_group == 4, lcolor(orange)), ///
    title("Average Daily Ridership Around Treatment Time (Indexed)") ///
    xtitle("Days Relative to Treatment") ///
    ytitle("Indexed Ridership (Relative to Day-of-Week Average)") ///
    legend(order(1 "Early Treated (Pre-Dec 2024)" 2 "Middle Treated (Dec-Mar 2025)" 3 "Late Treated (Post-Apr 2025)" 4 "Never Treated")) ///
    xline(0, lpattern(dash)) ///
    yline(1, lpattern(dash) lcolor(gs10)) /// Reference line at 1 (average)
    graphregion(color(white)) ///
    saving("$results/treatment_timing_indexed.gph", replace)
graph export "$results/treatment_timing_indexed.png", replace

restore

// 8. Parallel Trends Assessment with Random Routes (2023 Data)

// First, make sure the results directory exists
capture confirm file "$results"
if _rc != 0 {
    // If $results doesn't exist, create it
    capture mkdir "$results"
    if _rc != 0 {
        // If still fails, use current directory
        global results "."
    }
}

// Set seed for reproducibility
set seed 12345

// Create proper week variable
gen week_num = week(date)
gen year = year(date)

// 8a.) Weekly ridership for 5 random routes
preserve
keep if year == 2023

// Get random sample of routes
bysort route: keep if _n == 1
sample 5, count
keep route
tempfile random_routes
save `random_routes'
restore

// Weekly ridership overlay - FIXED
preserve
keep if year == 2023
merge m:1 route using `random_routes'
keep if _merge == 3
drop _merge

collapse (mean) weekly_ridership = riders, by(week_num route)

sort route week_num
levelsof route, local(routes)

local i = 1
local plot_cmd ""
foreach route in `routes' {
    local color: word `i' of "blue red green orange purple"
    local plot_cmd `"`plot_cmd' (line weekly_ridership week_num if route == "`route'", lcolor(`color') lwidth(medthick))"'
    local i = `i' + 1
}

sum week_num
local min_week = r(min)
local max_week = r(max)

twoway `plot_cmd', ///
    title("Weekly Ridership: 5 Random Routes (2023)") ///
    subtitle("Overlay Comparison") ///
    xtitle("Week of Year") ///
    ytitle("Average Weekly Ridership") ///
    xlabel(`min_week'(5)`max_week', grid) ///
    ylabel(, grid) ///
    legend(order(1 "Route 1" 2 "Route 2" 3 "Route 3" 4 "Route 4" 5 "Route 5") pos(6) rows(1)) ///
    graphregion(color(white)) plotregion(margin(medium))
graph export "$results/weekly_ridership_overlay.png", width(2000) replace
restore

// Weekly log ridership overlay
preserve
keep if year == 2023
merge m:1 route using `random_routes'
keep if _merge == 3
drop _merge

collapse (mean) weekly_log_ridership = log_riders, by(week_num route)

sort route week_num
levelsof route, local(routes)

local i = 1
local plot_cmd ""
foreach route in `routes' {
    local color: word `i' of "blue red green orange purple"
    local plot_cmd `"`plot_cmd' (line weekly_log_ridership week_num if route == "`route'", lcolor(`color') lwidth(medthick))"'
    local i = `i' + 1
}

sum week_num
local min_week = r(min)
local max_week = r(max)

twoway `plot_cmd', ///
    title("Log Weekly Ridership: 5 Random Routes (2023)") ///
    subtitle("Overlay Comparison") ///
    xtitle("Week of Year") ///
    ytitle("Log(Weekly Ridership)") ///
    xlabel(`min_week'(5)`max_week', grid) ///
    ylabel(, grid) ///
    legend(order(1 "Route 1" 2 "Route 2" 3 "Route 3" 4 "Route 4" 5 "Route 5") pos(6) rows(1)) ///
    graphregion(color(white)) plotregion(margin(medium))
graph export "$results/weekly_log_ridership_overlay.png", width(2000) replace
restore

// 8b.) Weekly plots for no parking routes
preserve
keep if year == 2023
keep if origin_parking == 0 | destination_parking == 0

// Get random sample from no-parking routes
bysort route: keep if _n == 1
sample 5, count
keep route
tempfile random_no_parking
save `random_no_parking'
restore

preserve
keep if year == 2023
keep if origin_parking == 0 | destination_parking == 0
merge m:1 route using `random_no_parking'
keep if _merge == 3
drop _merge

collapse (mean) weekly_log_ridership = log_riders, by(week_num route)

sort route week_num
levelsof route, local(routes)

local i = 1
local plot_cmd ""
foreach route in `routes' {
    local color: word `i' of "blue red green orange purple"
    local plot_cmd `"`plot_cmd' (line weekly_log_ridership week_num if route == "`route'", lcolor(`color') lwidth(medthick))"'
    local i = `i' + 1
}

sum week_num
local min_week = r(min)
local max_week = r(max)

twoway `plot_cmd', ///
    title("Log Weekly Ridership: 5 Random No-Parking Routes (2023)") ///
    subtitle("Overlay Comparison") ///
    xtitle("Week of Year") ///
    ytitle("Log(Weekly Ridership)") ///
    xlabel(`min_week'(5)`max_week', grid) ///
    ylabel(, grid) ///
    legend(order(1 "Route 1" 2 "Route 2" 3 "Route 3" 4 "Route 4" 5 "Route 5") pos(6) rows(1)) ///
    graphregion(color(white)) plotregion(margin(medium))
graph export "$results/weekly_no_parking_overlay.png", width(2000) replace
restore

// 8c.) Weekly plots for short no parking routes
preserve
keep if year == 2023
keep if (origin_parking == 0 | destination_parking == 0) & stops <= 5

// Get random sample from short no-parking routes
bysort route: keep if _n == 1
sample 5, count
keep route
tempfile random_short_no_parking
save `random_short_no_parking'
restore

preserve
keep if year == 2023
keep if (origin_parking == 0 | destination_parking == 0) & stops <= 5
merge m:1 route using `random_short_no_parking'
keep if _merge == 3
drop _merge

collapse (mean) weekly_log_ridership = log_riders, by(week_num route)

sort route week_num
levelsof route, local(routes)

local i = 1
local plot_cmd ""
foreach route in `routes' {
    local color: word `i' of "blue red green orange purple"
    local plot_cmd `"`plot_cmd' (line weekly_log_ridership week_num if route == "`route'", lcolor(`color') lwidth(medthick))"'
    local i = `i' + 1
}

sum week_num
local min_week = r(min)
local max_week = r(max)

twoway `plot_cmd', ///
    title("Log Weekly Ridership: 5 Random Short No-Parking Routes (2023)") ///
    subtitle("Overlay Comparison") ///
    xtitle("Week of Year") ///
    ytitle("Log(Weekly Ridership)") ///
    xlabel(`min_week'(5)`max_week', grid) ///
    ylabel(, grid) ///
    legend(order(1 "Route 1" 2 "Route 2" 3 "Route 3" 4 "Route 4" 5 "Route 5") pos(6) rows(1)) ///
    graphregion(color(white)) plotregion(margin(medium))
graph export "$results/weekly_short_no_parking_overlay.png", width(2000) replace
restore

// DAILY SNAPSHOTS (2 weeks)
// Get 2 random weeks for daily snapshots
preserve
keep if year == 2023
set seed 67890
gen temp_week = week(date)
bysort temp_week: keep if _n == 1
sample 2, count
keep temp_week
tempfile random_weeks
save `random_weeks'
restore

// Daily ridership snapshot
preserve
keep if year == 2023
merge m:1 route using `random_routes'
keep if _merge == 3
drop _merge

// Merge with random weeks
gen temp_week = week(date)
merge m:1 temp_week using `random_weeks'
keep if _merge == 3
drop _merge

collapse (mean) daily_ridership = riders, by(date route)
format date %tdNN/DD

sort route date
levelsof route, local(routes)

local i = 1
local plot_cmd ""
foreach route in `routes' {
    local color: word `i' of "blue red green orange purple"
    local plot_cmd `"`plot_cmd' (line daily_ridership date if route == "`route'", lcolor(`color') lwidth(medthick))"'
    local i = `i' + 1
}

twoway `plot_cmd', ///
    title("Daily Ridership: 5 Random Routes (2-Week Sample, 2023)") ///
    subtitle("Overlay Comparison") ///
    xtitle("Date") ///
    ytitle("Daily Ridership") ///
    xlabel(, angle(45) grid) ///
    ylabel(, grid) ///
    legend(order(1 "Route 1" 2 "Route 2" 3 "Route 3" 4 "Route 4" 5 "Route 5") pos(6) rows(1)) ///
    graphregion(color(white)) plotregion(margin(medium))
graph export "$results/daily_ridership_sample.png", width(2000) replace
restore

// Daily log ridership snapshot
preserve
keep if year == 2023
merge m:1 route using `random_routes'
keep if _merge == 3
drop _merge

// Merge with random weeks
gen temp_week = week(date)
merge m:1 temp_week using `random_weeks'
keep if _merge == 3
drop _merge

collapse (mean) daily_log_ridership = log_riders, by(date route)
format date %tdNN/DD

sort route date
levelsof route, local(routes)

local i = 1
local plot_cmd ""
foreach route in `routes' {
    local color: word `i' of "blue red green orange purple"
    local plot_cmd `"`plot_cmd' (line daily_log_ridership date if route == "`route'", lcolor(`color') lwidth(medthick))"'
    local i = `i' + 1
}

twoway `plot_cmd', ///
    title("Log Daily Ridership: 5 Random Routes (2-Week Sample, 2023)") ///
    subtitle("Overlay Comparison") ///
    xtitle("Date") ///
    ytitle("Log(Daily Ridership)") ///
    xlabel(, angle(45) grid) ///
    ylabel(, grid) ///
    legend(order(1 "Route 1" 2 "Route 2" 3 "Route 3" 4 "Route 4" 5 "Route 5") pos(6) rows(1)) ///
    graphregion(color(white)) plotregion(margin(medium))
graph export "$results/daily_log_ridership_sample.png", width(2000) replace
restore

display "All parallel trends graphs completed successfully!"
display "Check the $results directory for output files."


**# 4. Export & Save
************************************

// Display completion message
di "Analysis complete! All tables and graphs have been saved to the results folder."

// Close the log file
log close
