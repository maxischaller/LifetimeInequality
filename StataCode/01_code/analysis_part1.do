** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SIMULATION ANALYSIS -- PART 1
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- This scripts runs the main inequality decomposition analysis and derives 
		the program contributions to the redistributive and insurance effects 
		of the tax-transfer system in all simulated scenarios.
	- Results are presented in Chapter 5, 7, and the Web Appendix.


Generated Tables and Figures:	
	- Chapter 5: Table 6 and Table 7
	- Appendix: Robustness checks to Table 6 and 7
		-> written to CollectedResults.xlsx
	
	- Add. Results to Chapter 5: "Chapter5_AddResults" in CollectedResults.xlsx

	- "Figure_5a_InsTax_TaxShare.pdf": 		Share of lifetime earnings paid in tax (by skill-group)
	- "Figure_5b_InsTax_YearsWorked.pdf": 	Years worked during lifetime (by skill-group)
	- "Figure_5_InsTax_Legend.pdf": 		Legend to Figure 5
	
	- "Figure_SWA8a_InsTax_AvgEarnPerYear.pdf": 		Avg. Annual Earnings per year of work (incl. shock)
	- "Figure_SWA8b_InsTax_SDAvgEarn.pdf": 				Standard Dev. of annual earnings in work (incl. shock)
	- "Figure_SWA9a_InsTax_AvgEarnPerYear_NoWS.pdf": 	Avg. Annual Earnings per year of work (no wage shock)
	- "Figure_SWA9b_InsTax_SDAvgEarn_NoWS.pdf": 		Standard Dev. of annual earnings in work (no wage shock)
	
	- "Figure_6a_RedTax_TaxShare.pdf": 		Share of lifetime earnings paid in taxes
	- "Figure_6b_RedTax_Empl.pdf": 			Years worked during lifetime
	- "Figure_6c_RedTax_AvgEarn.pdf": 		Average earnings per year
	- "Figure_6d_RedTax_SDAnnualEarn.pdf": 	Average earning per year - standard deviation
	- "Figure_7a_DBsHealth.pdf": 			Rate of disability eligibility
	- "Figure_7b_DBsReceipt.pdf": 			Rate of disability benefit receipt
	- "Figure_8a_SAIns_IncGap.pdf":   		Social assistance as insurance - income gap
	- "Figure_8b_SAIns_Wealth.pdf":  		Social assistance as insurance - wealth effect
	- "Figure_9a_SARed_IncGap.pdf":  		Social assistance as redistribution - income gap
	- "Figure_9b_SARed_Wealth.pdf": 		Social assistance as redistribution - wealth effect
	
*/

	
	clear all


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 00. LOAD PROGRAM ORDER PERMUTATION MATRX
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
*** Notes:
* 	- generates permutation matrix used to derive order-robust program contributions
*	 to redistributive and insurance effects of tax-transfer system (cp. Shorrocks, 2013)
	
	set matsize 1000
	use "${SIMDATA}perms.dta", clear
	mkmat var1-var4,matrix(P)
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. INEQUALITY DECOMPOSITION AND PROGRAM CONTRIBUTIONS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
*** Notes:
* 	- decomposition is derived for main inequality measure (Theil-Index) and robustness
*	  measures (mean log-deviation, squared coefficient of variation, variance of log)


/* ----- Main inequality measures ----- */	
	clear
	
	foreach x in Base A B C D E  {
		
		* > Inequality measures: ge(0): mean-log-deviation; ge(1): Theil; ge(2): squared coef. of variation
		forval A = 0/2 {
			local dataset = "`x'"
			local measure = "`A'"
			do "${CODE}analysis_part1_decomp.do" `dataset' `measure'
			
		}		
	}


