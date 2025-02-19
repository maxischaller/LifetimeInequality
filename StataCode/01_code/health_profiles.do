** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- COMPUTE HEALTH TRANSITION PROFILES
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- script computes heterogeneous health state transition profiles 
	

Output: 
	- "health.dta": dataset containing generated health transition profiles
	- "hgg.txt", "hbg.txt": health profiles input for structural model -> see Matlab: "dataprep.m"
	
	
Generated Figures:	
	- Figure_3a_HealthGood.pdf	
	- Figure_3b_HealthBad.pdf
	- Figure_3ab_Legend.pdf
	
*/	
	
**************************************************************************************************
*** HETEROGENOUS HEALTH SHOCK PROFILES - AGE-DEPENDENT TRANSITION PROBABILITES

/* ----------( Health shocks generate heterogeneous profiles )--------------- */	

	use "${DATA_CONFID}data_EstimHealth.dta", clear
	

* >>> low-education, good health:
	lpoly health age if hl==1 & educ==0, at(age) generate (hgg_l) bwidth(10) nograph
	preserve
		collapse (mean) hgg_l, by(age)
		save "${TEMP_PATH}hgg_l.dta", replace
	restore

* >>> high-education, good health:		
	lpoly health age if hl==1 & educ==1, at(age) generate (hgg_h) bwidth(10) nograph
	preserve
		collapse (mean) hgg_h, by(age)
		save "${TEMP_PATH}hgg_h.dta", replace
	restore
	
* >>> low-education, bad health:	
	lpoly health age if hl==0 & educ==0, at(age) generate (hbg_l) bwidth(10) nograph
	preserve
		collapse (mean) hbg_l, by(age)
		save "${TEMP_PATH}hbg_l.dta", replace
	restore

* >>> high-education, bad health:	
	lpoly health age if hl==0 & educ==1, at(age) generate (hbg_h) bwidth(10) nograph
	preserve
		collapse (mean) hbg_h, by(age)
		save "${TEMP_PATH}hbg_h.dta", replace
	restore	
	
* >>> merge to health dataset
	use "${TEMP_PATH}hgg_l.dta", clear
	merge age using "${TEMP_PATH}hgg_h.dta", sort
	drop _merge
	merge age using "${TEMP_PATH}hbg_l.dta", sort
	drop _merge
	merge age using "${TEMP_PATH}hbg_h.dta", sort
	drop _merge

	save "${DATA_CONFID}health.dta", replace


* >>> export health profiles for use in structural model
	export delimited hbg_l hbg_h using "${MATLABINPUT}hbg.txt", delimiter(tab) novar replace
	
	export delimited hgg_l hgg_h using "${MATLABINPUT}hgg.txt", delimiter(tab) novar replace

	
* >>> clean-up	
	erase "${TEMP_PATH}hgg_l.dta"
	erase "${TEMP_PATH}hgg_h.dta"
	erase "${TEMP_PATH}hbg_l.dta"
	erase "${TEMP_PATH}hbg_h.dta"

		
/* ----------( Output: Figure 3 - Panel (a) and (b): Health shocks )--------------- */			
* >>> Output: Figure 3 - Panel (a) and (b): Health shocks
	use "${DATA_CONFID}health.dta", clear
	
* bad health shock (already generated in health.dta)
	ge hgb_l=1-hgg_l
	ge hgb_h=1-hgg_h


* >>> Figure 3 - Panel (a): Probability of good health shock
twoway (connected hbg_l age if age<=64, sort lcolor(black) msymbol(i)) (connected hbg_h age if age<=64, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
*/ ylabel(0 "0" 0.1 "0.1" 0.2 "0.2",labsize(medium)) /*
*/ xtitle("Age (years)", margin(medium) size(medium))  ytitle("Probability of good health shock", margin(medium) size(medium)) /*
*/ xlabel(20 30 40 50 60,labsize(medium))/*
*/ legend(order(1 "Low ed" 2 "High ed"))/*
*/ legend(region(lcolor(white))) legend(size(medium) cols(2))/*
*/ aspectratio(.85)
graph export "${FIGURES}Figure_3a_HealthGood.pdf", as(pdf) replace


* >>> Figure 3 - Panel (b): Probability of bad health shock
twoway (connected hgb_l age if age<=64, sort lcolor(black) msymbol(i)) (connected hgb_h age if age<=64, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
*/ ylabel(0 "0" 0.1 "0.1" 0.2 "0.2",labsize(medium)) /*
*/ xtitle("Age (years)", margin(medium) size(medium))  ytitle("Probability of bad health shock", margin(medium) size(medium)) /*
*/ xlabel(20 30 40 50 60,labsize(medium))/*
*/ legend(order(1 "Low ed" 2 "High ed"))/*
*/ legend(region(lcolor(white))) legend(size(medium) cols(2))/*
*/ aspectratio(.85)
graph export "${FIGURES}Figure_3b_HealthBad.pdf", as(pdf) replace


* >>> Figure 3 Legend
twoway (connected hgb_l age if age<=64, sort lcolor(black) msymbol(i)) (connected hgb_h age if age<=64, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
*/ ylabel(0 "0" 0.1 "0.1" 0.2 "0.2",labsize(medium)) /*
*/ xtitle("Age (years)", margin(medium) size(large))  ytitle("Probability of good health shock", margin(medium) size(large)) /*
*/ xlabel(20 40 60 78,labsize(medium))/*
*/ legend(order(1 "Low education" 2 "High education"))/*
*/ legend(region(lcolor(white))) legend(size(medium) cols(2))/*
*/ aspectratio(.85)
graph export "${FIGURES}Figure_3ab_HealthLegend.pdf", as(pdf) replace	
	
graph close 


/* ----------( CLEAN UP )--------------- */	
*	erase "${TEMP_PATH}data_EstimHealth.dta"
	
