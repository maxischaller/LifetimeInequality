** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SOEP LONGEVITY RISK ESTIMATION
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Script uses SOEP data to estimate heterogeneous longevity risks used in the structural model

	
Input:
	- Raw panel data: SOEP35 (long-format) 
	
	- Population Lifetables for West-German Men from Human Mortality Database: 
		https://www.mortality.org/Country/Country?cntr=DEUTW (last accessed: April 15, 2024)
		> Note: filename "mltper_1x1.txt"
			- Age-interval x Year-interval: 1x1
			- Life tables include column "q(x)": Probability of death between ages x and x+1

	
Output - Survival profiles for life-cycle model:
	- lifetable.txt
	- spbh_e0.txt
	- spbh_e1.txt
	- spgh_e0.txt
	- spgh_e1.txt
	
	
Generated Tables and Figures:
	- Table SWA.2: Parameter estimates of exponential survival model


*/

	clear
	set more off
	
	
*******************************************************************************
* PRELIMINARY SETTINGS - manual input required
*******************************************************************************
	global startyear 1984		//for usage in loops and restriciton using $startyear
	global endyear 2018	
	
	* > sample restriction to 1992-2016 applied after baseline dataset is generated
	

	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01a. COMBINE DATA FROM VARIOUS SOEP LONG SOURCE
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*** NOTES:
	* > generate sample of West-German Men

/* ----- info on adult household member - pl.dta ----- */	
	append using "${SOEP35}pl.dta", keep(cid syear hid pid plb0022_h plb0186_h)
	
		/*====================================================================*/
		/* ------ Sample Restriction: Years ----- */
			keep if syear>=$startyear & syear<=$endyear
				qui count if pid!=. 	
				scalar N1years=r(N)
		/*====================================================================*/
	
		
/* ----- info on adult household member - ppathl.dta ----- */		
	merge 1:1 pid hid syear using "${SOEP35}ppathl.dta", ///
		keepusing(sex gebjahr sampreg) ///
		gen(ppathldta) keep(3)		

/* ----- info on adult household member - pgen.dta ----- */
	merge 1:1 pid hid syear using "${SOEP35}pgen.dta", ///
		keepusing(pglfs pgemplst pgstib) gen(pgendta) keep(3)		
		
		
/* ----- info on cpi - pequiv.dta ----- */
	merge 1:1 pid hid syear using "${SOEP35}pequiv.dta", ///
		keepusing(d11109 l11101 m11124 m11126) gen(pequivdta) keep(3)


*******************************************************************************
* 01b. ENCODE MISSING VALUES
*******************************************************************************

	mvdecode _all,  mv(-1=. \ -2=.a \ -3=.c \ -4=.d \ -5=.b   \ -6=.e \ -7=.f \ -8=.g \ -9=.h \ -10=.i) 

		/*
		.  = no information (-1)
		.a = does not apply (-2)
		.b = not included in questionnaire (-5)
		.c = not valid (-3)
		.e = questionnarie changed (-6)
		.g = question not included in this year (-8)
		*/


*******************************************************************************
* 01c. DECLARE TIME-SERIES DATA SET
*******************************************************************************

	tsset pid syear
	*** Note: allows use of L.&F.-operators (lag and lead)		
		
	
		
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. GENERATE KEY VARIABLES
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
*******************************************************************************
* 02a. PERSONAL
*******************************************************************************
/* ----- age ----- */
	gen age = syear - gebjahr
	label var age "Age in Years"		
	
		
/* ----- gender ----- */
	gen male =.
		replace male = 1 if sex == 1
		replace male = 0 if sex == 2
	label var male "Male"		
		
	
*******************************************************************************
* 02b. Auxiliary Variables
*******************************************************************************

/* ----- West-Germany ----- */		
	ren l11101 state
	tab state, mis
		gen west = .
			replace west = 0 if state>10 & !mi(state)
			replace west = 1 if state<=10 & !mi(state)
		tab state west, missing	

	bys pid: egen west_adj = max(west)	
	bys pid: egen east_adj = min(west)
	
	tab west_adj east_adj		
	