/* ----- Add. measure: variance of log-earnings/income ----- */		
	clear
	
	foreach x in Base A B C D E {
		local dataset = "`x'"
		do "${CODE}analysis_part1_decomp_varinc.do" `dataset'	
	}

	
/* ----- Robustness Check: No interest income ----- */		
	clear	
	local dataset = "Base_NoInt"
	local measure = "1"
	do "${CODE}analysis_part1_decomp.do" `dataset' `measure'
	
	
/* ----- Robustness Check: Calibration of Preference Parameters ----- */		
	clear
	
	foreach x in Base_b98g50 Base_b97g50 Base_b99g25 Base_b99g75 Base_b98g25 Base_b98g75 Base_b97g25 Base_b97g75 {
		local dataset = "`x'"
		local measure = "1"
		do "${CODE}analysis_part1_decomp.do" `dataset' `measure'	
	}	
	
	
/* ----- Robustness Check: positive lifetime earnings ----- */		
	clear	
	local dataset = "Base_PosLTEarn"
	local measure = "1"
	do "${CODE}analysis_part1_decomp.do" `dataset' `measure'	
	
	
/* ----- Check: zero or negative lifetime earnings ----- */		
	* >>> see Footnote 20
	
	use "${SIMDATA}BASE.dta", clear
	sum WAGEInterest_LT if Age==20
	sum TranAugDispPersonalIncome_LT if Age==20	
	
	preserve
		keep if Age==20
		keep if WAGEInterest_LT<=0
		
		sum ID
			mat nmbr_obs_zeroearn = r(N)
	restore
	
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Chapter5_AddResults") modify
	putexcel I4 = matrix(nmbr_obs_zeroearn)
	
	
	
/* ----- Effect of tax-and-transfer system on inequality of annual income ----- */	
	* >>> see Footnote 23	
	
	use "${SIMDATA}BASE.dta", clear
	mat define gini=J(2,1,.)
	
	ineqdec0 WAGEInterest              
		mat gini[1,1]=r(gini)
	ineqdec0 TranAugDispPersonalIncome
		mat gini[2,1]=r(gini)
	
	mat list gini
	
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_6_7_MainDecomp") modify
	putexcel K6=matrix(gini)
	
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. INSURANCE AND REDISTRIBUTIVE EFFECTS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

********************************************************************************
* 02a. Insurance effects of taxation - Figure 5
********************************************************************************

/* ----- import estimated parameters ----- */	
	import delimited "${MATLABOUTPUT}paramhat.txt" , clear	
	mkmat v1, matrix(estim_params)	

/* ----- data preparation 1 ----- */
	use "${SIMDATA}Base.dta", clear

	ge atr_LT=-tax_LT/WAGEInterest_LT
	drop if WAGEInterest_LT>3000000
	drop if WAGEInterest_LT<0

	bys ID: egen memp=mean(Empl)
	bys ID: egen semp=sum(Empl)	// years worked during lifetime

	ge ew=WAGE if WAGE>0
	bys ID: egen mew=mean(ew)	
	bys ID: egen sew=sd(ew)
	
	
	gen eta1 = estim_params[1,1]		// type-1
	gen eta2 = estim_params[2,1]		// type-2
	gen eta3 = estim_params[3,1]		// type-3
	gen delta = estim_params[4,1]		// autocorrelation
	gen sig_v = estim_params[11,1]		// s.d. transitory wage shock
	
	gen psi1 = estim_params[5,1] 		// years of education
	gen psi2 = estim_params[6,1]		// low-educ exp
	gen psi3 = estim_params[7,1]		// high-educ exp
	gen psi4 = estim_params[8,1]		// low-educ exp^2
	gen psi5 = estim_params[9,1]		// high-educ exp^2
	gen psi6 = estim_params[10,1]		// health	
	
	
/* ----- data preparation 2 ----- */		
	gen LoEduc=1 if EDUC<12
		replace LoEduc=0 if LoEduc==.
	gen HiEduc=1-LoEduc

	gen Exper2=Exper^2

	gen pwage1=exp(eta1+psi1*EDUC/10+psi2*(Exper/10)*LoEduc+psi3*(Exper/10)*HiEduc+psi4*(Exper2/1000)*LoEduc+psi5*(Exper2/1000)*HiEduc+psi6*Health+(((sig_v^2)/(1-(delta^2))/2)))
	gen awage1=pwage1*40*52
	
	gen pwage2=exp(eta2+psi1*EDUC/10+psi2*(Exper/10)*LoEduc+psi3*(Exper/10)*HiEduc+psi4*(Exper2/1000)*LoEduc+psi5*(Exper2/1000)*HiEduc+psi6*Health+(((sig_v^2)/(1-(delta^2))/2)))
	gen awage2=pwage2*40*52
		
	gen pwage3=exp(eta3+psi1*EDUC/10+psi2*(Exper/10)*LoEduc+psi3*(Exper/10)*HiEduc+psi4*(Exper2/1000)*LoEduc+psi5*(Exper2/1000)*HiEduc+psi6*Health+(((sig_v^2)/(1-(delta^2))/2)))
	gen awage3=pwage3*40*52
	
	gen Pwage=awage1 if TYPE==1
		replace Pwage=awage2 if TYPE==2
		replace Pwage=awage3 if TYPE==3

	ge ewp=Pwage if Empl==1
	bys ID: egen mewp=mean(ewp)
	bys ID: egen sewp=sd(ewp)		
		
	
/* ----- Figure 5a: Share of lifetime earnings paid in tax (by skill-group) ----- */

	twoway (lpoly atr_LT WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly atr_LT WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(150000) lwidth(thick)  lcolor(black) msymbol(i))/*
		*/ (lpoly atr_LT WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(150000) lwidth(thick)  lcolor(black) msymbol(i))/*
		*/ (lpoly atr_LT WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(150000) lwidth(thick)  lcolor(black) msymbol(i))/*
		*/ (lpoly atr_LT WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(150000) lwidth(thick)  lcolor(black) msymbol(i))/*
		*/ (lpoly atr_LT WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(150000) lwidth(thick)  lcolor(black) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 .1 0.2 .3 0.4,labsize(large)) /*
		*/ legend(col(2) lab(1 "Low educ & high ability")  lab(2 "Low educ & medium ability") lab(3 "Low educ & low ability") lab(4 "High educ & high ability") lab(5 "High educ & medium ability") lab(6 "High educ & low ability"))/*
		*/ xtitle("Lifetime earnings (euros)"" ", margin(medium) size(large))  ytitle("Share of lifetime earnings" "paid in tax", margin(medium) size(large )) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,.33))/*
		*/ legend(region(lcolor(white))) legend(size(small) symysize(.1) symxsize(7) off)/*
		*/ aspectratio(.6)
	graph export "${FIGURES}Figure_5a_InsTax_TaxShare.pdf", as(pdf) replace

	
	
