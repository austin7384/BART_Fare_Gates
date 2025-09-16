*********************************************
* Project: Causal Effect of Next Generation Fare Gates
* Author:  Austin Coffelt
* Date:    9/1/2025
* Desc:    This do-file cleans and prepares the hourly ridership data for descriptive statistics and regression in future files.
*********************************************

**# 1. Set Up Environment
**************************
clear all       // Clears memory
set more off    // Prevents the -more- prompt
capture log close   // Capturally closes any open logs

// Define paths to main directories
global project "/Users/austincoffelt/Documents/bart_fare_gates_project"
global data    "$project/data"
global scripts "$project/scripts"
global results "$project/results"

// Start a log file to record all output
log using "$results/analysis_log_$S_DATE.smcl", replace


**# 2. Load Data
******************
cd "$data" 

// 2023 Data
import delimited "date-hour-soo-dest-2023.csv", clear
tempfile file2023
save `file2023'

// 2024 Data  
import delimited "date-hour-soo-dest-2024.csv", clear
tempfile file2024
save `file2024'

// 2025 Data
import delimited "date-hour-soo-dest-2025.csv", clear 
tempfile file2025
save `file2025'

// Fare Gates Completion Dates
import excel "bartCompletionDates.xlsx", clear firstrow
rename completionDate completion_date
label variable completion_date "Fare gate completion date"

describe

tempfile completionDates
save `completionDates'

// Fare Gates Start Date
import excel "bartStartDates.xlsx", clear firstrow
label variable start_date "Fare gate start date"

describe

tempfile startDates
save `startDates'

// BART station descriptive variables
import excel "bartStationLines.xlsx", clear firstrow

label variable station_id "Station ID"
label variable line_color_red "Is the station on the red line"
label variable line_color_orange "Is the station on the orange line"
label variable line_color_yellow "Is the station on the yellow line"
label variable line_color_green "Is the station on the green line"
label variable line_color_blue "Is the station on the blue line"
label variable line_order_red "Where in the red line the station falls"
label variable line_order_orange "Where in the orange line the station falls"
label variable line_order_yellow "Where in the yellow line the station falls"
label variable line_order_green "Where in the green line the station falls"
label variable line_order_blue "Where in the blue line the station falls"
label variable transfer_station "Transfer station"
label variable dist_to_BAYF "Distance to the Bayfair station"
label variable dist_to_BALB "Distance to the Balboa station"
label variable dist_to_12TH "Distance to the 12TH Street station"
label variable downtown_core "Downtown San Francisco station"
label variable parking "Parking next to the station"
label variable metro_connection "Connected to Muni Metro"
label variable other_train_connection "Connected to train station"
label variable airport_connection "Connected to airport"

tempfile bartStationLines
save `bartStationLines'

// Append all files together
use `file2023', clear
append using `file2024'
append using `file2025'


**# 3. Create Panel Dataset
****************************
// Inspect the data
describe
summarize

// rename variables and label data
label data "Appended BART Ridership Data 2023-2025"
rename (v1 v2 v3 v4 v5) (date hour origin destination riders)
label variable date "Date"
label variable hour "Hour from 0 to 23"
label variable origin "Starting Station"
label variable destination "Destination Station"
label variable riders "Hourly Riders"

// Generate origin destination pair (route)
egen route_id = group(origin destination)
gen route = origin + "_to_" + destination

// Convert string date to Stata date format (adjust format if needed)
gen date_numeric = date(date, "YMD")
format date_numeric %td
drop date
rename date_numeric date
label variable date "Date (Stata format)"

// Collapse to daily data
collapse (sum) riders, by(date origin destination route route_id)

// Establish daily panel
sort route_id date
xtset route_id date
tsfill, full

// Populate the missing origin and destination values using the route ID
bysort route_id: replace origin = origin[_n-1] if missing(origin) & _n > 1
bysort route_id: replace destination = destination[_n-1] if missing(destination) & _n > 1

// Handle the first observation for each route if it was missing
bysort route_id: replace origin = origin[_N] if missing(origin)
bysort route_id: replace destination = destination[_N] if missing(destination)

// Now handle missing values for riders
replace riders = 0 if missing(riders)

// Create day of week variables
gen dow = dow(date)
label variable dow "Day of Week (0=Sun, 6=Sat)"

// Create log ridership
gen log_riders = log(riders)

// Label the variables
label variable riders "Daily ridership on route"
label variable log_riders "Log ridership from origin to destination"
label variable route "Origin destination pair"

// Final panel check
xtset route_id date
xtdescribe


**# 4. Merge with Fare Gate Completion and Start Dates
********************************************
// Prepare station names for merging
replace origin = upper(trim(origin))
replace destination = upper(trim(destination))

// Merge completion dates (origin)
merge m:1 origin using `completionDates', keep(master matched) generate(merge_origin)

