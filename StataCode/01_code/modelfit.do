** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- MODEL FIT AND VALIDATION
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
	
Generated Tables and Figures:	
	- Figure 2a/b: Estimated wage profiles (excl. wage shocks)
	- Figure_SWA2a_FitUe.pdf
	- Figure_SWA2b_FitRet.pdf
	
	- Table_2_TypeEducMatch.tex 				(CollectedResults)	
	- Education-Ability correlation				(CollectedResults)
	
	- Figure_4a_FitEmp.pdf
	- Figure_4c_FitWealth.pdf
	- Figure_SWA2a_FitUe.pdf
	- Figure_SWA2b_FitRet.pdf
	
	- Table_SWA4_LSPers 						(CollectedResults)
	- Figure_SWA3_UESurv.pdf
	
	- Figure_4b_EarnQuantProf.pdf
	
	- Table_SWA6_EarnMob						(CollectedResults)

	- Figure_SWA6a_ObsWealthHist
	- Figure_SWA6b_SimWealthHist

*/


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 00. IMPORT ESTIMATED PARAMETERS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	import delimited "${MATLABOUTPUT}paramhat.txt" , clear
	
	mkmat v1, matrix(estim_params)


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. ESTIMATED WAGE PROFILES 		(Figure 2)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
/* ----- Generate age-profiles ----- */
	use "${SIMDATA}data_baseline.dta", clear

	* >>> parameters
		gen eta1 = estim_params[1,1]
		gen eta2 = estim_params[2,1]
		gen eta3 = estim_params[3,1]
		
		gen psi1 = estim_params[5,1]
		gen psi2 = estim_params[6,1]
		gen psi3 = estim_params[7,1]
		gen psi4 = estim_params[8,1]
		gen psi5 = estim_params[9,1]
		gen psi6 = estim_params[10,1]	
	

	* >>> generate wage profiles
		ge LoEduc=1 if EDUC<12
		replace LoEduc=0 if LoEduc==.
		ge HiEduc=1-LoEduc

		ge Exper2=Exper^2

		ge pwage1=exp(eta1+psi1*EDUC/10+psi2*(Exper/10)*LoEduc+psi3*(Exper/10)*HiEduc+psi4*(Exper2/1000)*LoEduc+psi5*(Exper2/1000)*HiEduc+psi6*Health)
		ge awage1=pwage1*40*52
		ge ewage1=pwage1

		ge pwage2=exp(eta2+psi1*EDUC/10+psi2*(Exper/10)*LoEduc+psi3*(Exper/10)*HiEduc+psi4*(Exper2/1000)*LoEduc+psi5*(Exper2/1000)*HiEduc+psi6*Health)
		ge awage2=pwage2*40*52
		ge ewage2=pwage2

		ge pwage3=exp(eta3+psi1*EDUC/10+psi2*(Exper/10)*LoEduc+psi3*(Exper/10)*HiEduc+psi4*(Exper2/1000)*LoEduc+psi5*(Exper2/1000)*HiEduc+psi6*Health)
		ge awage3=pwage3*40*52
		ge ewage3=pwage3

	drop if Age<(EDUC+8)
	drop if Reti==1
	drop if Age>60

	
	
/* ----- Figure 2: Estimated wage profiles (excl. wage shocks) ----- */	
	preserve
		duplicates drop Exper TYPE EDUC Health, force

		twoway (connected ewage1 Exper if TYPE==1 & EDUC==14 & Health==1 & Exper<=40, sort lcolor(black) msymbol(i)) /*
		*/ (connected ewage2 Exper if TYPE==2 & EDUC==14 & Health==1 & Exper<=40, sort lcolor(black) lpattern(dash) msymbol(i)) /*
		*/(connected ewage3 Exper if TYPE==3 & EDUC==14 & Health==1 & Exper<=40, sort lcolor(black) lpattern(dot) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 10 20 30,labsize(medlarge)) /*
		*/ xtitle("Experience (years)", margin(medium) size(medlarge))  ytitle("Wage (euros per hour)", margin(medium) size(medlarge)) /*
		*/ xlabel(0 10 20 30 40,labsize(medlarge))/*
		*/ yscale(range(0,35))/*
		*/ legend(order(1 "Productive ability type H" 2 "Productive ability type M" 3 "Productive ability type L"))/*
		*/ legend(region(lcolor(white))) legend(size(medlarge) cols(1))/*
		*/ aspectratio(.8)
		graph export "${FIGURES}Figure_2b_WageProfHigh.pdf", as(pdf) replace

		twoway (connected ewage1 Exper if TYPE==1 & EDUC==11 & Health==1 & Exper<=40, sort lcolor(black) msymbol(i)) /*
		*/ (connected ewage2 Exper if TYPE==2 & EDUC==11 & Health==1 & Exper<=40, sort lcolor(black) lpattern(dash) msymbol(i)) /*
		*/(connected ewage3 Exper if TYPE==3 & EDUC==11 & Health==1 & Exper<=40, sort lcolor(black) lpattern(dot) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 10 20 30,labsize(medlarge)) /*
		*/ xtitle("Experience (years)", margin(medium) size(medlarge))  ytitle("Wage (euros per hour)", margin(medium) size(medlarge)) /*
		*/ xlabel(0 10 20 30 40,labsize(medlarge))/*
		*/ yscale(range(0,35))/*
		*/ legend(order(1 "Productive ability type H" 2 "Productive ability type M" 3 "Productive ability type L"))/*
		*/ legend(region(lcolor(white))) legend(size(medlarge) cols(1))/*
		*/ aspectratio(.8)
		graph export "${FIGURES}Figure_2a_WageProfLow.pdf", as(pdf) replace
		
		graph close
		
	restore

	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. Joint distribution of education and productive ability - Table 2
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	
/* ----- load and prepare data ----- */		
	use "${SIMDATA}data_baseline_matched.dta", clear
	
	duplicates drop ID, force
	
	tab EDUC TYPE, col row
	
	
/* ----- generate labels ----- */		
	label define type_label 1 "High" 2 "Medium" 3 "Low"
		label values TYPE type_label
	

/* ----- Table 2: Joint distribution of years of education and productive ability ----- */			
	* > reports cell- and row-percentage
	
	eststo jointdistr: estpost tabulate EDUC TYPE	
		mat high_cell = e(pct)[1,1..12]'
			mat list high_cell
		mat med_cell = e(pct)[1,13..24]'
			mat list med_cell
		mat low_cell = e(pct)[1,25..36]'
			mat list low_cell
		mat all_cell = e(pct)[1,37..48]'
			mat list all_cell
		
		mat high_row = e(rowpct)[1,1..11]'
			mat list high_row
		mat med_row = e(rowpct)[1,13..23]'
			mat list med_row
		mat low_row = e(rowpct)[1,25..35]'
			mat list low_row
		mat all_row = e(rowpct)[1,37..47]'
			mat list all_row
	
	* >>> Export to CollectedResults
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_2_Corr") modify

	putexcel F6 = matrix(high_cell)
	putexcel G6 = matrix(high_row)
	putexcel H6 = matrix(med_cell)
	putexcel I6 = matrix(med_row)
	putexcel J6 = matrix(low_cell)
	putexcel K6 = matrix(low_row)
	putexcel L6 = matrix(all_cell)
	putexcel M6 = matrix(all_row)
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 03. PRODUCTIVITY TYPE-EDUCATION CORRELATION  -- Table 2 (Notes)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	
	use "${SIMDATA}data_baseline_matched.dta", clear