/* ----- Figure 5b: Lifetime years worked (by skill-group) ----- */		
	twoway (lpoly semp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly semp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly semp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly semp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly semp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly semp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 "0" 10 "10" 20 "20" 30 "30" 40 "40",labsize(large)) /*
		*/ legend(col(2) lab(1 "Low educ & high ability")  lab(2 "Low educ & medium ability") lab(3 "Low educ & low ability") lab(4 "High educ & high ability") lab(5 "High educ & medium ability") lab(6 "High educ & low ability"))/*
		*/ xtitle("Lifetime earnings (euros)" " ", margin(medium) size(large))  ytitle("Years worked during lifetime", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,40))/*
		*/ legend(region(lcolor(white))) legend(size(small) symysize(.1) symxsize(7) off)/*
		*/ aspectratio(.6)
	graph export "${FIGURES}Figure_5b_InsTax_YearsWorked.pdf", as(pdf) replace		
		
		
		
/* ----- Figure 5x: Generate a suitable Legend for Figure 5 ----- */
	twoway (lpoly mew WAGE_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly mew WAGE_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGE_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGE_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGE_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGE_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 "0" 25000 "25,000" 50000 "50,000",labsize(large)) /*
		*/ legend(col(1) lab(1 "Low education and high productive ability")  lab(2 "Low education and medium productive ability") lab(3 "Low education and low productive ability") lab(4 "High education and high productive ability") lab(5 "High education and medium productive ability") lab(6 "High education and low productive ability"))/*
		*/ xtitle("Lifetime labor earnings (euros)", margin(medium) size(large))  ytitle(off) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000",labsize(large))/*
		*/ xscale(range(0,2200000))/*
		*/ legend(region(lcolor(white))) legend(size(large))/*
		*/ aspectratio(.1)
	graph export "${FIGURES}Figure_5_InsTax_Legend.pdf", as(pdf) replace		
		
		
		
