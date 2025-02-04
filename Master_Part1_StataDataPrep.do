** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** MASTER SCRIPT PART 1: DATA PREPARATION AND AUXILIARY REGRESSIONS
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Extracts and prepares all required information from data sources.
	- Generates the main estimation sample and all additional datasets required
		in auxiliary regressions.
	- Generates all required inputs for the estimation of the life-cycle model.
	- Executes auxiliary regressions: heterogeneous health shock profiles, mortality 
		risk profiles, involuntary separation risk model
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
	global run_makedir 1 	// Create directories
	global run_install 1 	// Install packages

* >>> Run setup script
	do "${rootdir}/StataCode/01_code/setup.do"


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 02. Estimation sample preparation */
* ------------------------------------
	do "${CODE}gen_estim_sample.do"
	*** Notes:
	*	- generates estimation sample from SOEP data
	*	- Calls: gen_baseline_raw.do, gen_wealth_raw.do


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 03. Auxiliary regressions */
* ----------------------------

* >>> Health state transition profiles
	do "${CODE}health_profiles.do"

* >>> Logit model: involuntary job separation risk
	do "${CODE}jobsep_prob.do"

* >>> Heterogeneous longevity risk profiles
	do "${CODE}estim_longevity.do"