/* ----- Estimated prod. ability intercept parameters ----- */	
	gen type_inter = .
		replace type_inter = estim_params[1,1] if TYPE == 1
		replace type_inter = estim_params[2,1] if TYPE == 2
		replace type_inter = estim_params[3,1] if TYPE == 3
		
	label var type_inter "Prod. Type Intercepts"	

	
/* ----- Correlation: years of schooling and productive ability ----- */	
	pwcorr type_inter EDUC, star(0.01)
	
	mat ed_type_corr = round(r(rho),0.0001)
		mat list ed_type_corr
	
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_2_Corr") modify
	putexcel B3 = matrix(ed_type_corr)	
	
	


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 04. In-sample Fit: Life-cycle Profiles
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

*******************************************************************************
* 04a. Prepare observed and simulated data
*******************************************************************************		
			
	use "${DATA_CONFID}data_ObsSimComb_ob1.dta", clear
	
/* ----- Estimation sample: observed outcomes ----- */			
	replace o_WAGE=. if o_Empl==0
	replace o_WAGE=o_WAGE/(52*40)
	
	gen o_Unempl=(o_Empl==0 & o_Reti==0) if !mi(o_Empl)
	
	ge rAge=2*floor(Age/2) 
		replace Age=rAge if Age<=27

	bys Age: egen mEmpl_o=mean(o_Empl)
	bys Age: egen mWage_o=mean(o_WAGE)
	bys Age: egen mReti_o=mean(o_Reti)
	bys Age: egen mUnempl_o=mean(o_Unempl)
	bys Age: egen mWealth_o=mean(o_Wealth)
	bys Age: egen mWealth_SOEP07_o = mean(o_Wealth_SOEP07)
	bys Age: egen medWealth_SOEP07_o=median(o_Wealth_SOEP07)
	ge mne_o=1-mEmpl_o-mReti_o
		
		
/* ----- Simulated (matched) sample: predicted outcomes ----- */	
	replace WAGE2=. if Empl==0
	replace WAGE2=WAGE2/(52*40)
	
	gen Unempl=(Empl==0 & Reti==0)

	bys Age: egen mEmpl_s=mean(Empl)
	bys Age: egen mWage_s=mean(WAGE2)
	bys Age: egen mReti_s=mean(Reti)
	bys Age: egen mUnempl_s=mean(Unempl)
	bys Age: egen mWealth_s=mean(Wealth)
	bys Age: egen medWealth_s=median(Wealth)	
	ge mne_s=1-mEmpl_s-mReti_s
	
	
/* ----- Keep only averages by age ----- */		
	keep Age m*	
	duplicates drop Age, force		
		
		
*******************************************************************************
* 04b. In-sampel fit measures: Age-profiles
*******************************************************************************	