/* ----- Additional Results ----- */
*** Notes:
*	> export numbers reported in text of Chapter 5.1.1
	
	preserve
		keep if Age==20 & EDUC==11 & TYPE==1
				
		lpoly atr_LT WAGEInterest_LT, gen(lowed_type1) at(WAGEInterest_LT) nograph
		
		sum lowed_type1 if inrange(WAGEInterest_LT,495000,505000)
			mat val1 = r(mean)
		sum lowed_type1 if inrange(WAGEInterest_LT,2495000,2505000) 
			mat val2 = r(mean)
	restore

	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Chapter5_AddResults") modify

	putexcel B5 = matrix(100*val1)
	putexcel C5 = matrix(100*val2)


********************************************************************************
* 02b. Insurance effects of taxation - Additional results - Figure SWA.8 & SWA.9
********************************************************************************
	
/* ----- Figure SWA.8a: Avg. Annual Earnings per year of work (incl. shock) ----- */	
	twoway (lpoly mew WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly mew WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mew WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 40000 "40,000" 80000 "80,000",labsize(large)) /*
		*/ legend(col(2) lab(1 "Low educ & high ability")  lab(2 "Low educ & medium ability") lab(3 "Low educ & low ability") lab(4 "High educ & high ability") lab(5 "High educ & medium ability") lab(6 "High educ & low ability"))/*
		*/ xtitle("Lifetime earnings (euros)", margin(medium) size(large))  ytitle("Average earnings" "per year of work (euros)", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,82000))/*
		*/ legend(region(lcolor(white))) legend(size(small) symysize(.1) symxsize(7) off)/*
		*/ aspectratio(.6)
		graph export "${FIGURES}Figure_SWA8a_InsTax_AvgEarnPerYear.pdf", as(pdf) replace	
		
/* ----- Figure SWA.8b: Standard Dev. of annual earnings in work (incl. shock) ----- */			
	twoway (lpoly sew WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly sew WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sew WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sew WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sew WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sew WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 8000 "8,000" 15000 "15,000",labsize(large)) /*
		*/ legend(col(2) lab(1 "Low educ & high ability")  lab(2 "Low educ & medium ability") lab(3 "Low educ & low ability") lab(4 "High educ & high ability") lab(5 "High educ & medium ability") lab(6 "High educ & low ability"))/*
		*/ xtitle("Lifetime earnings (euros)" " ", margin(medium) size(large))  ytitle("Standard deviation of annual" "earnings when working (euros)", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ yscale(range(0,16000))/*
		*/ xscale(range(0,3100000))/*
		*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
		*/ aspectratio(.6)
		graph export "${FIGURES}Figure_SWA8b_InsTax_SDAvgEarn.pdf", as(pdf) replace		
		

		
/* ----- Figure SWA.9a: Avg. Annual Earnings per year of work (excl. shock) ----- */
	twoway (lpoly mewp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly mewp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mewp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mewp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mewp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly mewp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 40000 "40,000" 80000 "80,000",labsize(large)) /*
		*/ legend(col(2) lab(1 "Low educ & high ability")  lab(2 "Low educ & medium ability") lab(3 "Low educ & low ability") lab(4 "High educ & high ability") lab(5 "High educ & medium ability") lab(6 "High educ & low ability"))/*
		*/ xtitle("Lifetime earnings (euros)", margin(medium) size(large))  ytitle("Average earnings" "per year of work (euros)" "(excluding wage shocks)", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,82000))/*
		*/ legend(region(lcolor(white))) legend(size(small) symysize(.1) symxsize(7) off)/*
		*/ aspectratio(.6)
		graph export "${FIGURES}Figure_SWA9a_InsTax_AvgEarnPerYear_NoWS.pdf", as(pdf) replace
		

