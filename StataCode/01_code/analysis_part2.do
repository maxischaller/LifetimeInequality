** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SIMULATION ANALYSIS -- PART 2
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Analysis of counterfactual risk scenarios deriving behavioral implications
		and inequality decompositions of lifetime income and earnings
	- Results are presented in Chapter 6 and the Web Appendix
	
Generated Tables and Figures:	
	- Results written to Sheets of CollectedResults.xlsx, labeled `Part2_[]'.

	- "Figure_SWA10_PolTaxEmplRate.pdf"

*/

	clear all


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 00. LOAD PROGRAM ORDER PERMUTATION MATRX
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
*** NOTES:
* 	- generates permutation matrix used to derive order-robust program contributions
*	 to redistributive and insurance effects of tax-transfer system (cp. Shorrocks, 2013)
	
	set matsize 1000
	use "${SIMDATA}perms.dta", clear
	mkmat var1-var4,matrix(P)
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. MAIN INEQUALITY MEASURES: BEHAVIORAL IMPLICATIONS AND DECOMPOSITION
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		

	clear

/* ----- Loop over main inequality measures ----- */
	* > Inequality measures: ge(0): mean-log-deviation; ge(1): Theil; 
	*		ge(2): half the squared coef. of variation
	
	forval x = 0/2 {
			
		/* ----- Set output file ----- */
			putexcel set "${TABLES}CollectedResults.xlsx", sheet("Part2_ge`x'") modify
		
			
		************************************************************************
		* Behavioral implications
		************************************************************************
			
			mat define BehImpl = J(9,6,.)
			
			local r = 1
			
			/* ----- loop over scenarios ----- */
			foreach n in Base A B C D E {
				
				use "${SIMDATA}`n'.dta", clear
					assert Age<=59
				
				sum EDUC
					mat BehImpl[1,`r'] = r(mean)
				
				sum Empl
					mat BehImpl[3,`r'] = r(mean)
				sum TenterU if Age==20
					mat BehImpl[4,`r'] = r(mean)
				sum length if enterU==1 
					mat BehImpl[5,`r'] = r(mean)
				
				sum BadHealth 
					mat BehImpl[7,`r'] = r(mean)
				sum TenterH if Age==20
					mat BehImpl[8,`r'] = r(mean)
				sum lengthH if enterH==1
					mat BehImpl[9,`r'] = r(mean)
				
				local r = `r'+1
				
			}	
		putexcel B4 = matrix(BehImpl)
		
		
		************************************************************************
		* Inequality decomposition and program effects
		************************************************************************
		
			mat define IneqW=J(2,6,.)
			mat define IneqB=J(2,6,.)
		
			* preallocate for each permutation
			forvalues p=1/24{
				mat define MEw_`p'=J(4,6,.)
				mat define MEb_`p'=J(4,6,.)
			}	
		
		
			local r = 1
			
			/* ----- loop over scenarios ----- */
			foreach n in Base A B C D E {
				use "${SIMDATA}`n'.dta", clear
				keep if Age==20 // only consider lifetime measures
				
				* reassign values to match permuation matrix order
				replace inc1_LT=inc2_LT
				replace inc2_LT=inc3_LT
				replace inc3_LT=inc4_LT
				replace inc4_LT=inc5_LT

				* inequality metric
				local metric="ge`x'"
				
				ineqdeco inc0_LT, by(ty)
					mat sew=r(within_`metric')
					mat seb=r(between_`metric')
					mat IneqW[1,`r']=sew
					mat IneqB[1,`r']=seb
				ineqdeco TranAugDispPersonalIncome_LT, by(ty)
					mat snw=r(within_`metric')
					mat snb=r(between_`metric')
					mat IneqW[2,`r']=snw
					mat IneqB[2,`r']=snb
				
				keep inc* Age ID ty
				
				forvalues p=1/24 {
					disp `p'

					ge inc_LT=inc0_LT
					mat define sw=sew
					mat define sb=seb

						forvalues v=1/4 { 
							qui mat define pp=P[`p',`v']
							qui local pp=pp[1,1]
							qui replace inc_LT=inc_LT+inc`pp'_LT

							ineqdeco inc_LT, by(ty)
								mat MEw_`p'[`pp',`r']=r(within_`metric')-sw[1,1]
								mat MEb_`p'[`pp',`r']=r(between_`metric')-sb[1,1]
								mat define sw=r(within_`metric')
								mat define sb=r(between_`metric')
						}

					drop inc_LT									
				}	
				
				local r = `r'+1		
				
			} // end loop over scenarios
		
		* define output matrices
		mat define AvInw=MEw_1
		mat define AvInb=MEb_1
		forvalues p=2/24 {
			mat AvInw=((`p'-1)*AvInw+MEw_`p')/`p'
			mat AvInb=((`p'-1)*AvInb+MEb_`p')/`p'
		}
		
		* within
		mat IneqW=100*IneqW
		putexcel B19= matrix(IneqW)

		mat AvInw=100*AvInw
		putexcel B23= matrix(AvInw)

		* between
		mat IneqB=100*IneqB
		putexcel B45= matrix(IneqB)

		mat AvInb=100*AvInb
		putexcel B49= matrix(AvInb)		
	
	
	}
	

	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. ADDITIONAL INEQUALITY MEASURES: BEHAVIORAL IMPLICATIONS AND DECOMPOSITION
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	
	clear 
	
/* ----- Set output file ----- */
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Part2_VarInc") modify	


************************************************************************
* Behavioral implications
************************************************************************
	
	mat define BehImpl = J(9,6,.)
	
	local r = 1
	
/* ----- loop over scenarios ----- */
	foreach n in Base A B C {
		
		use "${SIMDATA}`n'.dta", clear
			assert Age<=59
		
		sum EDUC
			mat BehImpl[1,`r'] = r(mean)
		
		sum Empl
			mat BehImpl[3,`r'] = r(mean)
		sum TenterU if Age==20
			mat BehImpl[4,`r'] = r(mean)
		sum length if enterU==1 
			mat BehImpl[5,`r'] = r(mean)
		
		sum BadHealth 
			mat BehImpl[7,`r'] = r(mean)
		sum TenterH if Age==20
			mat BehImpl[8,`r'] = r(mean)
		sum lengthH if enterH==1
			mat BehImpl[9,`r'] = r(mean)
		
		local r = `r'+1
		
	}
	
	putexcel B4 = matrix(BehImpl)


************************************************************************
* Inequality decomposition and program effects
************************************************************************

	mat define IneqW=J(2,6,.)
	mat define IneqB=J(2,6,.)

	* preallocate for each permutation
	forvalues p=1/24{
		mat define MEw_`p'=J(4,6,.)
		mat define MEb_`p'=J(4,6,.)
	}	


	local r = 1
	
	/* ----- loop over scenarios ----- */
	foreach n in Base A B C {
		use "${SIMDATA}`n'.dta", clear
		keep if Age==20 // only consider lifetime measures
		
		* reassign values to match permuation matrix order
		replace inc1_LT=inc2_LT
		replace inc2_LT=inc3_LT
		replace inc3_LT=inc4_LT
		replace inc4_LT=inc5_LT
		
		gen lnEarn_LT = ln(WAGEInterest_LT)
		gen lnbaseInc_LT = ln(TranAugDispPersonalIncome_LT)			

		
		* lifetime earnings
		mixed lnEarn_LT || ty: 
			mat bw_earn = e(b)[1,2]
			mata : st_matrix("bw_earn", exp(st_matrix("bw_earn"))^2)
			mat li bw_earn
			
			mat within_earn = e(b)[1,3]
			mata : st_matrix("within_earn", exp(st_matrix("within_earn"))^2)
			mat li within_earn			
		
		mat sew = within_earn
		mat seb = bw_earn
			mat IneqW[1,`r']=sew
			mat IneqB[1,`r']=seb	
		
		* lifetime income
		mixed lnbaseInc_LT || ty:
			mat bw_inc = e(b)[1,2]
			mata : st_matrix("bw_inc", exp(st_matrix("bw_inc"))^2)
			mat li bw_inc
			
			mat within_inc = e(b)[1,3]
			mata : st_matrix("within_inc", exp(st_matrix("within_inc"))^2)
			mat li within_inc		
		
		mat snw = within_inc
		mat snb = bw_inc
			mat IneqW[2,`r']=snw
			mat IneqB[2,`r']=snb
		
		keep inc* Age ID ty 
		
		forvalues p=1/24{

			disp `p'

			ge inc_LT=inc0_LT

			mat define sw=sew
			mat define sb=seb
			
				forvalues v=1/4{ 

					qui mat define pp=P[`p',`v']
					qui local pp=pp[1,1]
					qui replace inc_LT=inc_LT+inc`pp'_LT
					
					gen lninc_LT = ln(inc_LT)
					
					mixed lninc_LT || ty:
						mat bw_inc = e(b)[1,2]
						mata : st_matrix("bw_inc", exp(st_matrix("bw_inc"))^2)
						mat li bw_inc
						
						mat within_inc = e(b)[1,3]
						mata : st_matrix("within_inc", exp(st_matrix("within_inc"))^2)
						mat li within_inc					
					
					mat MEw_`p'[`pp',`r']=within_inc-sw[1,1]
					mat MEb_`p'[`pp',`r']=bw_inc-sb[1,1]
					mat define sw=within_inc
					mat define sb=bw_inc
					
					drop lninc_LT
				}
			
			drop inc_LT
			
		}
		
		local r = `r'+1		
		
		
	} // end loop over scenarios

	
	* define output matrices
	mat define AvInw=MEw_1
	mat define AvInb=MEb_1
	forvalues p=2/24 {
		mat AvInw=((`p'-1)*AvInw+MEw_`p')/`p'
		mat AvInb=((`p'-1)*AvInb+MEb_`p')/`p'
	}

	* within
	mat IneqW=100*IneqW
	putexcel B19= matrix(IneqW)

	mat AvInw=100*AvInw
	putexcel B23= matrix(AvInw)

	* between
	mat IneqB=100*IneqB
	putexcel B45= matrix(IneqB)

	mat AvInb=100*AvInb
	putexcel B49= matrix(AvInb)		




* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 03. POLICY REFORM SCENARIO: LABOR SUPPLY EFFECTS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/* ----- load baseline behavior ----- */
	use "${SIMDATA}D.dta", clear

		keep ID Age EDUC Reti Empl flagID_LTpoor50
		
		ren EDUC D_EDUC
		ren Reti D_Reti
		ren Empl D_Empl
		ren flagID_LTpoor50 D_flagID_LTpoor50

/* ----- merge adjusted behavior profiles ----- */
	merge 1:1 ID Age using "${SIMDATA}E.dta", gen(Edta) keepusing(EDUC Reti Empl flagID_LTpoor50)

		ren EDUC E_EDUC
		ren Reti E_Reti
		ren Empl E_Empl
		ren flagID_LTpoor50 E_flagID_LTpoor50

	foreach x in D E {
		replace `x'_Empl = . if Age<(`x'_EDUC+8)
		
		bys Age: egen mEmpl_`x' = mean(`x'_Empl)
		bys Age : egen mEmpl_poor_`x' = mean(`x'_Empl) if `x'_flagID_LTpoor50==1
		bys Age : egen mEmpl_rich_`x' = mean(`x'_Empl) if `x'_flagID_LTpoor50==0		
	}

	sort ID Age

	foreach x in mEmpl_D mEmpl_E {
		preserve 
			collapse (mean) `x', by(Age)
			*list
			save "${TEMP_PATH}tempfig_`x'.dta", replace
		restore
	}
	
	foreach x in D E {
		preserve
			collapse (mean) mEmpl_`x', by(Age)
			*list
			save "${TEMP_PATH}tempfig_mEmpl_`x'.dta", replace		
		restore			
		preserve
			collapse (mean) mEmpl_poor_`x' if `x'_flagID_LTpoor50==1, by(Age)
			*list
			save "${TEMP_PATH}tempfig_mEmpl_poor_`x'.dta", replace		
		restore	
		preserve
			collapse (mean) mEmpl_rich_`x' if `x'_flagID_LTpoor50==0, by(Age)
			*list
			save "${TEMP_PATH}tempfig_mEmpl_rich_`x'.dta", replace		
		restore			
	}
	
	clear
	
	use "${TEMP_PATH}tempfig_mEmpl_D.dta", clear
	
	merge 1:1 Age using "${TEMP_PATH}tempfig_mEmpl_E.dta", nogen
	
	foreach x in D E {
		merge 1:1 Age using "${TEMP_PATH}tempfig_mEmpl_poor_`x'.dta", nogen
		merge 1:1 Age using "${TEMP_PATH}tempfig_mEmpl_rich_`x'.dta", nogen
	}			

************************************************************************
* 03a. Figure SWA.10: Labor supply effects of the lifetime tax reform
************************************************************************		
	
	twoway  (line mEmpl_D Age, lcolor(black) lpattern(solid)) ///
			(line mEmpl_E Age, lcolor(gs10) lpattern(solid))  ///
			(line mEmpl_poor_D Age, lcolor(black) lpattern(dash)) ///
			(line mEmpl_poor_E Age, lcolor(gs10) lpattern(dash)) ///
			(line mEmpl_rich_D Age, lcolor(black) lpattern(dash_dot)) ///
			(line mEmpl_rich_E Age, lcolor(gs10) lpattern(dash_dot)), ///
			scheme(s2mono) graphregion(color(white))	///
			xtitle("Age (years)", margin(medium) size(medlarge)) ytitle("Employment rate", margin(medium) size(medlarge)) ///
			yscale(range(0.5 1.0)) ylabel(0.5 .6 0.7 0.8 0.9 1,labsize(medlarge) nogrid) ///
			xlabel(20 30 40 50 60,labsize(medlarge)) ///
			legend(order(1 "Baseline - All" 2 "Reform - All" 3 "Baseline - weak employment history" 4 "Reform - weak employment history" 5 "Baseline - strong employment history"  6 "Reform - strong employment history"))	///
			legend(region(lcolor(white))) legend(size(small) cols(2)) // 
			*aspectratio(.6)
		graph export "${FIGURES}Figure_SWA10_PolTaxEmplRate.pdf", as(pdf) replace	

* >>> clean-up
foreach x in D E {
	erase "${TEMP_PATH}tempfig_mEmpl_`x'.dta"
	erase "${TEMP_PATH}tempfig_mEmpl_poor_`x'.dta"
	erase "${TEMP_PATH}tempfig_mEmpl_rich_`x'.dta"
}