/* ----- Figure 4a: Age-profile - Employment ----- */
	twoway (connected mEmpl_o Age if Age<=65, sort lcolor(black) msymbol(i)) (connected mEmpl_s Age if Age<=65, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
	*/ ylabel(0 0.25 0.5 .75 1,labsize(medlarge)) /*
	*/ yscale(range(0 1.0)) /*
	*/ xtitle("Age (years)", margin(medium) size(medlarge))  ytitle("Employment rate", margin(medium) size(medlarge)) /*
	*/ xlabel(20 30 40 50 60,labsize(medlarge))/*
	*/ legend(order(1 "Observed" 2 "Predicted"))/*
	*/ legend(region(lcolor(white))) legend(size(medlarge) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_4a_FitEmp.pdf", as(pdf) replace

	
/* ----- Figure 4c: Age-profile - Wealth (mean) ----- */			
	twoway (connected mWealth_SOEP07_o Age if Age<=64, sort lcolor(black) msymbol(i)) (connected mWealth_s Age if Age<=64, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
	*/ ylabel(0 "0" 40000 "40,000"  80000 "80,000",labsize(medlarge)) /*
	*/ yscale(range(0 80000)) /*
	*/ xtitle("Age (years)", margin(medium) size(medlarge))  ytitle("Mean wealth (euros)",  margin(medium) size(medlarge)) /*
	*/ xlabel(20 30 40 50 60,labsize(medlarge))/*
	*/ legend(order(1 "Obs" 2 "Predicted"))/*
	*/ legend(region(lcolor(white))) legend(size(medlarge) cols(2))/*
	*/ aspectratio(.8)			
	graph export "${FIGURES}Figure_4c_FitWealth.pdf", as(pdf) replace	

	
/* ----- Figure SWA.2a: Age-profile - Unemployment ----- */
	twoway (connected mUnempl_o Age if Age<=65, sort lcolor(black) msymbol(i)) (connected mUnempl_s Age if Age<=65, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
	*/ ylabel(0 0.25 0.5 .75 1,labsize(medlarge)) /*
	*/ yscale(range(0 1.0)) /*
	*/ xtitle("Age (years)", margin(medium) size(medlarge))  ytitle("Unemployment rate", margin(medium) size(medlarge)) /*
	*/ xlabel(20 30 40 50 60,labsize(medlarge))/*
	*/ legend(order(1 "Observed" 2 "Predicted"))/*
	*/ legend(region(lcolor(white))) legend(size(medlarge) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA2a_FitUe.pdf", as(pdf) replace


/* ----- Figure SWA.2b: Age-profile - Retirement ----- */
	twoway (connected mReti_o Age if Age<=65, sort lcolor(black) msymbol(i)) (connected mReti_s Age if Age<=65, sort lcolor(black) msymbol(i) lpattern(dash)), scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
	*/ ylabel(0 0.25 0.5 .75 1,labsize(medlarge)) /*
	*/ yscale(range(0 1.0)) /*
	*/ xtitle("Age (years)", margin(medium) size(medlarge))  ytitle("Retirement rate", margin(medium) size(medlarge)) /*
	*/ xlabel(20 30 40 50 60,labsize(medlarge))/*
	*/ legend(order(1 "Observed" 2 "Predicted"))/*
	*/ legend(region(lcolor(white))) legend(size(medlarge) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA2b_FitRet.pdf", as(pdf) replace


	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 05. In-sample Fit: Distributional measures
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		

*******************************************************************************
* 05a. Prepare observed and simulated data
*******************************************************************************		
	
	use "${DATA_CONFID}data_ObsSimComb_ob1.dta", clear	

	keep o_WAGE EDUC Age Ob o_ID o_Empl ID WAGE2 Empl

	drop if Age>=60	
	
/* ----- Estimation sample: observed outcomes ----- */	
	replace o_WAGE=o_WAGE/(40*52)
	
	bys ID: egen AAE_o=mean(o_WAGE)
		replace AAE_o=AAE_o*40*52
	
	bys o_ID: ge n_o=_n	if Ob==1
	
	
/* ----- Simulated (matched) sample: predicted outcomes ----- */	
	replace WAGE2=WAGE2/(40*52)
	
	bys ID: egen AAE_s=mean(WAGE2)
		replace AAE_s=AAE_s*40*52
		
	bys ID: ge n_s=_n	
	
		
*******************************************************************************
* 05b. Figure SWA.1: Distribution of wages
*******************************************************************************	

/* ----- Figure SWA.1a: Distribution of Wages -- All ----- */
	kdensity o_WAGE  if o_WAGE>0  & o_WAGE<50, addplot (kdensity WAGE2  if WAGE2>0  & WAGE2<50)/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Wage (euros per hour), margin(medium) size(large))/*
	*/ xlabel(0 10 20 30 40 50,labsize(large))/*
	*/ ylabel(0 0.03 0.06 0.09,nogrid labsize(large))/*
	*/ title("")/*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA1a_FitWages.pdf", as(pdf) replace


/* ----- Figure SWA.1b: Distribution of Wages -- HighEduc ----- */
	kdensity o_WAGE  if o_WAGE>0 & o_WAGE<50 & EDUC>=12, addplot (kdensity WAGE2  if WAGE2>0  & WAGE2<50 & EDUC>=12)/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Wage (euros per hour), margin(medium) size(large))/*
	*/ xlabel(0 10 20 30 40 50, labsize(large))/*
	*/ ylabel(0 0.03 0.06 0.09,  nogrid labsize(large))/*
	*/ title("")/*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA1b_FitWagesHE.pdf", as(pdf) replace


/* ----- Figure SWA.1c: Distribution of Wages -- LowEduc ----- */
	kdensity o_WAGE  if o_WAGE>0 & o_WAGE<50 & EDUC<12, addplot (kdensity WAGE2  if WAGE2>0   & WAGE2<50 & EDUC<12)/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Wage (euros per hour),margin(medium) size(large))/*
	*/ xlabel(0 10 20 30 40 50, labsize(large))/*
	*/ ylabel(0 0.03 0.06 0.09,nogrid labsize(large))/*
	*/ title("")/*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA1c_FitWagesLE.pdf", as(pdf) replace

	graph close

*******************************************************************************
* 05c. Figure SWA.3: Distribution of avg. annual labor earnings
*******************************************************************************	

/* ----- Figure SWA.3a: Distribution of Labor Earnings -- All ----- */
	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & n_o==1, addplot (kdensity AAE_s if AAE_s>0 & AAE_s<80000 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ yscale(range(0 0.000045)) /*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA4a_FitAAE.pdf", as(pdf) replace

	
/* ----- Figure SWA.3b: Distribution of Labor Earnings -- HighEduc ----- */
	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & EDUC>=12 & n_o==1, addplot (kdensity AAE_s if AAE_s>0 & AAE_s<80000 & EDUC>=12 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ yscale(range(0 0.000045)) /*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA4b_FitAAEHE.pdf", as(pdf) replace


/* ----- Figure SWA.3c: Distribution of Labor Earnings -- LowEduc ----- */
	kdensity AAE_o if AAE_o>0 & AAE_o<80000 & EDUC<12 & n_o==1, addplot (kdensity AAE_s if AAE_s>0 & AAE_s<80000 & EDUC<12 & n_s==1, bw(2800))/*
	*/ ytitle(Density,size(large))/* 
	*/ xtitle(Average annual labor earnings (euros), margin(medium) size(large))/*
	*/ xlabel(0 25000 50000 75000,labsize(large))/*
	*/ yscale(range(0 0.000045)) /*
	*/ ylabel(0 2e-5 4e-5,nogrid labsize(large))/*
	*/ title("")/*
	*/ legend(order(1 "Obs" 2 "Predicted")) scheme(sj) graphregion(color(white))/*
	*/ legend(region(lcolor(white))) legend(size(large) cols(2))/*
	*/ aspectratio(.8)
	graph export "${FIGURES}Figure_SWA4c_FitAAELE.pdf", as(pdf) replace

	graph close
	

	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 06. Table SWA.4: Observed and Predicted Persistence in Labor Supply
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		

*******************************************************************************
* 06a. Prepare data and derive main measures
*******************************************************************************	
	
	clear matrix
	
/* ----- Estimation sample: observed outcomes ----- */	
	use "${DATA_CONFID}esample_plus.dta", clear
	
	drop if Age>=60
	
	foreach x in All High Low {		
		preserve
		
			if "`x'"=="High" {
				drop if EDUC<=11
			}
			
			if "`x'"=="Low" {
				drop if EDUC>=12
			}						
			* --------------------------
			ge nonemp=1-Empl-Reti
			bys ID: egen mEmp=mean(Empl)
			bys ID: egen mNe=mean(nonemp)
			bys ID: egen mRt=mean(Reti)

			bys ID: ge nn=_n
			keep if nn==1

			su mEmp mNe mRt

			foreach j in 0 25 50 75{
				ge mEmp`j'=1 if mEmp<=`j'/100
					replace mEmp`j'=0 if mEmp`j'==.
				ge mNe`j'=1 if mNe<=`j'/100
					replace mNe`j'=0 if mNe`j'==.
				ge mRt`j'=1 if mRt<=`j'/100
					replace mRt`j'=0 if mRt`j'==.

				egen Memp`j'=mean(mEmp`j')
				egen MNe`j'=mean(mNe`j')
				egen MRt`j'=mean(mRt`j')
			}

			foreach j in emp Ne Rt{
				ge M`j'_o=M`j'0 if _n==1
					replace M`j'_o=M`j'25 if _n==2
					replace M`j'_o=M`j'50 if _n==3
					replace M`j'_o=M`j'75 if _n==4
			}
			
			keep if _n<=4
			keep M*_o
			
			* --------------------------
			* >>> rename and save to matrix (by All/High/Low Educ)
			foreach r of varlist _all {			
				ren `r' `r'_`x'
			}
			
			mkmat _all 
			
			list	
	
		restore	
	}	
		
	
/* ----- Simulated (matched) sample: predicted outcomes ----- */			
	use "${SIMDATA}data_baseline_ob1.dta", clear

	drop if Age>=60

	foreach x in All High Low {		
		preserve
		
			if "`x'"=="High" {
				drop if EDUC<=11
			}
			
			if "`x'"=="Low" {
				drop if EDUC>=12
			}		
	
			ge nonemp=1-Empl-Reti
			bys ID: egen mEmp=mean(Empl)
			bys ID: egen mNe=mean(nonemp)
			bys ID: egen mRt=mean(Reti)

			bys ID: ge nn=_n
			keep if nn==1

			su mEmp mNe mRt

			foreach j in 0 25 50 75{
				ge mEmp`j'=1 if mEmp<=`j'/100
					replace mEmp`j'=0 if mEmp`j'==.
				ge mNe`j'=1 if mNe<=`j'/100
					replace mNe`j'=0 if mNe`j'==.
				ge mRt`j'=1 if mRt<=`j'/100
					replace mRt`j'=0 if mRt`j'==.

				egen Memp`j'=mean(mEmp`j')
				egen MNe`j'=mean(mNe`j')
				egen MRt`j'=mean(mRt`j')
			}

			foreach j in emp Ne Rt{
				ge M`j'_s=M`j'0 if _n==1
					replace M`j'_s=M`j'25 if _n==2
					replace M`j'_s=M`j'50 if _n==3
					replace M`j'_s=M`j'75 if _n==4
			}

			keep if _n<=4
			keep M*_s
			
			* --------------------------
			* >>> rename and save to matrix (by All/High/Low Educ)
			foreach r of varlist _all {			
				ren `r' `r'_`x'
			}
			
			mkmat _all 			
			
			list
		restore
	}
	

*******************************************************************************
* 06b. Observed Data: Add. measures on unemployment frequency and durations
*******************************************************************************	

/* ----- Load dataset & Execute script  ----- */	
	use "${DATA_CONFID}esample_plus.dta", clear	
		
	do "${CODE}ue_durations.do"
	
	
/*----- average number of unemployment spells -----*/	
	preserve 
		duplicates drop ID, force

		sum nmbr_uempl_spell
			mat mean_spells_all_o = r(mean)
		sum nmbr_uempl_spell if EDUC<=11
			mat mean_spells_low_o = r(mean)
		sum nmbr_uempl_spell if EDUC>=12	
			mat mean_spells_high_o = r(mean)
	restore		
	
	
/*----- average unemployment spell duration  -----*/	
	preserve
		su length if begin==1
			mat mean_length_all_o = r(mean)
		su length if begin==1 & EDUC<=11
			mat mean_length_low_o = r(mean)
		su length if begin==1 & EDUC>=12
			mat mean_length_high_o = r(mean)
	restore	
		
	
/*----- predict survival -----*/			
	gen surv_rate = 1-ue_haz	
	gen dur_axis = ue_dur
	
	preserve
		collapse (mean) ue_haz surv_rate dur_axis, by(ue_dur)
		list
		* > survivor function
			*graph bar surv_rate, over(dur_axis)
	
		*drop if mi(surv_rate)
		replace dur_axis = 0 if dur_axis==.
		replace surv_rate = 1 if dur_axis==0
		sort dur_axis
		gen surv_func = 1 in 1
			replace surv_func = surv_func[_n-1]*surv_rate in 2/L
		list
		mkmat surv_func
			*twoway (line surv_func dur_axis, connect(J)), yscale(range(0,1))
	restore
	
	
	mat surv_func_obs = surv_func
	mat list surv_func_obs
	
	
	
/*----- by educ: predict survival -----*/			
	gen surv_rate_ed = 1-ue_haz_ed	
	
	preserve
		collapse (mean) ue_haz_ed surv_rate_ed dur_axis, by(ue_dur educ_lvl)
		list
		* > survivor function
		replace dur_axis = 0 if dur_axis==.
		replace surv_rate_ed = 1 if dur_axis==0
		sort educ_lvl dur_axis
		
		* led
		gen surv_func_ed0 = 1 if surv_rate_ed==1 & educ_lvl==0
			replace surv_func_ed0 = surv_func_ed0[_n-1]*surv_rate_ed in 2/L if educ_lvl==0 & !mi(surv_func_ed0[_n-1])	
		* hed
		gen surv_func_ed1 = 1 if surv_rate_ed==1 & educ_lvl==1
			replace surv_func_ed1 = surv_func_ed1[_n-1]*surv_rate_ed in 2/L if educ_lvl==1	& !mi(surv_func_ed1[_n-1])	
		
		list
		mkmat surv_func_ed0 if !mi(surv_func_ed0)
		mkmat surv_func_ed1 if !mi(surv_func_ed1)
	restore
	
	
	mat surv_func_ed0_obs = surv_func_ed0
	mat surv_func_ed1_obs = surv_func_ed1
	mat list surv_func_ed0_obs
	mat list surv_func_ed1_obs
	
	
	
	
*******************************************************************************
* 06c. Simulated Data: Add. measures on unemployment frequency and durations
*******************************************************************************	

/* ----- Simulated (matched) sample: predicted outcomes ----- */				
	use "${SIMDATA}data_baseline_ob1.dta", clear
		
	do "${CODE}ue_durations.do"
	
/*----- average number of unemployment spells -----*/	
	preserve 
		duplicates drop ID, force

		sum nmbr_uempl_spell
			mat mean_spells_all_s = r(mean)
		sum nmbr_uempl_spell if EDUC<=11
			mat mean_spells_low_s = r(mean)
		sum nmbr_uempl_spell if EDUC>=12	
			mat mean_spells_high_s = r(mean)
	restore		

	
/*----- average unemployment spell duration  -----*/	
	preserve
		su length if begin==1
			mat mean_length_all_s = r(mean)
		su length if begin==1 & EDUC<=11
			mat mean_length_low_s = r(mean)
		su length if begin==1 & EDUC>=12
			mat mean_length_high_s = r(mean)
	restore	
	
	
/*----- predict survival -----*/			
	gen surv_rate = 1-ue_haz	
	gen dur_axis = ue_dur
	preserve
		collapse (mean) ue_haz surv_rate dur_axis, by(ue_dur)
		list
		* > survivor function
			*graph bar surv_rate, over(dur_axis)
	
		*drop if mi(surv_rate)
		replace dur_axis = 0 if dur_axis==.
		replace surv_rate = 1 if dur_axis==0
		sort dur_axis
		gen surv_func = 1 in 1
			replace surv_func = surv_func[_n-1]*surv_rate in 2/L
		list
		mkmat surv_func
			*twoway (line surv_func dur_axis, connect(J)), yscale(range(0,1))
	restore
	
	mat surv_func_sim = surv_func
	mat list surv_func_sim	
	
	
/*----- by educ: predict survival -----*/			
	gen surv_rate_ed = 1-ue_haz_ed	
	
	preserve
		collapse (mean) ue_haz_ed surv_rate_ed dur_axis, by(ue_dur educ_lvl)
		list
		* > survivor function
		replace dur_axis = 0 if dur_axis==.
		replace surv_rate_ed = 1 if dur_axis==0
		sort educ_lvl dur_axis
		
		* led
		gen surv_func_ed0 = 1 if surv_rate_ed==1 & educ_lvl==0
			replace surv_func_ed0 = surv_func_ed0[_n-1]*surv_rate_ed in 2/L if educ_lvl==0 & !mi(surv_func_ed0[_n-1])	
		* hed
		gen surv_func_ed1 = 1 if surv_rate_ed==1 & educ_lvl==1
			replace surv_func_ed1 = surv_func_ed1[_n-1]*surv_rate_ed in 2/L if educ_lvl==1	& !mi(surv_func_ed1[_n-1])	
		
		list
		mkmat surv_func_ed0 if !mi(surv_func_ed0)
		mkmat surv_func_ed1 if !mi(surv_func_ed1)
	restore
	
	
	mat surv_func_ed0_sim = surv_func_ed0
	mat surv_func_ed1_sim = surv_func_ed1
	mat list surv_func_ed0_sim
	mat list surv_func_ed1_sim	
	
	
*******************************************************************************
* 06d. Plot survivor function
*******************************************************************************		
	
	clear
	svmat double surv_func_obs
	svmat double surv_func_sim
	svmat double surv_func_ed0_obs
	svmat double surv_func_ed0_sim	
	svmat double surv_func_ed1_obs
	svmat double surv_func_ed1_sim
	
	gen countcall = 0
	replace countcall = . if surv_func_obs1==1
	gen x_var = sum(!mi(countcall)) 
	list
	
	twoway (line surv_func_obs1 x_var, connect(J) lcolor(black) msymbol(i)) /// 
		   (line surv_func_sim1 x_var, connect(J) lcolor(black) msymbol(i) lpattern(dash)) ///
			, scheme(s2mono) graphregion(color(white)) ///
			ylabel(0 0.25 0.5 0.75 1, labsize(medlarge)) yscale(range(0,1)) ///
			xtitle("Unemployment spell duration (years)", margin(medium) size(medlarge)) ///
			ytitle("Survivor function", margin(medium) size(medlarge)) ///
			legend(order(1 "Observed" 2 "Predicted")) ///
			legend(region(lcolor(white))) legend(size(medlarge) cols(2)) ///
			aspectratio(.7)				
	graph export "${FIGURES}Figure_SWA3a_UESurv.pdf", as(pdf) replace
	

	twoway (line surv_func_ed0_obs1 x_var, connect(J) lcolor(black) msymbol(i)) /// 
		   (line surv_func_ed0_sim1 x_var, connect(J) lcolor(black) msymbol(i) lpattern(dash)) ///
			, scheme(s2mono) graphregion(color(white)) ///
			ylabel(0 0.25 0.5 0.75 1, labsize(medlarge)) yscale(range(0,1)) ///
			xtitle("Unemployment spell duration (years)", margin(medium) size(medlarge)) ///
			ytitle("Survivor function", margin(medium) size(medlarge)) ///
			legend(order(1 "Observed" 2 "Predicted")) ///
			legend(region(lcolor(white))) legend(size(medlarge) cols(2)) ///
			aspectratio(.7)		
	graph export "${FIGURES}Figure_SWA3c_UESurvLE.pdf", as(pdf) replace		
			

	twoway (line surv_func_ed1_obs1 x_var, connect(J) lcolor(black) msymbol(i)) /// 
		   (line surv_func_ed1_sim1 x_var, connect(J) lcolor(black) msymbol(i) lpattern(dash)) ///
			, scheme(s2mono) graphregion(color(white)) ///
			ylabel(0 0.25 0.5 0.75 1, labsize(medlarge)) yscale(range(0,1)) ///
			xtitle("Unemployment spell duration (years)", margin(medium) size(medlarge)) ///
			ytitle("Survivor function", margin(medium) size(medlarge)) ///
			legend(order(1 "Observed" 2 "Predicted")) ///
			legend(region(lcolor(white))) legend(size(medlarge) cols(2)) ///
			aspectratio(.7)					
	graph export "${FIGURES}Figure_SWA3b_UESurvHE.pdf", as(pdf) replace		
	
	
*******************************************************************************
* 06d. Table SWA.4: Persistence in Labor Supply
*******************************************************************************		

/* ----- Table SWA.4: Export results to ExcelBook "CollectedResults" ----- */	
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_SWA4_LSPers") modify
	
	* >>> Preparations for export to Table SWA.4
	mat Memp_o_All = Memp_o_All \ 1
		mat Memp_o_High = Memp_o_High \ 1
		mat Memp_o_Low = Memp_o_Low \ 1	
	mat MNe_o_All = MNe_o_All \ 1
		mat MNe_o_High = MNe_o_High \ 1
		mat MNe_o_Low = MNe_o_Low \ 1
		
	mat Memp_s_All = Memp_s_All \ 1
		mat Memp_s_High = Memp_s_High \ 1
		mat Memp_s_Low = Memp_s_Low \ 1
	mat MNe_s_All = MNe_s_All \ 1
		mat MNe_s_High = MNe_s_High \ 1
		mat MNe_s_Low = MNe_s_Low \ 1
	
	
	* >>> Observed persistence in employment:
		putexcel D9 = matrix(Memp_o_All*100)
		putexcel F9 = matrix(Memp_o_High*100)
		putexcel H9 = matrix(Memp_o_Low*100)		
	* >>> Simulated persistence in employment:	
		putexcel E9 = matrix(Memp_s_All*100)
		putexcel G9 = matrix(Memp_s_High*100)
		putexcel I9 = matrix(Memp_s_Low*100)
		
	* >>> Observed persistence in unemployment:
		putexcel D18 = matrix(MNe_o_All*100)
		putexcel F18 = matrix(MNe_o_High*100)
		putexcel H18 = matrix(MNe_o_Low*100)		
	* >>> Simulated persistence in unemployment:	
		putexcel E18 = matrix(MNe_s_All*100)
		putexcel G18 = matrix(MNe_s_High*100)
		putexcel I18 = matrix(MNe_s_Low*100)		
	
	
	* ---------------------------------------------------
	* >>> Observed mean number of unemployment spells	
		putexcel D24 = matrix(mean_spells_all_o)
		putexcel F24 = matrix(mean_spells_high_o)
		putexcel H24 = matrix(mean_spells_low_o)
	* >>> Simulated mean number of unemployment spells
		putexcel E24 = matrix(mean_spells_all_s)
		putexcel G24 = matrix(mean_spells_high_s)
		putexcel I24 = matrix(mean_spells_low_s)		

	* >>> Observed mean length of unemployment spells	
		putexcel D25 = matrix(mean_length_all_o)
		putexcel F25 = matrix(mean_length_high_o)
		putexcel H25 = matrix(mean_length_low_o)
	* >>> Simulated mean length of unemployment spells
		putexcel E25 = matrix(mean_length_all_s)
		putexcel G25 = matrix(mean_length_high_s)
		putexcel I25 = matrix(mean_length_low_s)			
		
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 07. Labor Earnings Mobility: Transition Matrices
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
* Notes:
*	> execution in separate script
* 	> Results: Table SWA.5 exported to "CollectedResults.xlsx", Sheet: "Tab_SWA5_EarnMob"
	
	clear
	
	do "${CODE}earn_mobil.do"
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 08. Earnings Percentiles: Life-cycle Profiles
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
	clear

	mat define LC_p90p10 = J(40,2,.)
	mat define LC_p90p50 = J(40,2,.)
	mat define LC_p10p50 = J(40,2,.)
	mat define LC_p75p25 = J(40,2,.)

	mat define LC_p10 = J(40,2,.)
	mat define LC_p25 = J(40,2,.)
	mat define LC_p50 = J(40,2,.)
	mat define LC_p75 = J(40,2,.)
	mat define LC_p90 = J(40,2,.)

	mat define LC_p20 = J(40,2,.)
	mat define LC_p40 = J(40,2,.)
	mat define LC_p60 = J(40,2,.)
	mat define LC_p80 = J(40,2,.)
		
	
	* ---------------------------------------------------------------------	
	/* ----- Simulated (matched) sample: predicted outcomes ----- */
	use "${SIMDATA}data_baseline_ob1.dta", clear
	drop if Age>=60

	replace WAGE2 = . if Empl==0 

	ge rAge=2*floor(Age/2) 
		replace Age=rAge if Age<=27

	foreach x in 20 22 24 26 {
		preserve 
			keep if Age == `x'
			ineqdeco WAGE2 
			
			mat LC_p90p10[`x'-19,1] = r(p90p10)
			mat LC_p90p50[`x'-19,1] = r(p90p50)
			mat LC_p10p50[`x'-19,1] = r(p10p50)
			mat LC_p75p25[`x'-19,1] = r(p75p25)		
			
			mat  LC_p10[`x'-19,1]  = r(p10)
			mat  LC_p25[`x'-19,1]  = r(p25)
			mat  LC_p50[`x'-19,1]  = r(p50)
			mat  LC_p75[`x'-19,1]  = r(p75)
			mat  LC_p90[`x'-19,1]  = r(p90)
			
			_pctile WAGE2, nq(5)
			mat LC_p20[`x'-19,1] = r(r1)
			mat LC_p40[`x'-19,1] = r(r2)
			mat LC_p60[`x'-19,1] = r(r3)
			mat LC_p80[`x'-19,1] = r(r4)
			
			
		restore		
	}


	forval x = 28/59 {
		preserve 
			keep if Age == `x'
			ineqdeco WAGE2 
			
			mat LC_p90p10[`x'-19,1] = r(p90p10)
			mat LC_p90p50[`x'-19,1] = r(p90p50)
			mat LC_p10p50[`x'-19,1] = r(p10p50)
			mat LC_p75p25[`x'-19,1] = r(p75p25)		
			
			mat  LC_p10[`x'-19,1]  = r(p10)
			mat  LC_p25[`x'-19,1]  = r(p25)
			mat  LC_p50[`x'-19,1]  = r(p50)
			mat  LC_p75[`x'-19,1]  = r(p75)
			mat  LC_p90[`x'-19,1]  = r(p90)
			
			_pctile WAGE2, nq(5)
			mat LC_p20[`x'-19,1] = r(r1)
			mat LC_p40[`x'-19,1] = r(r2)
			mat LC_p60[`x'-19,1] = r(r3)
			mat LC_p80[`x'-19,1] = r(r4)
			
		restore	
	}


	* ---------------------------------------------------------------------	
	/* ----- Estimation sample: observed outcomes ----- */	
	use "${DATA_CONFID}esample_plus.dta", clear
	drop if Age>=60
	ge N=_N
	bys Age: gen Na=_N
	ge Fa=Na/N
	ge fa=1/Fa

	replace WAGE = . if Empl==0 

	ge rAge=2*floor(Age/2) 
		replace Age=rAge if Age<=27


	foreach x in 20 22 24 26 {
		preserve 
			keep if Age == `x'
			ineqdeco WAGE
			
			mat LC_p90p10[`x'-19,2] = r(p90p10)
			mat LC_p90p50[`x'-19,2] = r(p90p50)
			mat LC_p10p50[`x'-19,2] = r(p10p50)
			mat LC_p75p25[`x'-19,2] = r(p75p25)		
			
			mat  LC_p10[`x'-19,2]  = r(p10)
			mat  LC_p25[`x'-19,2]  = r(p25)
			mat  LC_p50[`x'-19,2]  = r(p50)
			mat  LC_p75[`x'-19,2]  = r(p75)
			mat  LC_p90[`x'-19,2]  = r(p90)
			
			_pctile WAGE, nq(5)
			mat LC_p20[`x'-19,2] = r(r1)
			mat LC_p40[`x'-19,2] = r(r2)
			mat LC_p60[`x'-19,2] = r(r3)
			mat LC_p80[`x'-19,2] = r(r4)
			
		restore		
	}


	forval x = 28/59 {
		preserve 
			keep if Age == `x'
			ineqdeco WAGE
			
			mat LC_p90p10[`x'-19,2] = r(p90p10)
			mat LC_p90p50[`x'-19,2] = r(p90p50)
			mat LC_p10p50[`x'-19,2] = r(p10p50)
			mat LC_p75p25[`x'-19,2] = r(p75p25)	
		
			mat  LC_p10[`x'-19,2]  = r(p10)
			mat  LC_p25[`x'-19,2]  = r(p25)
			mat  LC_p50[`x'-19,2]  = r(p50)
			mat  LC_p75[`x'-19,2]  = r(p75)
			mat  LC_p90[`x'-19,2]  = r(p90)	
			
			_pctile WAGE, nq(5)
			mat LC_p20[`x'-19,2] = r(r1)
			mat LC_p40[`x'-19,2] = r(r2)
			mat LC_p60[`x'-19,2] = r(r3)
			mat LC_p80[`x'-19,2] = r(r4)		
			
		restore	
	}


	* >>> Plots
		clear
		svmat LC_p90p10 
		svmat LC_p90p50 
		svmat LC_p10p50 
		svmat LC_p75p25
		svmat LC_p10
		svmat LC_p25
		svmat LC_p50
		svmat LC_p75
		svmat LC_p90
		svmat LC_p20
		svmat LC_p40
		svmat LC_p60
		svmat LC_p80
			gen countcall = 0
			gen x_var = sum(!mi(countcall))
			drop countcall
			replace x_var = x_var + 19


	/* ----- Figure 4b: Earnings percentiles: 10, 25, 50, 75, 100 ----- */
	twoway (connected LC_p102 x_var, sort lcolor(black) msymbol(i)) ///		
			(connected LC_p101 x_var,sort lcolor(black) msymbol(i) lpattern(dash)) ///
			(connected LC_p252 x_var, sort lcolor(black) msymbol(i)) ///		
			(connected LC_p251 x_var,sort lcolor(black) msymbol(i) lpattern(dash)) ///
			(connected LC_p502 x_var, sort lcolor(black) msymbol(i)) ///		
			(connected LC_p501 x_var,sort lcolor(black) msymbol(i) lpattern(dash)) ///
			(connected LC_p752 x_var, sort lcolor(black) msymbol(i)) ///		
			(connected LC_p751 x_var,sort lcolor(black) msymbol(i) lpattern(dash)) ///
			(connected LC_p902 x_var, sort lcolor(black) msymbol(i)) ///		
			(connected LC_p901 x_var,sort lcolor(black) msymbol(i) lpattern(dash)) ///
			, scheme(s2mono) ylab(, nogrid) graphregion(color(white)) ///
			xlabel(20 30 40 50 60,labsize(medlarge))	///
			ylabel(0 20000 "20,000" 45000 "45,000" 70000 "70,000" ,labsize(medlarge)) yscale(r(10000,75000)) ///
			xtitle("Age (years)", margin(medium) size(medlarge)) ///
			ytitle("Annual labor earnings (euros)", margin(medium) size(medlarge)) /// title("Percentile p10, p25, p50, p75, p90") ///	
			legend(order(1 "Observed" 2 "Predicted")) ///
			legend(region(lcolor(white))) legend(size(small) cols(5)) ///
			aspectratio(.8)
	graph export "${FIGURES}Figure_4b_EarnQuantProf.pdf", as(pdf) replace		

		
				
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 09. Rank correlations between annual labor earnings in different years
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%				
		
	mat define rankpool = J(2,5,.)	
	
	* ---------------------------------------------------------------------	
	/* ----- Estimation sample: observed outcomes ----- */	
		use "${DATA_CONFID}esample_plus.dta", clear
		
		xtset ID Age
		sort ID Age
				
		drop if Age>=60
		*ge N=_N 
		*bys Age: gen Na=_N
		*ge Fa=Na/N
		*ge fa=1/Fa
			
		egen rank = rank(WAGE)		
		
		forval x = 1/5 {
			gen lag`x'WAGE = l`x'.WAGE	
			egen lag`x'rank = rank(lag`x'WAGE)	
			pwcorr lag`x'rank rank	
			mat rankpool[1,`x'] = r(rho)
		}
			
		
		
	* ---------------------------------------------------------------------	
	/* ----- Simulated (matched) sample: predicted outcomes ----- */		
		use "${SIMDATA}data_baseline_ob1.dta", clear
		
		xtset ID Age
		sort ID Age

		egen rank = rank(WAGE2)		
		
		forval x = 1/5 {
			gen lag`x'WAGE = l`x'.WAGE2	
			egen lag`x'rank = rank(lag`x'WAGE)	
			pwcorr lag`x'rank rank	
			mat rankpool[2,`x'] = r(rho)
		}		
			
		
		
	* ---------------------------------------------------------------------	
	/* ----- Table 4: Rank correlations b/w annual labor earnings ----- */			
		mat list rankpool	
		
		putexcel set "${TABLES}CollectedResults.xlsx", modify sheet("Tab_4_RankCorr")
		
		putexcel D7 = matrix(rankpool)
		
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 09. Validation: Gini Coefficients for annual and lifetime labor earnings
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	clear
	clear matrix
	
* ---------------------------------------------------------------------	
/* ----- Simulated (matched) sample: predicted outcomes ----- */		
	use "${SIMDATA}data_baseline.dta", clear	
		drop if Age>=60
		
/* ----- Annual labor earnings inequality ----- */		
	ineqdec0 WAGE
		mat sim_gini_annual = r(gini)
		
/* ----- Lifetime labor earnings inequality ----- */		
	bys ID: egen LTEarnings = sum(WAGE)
	
	ineqdec0 LTEarnings
		mat sim_gini_lt = r(gini)
		

* -----------------------------------------------------------------------------	
/* ----- Estimation sample: re-weighted to replicate uniform age-distr. ----- */			
	use "${DATA_CONFID}esample_plus.dta", clear	
		drop if Age>=60
	
	ge N=_N
	bys Age: gen Na=_N
	ge Fa=Na/N
	ge fa=1/Fa
	
	ineqdec0 WAGE [fweight=floor(100*fa)]		
		mat soep_gini_annual = r(gini)
	
	
* -----------------------------------------------------------------------------	
/* ----- Table 5: Gini coefficients for annual and lifetime labor earnings ----- */	
	putexcel set "${TABLES}CollectedResults.xlsx", modify sheet("Tab_5_Valid")
	
	putexcel D6 = matrix(sim_gini_annual)	
	putexcel D8 = matrix(sim_gini_lt)
	putexcel H6 = matrix(soep_gini_annual)
	
	

	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 10. Transitions between employment states
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

	clear

*******************************************************************************
* 10a. E -> UE: Model fit of involuntary and voluntary transitions
*******************************************************************************	

/* ----- prepare InvolSep simulation data ----- */	
	* >>> generate lagged-employment indicator (to derive transitions later)
	use "${SIMDATA}data_involsep.dta", clear
		*br ID Age Empl Reti
		sort ID Age
		cap drop Empl_lag
		by ID: gen Empl_lag = l.Empl	
	save "${SIMDATA}data_involsep.dta", replace
	
	
/* ----- generate: matched dataset for InvolSep simulation data ----- */	
	* >>> select IDs based on baseline simualation match
	use "${DATA_CONFID}data_ObsSimComb_ob1.dta", clear
	
		keep ID Age EDUC Ob o* dupl_ID match_id

	merge 1:1 ID Age using "${SIMDATA}data_involsep.dta", gen(involdta_merge) keep(3)

	xtset ID Age
	
	keep ID Age EDUC Ob Reti Empl Empl_lag SepShock Health o_ID o_Reti o_Empl o_Empl_lag o_Jobsep o_Health


/* ----- generate employment -> unemployment transition indicator ----- */	
	
	* -----------------------------
	* >>> observed sample
	sort o_ID Age
	by o_ID: gen byte o_E2UE = o_Empl==0 & o_Empl_lag==1 & Ob==1	// & o_Reti==0 
		label var o_E2UE "Observed sample: transition into UE"
	* > full sample
	tab o_E2UE o_Jobsep if Ob==1, mis row
		assert o_Reti==1 if o_E2UE==0 & o_Jobsep==1
		* > involuntary transitions out of Employment leading to Retirement
		tab o_Reti if o_Jobsep==1 & o_E2UE==0, mis

	sum o_Jobsep if o_E2UE==1 & Ob==1 
		mat JobSep_all_obs = r(mean)
		
	* -----------------------------
	* >>> simulated sample
	sort ID Age
	by ID: gen byte E2UE = Empl==0 & Empl_lag==1 & Reti==0
	tab E2UE, mis
	* > full sample
	tab E2UE SepShock, mis row
		* > SepShock might occur at retirement entry
		*list ID if SepShock==1 & E2UE ==0
		assert Reti==1 if E2UE==0 & SepShock==1

	sum SepShock if E2UE==1
		mat JobSep_all_sim = r(mean)
	
/* ----- view transition rates by education and age (separately) ----- */	
	* >>> by education:	
		*tab o_E2UE o_Jobsep if Ob==1 & EDUC<=11, mis row
		*tab E2UE SepShock if EDUC<=11, mis row
		*tab o_E2UE o_Jobsep if Ob==1 & EDUC>=12, mis row
		*tab E2UE SepShock if EDUC>=12, mis row	
		
		sum o_Jobsep if o_E2UE==1 & Ob==1 & EDUC<=11
			mat JobSep_led_obs = r(mean)
		sum SepShock if E2UE==1 & EDUC<=11	
			mat JobSep_led_sim = r(mean)
		sum o_Jobsep if o_E2UE==1 & Ob==1 & EDUC>=12
			mat JobSep_hed_obs = r(mean)
		sum SepShock if E2UE==1 & EDUC>=12	
			mat JobSep_hed_sim = r(mean)		
	
			
	* >>> by age	
		tab o_E2UE o_Jobsep if Ob==1 & inrange(Age,20,49), mis row
		tab E2UE SepShock if  inrange(Age,20,49), mis row

		* > summarizing the three age groups >50 
		tab o_E2UE o_Jobsep if Ob==1 & inrange(Age,50,54), mis row
		tab E2UE SepShock if inrange(Age,50,54), mis row
		
		tab o_E2UE o_Jobsep if Ob==1 & inrange(Age,55,59), mis row
		tab E2UE SepShock if  inrange(Age,55,59), mis row
		
		tab o_E2UE o_Jobsep if Ob==1 & inrange(Age,60,64), mis row
		tab E2UE SepShock if inrange(Age,60,64), mis row	

		* > output
		sum o_Jobsep if o_E2UE==1 & Ob==1 & inrange(Age,20,49)
			mat JobSep_age1_obs = r(mean)
		sum SepShock if E2UE==1 & inrange(Age,20,49)
			mat JobSep_age1_sim = r(mean)
		sum o_Jobsep if o_E2UE==1 & Ob==1 & inrange(Age,50,54)
			mat JobSep_age2_obs = r(mean)
		sum SepShock if E2UE==1 & inrange(Age,50,54)
			mat JobSep_age2_sim = r(mean)
		sum o_Jobsep if o_E2UE==1 & Ob==1 & inrange(Age,55,59)
			mat JobSep_age3_obs = r(mean)
		sum SepShock if E2UE==1 & inrange(Age,55,59)
			mat JobSep_age3_sim = r(mean)
		sum o_Jobsep if o_E2UE==1 & Ob==1 & inrange(Age,60,64)
			mat JobSep_age4_obs = r(mean)
		sum SepShock if E2UE==1 & inrange(Age,60,64)
			mat JobSep_age4_sim = r(mean)			
	
	
*******************************************************************************
* 10b. Export to CollectedResults - Table SWA.6
*******************************************************************************	

/* ----- Table SWA.6: Involuntary job separations ----- */	
	putexcel set "${TABLES}CollectedResults.xlsx", modify sheet("Tab_SWA6_Invol")
	
	putexcel B5 = matrix(JobSep_all_obs*100)
	putexcel B6 = matrix(JobSep_all_sim*100)
	
	putexcel C5 = matrix(JobSep_hed_obs*100)
	putexcel C6 = matrix(JobSep_hed_sim*100)
	putexcel D5 = matrix(JobSep_led_obs*100)
	putexcel D6 = matrix(JobSep_led_sim*100)	
	
	putexcel E5 = matrix(JobSep_age1_obs*100)
	putexcel E6 = matrix(JobSep_age1_sim*100)
	putexcel F5 = matrix(JobSep_age2_obs*100)
	putexcel F6 = matrix(JobSep_age2_sim*100)
	putexcel G5 = matrix(JobSep_age3_obs*100)
	putexcel G6 = matrix(JobSep_age3_sim*100)
	putexcel H5 = matrix(JobSep_age4_obs*100)
	putexcel H6 = matrix(JobSep_age4_sim*100)



* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 11. DISTRIBUTION OF WEALTH - Figure SWA.6
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

	use "${DATA_CONFID}data_ObsSimComb_ob1.dta", clear

	keep o_ID ID Age Ob o_Wealth* Wealth

	replace Wealth = -20000 if Wealth<-20000
	
	foreach var in Wealth o_Wealth o_Wealth_SOEP07 {
		gen `var'_cens = max(`var',0) if !mi(`var')
	}
	
	
	twoway hist o_Wealth_SOEP07_cens if o_Wealth_SOEP07_cens<200000, percent w(20000) lcolor(gs0) fcolor(gs12)  aspectratio(0.8) ///
		ylabel(0 10 20 30 40 50 60,labsize(medlarge)) ///
		xlabel(0 "0" 50000 "50,000" 100000 "100,000" 150000 "150,000" 200000 "200,000",labsize(medlarge)) ///
		xtitle(Wealth (euros), margin(medium) size(medlarge)) ytitle("Share in percent", margin(medium) size(medlarge)) ///
		plotregion(style(none)) bgcolor(white) 	///
		graphregion(color(white)) 	//				
	graph export "${FIGURES}Figure_SWA6a_ObsWealth.pdf", as(pdf) replace	
		
		
	twoway hist Wealth_cens if Wealth_cens<200000, percent w(20000) fcolor(gs12) lcolor(gs0) aspectratio(0.8) ///
		 /// title("Simulated Wealth Distribution", size(small))
		ylabel(0 10 20 30 40 50 60,labsize(medlarge)) ///
		xlabel(0 "0" 50000 "50,000" 100000 "100,000" 150000 "150,000" 200000 "200,000",labsize(medlarge)) ///
		xtitle(Wealth (euros), size(medlarge) margin(medium)) ytitle("Share in percent", margin(medium) size(medlarge)) ///
		plotregion(style(none)) bgcolor(white) 	///
		graphregion(color(white)) 	//
		*name(hist_wealth_sim)	
	graph export "${FIGURES}Figure_SWA6b_SimWealth.pdf", as(pdf) replace	
	