/* ----- Figure SWA.9b: Standard Dev. of annual earnings in work (excl. shock) ----- */		
	twoway (lpoly sewp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==1, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly sewp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==2, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sewp WAGEInterest_LT if Age==20  & EDUC==11 & TYPE==3, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sewp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==1, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sewp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==2, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i))/*
		*/ (lpoly sewp WAGEInterest_LT if Age==20  & EDUC==14 & TYPE==3, sort bw(250000) lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 8000 "8,000" 15000 "15,000",labsize(large)) /*
		*/ legend(col(2) lab(1 "Low educ & high ability")  lab(2 "Low educ & medium ability") lab(3 "Low educ & low ability") lab(4 "High educ & high ability") lab(5 "High educ & medium ability") lab(6 "High educ & low ability"))/*
		*/ xtitle("Lifetime earnings (euros)" " ", margin(medium) size(large))  ytitle("Standard deviation of annual" "earnings when working (euros)" "(excluding wage shocks)", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ yscale(range(0,16000))/*
		*/ xscale(range(0,3100000))/*
		*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
		*/ aspectratio(.6)
		graph export "${FIGURES}Figure_SWA9b_InsTax_SDAvgEarn_NoWS.pdf", as(pdf) replace
			
	
	
********************************************************************************
* 02d. Inequality in Lifetime earnings due to differences in years worked
********************************************************************************	
	
/* ----- data preparation ----- */	
	use "${SIMDATA}BASE.dta", clear

	keep ID Age ty WAGEInterest_LT WAGE Empl InvestmentInc
	
	ineqdeco WAGEInterest_LT if Age==20, by(ty) 
		mat define theil_wg=r(within_ge1)
		mat define theil_bg=r(between_ge1)

	* >>> Lifetime earnings with same years worked for each person in skill group
	bys ID: egen yemp=sum(Empl)
	gen iwage=WAGE if WAGE>0
	bys ID: egen mwage=mean(iwage)
	bys ty: egen ty_emp=mean(yemp)
	egen memp=mean(yemp)
	bys ID: egen InvestmentInc_LT=sum(InvestmentInc)
	ge ltyW=ty_emp*mwage+InvestmentInc_LT
	ge ltyB=memp*mwage+InvestmentInc_LT
	
 
/* ----- inequality decomposition ----- */	 
	ineqdeco ltyW if Age==20, by(ty) 
		mat define theil_wg_SameEmp=r(within_ge1)

	ineqdeco ltyB if Age==20, by(ty)
		mat define theil_bg_SameEmp=r(between_ge1)

	mat define ShareWGEmp=(theil_wg[1,1]-theil_wg_SameEmp[1,1])/theil_wg[1,1]
		mat li ShareWGEmp

	mat define ShareBGEmp=(theil_bg[1,1]-theil_bg_SameEmp[1,1])/theil_bg[1,1]
		mat li ShareBGEmp	
	
	
/* ----- export results ----- */		
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Chapter5_AddResults") modify

	putexcel C10 = matrix(100*ShareWGEmp)	
	putexcel C11 = matrix(100*ShareBGEmp)
	
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 03. REDISTRIBUTIVE EFFECTS OF TAXATION - Figure 6
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
/* ----- data preparation ----- */	
	use "${SIMDATA}BASE.dta", clear

	keep ID Age TYPE EDUC ty WAGEInterest_LT tax_LT Empl WAGE GCI
	
	* skill group level average lifetime labor earnings
	bys ty: egen mEWAGE_LT=mean(WAGEInterest_LT)

	* skill group level average tax on labor earnings
	bys ty: egen mEITAX_LT=mean(-tax_LT/WAGEInterest_LT)

	* skill group level years worked in lifetime
	bys ID: egen semp=sum(Empl)
	bys ty: egen swemp = mean(semp)

	* skill group average annual labor earnings
	ge we=WAGE if WAGE>0
	bys ty: egen mwe=mean(we)
	bys ty: egen swe=sd(we)	
	
	
/* ----- Figure 6a: Share of lifetime earnings paid in taxes ----- */
	preserve 
		keep if Age==20
				
		twoway (lpoly  mEITAX_LT mEWAGE_LT, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 0.1 0.2 0.3 0.4,labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Share of lifetime earnings" "paid in tax", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,.33))/*
			*/ legend(region(lcolor(white))) legend(size(small) symysize(.1) symxsize(7) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_6a_RedTax_TaxShare.pdf", as(pdf) replace	
	restore
	
	
/* ----- Figure 6b: Years worked during lifetime ----- */
	* > between-skill-group employment differences by lifetime earnings
	preserve 
		keep if Age==20

		tab ty swemp
		tab swemp
	
		twoway (lpoly  swemp mEWAGE_LT, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 "0" 10 "10" 20 "20" 30 "30" 40 "40",labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Years worked during lifetime", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,41))/*
			*/ legend(region(lcolor(white))) legend(size(small) symysize(.1) symxsize(7) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_6b_RedTax_Empl.pdf", as(pdf) replace				
	restore
	
	
/* ----- Figure 6c: Average earnings per year ----- */	
	preserve
		keep if Age==20
	
		twoway (lpoly  mwe mEWAGE_LT, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 40000 "40,000" 80000 "80,000",labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Average earnings" "of workers (euros)", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,82000))/*
			*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_6c_RedTax_AvgEarn.pdf", as(pdf) replace	
	restore
	
	
/* ----- Figure 6d: Average earnings per year - standard deviation ----- */
	preserve
		keep if Age==20

		twoway (lpoly  swe mEWAGE_LT, sort bw(150000) lcolor(black) lwidth(thick) msymbol(i)),/* 
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 8000 "8,000" 15000 "15,000",labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Standard deviation of annual" "earnings of workers (euros)", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,16000))/*
			*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_6d_RedTax_SDAnnualEarn.pdf", as(pdf) replace	
	restore	


/* ----- Add. results: tax share for lowest/highest earning skill group ----- */	
	preserve 
		duplicates drop ty, force
		sum mEWAGE_LT
			local maxearn = r(max)
			local minearn = r(min)
		disp `maxearn' `minearn'
		
		* > highest earning skill group
		list ty if mEWAGE_LT==`maxearn'
		sum TYPE if mEWAGE_LT==`maxearn'
			mat maxearn_type = r(mean)
		sum EDUC if mEWAGE_LT==`maxearn'
			mat maxearn_educ = r(mean)	
		sum mEITAX_LT if mEWAGE_LT==`maxearn'
			mat maxearn_tax = r(mean)

		* > lowest earning skill group
		list ty if mEWAGE_LT==`minearn'
		sum TYPE if mEWAGE_LT==`minearn'
			mat minearn_type = r(mean)
		sum EDUC if mEWAGE_LT==`minearn'
			mat minearn_educ = r(mean)				
		sum mEITAX_LT if mEWAGE_LT==`minearn'		
			mat minearn_tax = r(mean)
		
		* > export
		putexcel set "${TABLES}CollectedResults.xlsx", sheet("Chapter5_AddResults") modify
			putexcel B17 = matrix(minearn_type)
			putexcel C17 = matrix(minearn_educ)
			putexcel E17 = matrix(100*minearn_tax)
			putexcel B18 = matrix(maxearn_type)
			putexcel C18 = matrix(maxearn_educ)
			putexcel E18 = matrix(100*maxearn_tax)	
		
	restore
		


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 04. REDISTRIBUTIVE EFFECTS OF DISABILITY BENEFITS - Figure 7
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

/* ----- data preparation ----- */
	* >>> skill-group level average disability benefits

	use "${SIMDATA}BASE.dta", clear

	keep ID Age EDUC ty BadHealth inc5 inc5_LT WAGEInterest_LT NClaimDB
	
	bys ty: egen mDB_LT=mean(inc5_LT)
	bys ty: egen mEWAGEInterest_LT=mean(WAGEInterest_LT)
	gen msDB_LT=mDB_LT/mEWAGEInterest_LT
	bys ty: egen myearDB=mean(NClaimDB)
	gen s=mDB_LT/mEWAGEInterest_LT
	bys ty: egen m=mean(NClaimDB)
	gen iBadHealth=BadHealth if Age>=(EDUC+8)
	bys ty: egen mBadHealth=mean(iBadHealth)
	gen idb=1 if inc5>0 & Age>=(EDUC+8)
		replace idb=0 if idb!=1 & Age>=(EDUC+8)
	bys ty: egen midb=mean(idb)

	
/* ----- Figure 7a: Rate of disability eligibility ----- */
	preserve
		keep if Age==20
		
		twoway (lpoly mBadHealth mEWAGEInterest_LT, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)),/* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 0.05 0.1 0.15 0.2,labsize(large)) /*
		*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Rate of disability benefit eligibility", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,0.2))/*
		*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
		*/ aspectratio(.6)
		graph export "${FIGURES}Figure_7a_DBsHealth.pdf", as(pdf) replace
	restore	

	
/* ----- Figure 7b: Rate of disability benefit receipt ----- */	
	preserve
		keep if Age==20
		
		twoway (lpoly midb mEWAGEInterest_LT, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)),/* 
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 0.02 0.04 0.06 0.08,labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Rate of disability benefit receipt", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,.085))/*
			*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_7b_DBsReceipt.pdf", as(pdf) replace
	restore
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 05. REDISTRIBUTIVE EFFECTS OF UNEMPLOYMENT INSURANCE
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
* 	> Results for Chapter 5.1.3 What drives the redistributive effect of un-
*		employment insurance?

/* ----- data preparation ----- */	
	use "${SIMDATA}BASE.dta", clear
	
	bys ty: egen mdb=mean(NClaimUI)
	bys ty: egen mEWAGEInterest_LT=mean(WAGEInterest_LT)


/* ----- UI receipt by lifetime earnings ----- */		
	preserve
		duplicates drop ty, force		
			*scatter mdb mEWAGEInterest_LT
			*tab mEWAGEInterest_LT
	
		su mdb if mEWAGEInterest_LT<600000
			mat mdb_low = r(mean)
		su mdb if mEWAGEInterest_LT>2000000		
			mat mdb_high = r(mean)
	
		putexcel set "${TABLES}CollectedResults.xlsx", sheet("Chapter5_AddResults") modify
			putexcel C25 = matrix(mdb_low)
			putexcel C26 = matrix(mdb_high)	
	restore
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 05. REDISTRIBUTIVE & INSURANCE EFFECTS OF SOCIAL ASSISTANCE
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

/* ----- data preparation ----- */	
	use "${SIMDATA}BASE.dta", clear
	
	bys ty: egen msa=mean(NClaimsab)
	bys ty: egen mEWAGEInterest_LT=mean(WAGEInterest_LT)
	bys ty: egen s=mean(sab_LT/WAGEInterest_LT)
	gen diffearnings=(WAGEInterest_LT-mEWAGEInterest_LT)
	replace diffearnings=-500000 if diffearnings<-500000
	replace diffearnings=250000 if diffearnings>250000

	* Difference between income and SA income floor
	ge diff=max(8400-di,0)
	replace diff=. if Age<(EDUC+8)

	* Wealth test
	ge wt=10000+500*(Age-20)

	ge we=1 if Wealth<wt  & Age>=(EDUC+8) 			// 'passing wealth test - indicator'; we==1: passing wealth test (not yet cond. on income eligibility (see ii below))
	replace we=0 if we==. & Age>=(EDUC+8) & diff>0 	// sa-eligible based on income value, but failed wealth test (we==.)
		* > note: individuals may be income-eligible for SA, but fail the wealth test.

	gen ii=1 if diff>0 & diff!=.
		* > ii==1 indicates set of income-eligible individuals; eligibility cond. on wealth indicated by 'we'	
		* ii = {1,.}
		
	bys ty: egen mdiff=mean(diff)
	bys ty: egen mwe=mean(we) if ii==1 //cond. on income-eligibility

	
********************************************************************************
* 05a. Insurance effect of social assistance - Figure 8
********************************************************************************

	graph drop _all
	
/* ----- Figure 8a: Income gap ----- */		
	 
	twoway (lpoly diff WAGEInterest_LT if EDUC==11 & TYPE==1, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)) /* 
	*/     (lpoly diff WAGEInterest_LT if EDUC==11 & TYPE==2, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i))  /*
	*/     (lpoly diff WAGEInterest_LT if EDUC==11 & TYPE==3, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)) /* 
	*/     (lpoly diff WAGEInterest_LT if EDUC==14 & TYPE==1, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)) /*
	*/     (lpoly diff WAGEInterest_LT if EDUC==14 & TYPE==2, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i))  /*
	*/     (lpoly diff WAGEInterest_LT if EDUC==14 & TYPE==3, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)),/*
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 2500 "2,500" 5000 "5,000",labsize(large)) /*
		*/ xtitle("Lifetime earnings (euros)", margin(medium) size(large))  ytitle("Social assistance income gap" "(euros per year)", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,6000))/*
		*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
		*/ aspectratio(.6)
	graph export "${FIGURES}Figure_8a_SAIns_IncGap.pdf", as(pdf) replace

	
	
