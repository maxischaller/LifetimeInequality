** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SOEP DATA PREPARATION - ESTIMATION DATASET
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- script uses SOEP data to generate the sample used for the estimation of the
		structural life-cycle model

	
INPUT:
	- SOEP33 "raw" datasets (cross-sections)
	- SOEP27: wealth data of 2007
	
OUTPUT:
	- "data_EstimSample.dta": estimation sample to generate inputs for structural model
	- "estim_sample.txt": estimation sample for use in structural model



*/


clear
clear matrix
clear mata



* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 01. Generate Base-dataset from SOEP - ppfad / phrf */
* ------------------------------------------------------

/* ----------------------( generate SOEP baseline panel )------------------ */    
*** Output files (saved to temp-files):
	* > data_base_raw.dta 
	* > data_base_long.dta

	do "${CODE}gen_baseline_raw.do"



	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 02. Generate Wealth data from SOEP  */
* ---------------------------------------
*** Output files (saved to temp-files):
	* > data_wealth_raw.dta 
	* > data_wealth_long.dta	
	
	do "${CODE}gen_wealth_raw.do"
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 03. Generate Variables for Estimation */
* ----------------------------------------

	clear
	clear matrix
	set memory 500m
	set more off


	use "${TEMP_PATH}data_base_long.dta", clear
	

/* -------------------( recode and rename variables )------------------------ */

	rename d11105 relhead
	rename d11107 numchild
	rename d11109 yschool
		replace yschool = round(yschool)
	rename e11101 hours
	rename e11102 emplstat
	rename e11103 empllev
	rename e11104 primact
	rename e11105 occup
	rename y11101 cpi
	rename l11101 state
	rename m11124 disabil
	rename m11126 srh
	rename i11110 labgro2
	rename i11101 hhincgro
	rename i11102 hhincnet
	rename i11103 hhlabinc

	recode numchild yschool hours emplstat empllev primact occup hhincgro hhincnet hhlabinc labgro2 jobend cpi state iself ioldy disabil srh partz stib labgro emplst expft exppt vebzeit tatzeit bilzeit uebzeit iunby iunay(-1=.) (-3=.)
		
	recode tatzeit vebzeit uebzeit hours (-2=0)

	recode srh disabil jobend yschool (-2=.)
	recode yschool (7=8) // lower education bound consistent with structural model
		
	replace labgro   = labgro   * (106.9/cpi)
	replace labgro2  = labgro2  * (106.9/cpi)
	replace hhincgro = hhincgro * (106.9/cpi)
	replace hhincnet = hhincnet * (106.9/cpi)
	replace hhlabinc = hhlabinc * (106.9/cpi)

	gen     factor = 1+0.5*(partz!=0)+0.3*numchild
	gen     equinc = hhincnet / (factor*1000)
	sum     equinc, det
	replace equinc = . if (equinc < r(p1) | equinc > r(p99))

	replace hours = hours / 52
	replace labgro2 = labgro2 / 12



/* ----------------------( generate variables )---------------------------- */

	xtset persnr svyyear

	replace hours   = f.hours
	replace labgro2 = f.labgro2

	gen age=svyyear-gebjahr
	gen agesq=age*age
	gen age50=(age>=50 & age<55)
	gen age55=(age>=55 & age<60)
	gen age60=(age>=60 & age<65)

	replace srh = 1 if srh == 2 | srh == 3
	replace srh = 0 if srh == 4 | srh == 5

	gen     health =      (srh==1 & disabil==0)
	replace health = . if (srh==. | disabil==.)

	replace health = 1 if health == 0 & l.health == 1 & f.health == 1

	gen     pensioner = (ioldy > 0 & ioldy < .)
	replace pensioner = . if ioldy == .

	gen     work = ((tatzeit >= 20 & tatzeit <.) & pensioner == 0)
	replace work = . if tatzeit == . | pensioner == .
	
	replace labgro = 0 if work == 0
	replace labgro = . if work == 1 & labgro <= 0
	replace labgro = . if labgro < 0

	gen     wage = (labgro*12) / (tatzeit*52) if work == 1
	replace wage = . if work == 1 & labgro <= 0
	replace wage = 0 if work == 0

	gen     exper = round(expft+exppt/2)
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2006
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2006
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2007
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2007
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2008
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2008
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2009
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2009
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2010
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2010
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2011
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2011
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2012
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2012
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2013
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2013
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2014
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2014
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2015
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2015
	replace exper = l.exper+1 if l.exper != . & l.work==1 & svyyear==2016
	replace exper = l.exper   if l.exper != . & l.work==0 & svyyear==2016

	replace exper = 50 if exper > 50 & exper < .

	gen     east = 0 if state <= 10
	replace east = 1 if state > 10 & state <= 16