*******************************************************************************
* 02c. Replication of Estimation-Sample Variables: Education and Health
*******************************************************************************	
	
	rename m11124 disabil
	rename m11126 srh
	rename d11109 yschool
		replace yschool = round(yschool)
		recode yschool (7=8) // lower education bound consistent with structural model
	
	recode yschool disabil srh (-1=.) (-3=.)
	recode srh disabil (-2=.)

	replace srh = 1 if srh == 2 | srh == 3
	replace srh = 0 if srh == 4 | srh == 5		
	
	
/* ----- Health Variable ----- */	
	sort pid syear
	
	gen health =      (srh==1 & disabil==0)
		replace health = . if (srh==. | disabil==.)	
			tab health, mis

	tab age if mi(health), mis
	tab syear if mi(health), mis
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 03. SAMPLE RESTRICTIONS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*******************************************************************************
* 02d. Sample restriction: West German men (see Estimation Sample specification) 
* Drop: in education, civial sevants, self employed, military (done above)
* Drop without valied educ info
* Drop observation before 1992 and after 2016 (estimation sample end)
*******************************************************************************	
	
/* ------ Sample Restriction: Personal information ----- */	
	keep if male == 1
	
	drop if age < 20
	
	keep if west_adj == 1
	
	
/* ------ Sample Restriction: Employment Status ----- */	
	drop if pgemplst==3 | pgemplst==4 | pgemplst==6 
		 
	drop if  plb0022_h ==3| plb0022_h ==4| plb0022_h ==6| plb0022_h ==7|plb0022_h ==8|plb0022_h ==10|plb0022_h ==11	
		
	drop if pgstib ==11| pgstib ==15 
	drop if pgstib>100 & pgstib<200  
	drop if pgstib>300 & pgstib<500  
	drop if pgstib>600
	
	
/* ------ Sample Restriction: Time Frame ----- */		
	keep if inrange(syear,1992,2016)


	
/* ----- Generate Education Variable consistent with structural model ----- */		

	gen educ_first = .
	bys pid (syear): replace educ_first = cond(educ_first[_n-1]!=.,educ_first[_n-1],yschool)	
	replace yschool = educ_first if !mi(yschool)
		
	* >>> generate low/high education indicator
	gen educ=.
		replace educ=0 if yschool >=  8 & yschool < 12
		replace educ=1 if yschool >= 12 & yschool <  .		
	
	by pid : egen educ_adj = max(educ)
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 04. SAVE MORTALITY ESTIMATION SAMPLE
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	
	gen sample_flag = 1
		label var sample_flag "Flag: Mortality Sample"

	keep pid hid syear sample_flag male educ educ_adj health west_adj
	

	save "${TEMP_PATH}data_base_mort.dta", replace
				
	*use "${TEMP_PATH}data_base_mort.dta", clear	
	
	
* ====================================================================================================
* ====================================================================================================
* ====================================================================================================
* ====================================================================================================	
	
	clear all
		
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 05. GENERATE LIFESPELL DATASET
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
*** NOTES:
	* - base: lifespell.dta - spell-format dataset w/ general info on alive-episodes	
	

*******************************************************************************
* 05a. GENERATE LONG-FORMAT DATASET FROM LIFESPELL
*******************************************************************************
/* ----- spells:  lifespell.dta ----- */
	use "${SOEP35}lifespell.dta", clear
	
	* --- expand spells into long-format
		gen spellduration = (end-begin) + 1
	
		expand spellduration

	* --- generate years
		bys pid spellnr : gen n = _n
		
		gen syear = begin + n - 1
		
	* --- clean up
		*drop if syear>2018 & !mi(syear)
	
		keep pid cid syear spellnr spelltyp zensor info study1992 study2001 ///
			study2006 study2008 flag1 immiyearinfo
		
		compress
		

