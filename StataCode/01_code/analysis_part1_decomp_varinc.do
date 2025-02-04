args dataset
set more off
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SIMULATION ANALYSIS -- ADD. ROBUSTNESS DECOMPOSITION
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Additional robustness check of main decomposition and program contribution
	  results using alternative measure of inequality: variance of log-earnings/income
*/

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 00. Initialize Dataset and Output Location (CollectedResults.xlsx)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

/* ----- load current dataset ----- */	
	use "${SIMDATA}`dataset'.dta", clear
	

/* ----- set output location ----- */		
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("`dataset'_VarInc") modify
	

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

	preserve
		keep if Age==20
		
		* >>> type-proportions in sample
		by ty, sort : gen freq = _N
		gen pc_freq = freq / _N		

		* >>> Taking logs
		gen lnEarn_LT = ln(WAGEInterest_LT)
		gen lnInc_LT = ln(TranAugDispPersonalIncome_LT)

		
		* >>> Log-Earnings:
			* Total
			sum lnEarn_LT , det 	// overall variance
				mat GrossNet[1,1] = r(Var)	
			
			* Withing/Between skill groups
			mixed lnEarn_LT || ty: 
				mat bw_earn = e(b)[1,2]
				mata : st_matrix("bw_earn", exp(st_matrix("bw_earn"))^2)
				mat li bw_earn
				
				mat within_earn = e(b)[1,3]
				mata : st_matrix("within_earn", exp(st_matrix("within_earn"))^2)
				mat li within_earn	
			
				mat GrossNet[1,2]=within_earn
				mat GrossNet[1,3]=bw_earn
			

		* >>> Log-Income: 
			* Total
			sum lnInc_LT, det
				mat GrossNet[2,1] = r(Var)
			* Within/Between skill groups
			mixed lnInc_LT || ty:
				mat bw_inc = e(b)[1,2]
				mata : st_matrix("bw_inc", exp(st_matrix("bw_inc"))^2)
				mat li bw_inc
				
				mat within_inc = e(b)[1,3]
				mata : st_matrix("within_inc", exp(st_matrix("within_inc"))^2)
				mat li within_inc	
				
				mat GrossNet[2,2]=within_inc
				mat GrossNet[2,3]=bw_inc
				

	restore

	putexcel B6 = matrix(100*GrossNet)



* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. Tax-transfer System: Program Contributions
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/* ----- Lifetime earnings inequality ----- */
	preserve
		keep if Age==20
		
		* >>> type-proportions in sample
		by ty, sort : gen freq = _N
		gen pc_freq = freq / _N	
		
		* >>> Taking logs
		gen lnEarn_LT = ln(WAGEInterest_LT)
		gen lnInc_LT = ln(TranAugDispPersonalIncome_LT)

		* >>> Log-Earnings
			sum lnEarn_LT, det
				mat si=r(Var)

			mixed lnEarn_LT || ty: 
				mat bw_earn = e(b)[1,2]
				mata : st_matrix("bw_earn", exp(st_matrix("bw_earn"))^2)
				mat li bw_earn
				
				mat within_earn = e(b)[1,3]
				mata : st_matrix("within_earn", exp(st_matrix("within_earn"))^2)
				mat li within_earn	
			
				mat sib=bw_earn
				mat siw=within_earn		
		
	restore


	keep inc* Age ID ty	

	
/* ----- Derive marginal programm contributions ----- */		
	* > for all order permutations

	forval p = 1/24 {
		
		disp `p'
			
		ge inc_LT=inc0_LT
		*ge inc=inc0

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
				
				by ty, sort : gen freq = _N
				gen pc_freq = freq / _N	
				
				gen lnInc_LT = ln(inc_LT)		

				sum lnInc_LT, det
					mat ME_`p'[`pp',1] = r(Var) - s[1,1]
					mat define s=r(Var)
				
				mixed lnInc_LT || ty:
					mat bw_inc = e(b)[1,2]
					mata : st_matrix("bw_inc", exp(st_matrix("bw_inc"))^2)
					mat li bw_inc
					
					mat within_inc = e(b)[1,3]
					mata : st_matrix("within_inc", exp(st_matrix("within_inc"))^2)
					mat li within_inc	
					
				mat MEw_`p'[`pp',1]=within_inc-sw[1,1]
				mat MEb_`p'[`pp',1]=bw_inc-sb[1,1]
				mat define sw=within_inc
				mat define sb=bw_inc		
						
			restore	
			
		}
		
		drop inc_LT
			
	}

	
/* ----- Save results to CollectedResults.xlsx ----- */	
	mat define AvIn=ME_1
	mat define AvInw=MEw_1
	mat define AvInb=MEb_1

	forvalues p=2/24 {
		mat AvIn=((`p'-1)*AvIn+ME_`p')/`p'
		mat AvInw=((`p'-1)*AvInw+MEw_`p')/`p'
		mat AvInb=((`p'-1)*AvInb+MEb_`p')/`p'
	}

	mat list AvIn 
	mat list AvInw
	mat list AvInb

	putexcel B14 = matrix(100*AvIn) 			// on total inequality											
	putexcel C14 = matrix(100*AvInw)			// on within-skill-group inequality
	putexcel D14 = matrix(100*AvInb) 			// on between-skill-group inequality