/* ----- Figure 8b: Wealth effect ----- */

	replace we=1-we	

	twoway (lpoly we WAGEInterest_LT if WAGEInterest_LT<3000000 & EDUC==11 & TYPE==1 & ii==1, bw(400000)  sort lcolor(black) lwidth(thick) msymbol(i)) /* 
		*/ (lpoly we WAGEInterest_LT if WAGEInterest_LT<3000000 & EDUC==11 & TYPE==2 & ii==1, bw(400000)  sort lcolor(black) lwidth(thick) msymbol(i)) /* 
		*/ (lpoly we WAGEInterest_LT if WAGEInterest_LT<3000000 & EDUC==11 & TYPE==3 & ii==1, bw(400000)  sort lcolor(black) lwidth(thick) msymbol(i)) /* 
		*/ (lpoly we WAGEInterest_LT if WAGEInterest_LT<3000000 & EDUC==14 & TYPE==1 & ii==1, bw(400000)  sort lcolor(black) lwidth(thick) msymbol(i)) /*
		*/ (lpoly we WAGEInterest_LT if WAGEInterest_LT<3000000 & EDUC==14 & TYPE==2 & ii==1, bw(400000)  sort lcolor(black) lwidth(thick) msymbol(i)) /* 
		*/ (lpoly we WAGEInterest_LT if WAGEInterest_LT<3000000 & EDUC==14 & TYPE==3 & ii==1, bw(400000)  sort lcolor(black) lwidth(thick) msymbol(i)), /* 
		*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
		*/ ylabel(0 0.1 0.2 0.3,labsize(large)) /* ylabel(0 0.05 0.1,labsize(large))
		*/ xtitle("Lifetime earnings (euros)", margin(medium) size(large))  ytitle("Fraction of income-eligible" "individuals who fail wealth test", margin(medium) size(large)) /*
		*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
		*/ xscale(range(0,3100000))/*
		*/ yscale(range(0,.06))/*
		*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
		*/ aspectratio(.6)
	graph export "${FIGURES}Figure_8b_SAIns_Wealth.pdf", as(pdf) replace