/* ----- Birth (based on lifespell) ----- */		
*** NOTES:
	* - for validation of data merged from SOEP-long sources
	
	egen begin 	= min(syear), by(pid spellnr)
	egen end 	= max(syear), by(pid spellnr)
	egen max_spell = max(spellnr), by(pid)
	
	* --- Geburt:
		gen d_birth	= begin if spellnr==1			
		egen birth 	= mean(d_birth), by(pid)		
			label var birth "Geburtsjahr (lifespell)"
			
	* --- Last Record:
		gen d_exit 	= end if spellnr==max_spell
		egen exit	= mean(d_exit), by(pid)
			label var exit "Year of Last Record"

	* --- check consistency:
		drop if syear<birth | syear>exit	// good.
			
	* --- Age:		
		gen age = syear - birth
			label var age "Alter (lifespell)"

					
	* --- clean-up
		drop d_birth end max_spell d_exit //d_entry 

	
/* ----- DEATH - EVENT-Variable ----- */			
	gen byte event = spelltyp==4	
		label var event "Event - Tod"


/* ----- Consistency Check ----- */		
	sort pid syear spellnr
	drop if syear[_n]==syear[_n+1] & pid[_n]==pid[_n+1]



*******************************************************************************
* 05b. MERGE BASIC VARIABLES 
*******************************************************************************		

/* ----- info on adult household member - pl.dta ----- */
	merge 1:1 pid cid syear using "${SOEP35}pl.dta", ///
		keepusing(hid) 	///
		gen(pldta)
	drop if pldta==2	// drop not merged observations steming from pl.dta

		
/* ----- info on adult household member - ppathl.dta ----- */
	merge 1:1 pid hid syear using "${SOEP35}ppathl.dta", ///
		keepusing(gebjahr todjahr todinfo phrf ) ///
		gen(ppathldta)
	drop if ppathldta==2	
	

	
*******************************************************************************
* 05c. ENCODE MISSING VALUES
*******************************************************************************

	mvdecode _all,  mv(-1=. \ -2=.a \ -3=.c \ -4=.d \ -5=.b   \ -6=.e \ -7=.f \ -8=.g \ -9=.h \ -10=.i) 

		/*
		.  = no information (-1)
		.a = does not apply (-2)
		.b = not included in questionnaire (-5)
		.c = not valid (-3)
		.e = questionnarie changed (-6)
		.g = question not included in this year (-8)
		*/
		
		
		
/* ----- save life-spell dataset ----- */	
	compress 
	
	save "${TEMP_PATH}data_base_lifespell.dta", replace		
		
		
			
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 06. MERGE LIFESPELLS TO MORTALITY DATASET
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%			
	
/* ----- use lifespell and merge dataset ----- */	
	use "${TEMP_PATH}data_base_lifespell.dta", clear
		
	merge 1:1 pid hid syear using "${TEMP_PATH}data_base_mort.dta", ///
		keepusing(sample_flag male west_adj health educ educ_adj) gen(sampledta)	
	
	
/* ----- keep: sample-related observations ----- */	
	gen byte match = sampledta==3
	
	
	* - extend match variable
	sort pid syear
		by pid: egen match2 = max(match) 

	
	* --- drop irrelevant observations from dataset
		keep if match2==1	
		
*** NOTES:
	* - sample now contains complete life-spells of men identified by the base-mortality-dataset
	*	> including pre-SOEP and post-SOEP (even if these are not directly observed)	
	
	* > number of individuals in sample:
	preserve
		sum pid
		duplicates drop pid, force
		sum pid
	restore			
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 07. GENERATE VARIABLES FOR ESTIMATION
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
	
/* ----- Alter bei SOEP-Eintritt (i.e. first survey-report) ----- */	
		gen d_entry = age if spelltyp==2 & syear==begin
		egen entry = min(d_entry), by(pid)
			label var entry "Eintrittsalter - SOEP"
		
	* --- drop pre-SOEP periods:	
		drop if age<entry & !mi(entry)	
		
		* > note: some of the identified males might still have entered the SOEP at age younger than 20
		*		> however, these observations were removed by sample-restriction in base-dataset (age>20)
		tab age, m
	
					
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 08. EXTEND RELEVANT VARIABLES OVER LIFE-SPELLS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
*******************************************************************************
* 08a. Education
*******************************************************************************		
	
	sort pid syear
	
	by pid: egen educ_final = max(educ_adj)
	
	
