** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** MASTER SCRIPT: POST-ESTIMATION ANALYSIS OF SIMULATED DATA
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Prepares simulation data for post-estimation analysis
	- Generates descriptives, in-sample goodness of fit and model validation
	- Post-estimation analysis of simulation data	
	- Robustness checks: reduced working hours	

*/

clear all
set more off


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 01. Setup STATA environment */
* ------------------------------

* >>> Get root directory
	global rootdir : pwd
	display in green "Root directory: " "$rootdir"

* >>> Define setup steps
	global run_makedir 0 	// Create directories
	global run_install 0 	// Install packages

* >>> Run setup script
	do "${rootdir}/StataCode/01_code/setup.do"

	
*******************************************************************************	
/* 02. Post-Estimation Analysis of Simulation Data   */
* ------------------------------------------------------	

* >>> Prepare simulation data and estimation sample
	do "${CODE}analysis_dataprep.do"

* >>> Generate descriptives
	do "${CODE}sample_descript.do"

* >>> Examine in-sample goodness of fit
	do "${CODE}modelfit.do"
	
* >>> Analysis Part 1
	do "${CODE}analysis_part1.do"
	
* >>> Analysis Part 2	
	do "${CODE}analysis_part2.do"
	
* >>> Robustness: Reduced working hours
	do "${CODE}rob_parttime.do"		
