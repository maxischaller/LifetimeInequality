** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- ROBUSTNESS: PART-TIME ASSUMPTION
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*

Generated Figures and Tables:

	- Figure_SWA5a_FitAAE_PT_3p2div.pdf
	- Figure_SWA5b_FitAAEHE_PT_3p2div.pdf
	- Figure_SWA5c_FitAAELE_PT_3p2div.pdf
	- Figure_SWA5d_FitAAE_PT_3p3div.pdf
	- Figure_SWA5e_FitAAEHE_PT_3p3div.pdf
	- Figure_SWA5f_FitAAELE_PT_3p3div.pdf
	
	- Table SWA.16 								(CollectedResults)


*/


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 00. View estimation sample 
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	use "${DATA_CONFID}data_EstimSample.dta", clear
		sum tatzeit if tatzeit!=0 & !mi(tatzeit) & pensioner==0
			local n_samp = r(N)
		
		sum tatzeit if tatzeit!=0 & !mi(tatzeit) & pensioner==0 & tatzeit<30
			local n_nonfull = r(N)
		
		local robsamp_share =  round((`n_nonfull'/`n_samp')*100)
		*mat robsamp = round((`n_nonfull'/`n_samp')*100)
		mat robsamp = `robsamp_share'
		mat list robsamp

	putexcel set "${TABLES}CollectedResults.xlsx", sheet("WebAppen_AddResults") modify
	putexcel B3 = matrix(robsamp)	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. Prepare part-time labor earnings adjustment
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
	set seed 182
	
/* ----- Pseudo-random subsample of individuals ----- */	
	use "${DATA_CONFID}data_ObsSimComb_ob1.dta", clear	
	
	keep ID EDUC TYPE
	
	duplicates drop ID, force
	
	sample `robsamp_share' , by(EDUC TYPE)
	
	* >>> gen sampling indicator
	gen subsamp_pt = 1
	
	sum EDUC TYPE ID
	
/* ----- Generate adjusted labor earnings for subsample ----- */		
	merge 1:m ID EDUC using "${DATA_CONFID}data_ObsSimComb_ob1.dta", ///
		gen(PT_merge) keepusing(Age WAGE2) keep(3)
	
	* >>> Part-time earnings adjustments
	gen WAGE2_PT2 = WAGE2/2
	gen WAGE2_PT3 = WAGE2/3
		sum WAGE*
		
		
/* ----- Save part-time sample ----- */			
	save "${DATA_CONFID}data_subsample_PTadj.dta", replace
	
	
/* ----- Merge adjusted labor earnings to main dataset ----- */		
	use "${DATA_CONFID}data_ObsSimComb_ob1.dta", clear	
		keep o_WAGE EDUC Age Ob o_ID o_Empl ID WAGE2 Empl
	
	merge 1:1 ID Age using "${DATA_CONFID}data_subsample_PTadj.dta", ///
		gen(PT_merge) keepusing(subsamp_pt WAGE2_PT2 WAGE2_PT3)
	
	*br ID Age WAGE*
	
	* >>> replace part-time adjusted earnings variables
	replace WAGE2_PT2 = WAGE2 if mi(WAGE2_PT2)
	replace WAGE2_PT3 = WAGE2 if mi(WAGE2_PT3)
	
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. Figure SWA.5: Distribution of (adjusted) labor earnings
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
/* ----- prepare observed and simulated data ----- */		
	drop if Age>=60
	
	* > observed
	replace o_WAGE=o_WAGE/(40*52)
	bys ID: egen AAE_o=mean(o_WAGE)
		replace AAE_o=AAE_o*40*52	
	bys o_ID: ge n_o=_n	if Ob==1	

	* > predicted
	replace WAGE2_PT2=WAGE2_PT2/(40*52)
	replace WAGE2_PT3=WAGE2_PT3/(40*52)
	bys ID: egen AAE_PT2_s=mean(WAGE2_PT2)
		replace AAE_PT2_s=AAE_PT2_s*40*52
	bys ID: egen AAE_PT3_s=mean(WAGE2_PT3)
		replace AAE_PT3_s=AAE_PT3_s*40*52
	bys ID: ge n_s=_n	
		
	
	
/* ----- Figure SWA.5 a-c: 1/2 reduction labor earnings ----- */		
	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & n_o==1, addplot (kdensity AAE_PT2_s if AAE_PT2_s>0 & AAE_PT2_s<80000 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ yscale(range(0 0.000045)) /*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA5a_FitAAE_PT_3p2div.pdf", as(pdf) replace

	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & EDUC>=12 & n_o==1, addplot (kdensity AAE_PT2_s if AAE_PT2_s>0 & AAE_PT2_s<80000 & EDUC>=12 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ yscale(range(0 0.000045)) /*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA5b_FitAAEHE_PT_3p2div.pdf", as(pdf) replace

	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & EDUC<12 & n_o==1, addplot (kdensity AAE_PT2_s if AAE_PT2_s>0 & AAE_PT2_s<80000 & EDUC<12 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ yscale(range(0 0.000045)) /*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA5c_FitAAELE_PT_3p2div.pdf", as(pdf) replace		
	
	
/* ----- Figure SWA.5 d-f: 2/3 reduction labor earnings ----- */		
	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & n_o==1, addplot (kdensity AAE_PT3_s if AAE_PT3_s>0 & AAE_PT3_s<80000 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ yscale(range(0 0.000045)) /*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA5d_FitAAE_PT_3p3div.pdf", as(pdf) replace

	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & EDUC>=12 & n_o==1, addplot (kdensity AAE_PT3_s if AAE_PT3_s>0 & AAE_PT3_s<80000 & EDUC>=12 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ yscale(range(0 0.000045)) /*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA5e_FitAAEHE_PT_3p3div.pdf", as(pdf) replace

	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & EDUC<12 & n_o==1, addplot (kdensity AAE_PT3_s if AAE_PT3_s>0 & AAE_PT3_s<80000 & EDUC<12 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ yscale(range(0 0.000045)) /*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA5f_FitAAELE_PT_3p3div.pdf", as(pdf) replace	
	
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. Table SWA.16: Robustness main inequality decomposition
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	set seed 182

/* ----- Pseudo-random subsample of individuals ----- */
	use "${SIMDATA}Base.dta", clear	
	
	keep ID EDUC TYPE
	
	duplicates drop ID, force
	
	sample `robsamp_share' , by(EDUC TYPE)

	sum EDUC TYPE ID

/* ----- Generate adjusted labor earnings for subsample ----- */		
	merge 1:m ID using "${SIMDATA}Base.dta", ///
		gen(PT_merge) keepusing(Age EDUC WAGEInterest_LT TranAugDispPersonalIncome_LT) keep(3)

	* >>> Part-time earnings adjustments
	gen WAGEInterest_LT_PT2 = WAGEInterest_LT/2
	gen WAGEInterest_LT_PT3 = WAGEInterest_LT/3

	gen TranAugDispPersonalIncome_LT_PT2 = TranAugDispPersonalIncome_LT/2	
	gen TranAugDispPersonalIncome_LT_PT3 = TranAugDispPersonalIncome_LT/3
		
		
/* ----- Save part-time sample ----- */	
	save "${SIMDATA}data_Base_PTadj.dta", replace
	
			
/* ----- Merge adjusted labor earnings to main dataset ----- */		
	use "${SIMDATA}Base.dta", clear

	merge 1:1 ID Age using "${SIMDATA}data_Base_PTadj.dta", ///
		gen(PT_merge) keepusing(WAGEInterest_LT_PT* TranAugDispPersonalIncome_LT_PT*)

	* >>> replace part-time adjusted earnings variables
	replace WAGEInterest_LT_PT2 = WAGEInterest_LT if mi(WAGEInterest_LT_PT2)
	replace WAGEInterest_LT_PT3 = WAGEInterest_LT if mi(WAGEInterest_LT_PT3)	

	replace TranAugDispPersonalIncome_LT_PT2 = TranAugDispPersonalIncome_LT	if mi(TranAugDispPersonalIncome_LT_PT2)
	replace TranAugDispPersonalIncome_LT_PT3 = TranAugDispPersonalIncome_LT	if mi(TranAugDispPersonalIncome_LT_PT3)
	
	
/* ----- Save data for inequality decomposition ----- */		
	* >>> 1/2 reduction 
	preserve
		drop WAGEInterest_LT TranAugDispPersonalIncome_LT
		
		ren WAGEInterest_LT_PT2 WAGEInterest_LT
		ren TranAugDispPersonalIncome_LT_PT2 TranAugDispPersonalIncome_LT
		
		compress
		save "${SIMDATA}Base_PT2.dta", replace	
	restore
	
	* >>> 2/3 reduction 
	preserve
		drop WAGEInterest_LT TranAugDispPersonalIncome_LT
		
		ren WAGEInterest_LT_PT3 WAGEInterest_LT
		ren TranAugDispPersonalIncome_LT_PT3 TranAugDispPersonalIncome_LT
		
		compress
		save "${SIMDATA}Base_PT3.dta", replace	
	restore	
	
	
/* ----- Run inequality decomposition ----- */	
	clear all
	
	set matsize 1000
	use "${SIMDATA}perms.dta", clear
	mkmat var1-var4,matrix(P)
	
	
	clear
	
	foreach x in Base_PT2 Base_PT3  {		
		* > Inequality measure - Theil Index (ge1)
		forval A = 1/1 {
			local dataset = "`x'"
			local measure = "`A'"
			do "${CODE}analysis_part1_decomp.do" `dataset' `measure'			
		}		
	}
	
	