/* ------------------( generate lagged variables )--------------------------- */

	gen hl = l.health
	gen hf = f.health
	gen dl = l.disabil
	gen dl2 = l2.disabil
	gen wl = l.work
		gen wf = f.work
	gen wagel = l1.wage*wl
	gen pl = l.pensioner
	gen stibl = l.stib
	gen iselfl = l.iself
	gen emplstl = l.emplst
	gen experl = l.exper

	gen jobloss=(work==0 & wl==1)
	gen jobsep =(jobloss==1 & ((jobend==1 | jobend==9 |jobend==11) | health==0))

	gen jobsep_nh = (jobloss==1 & ((jobend==1 | jobend==9 |jobend==11)))
	
	gen hgg=0
	replace hgg=1 if health==hl & health==1
	gen hgb=0
	replace hgb=1 if health!=hl & health==0
	gen hbb=0
	replace hbb=1 if health==hl & health==0
	gen hbg=0
	replace hbg=1 if health!=hl & health==1




/* ------------------( merge wealth information )--------------------------- */

	merge m:m persnr svyyear using "${TEMP_PATH}data_wealth.dta"
	gen _merge_old = _merge
	drop _merge
	
	
/* ------------------( generate variables of spouse )------------------------- */
	sort persnr svyyear
	save  "${TEMP_PATH}temp.dta", replace // save main person dataset
	drop persnr 
	rename partnr persnr
	keep persnr svyyear labgro work pensioner wage wl wagel ioldy //nw
	rename labgro labgro_p 
	rename work work_p 
	rename pensioner pensioner_p
	rename wage wage_p
	*rename nw nw_p
	rename wl wl_p
	rename wagel wagel_p
	rename ioldy ioldy_p


	sort persnr svyyear
	merge persnr svyyear using "${TEMP_PATH}temp.dta"
	tab _merge
	keep if _merge == 2 | _merge == 3
	drop _merge


	sort persnr svyyear
	replace labgro   = max(8400/12,l.labgro   * 0.6) if work   == 0 & wl   == 1
	replace labgro_p = max(8400/12,l.labgro_p * 0.6) if work_p == 0 & wl_p == 1

	gen share=labgro/(labgro+labgro_p)

	keep if _merge_old == 3

	drop _merge_old
	


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 04. Sample Restrictions & Consistency with Model Assumptions */
* ----------------------------------------------------------------

/* ------------------( restrict sample 1 )------------------------- */
	drop if svyyear == 2003 | svyyear == 2004
		      
	keep if sex == 1 & health != . & hl != . & exper != . & wage != . & wagel != . & yschool >= 0 & yschool != . & pensioner != . & pl != . & work != . & wl != . & east == 0 & /*
		 */ stib != 11 & stibl != 11 & stib != 15 & stibl != 15 & stib != 140 & stibl != 140 & stib != 120 & stibl != 120 & stib != 130 & stibl != 130 & (stib < 400 | (stib >= 500 & stib < 600)) & /*
		 */ (stibl < 400 | (stibl >= 500 & stibl < 600)) & iself <= 100 & iselfl <= 100 & emplst != 6 & emplstl != 6 & (partz == 0 | (partz > 0 & partz < . & share != .)) & relhead <= 2
		
		
