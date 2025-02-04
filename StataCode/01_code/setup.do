** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** SETUP SCRIPT: SET PATHS AND STATA ENVIRONMENT
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
    - Sets up the project environment by defining paths and a Stata environment including all required packages
    - Called by: Master_Part1_StataDataPrep.do & Master_Part4_StataAnalysis.do
        Creation of directories and package installation only executed on call from Master_Part1_StataDataPrep.do
*/


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 01. Setup project directory and paths */
* ----------------------------------------

* >>> Paths to data directories
	global DATA			"${rootdir}/Data/"
	global TEMP_PATH    "${rootdir}/Data/tempfiles/"	

	* SOEP raw data (confidential)
	global SOEP27RAW 	"${DATA}SOEP_confid/SOEPv27/"
	global SOEP33RAW 	"${DATA}SOEP_confid/SOEPv33/"
	global SOEP35		"${DATA}SOEP_confid/SOEPv35/"
	
	* Datasets derived from SOEP raw data (confidential)
	global DATA_CONFID 	"${DATA}SOEP_confid/derived_confid/"

	* Simulated data (Matlab output)
	global SIMDATA		"${DATA}SimData/"


* >>> Stata directory
	global CODE  		"${rootdir}/StataCode/01_code/"  	
	global FIGURES		"${rootdir}/StataCode/02_figures/"	
	global TABLES		"${rootdir}/StataCode/03_tables/"
	

* >>> Matlab directory (input/output for structural model)
	global MATLABINPUT	"${rootdir}/MatlabCode/01_input/"
	global MATLABOUTPUT "${rootdir}/MatlabCode/02_output/"

* >>> Create data directories
	if $run_makedir == 1 {
        capture mkdir "${TEMP_PATH}"
	    capture mkdir "${DATA_CONFID}"
	    capture mkdir "${SIMDATA}"
    }


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 02. Setup project environment */
* --------------------------------
*** Note on Project Environment:
*	- all packages required for this project are located at "rootdir/StataCode/01_code/ado"
*	- adopath is simplified to point to this location
* 	- package installation executed below

* >>> Project environment: Define location of required packages
	* Set location an create directory for packages
	global adodir "$rootdir/StataCode/01_code/ado"
	capture mkdir "$adodir"

	* Simplify the adopath (remove unused OLdPLACE and PERSONAL paths)
	*adopath - OLDPLACE
	*adopath - PERSONAL

	* Modify the PLUS path to point to our new location, and move it up in the order
	sysdir set PLUS "$adodir"
	adopath ++ PLUS
	* verify the path
	adopath

* >>> Install required packages
	if $run_install == 1 {
        display in green "Installing required packages..."
		ssc install estout
	    ssc install ineqdeco
		ssc install ineqdec0
    }