********************************************************************************
* 05b. Redistribution effect of social assistance - Figure 9
********************************************************************************

/* ----- Figure 9a: Income gap ----- */
	preserve 
		keep if Age==20
		tab mdiff 
	
		twoway (lpoly mdiff mEWAGEInterest_LT, bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)),/* 
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 750 "750" 1500 "1500",labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Social assistance income gap" "(euros per year)", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,1550))/* yscale(range(0,2500))
			*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_9a_SARed_IncGap.pdf", as(pdf) replace
			
	restore
	

/* ----- Figure 9b: Wealth effect ----- */
	preserve 

		bys ty: egen mwe_helper = mean(mwe)
		tab ty mwe
		tab ty mwe_helper
		
		keep if Age==20		
		
		replace mwe=1-mwe
		replace mwe_helper = 1-mwe_helper
		
		twoway (lpoly mwe_helper mEWAGEInterest_LT , bw(150000)  sort lcolor(black) lwidth(thick) msymbol(i)),/* if ii>0
			*/ scheme(s2mono) ylab(, nogrid) graphregion(color(white))/*
			*/ ylabel(0 0.07 0.14,labsize(large)) /*
			*/ xtitle("Skill-group-level average lifetime earnings (euros)" "(Expected lifetime earnings (euros))", margin(medium) size(large))  ytitle("Fraction of income-eligible" "individuals who fail wealth test", margin(medium) size(large)) /*
			*/ xlabel(0 "0" 1000000 "1,000,000"  2000000 "2,000,000" 2900000 "3,000,000",labsize(large))/*
			*/ xscale(range(0,3100000))/*
			*/ yscale(range(0,0.042))/*
			*/ legend(region(lcolor(white))) legend(size(vsmall) off)/*
			*/ aspectratio(.6)
		graph export "${FIGURES}Figure_9b_SARed_Wealth.pdf", as(pdf) replace
	restore	
	
	