*******************************************************************************
* 08b. Health
*******************************************************************************		
	*br pid syear age health	
	
	gen health_orig = health

	tab health_orig, mis
	
	sort pid syear
	* --- fill gaps:
		forval y=1/22 {
			dis `y'
			forval x=1/20 {
				qui by pid: replace health = health[_n+`x'] if mi(health[_n]) & !mi(health[_n+`x']) & !mi(health[_n-1]) & health[_n-1]==health[_n+`x'] 
			}
		}	
	
	tab health_orig health, mis
	
	tab health event, mis
	tab health_orig event, mis
		
	* --- expand post-observed
		sort pid syear
		by pid: replace health = health[_n-1] if !mi(health[_n-1]) & mi(health[_n]) 
	
		
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* XX. FINAL SAMPLE ADJUSTMENT // SAVING
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	tab syear if event==1, m
	
	tab age if event==1, m
		* > systematically no events pre age 20: by design as sample identifies only males that at least 
		*	reached age 20
	

	keep pid syear age event health educ_final
	
	compress
	save "${TEMP_PATH}data_mort_estim.dta", replace
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 09. LAMPERT & KROLL (2009): ESTIMATION SURVIVAL -- SAMPLE PREPARATIONS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	use "${TEMP_PATH}data_mort_estim.dta", clear

*******************************************************************************
* 09a. PREPARATION: DUPLICATION OF DATASET
*******************************************************************************	

/* ----- data preparation for stset ----- */	
	* --- flag first observation of pid	
	gen pid_first = 0
		bysort pid (syear): replace pid_first = 1 if _n == 1	


/* ----- double the dataset ----- */			
	* --- duplicates-identifier
		gen dupli = 0
			label var dupli "Identifier Duplicates"
			
	* --- gen new personal identifiers		
		qui levelsof pid
			dis `r(r)'		// 34,529
		
		preserve 
			keep pid			
			sort pid
			
			duplicates drop pid, force
				sum pid		// 34,529; good.
			
			gen npid = sum(!mi(pid))
				label var npid "New PID"
				sum npid
			
			qui levelsof pid
				local max_pid=`r(r)'
			
			gen npid_dupli = npid + `max_pid'
				label var npid_dupli "New PID - Duplicates"
			
			save "${TEMP_PATH}lci_mort_npid.dta", replace
			
		restore
	
	
	* --- merge new PID
		merge m:1 pid using "${TEMP_PATH}lci_mort_npid.dta", ///
			gen(npiddta)
	
		*br pid npid npid_dupli 
	
	
	* --- gen duplicates dataset
	preserve
		* > select covariates for analysis:
		keep pid npid_dupli syear event educ_final health age pid_first dupli
	
		* --- rename duplicates NPID to match original NPID
		ren npid_dupli npid
		
		* --- change duplicates identifier
		recode dupli (0 = 1)
		
		*compress
		
		save "${TEMP_PATH}lci_mort_dupli.dta", replace
		
	restore
	
	
	* --- append by duplicates dataset
		sum npid
		
		append using "${TEMP_PATH}lci_mort_dupli.dta", gen(dupli_append)
		
		sum npid	// seems good.
		assert dupli==1 if dupli_append==1		// good.
		
		
		*br pid npid syear pid_first dupli
		sort pid syear
			* > looks good.
	

/* ----- grouping ----- */		
*** NOTES:
	* - generate one categorical identifer variable with base (0) being the duplicates subset
	

	/* ----- gen group-flags ----- */
	gen byte flag_h0e0 = educ_final==0 & health==0
		label var flag_h0e0 "Low-Ed, Bad-Health"
	gen byte flag_h0e1 = educ_final==1 & health==0
		label var flag_h0e1 "High-Ed, Bad-Health"
	
	gen byte flag_h1e0 = educ_final==0 & health==1
		label var flag_h0e0 "Low-Ed, Good-Health"
	gen byte flag_h1e1 = educ_final==1 & health==1
		label var flag_h0e1 "High-Ed, Good-Health"


	* >> not useable like that bc ignore missings				
	*drop group*
	
	gen group =.
		replace group=0 if dupli==1 & (flag_h0e0==1 | flag_h0e1==1 | flag_h1e0==1 | flag_h1e1==1)
		
		replace group=1 if dupli==0 & flag_h0e0==1
		
		replace group=2 if dupli==0 & flag_h0e1==1
		
		replace group=3 if dupli==0 & flag_h1e0==1
		
		replace group=4 if dupli==0 & flag_h1e1==1
		
		
	label define group 0 "Duplicates" 1 "Low-Ed, Bad-Health" 2 "High-Ed, Bad-Health" 3 "Low-Ed, High-Health" ///
						4 "High-Ed, High-Health" 		
	
	
	* --- gen group dummies
		tab health educ_final, mis
			* > health status contains missings
			tab age health, mis
		
		tab group, gen(group)	
		
	
	
/* ----- IMPORTANT: CHECK IF EVENTS HAVE GROUPS ASSIGNED (i.e. non-missing) ----- */

	tab event group, mis
	




* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 10. ESTIMATION AND APPLICATION OF ESTIMATED HAZARD-SHIFTS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

*******************************************************************************
* 10a. ESTIMATION: SURVIVAL
*******************************************************************************		

/* ----- declare dataset ----- */		
	stset age , id(npid) failure(event) enter(pid_first==1)
	
	
/* ----- estimate group hazard-shifts : for Table report ----- */
	streg age  group2 group3 group4 group5, dist(e) vce(cluster npid)	
		eststo soep_mort_nocons

		* >>> Note: duplicated dataset -> adjust observations numbers for Table
		estadd scalar N_obsadj = e(N)/2 
		estadd scalar N_IDadj = e(N_sub)/2 
		estadd scalar N_Deathadj = e(N_fail)/2 
		
		* >>> Prepare export to CollectedResults
		mat mort_hr = r(table)[1,2..5]'
		mat mort_se = r(table)[2,2..5]'
		mat mort_obs = e(N)/2
		mat mort_ID = e(N_sub)/2
		mat mort_death = e(N_fail)/2
		mat mort_llik = e(ll)
		mat mort_chi2 = e(chi2)
		
/* ----- Table SWA.2: Parameter estimates: exponential survival model ----- */		
	label var age 	 "Age"
	label var group1 "Population-Baseline"
	label var group2 "Bad-health, low-education"
	label var group3 "Bad-health, high-education"
	label var group4 "Good-Health, low-education"
	label var group5 "Good-Health, high-education"
		
	/*
	esttab soep_mort_nocons using "${TABLES}Table_SWA2_MortRisk.tex", replace ///
		 booktabs label b(3) p(3) alignment(S S) eform /// fragment
		cells("b(fmt(3)star) se(fmt(3)par)") collabels("\multicolumn{1}{c}{Coef.}" "\multicolumn{1}{c}{s.e.}") ///
		refcat(group1 "\textbf{Groups}") ///
		stats(N_obsadj N_IDadj N_Deathadj ll chi2, fmt(0 0 0 2 2) ///
			layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" ///
				"\multicolumn{1}{S}{@}" "\multicolumn{1}{S}{@}") ///
			labels(`"Observations"' `"Subjects"' `"Failures"' `"Loglikelihood"' `"Chi2"')) //	
	*/
	
	* >>> Export to CollectedResults
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_SWA2_Mort") modify 
		putexcel B4 = matrix(mort_hr)
		putexcel C4 = matrix(mort_se)
		putexcel B9 = matrix(mort_obs)
		putexcel B10 = matrix(mort_ID)
		putexcel B11 = matrix(mort_death)
		putexcel B12 = matrix(mort_llik)
		putexcel B13 = matrix(mort_chi2)
		
	
	
/* ----- estimate group hazard-shifts : for application to baseline surivival ----- */
	streg age group2 group3 group4 group5, dist(e) vce(cluster npid) nohr
		eststo soep_mort_nocons_nohr
	
	* > extract coefficients
	matrix coeffs = e(b)
	matrix list coeffs
	
	
	
*******************************************************************************
* 10b. APPLICATION OF ESTIMATED HAZARD-SHIFTS
*******************************************************************************	
*** NOTES:
	* - estimated relative hazard-shifts are combined with population baseline-hazard 
	
	clear

	*set type double
	
/* ----- import population baseline-hazard ----- */	
***NOTES:
	* > based on population life-tables obtained from the Human Mortality Database
	* > baseline population mortality risk q(x) is averaged over estimation sample timeframe 1992-2016
	
	
	import delimited "${DATA}HMD/mltper_1x1.csv", varnames(3)
	
	keep year age qx
	
	keep if inrange(year,1992,2016)
	
	replace age = "110" if age=="110+"

	destring age, replace
	
	keep if inrange(age,20,100)
	

/* ----- average population baseline-hazard ----- */		
	reshape wide qx, i(age) j(year)
	
	egen base_mort = rowmean(qx*)
	
	drop qx*
	
	* >>> generate lifetable survival variable
	gen lifetable_surv = 1 - base_mort
	
	
/* ----- get estimated group-coefficients (hazard-shifters) ----- */		

	svmat double coeffs
	
	* >>> expand coef values
	foreach x in coeffs1 coeffs2 coeffs3 coeffs4 coeffs5 coeffs6 {
		replace `x' = `x'[1]	
	}	
		
		
	* >>> exp-transform coefficients		
	gen beta_age 		= exp(coeffs1)
	gen beta_edlow_bh 	= exp(coeffs2)
	gen beta_edhigh_bh 	= exp(coeffs3)
	gen beta_edlow_gh 	= exp(coeffs4)
	gen beta_edhigh_gh	= exp(coeffs5)	
	gen beta_sampavg	= exp(coeffs6)
	
	
	drop coeffs*
	
	
/* ----- Hazard functions: apply hazard shift to population average ----- */	
	gen haz_edlow_bh 	= base_mort * beta_edlow_bh
	gen haz_edhigh_bh 	= base_mort * beta_edhigh_bh
	
	gen haz_edlow_gh 	= base_mort * beta_edlow_gh	
	gen haz_edhigh_gh 	= base_mort * beta_edhigh_gh
	

	drop beta*
	
	
/* ----- Survival function ----- */	
	gen surv_base 	= exp(-base_mort)
	
	gen surv_edlow_bh 	= exp(-haz_edlow_bh)
	gen surv_edhigh_bh 	= exp(-haz_edhigh_bh)
	
	gen surv_edlow_gh 	= exp(-haz_edlow_gh)
	gen surv_edhigh_gh 	= exp(-haz_edhigh_gh)	
	
	
	drop haz*
	
	
/* ----- Export survival function for use in structural model ----- */		
	
	export delimited lifetable_surv using "${MATLABINPUT}lifetable.txt", novar replace
	
	export delimited surv_edlow_bh using "${MATLABINPUT}spbh_e0.txt", novar replace
	export delimited surv_edhigh_bh using "${MATLABINPUT}spbh_e1.txt", novar replace
	
	export delimited surv_edlow_gh using "${MATLABINPUT}spgh_e0.txt", novar replace
	export delimited surv_edhigh_gh using "${MATLABINPUT}spgh_e1.txt", novar replace	
	
	
	
	
/* ----- Figure 3c) Mortality Risk Graph ----- */	
	*** NOTE:
		* > final graph for paper is generated in Matlab, see: "dataprep.m"
	
	/*
	foreach x in lifetable_surv surv_edlow_bh surv_edhigh_bh  surv_edlow_gh surv_edhigh_gh {
		gen c`x' = sum(ln(`x'))
		replace c`x' = exp(c`x')
	}
	
	twoway (line clifetable_surv age) ///
			(line csurv_edlow_bh age, lcolor(gs11)) ///
			(line csurv_edhigh_bh age, lcolor(gs11)) ///
			(line csurv_edlow_gh age, lcolor(gs7)) ///
			(line csurv_edhigh_gh age, lcolor(gs7)),  ///
			scheme(s2mono) graphregion(color(white)) ///
			xtitle("Age", margin(medium) size(medlarge)) ytitle("Cumulative survival probability", margin(medium) size(medsmall)) 
			
	
	*/
	
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* XX. CLEAN UP
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
	erase "${TEMP_PATH}data_base_lifespell.dta"
	erase "${TEMP_PATH}data_base_mort.dta"
	erase "${TEMP_PATH}data_mort_estim.dta"
	erase "${TEMP_PATH}lci_mort_dupli.dta"
	erase "${TEMP_PATH}lci_mort_npid.dta"
	