/* ----------------( consistency: years of education )-------------------- */		
	gen educ_first = .
	bys persnr (svyyear): replace educ_first = cond(educ_first[_n-1]!=.,educ_first[_n-1],yschool)	
	replace yschool = educ_first if !mi(yschool)
	
	* >>> generate low/high education indicator
	gen educ=.
		replace educ=0 if yschool >=  8 & yschool < 12
		replace educ=1 if yschool >= 12 & yschool <  .		
	
	sum yschool educ
	
	
/* ----------( consistency: labor market entry assumption )--------------- */	
	gen entry_test = yschool+8
	gen byte entry_flag = age < entry_test
	
	tab entry_flag, mis
	list persnr if entry_flag==1

	drop if entry_flag==1	
	
	
/* -----------( export dataset for health profile estimation)---------------- */	
	* >>> Age 65 health information is required for estimation of health-profiles
	preserve
		sort persnr svyyear
		keep if inrange(age,20,65) 
		keep persnr age health hl educ
		save "${DATA_CONFID}data_EstimHealth.dta", replace
	restore	

	
/* ------------------( restrict sample 2 )------------------------- */
	
	keep if inrange(age,20,64) 	
	

	
/* ----------------( consistency: wealth )-------------------- */
	* ---------------------------------------------
	* >>> Observed 2007 cross-sectional wealth data
		replace netwealth = round(netwealth)
		gen netwealth_soep07 = max(netwealth,-20000) if !mi(netwealth)
		
		forvalues x = 20(1)64 {	
			* set to misssing if pre-labor market entry / completion of education
			replace netwealth_soep07 = . if `x'==age & `x'<(yschool+8)
			
			* set maximum
			replace netwealth_soep07 = . if netwealth_soep07 > (`x'-(max(yschool+8,20)))*15000 & age == `x' & !mi(netwealth_soep07) & age>=(yschool+8)
			
			* set minimum
			replace netwealth_soep07 = . if netwealth_soep07 < -(`x'-(max(yschool+8,20)))*15000 & age == `x' & !mi(netwealth_soep07) & age>=(yschool+8) & `x'<=max((yschool+8),20)+1		
		}	
		
	* ---------------------------------------------
	* >>> Net wealth information
		
		* > rounding
		replace impwealth = round(impwealth)
	
		* > generate variable for structural model
		gen nw_blim_new = max(impwealth,-20000)
	
		forvalues x = 20(1)64 {
			* set to misssing if pre-labor market entry / completion of education
			replace nw_blim_new = . if `x'==age & `x'<(yschool+8) & !mi(nw_blim_new)
				
			* set maximum
			replace nw_blim_new = (`x'-(max(yschool+8,20)))*15000 if nw_blim_new > (`x'-(max(yschool+8,20)))*15000 & age == `x' & !mi(nw_blim_new) & age>=(yschool+8)
			
			* set minimum
			replace nw_blim_new = - (`x'-(max(yschool+8,20)))*15000 if nw_blim_new < -(`x'-(max(yschool+8,20)))*15000 & age == `x' & !mi(nw_blim_new) & age>=(yschool+8) & `x'<=max((yschool+8),20)+1
		}		
	
		* > rename
		rename nw_blim_new nw
		sum nw, det		
	
	
/* ------------------( consistency: wages )------------------------- */	
	sum wage if work == 1, det
		 
	replace wage  = 8.5    if work == 1 & wage  < 8.5
	replace wagel = 8.5    if wl   == 1 & wagel < 8.5
	replace wage  = r(p99) if work == 1 & wage  > r(p99)
	replace wagel = r(p99) if wl   == 1 & wagel > r(p99)

	sum wage if work == 1, det



/* ---------( restriction of minimum panel length if required )----------------- */

	sort persnr svyyear
	save "${TEMP_PATH}temp.dta", replace
	gen ind=1
	collapse (sum) ind, by(persnr)
	keep if ind >= 1
	tab ind
	merge persnr using "${TEMP_PATH}temp.dta"
	tab _merge
	keep if _merge == 3
	drop _merge


/* ----------( generate variable that counts employment spells )--------------- */	
	
	sort persnr svyyear

	gen empltrans1=1 if work==1 & (l.work==0 | l.work==.)
	recode empltrans1 (.=0)

	gen empltrans2 =l.empltrans1
	gen empltrans3 =l2.empltrans1
	gen empltrans4 =l3.empltrans1
	gen empltrans5 =l4.empltrans1
	gen empltrans6 =l5.empltrans1
	gen empltrans7 =l6.empltrans1
	gen empltrans8 =l7.empltrans1
	gen empltrans9 =l8.empltrans1
	gen empltrans10=l9.empltrans1
	gen empltrans11=l10.empltrans1
	gen empltrans12=l11.empltrans1

	egen total=rowtotal(empltrans1-empltrans12)

	gen spell=0
	forvalues z=1/12 {
		replace spell=`z' if work==1 & total==`z'
	}

	
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*  4. SAVE ESTIMATION SAMPLE AS STATA DATASET
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	preserve 
		sum persnr
		duplicates drop persnr, force
		sum persnr
	restore
	
	sort persnr svyyear
	save "${DATA_CONFID}data_EstimSample.dta", replace
	
	
/* --------( view sample stats )---------- */	
	use "${DATA_CONFID}data_EstimSample.dta", clear


/* --------( Chapter 3 - Footnote 8: Working hours )---------- */		
	* >>> Median (actual) working hours
	sum tatzeit, det
		mat hours_median = r(p50)
	
	* >>> share of part-time among employed
	sum tatzeit if tatzeit!=0 & !mi(tatzeit)
		sum tatzeit if tatzeit!=0 & !mi(tatzeit) & pensioner==0
		* local n_poshrs = r(N)
	
	sum tatzeit if tatzeit!=0 & tatzeit<20 & !mi(tatzeit)
		sum tatzeit if tatzeit!=0 & tatzeit<20 & !mi(tatzeit) & pensioner==0
		local n_pt20 = r(N)
		mat n_pt20 = r(N)
	
	sum persnr
		local n_sample = r(N)
		mat n_sample = r(N)

	mat share_ptwork = (`n_pt20'/`n_sample')*100
		mat list share_ptwork
	
	* >>> Export to CollectedResults			
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Chapter_3") modify
		putexcel B3 = matrix(hours_median)		
		putexcel B4 = matrix(share_ptwork)
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("WebAppen_AddResults") modify
		putexcel B3 = matrix(n_sample)
		putexcel B4 = matrix(n_pt20)
		putexcel B5 = matrix(share_ptwork)

	
/* --------( WebAppendix IV.3.1: 30hrs share among employed )---------- */	
	sum tatzeit if tatzeit!=0 & !mi(tatzeit) & pensioner==0
		local n_employed = r(N)
	sum tatzeit if tatzeit!=0 & !mi(tatzeit) & pensioner==0 & tatzeit<30
		local n_empl_30h = r(N)
	mat share_empl_30h = (`n_empl_30h'/`n_employed')*100
		mat list share_empl_30h

	* >>> Export to CollectedResults
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("WebAppen_AddResults") modify
		putexcel B20 = matrix(share_empl_30h)	
	
	
/* --------( WebAppendix II: Sample descriptives )---------- */	
*** Robustness to alternative sample restriction based on working hours
		* ---------------------------------------------------
		* >>> Estimation sample:
		sum persnr work
		preserve
			duplicates drop persnr, force
			sum persnr
		restore

		putexcel set "${TABLES}CollectedResults.xlsx", sheet("WebAppen_AddResults") modify

		preserve
			ren persnr ID
			ren age Age
			ren yschool EDUC
			ren pensioner Reti
			ren work Empl
			ren wl Empl_lag
			ren wf Empl_lead

			sum Empl 
				mat emplrate_sampl = r(mean)
			
			do "${CODE}ue_durations.do"
			
			* >>> length ue-spells
			su length if begin==1
				mat length_ue_sampl = r(mean)
			
			* >>> avg. number of ue-spells
			duplicates drop ID, force
			sum nmbr_uempl_spell
				mat nmbr_ue_sampl = r(mean)
		
			* >>> Export to CollectedResults
				putexcel B10 = matrix(emplrate_sampl)
				putexcel B12 = matrix(length_ue_sampl)
				putexcel B11 = matrix(nmbr_ue_sampl)

		restore		
		
		* ---------------------------------------------------	
		* >>> Alternative - dropping observations with <20hrs
		preserve 
			drop if pensioner==0 & work==0 & tatzeit!=0	
			sum persnr work
			duplicates drop persnr, force
			sum persnr
		restore
		* > examine unemployment durations after dropping
		preserve
			drop if pensioner==0 & work==0 & tatzeit!=0	
			ren persnr ID
			ren age Age
			ren yschool EDUC
			ren pensioner Reti
			ren work Empl
			ren wl Empl_lag
			ren wf Empl_lead

			sum Empl 
				mat emplrate_alt = r(mean)			
			
			do "${CODE}ue_durations.do"
			
			* > length ue-spells
			su length if begin==1
				mat length_ue_alt = r(mean)
			
			* > avg. number of ue-spells
			duplicates drop ID, force
			sum nmbr_uempl_spell
				mat nmbr_ue_alt = r(mean)

			* >>> Export to CollectedResults
				putexcel C10 = matrix(emplrate_alt)
				putexcel C12 = matrix(length_ue_alt)
				putexcel C11 = matrix(nmbr_ue_alt)		
		restore
		
		* > Details:
			*   > i.e. persistence of part-time
			gen byte flag_ptreclass = pensioner==0 & work==0 & tatzeit!=0	
			sort persnr age
			by persnr: egen flag_ptonly = mean(flag_ptreclass)
				tab flag_ptreclass
				tab flag_ptonly
				sum flag_ptonly if flag_ptonly==1
					mat obs_ptpers = r(N)
			preserve
				keep if flag_ptonly==1
				duplicates drop persnr, force
				sum persnr
			restore	

			* >>> Export to CollectedResults
			putexcel set "${TABLES}CollectedResults.xlsx", sheet("WebAppen_AddResults") modify
				putexcel B6 = matrix(obs_ptpers)


	
**************************************************************************************************

/* --------( export estimation sample for use in structural model )---------- */

	tab svyyear

	sort persnr svyyear
	tsset persnr svyyear
	tsfill, full
	tab svyyear

	* >>> rename separation variable
	ren jobsep jobsep_incl_health
	ren jobsep_nh jobsep

	* >>> select and order variables for structural model
	order  	age work pensioner 	yschool exper wage health hl wl nw pl wagel ioldy 	spell jobsep netwealth_soep07 wf
	keep 	age work pensioner 	yschool exper wage health hl wl nw pl wagel ioldy 	spell jobsep netwealth_soep07 wf
	* Pos.   1   2    3           4      5     6    7     8   9 10 11  12    13       14    15    16              17

	* >>> recode	
	recode netwealth_soep07 wf (.=-99999) if !mi(age)
		* to keep missing observations distinguishable from zero-wealth
	
	recode age work pensioner 	yschool exper wage health hl wl nw pl wagel ioldy 	spell jobsep netwealth_soep07 wf (.=0)
	
	
	* >>> export estimation sample
	*outsheet using "${MATLABINPUT}estim_sample.txt" , nonames nolabel noquote replace
	outsheet using "${DATA_CONFID}estim_sample.txt" , nonames nolabel noquote replace


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*  5. ERASE TEMPORARY DATASETS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	erase "${TEMP_PATH}data_base_raw.dta" 
	erase "${TEMP_PATH}data_base_long.dta"

	erase "${TEMP_PATH}data_wealth_raw.dta" 
	erase "${TEMP_PATH}data_wealth_long.dta"
	erase "${TEMP_PATH}data_wealth.dta"
	erase "${TEMP_PATH}wealth_temp.dta"
	
	erase "${TEMP_PATH}temp.dta"
	