rename completion_date origin_completion_date

// Check merge results
drop if merge_origin == 2
drop merge_origin

// Label the existing variable 
label variable origin_completion_date "Origin station fare gate completion date"

// Merge completion dates (destination)
preserve
use `completionDates', clear
rename origin destination
save temp_dest_dates, replace
restore

merge m:1 destination using temp_dest_dates, keep(master matched) generate(merge_destination)
rename completion_date destination_completion_date

// Check merge results
drop if merge_destination == 2
drop merge_destination

// Clean up temporary file
erase temp_dest_dates.dta

// Label the variable
label variable destination_completion_date "Destination station fare gate completion date"

// Merge start dates (origin)
merge m:1 origin using `startDates', keep(master matched) generate(merge_origin)

rename start_date origin_start_date

// Check merge results
drop if merge_origin == 2
drop merge_origin

// Label the existing variable 
label variable origin_start_date "Origin station fare gate start date"

// Merge start dates (destination)
preserve
use `startDates', clear
rename origin destination
save temp_dest_dates, replace
restore

merge m:1 destination using temp_dest_dates, keep(master matched) generate(merge_destination)
rename start_date destination_start_date

// Check merge results
drop if merge_destination == 2
drop merge_destination

// Clean up temporary file
erase temp_dest_dates.dta

// Label the variable
label variable destination_start_date "Destination station fare gate start date"

// Merge origin station characteristics
preserve
use `bartStationLines', clear
rename station_id origin
rename line_color_red origin_red
rename line_color_orange origin_orange
rename line_color_yellow origin_yellow
rename line_color_green origin_green
rename line_color_blue origin_blue
rename line_order_red origin_order_red
rename line_order_orange origin_order_orange
rename line_order_yellow origin_order_yellow
rename line_order_green origin_order_green
rename line_order_blue origin_order_blue
rename transfer_station origin_transfer
rename dist_to_BAYF origin_dist_to_BAYF
rename dist_to_BALB origin_dist_to_BALB
rename dist_to_12TH origin_dist_to_12TH
rename downtown_core origin_downtown
rename parking origin_parking
rename metro_connection origin_metro
rename other_train_connection origin_other_train
rename airport_connection origin_airport
save temp_bart_lines, replace
restore

merge m:1 origin using temp_bart_lines, keep(master matched) generate(merge_origin)

// Check merge results
drop if merge_origin == 2
drop merge_origin

// Clean up temporary file
erase temp_bart_lines.dta

