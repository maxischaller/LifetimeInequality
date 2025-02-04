args dataset measure
set more off
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SIMULATION ANALYSIS -- MAIN DECOMPOSITION
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Running main inequality decomposition analysis & deriving marginal effects of
	  tax-transfer system components
	- Generated results written to CollectedResults.xlsx
*/

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 00. Initialize Dataset and Output Location (CollectedResults.xlsx)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

/* ----- load current dataset ----- */	
	use "${SIMDATA}`dataset'.dta", clear
	

/* ----- set output location ----- */		
	if ("`dataset'" == "Base") & ("`measure'"=="1") {
		putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_6_7_MainDecomp") modify
	}
	else {
		putexcel set "${TABLES}CollectedResults.xlsx", sheet("`dataset'_ge`measure'") modify
	}
	
	
/* ----- set inequality metric ----- */	
* 	> Inequality measures: ge(0): mean-log-deviation; ge(1): Theil; ge(2): half the squared coef. of variation
	local metric = "ge`measure'"
		*di "`metric'"
	
	
/* ----- Preparations ----- */	

	* > re-assign numbering to match values in permutation-order matrix P
	replace inc1=inc2
	replace inc2=inc3
	replace inc3=inc4
	replace inc4=inc5

	replace inc1_LT=inc2_LT
	replace inc2_LT=inc3_LT
	replace inc3_LT=inc4_LT
	replace inc4_LT=inc5_LT
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. Main Inequality decompositions (Total/Within/Between)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
	mat define GrossNet=J(2,3,.)

/* ----- inequality of lifetime earnings/income ----- */	
	preserve
		keep if Age==20

		ineqdeco WAGEInterest_LT,  by(ty)
			mat GrossNet[1,1]=r(`metric')
			mat GrossNet[1,2]=r(within_`metric')
			mat GrossNet[1,3]=r(between_`metric')
			

		ineqdeco TranAugDispPersonalIncome_LT, by(ty)
			mat GrossNet[2,1]=r(`metric')
			mat GrossNet[2,2]=r(within_`metric')
			mat GrossNet[2,3]=r(between_`metric')
			
	restore

	mat list GrossNet
	
/* ----- save results to CollectedResults.xlsx ----- */	
	* >>> scale inequality measure 
	mat GrossNet = 100*GrossNet 

	* >>> output 
	putexcel B6 = matrix(GrossNet)

	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. Tax-transfer System: Program Contributions
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

/* ----- Lifetime earnings inequality ----- */	 
	preserve
		keep if Age==20
		
		ineqdeco WAGEInterest_LT, by(ty)
			mat si=r(`metric')
			mat siw=r(within_`metric')
			mat sib=r(between_`metric')
	
	restore


	keep inc* Age ID ty

	
/* ----- Derive marginal programm contributions ----- */		
	* > for all order permutations
	forvalues p=1/24{

		disp `p'

		ge inc_LT=inc0_LT

		mat define s=si
		mat define sw=siw
		mat define sb=sib

		mat define ME_`p'=J(4,1,.)
		mat define MEw_`p'=J(4,1,.)
		mat define MEb_`p'=J(4,1,.)


		forvalues v=1/4{

			qui mat define jj=P[`p',`v']
			qui local pp=jj[1,1]

			qui replace inc_LT=inc_LT+inc`pp'_LT

			preserve
				keep if Age==20

				qui ineqdeco inc_LT, by(ty)
					mat ME_`p'[`pp',1]=r(`metric')-s[1,1]
					mat MEw_`p'[`pp',1]=r(within_`metric')-sw[1,1]
					mat MEb_`p'[`pp',1]=r(between_`metric')-sb[1,1]
					mat define s=r(`metric')
					mat define sw=r(within_`metric')
					mat define sb=r(between_`metric')
			restore

		}

		drop inc_LT

	}


/* ----- Save results to CollectedResults.xlsx ----- */	

	mat define AvIn=ME_1
	mat define AvInw=MEw_1
	mat define AvInb=MEb_1
	
	forvalues p=2/24{
		mat AvIn=((`p'-1)*AvIn+ME_`p')/`p'
		mat AvInw=((`p'-1)*AvInw+MEw_`p')/`p'
		mat AvInb=((`p'-1)*AvInb+MEb_`p')/`p'
	}


	* > Save marginal program effects
	putexcel B14 = matrix(100*AvIn)			// on total inequality
	putexcel C14 = matrix(100*AvInw)		// on within-skill-group inequality
	putexcel D14 = matrix(100*AvInb)		


	









