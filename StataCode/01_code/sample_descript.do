** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- ESTIMATION SAMPLE & MODEL DESCRIPTIVES
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
	1. Model Specification: Tax Functions
		- Prepare data for tax-function plots
		- Figure 1: Annual Taxes
	2. Descriptive Statistics: Estimation Sample
		- Table SWA.1: Descriptive statistics estimation sample

Generated Tables and Figures:	
	- Figure_1a_TTETax.pdf
	- Figure_1b_AvETax.pdf
	- Table_SWA1_Descript.tex 	(CollectedResults)

*/


	clear

	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. MODEL SPECIFICATION: TAX FUNCTIONS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

********************************************************************************
* 01a. Prepare data for tax-function plots
********************************************************************************

/* ----- Wage Basis----- */
	set obs 351
	
	gen wage = 0
		replace wage = wage[_n-1]+200 if !mi(wage[_n-1])
	
	
/* ----- Labor Income Taxation----- */	
	* > tax base
	gen bg = wage - 1000
		replace bg = 0 if bg<=0
	
	gen bg1 = (bg - 8652)/10000
	
	gen bg2 = (bg - 13669)/10000
		
		
	gen tax1 = 0	
		replace tax1 = (993.62*bg1 + 1400)*bg1 if bg>=8653 & bg<=13669
	
	gen tax2 = 0
		replace tax2 = (225.40*bg2 +2397)*bg2 + 952.48 if bg>=13670 & bg<=53665

	gen tax3 = 0
		replace tax3 = 0.42*bg - 8394.14 if bg>=53666
	
		
	gen itax = 0
		replace itax = (993.62*bg1 + 1400)*bg1 if bg>=8653 & bg<=13669
		replace itax =  (225.40*bg2 +2397)*bg2 + 952.48 if bg>=13670 & bg<=53665
		replace itax =  0.42*bg - 8394.14 if bg>=53666
		
	
/* ----- Setting for plots ----- */	
	ge Interest=0
	ge tax_ss=0.182*wage
	ge tax_interest=0.25*max(Interest-801,0)
	ge art_ss=tax_ss/wage
	
	ge ATR=(tax_interest+tax_ss+itax)/(Interest+wage)
	
	ge Tax=itax+tax_ss+tax_interest	
	
	
********************************************************************************
* 01b. Figure 1: Annual Taxes
********************************************************************************	

	twoway (connected Tax wage, sort lcolor(black) msymbol(i)),/* 
	*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
	*/ ylabel(0 10000 "10,000" 20000 "20,000" 30000 "30,000",labsize(large)) /*
	*/ xtitle("Annual earnings (euros)", margin(medium) size(large))  ytitle("Annual tax (euros)", margin(medium) size(large)) /*
	*/ xlabel(10000 "10,000" 30000 "30,000" 50000 "50,000"  70000 "70,000",labsize(large))/*
	*/ xscale(range(0,75000))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(1))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_1a_TTETax.pdf", as(pdf) replace	

	
	twoway (connected ATR wage, sort lcolor(black) msymbol(i)),/* 
	*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
	*/ ylabel(0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3" 0.4 "0.4" 0.5 "0.5",labsize(large)) /*
	*/ xtitle("Annual earnings (euros)", margin(medium) size(large))  ytitle("Average annual tax rate", margin(medium) size(large)) /*
	*/ xlabel(10000 "10,000" 30000 "30,000" 50000 "50,000"  70000 "70,000",labsize(large))/*
	*/ xscale(range(0,75000))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(1))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_1b_AvETax.pdf", as(pdf) replace

	graph close
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. DESCRIPTIVE STATISTICS: ESTIMATION SAMPLE 	(Table SWA.1)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

	use "${DATA_CONFID}esample_plus.dta", clear
	
	ge Unemp=1-Empl-Reti
	ge hWage=WAGE/(40*52) if WAGE>0

	* > view summary statistics
	sum Age Empl Unemp Reti Exper hWage EDUC Health Jobsep Wealth_SOEP07
	
	
/* ----- Prepare labels ----- */		
	label var Age "Age"
	label var Empl "Employed"
	label var Unemp "Unemployed"
	label var Reti "Retired"
	label var EDUC "Education (years)"
	label var Exper "Experience (years)"
	label var hWage "Wage (euros per hour)"
	label var Wealth_SOEP07 "Wealth (euros)"
	label var Health "Health"
	label var Jobsep "Involuntary job separation"
	
	
/* ----- Generate summary statistics for table ----- */	
	eststo descript : estpost sum Age Empl Unemp Reti Exper hWage EDUC Health Jobsep Wealth_SOEP07
		mat samp_obs = e(count)'
		mat samp_mean = e(mean)'
		mat samp_min = e(min)'
		mat samp_max = e(max)'
	
	
/* ----- Table SWA.1: Descriptive statistics estimation sample ----- */		
	
	* >>> Export to CollectedResults.xlsx
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_SWA1_Sample") modify

	putexcel B4 = matrix(samp_obs)
	putexcel C4 = matrix(samp_mean)
	putexcel D4 = matrix(samp_min)
	putexcel E4 = matrix(samp_max)
	
	
	