// Merge destination station characteristics
preserve
use `bartStationLines', clear
rename station_id destination
rename line_color_red destination_red
rename line_color_orange destination_orange
rename line_color_yellow destination_yellow
rename line_color_green destination_green
rename line_color_blue destination_blue
rename line_order_red destination_order_red
rename line_order_orange destination_order_orange
rename line_order_yellow destination_order_yellow
rename line_order_green destination_order_green
rename line_order_blue destination_order_blue
rename transfer_station destination_transfer
rename dist_to_BAYF dest_dist_to_BAYF
rename dist_to_BALB dest_dist_to_BALB
rename dist_to_12TH dest_dist_to_12TH
rename downtown_core destination_downtown
rename parking destination_parking
rename metro_connection destination_metro
rename other_train_connection destination_other_train
rename airport_connection destination_airport
save temp_bart_lines, replace
restore

merge m:1 destination using temp_bart_lines, keep(master matched) generate(merge_destination)

// Check merge results
drop if merge_destination == 2
drop merge_destination

// Clean up temporary file
erase temp_bart_lines.dta


**# 5. Create Needed Variables
*******************************

// Create Treatment Variables
gen treated_origin = ///
	((date >= origin_completion_date) & !missing(origin_completion_date))
	
label variable treated_origin "Origin post fare gate installment"

gen treated_destination = ///
	((date >= destination_completion_date) & !missing(destination_completion_date))
	
label variable treated_destination "Destination post fare gate installment"

gen treated_either = ///
	((date >= origin_completion_date) & !missing(origin_completion_date)) | ///
	((date >= destination_completion_date) & !missing(destination_completion_date))
	
label variable treated_either "Either origin or destination post fare gate installment"

gen treated_both = ///
	((date >= origin_completion_date) & !missing(origin_completion_date)) & ///
	((date >= destination_completion_date) & !missing(destination_completion_date))
	
label variable treated_both "Both origin or destination post fare gate installment"

// Create Under Construction Variable
gen under_construction = ///
    ((date < origin_completion_date) & (date >= origin_start_date) & !missing(origin_start_date)) | ///
    ((date < destination_completion_date) & (date >= destination_start_date) & !missing(destination_start_date))

label variable under_construction "Either origin or destination fare gate under construction"

// Create time-to-treatment variable
gen earliest_completion_route = min(origin_completion_date, destination_completion_date)
gen time_to_treatment_route = date - earliest_completion_route
label variable earliest_completion_route "Date of earliest fare gate completion on the route"
label variable time_to_treatment_route "Days relative to fare gate completion "

// Create stops variable - simplified version
gen stops = 999

// Direct connections only
foreach line in red orange yellow green blue {
    replace stops = abs(origin_order_`line' - destination_order_`line') if ///
        origin_`line' == 1 & destination_`line' == 1 & ///
        origin_order_`line' != 0 & destination_order_`line' != 0 & ///
        stops == 999
}

// Create transfer needed dummy before calculating transfer stops
gen transfer_needed = (stops == 999) if !missing(stops)
replace transfer_needed = 0 if stops != 999 & stops != .

// Calculate transfer connections using minimum distance sums
// List of transfer stations
local transfer_stations BAYF BALB 12TH // Add other transfer stations as needed

// Initialize minimum distance variable
gen min_transfer_distance = .

// Calculate minimum transfer distance for connections requiring transfer
foreach station in `transfer_stations' {
    // Calculate distance sum for this transfer station
    gen temp_dist_`station' = origin_dist_to_`station' + dest_dist_to_`station' ///
        if transfer_needed == 1 & !missing(origin_dist_to_`station', dest_dist_to_`station')
    
    // Update minimum distance
    replace min_transfer_distance = temp_dist_`station' ///
        if (temp_dist_`station' < min_transfer_distance | missing(min_transfer_distance)) & ///
        !missing(temp_dist_`station')
    
    // Drop temporary variable
    drop temp_dist_`station'
}

// Replace stops with transfer distance for transfer connections
replace stops = min_transfer_distance if transfer_needed == 1 & !missing(min_transfer_distance)

// Drop the temporary minimum distance variable
drop min_transfer_distance

// Label variables
label variable stops "Number of stops (direct) or distance sum (transfer)"
label variable transfer_needed "1 if transfer needed"
label define transfer_dummy 0 "No transfer" 1 "Transfer needed"
label values transfer_needed transfer_dummy

// Show summary
tab stops
tab transfer_needed


**# 6. Final Data Inspection & Save
************************************
// Check the treatment variables
tab treated_either
tab treated_origin
tab treated_destination  
tab treated_both
sum time_to_treatment_route, detail

// Check a few treated stations
list origin destination date treated_either under_construction  stops transfer_needed riders if inlist(origin, "EMBR", "CAST") & inrange(date, td(09jan2025), td(11jan2025)), noobs clean

// Save the final dataset
save "bart_ridership_2023_2025_with_treatment.dta", replace

// Close the log file
log close
