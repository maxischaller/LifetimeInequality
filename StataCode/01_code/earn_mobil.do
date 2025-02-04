** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY --- LABOR EARNINGS MOBILITY
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*

Generated Tables:
	- Tab_SWA5_EarnMob

*/

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. SIMULATED DATA: LOAD MATCHED BASELINE SAMPLE
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

	clear
	clear matrix

/* ----- load dataset ----- */ 	
	use "${SIMDATA}data_baseline_ob1.dta", clear
	
	keep ID Age WAGE2 Empl Reti
	order ID Age Reti Empl WAGE2
	
	xtset ID Age
	
/* ----- data pre-view & rename ----- */	
	ren Age age
	
	drop if age>=60

	tab Reti Empl
	
	
/* ----- assessed variables ----- */
	sum WAGE2 
	
	replace WAGE2 = . if Empl!=1

	drop if mi(WAGE2)


*******************************************************************************
* 01a. First stage: Determine Bins
*******************************************************************************	
	
	gen z = 1		// bin category base assignment -> adjusted in loop below

	global 	nbins = 5		// define number of equally sized bins
	local	nbins_0 = $nbins
	local	nbins_1 = $nbins - 1
	

	* --- generate and fill vector of mean values of bins
		* matrices:
		mat m = J(`nbins_0',1,.)		// mean resid; (nbins,1) matrix of missings
	
		* quantiles of residual wage distribution
		_pctile WAGE2, n(`nbins_0')
		

		* change bin category
		local test = r(r1)
			forval j = 1(1)`nbins_1' {						/* change bin category */
				local	z`j' =  r(r`j')	
				replace	z = (`j' + 1) if  `z`j'' < WAGE2
			}
		* > stepwise increase bin/percentile assignment till correct match per observation
		
				
		* > fill vector of mean resid and wage values
		forval j=1(1)`nbins_0'	{
			sum		WAGE2  if z==`j', mean	// z indicates bin-category
			
			* fill mean wage 
			mat m[`j',1] = r(mean)
			
		}
	* > view result:
	mat list m
	
	forval r = 1(1)5 {
		sum WAGE2 if z==`r'
	}
		


*******************************************************************************
* 01b. Second stage: Derive Transition Matrices
*******************************************************************************	
	
/* ----- Preparations ----- */	
	global 	nbins = 5		// define number of equally sized bins
	local	nbins_0 = $nbins
	local	nbins_1 = $nbins - 1

	mat	t = J(`nbins_0',`nbins_0',0)				/* matrix for final transition matrix */
				
	* >>> delete pid if only one observation available
		by ID, sort 	: gen nr = _n
		by ID			: egen mnr = max(nr)
		drop if mnr==1		
							
	* > generate counter of observations
		by ID, sort		: gen order = sum(!mi(ID))

		
/* ----- generate indicator for change in quintile category ----- */			
		sort ID age
		
		by ID: gen zt = z[_n+1] - z 
		
		drop if mi(zt)

/* ----- Compute transition matrix ----- */					
	forval k = 1(1)`nbins_0' {
		disp `k'
		tab zt if z==`k', matcell(nu`k'_mat) matrow(bin)
		
		local numb_`k' = r(N)
		
		* > second loop over follow up observation:
		forval kt = 1(1)`nbins_0'	{		
			
			* > number of obs in specific bin next observation given bin this observation
			local numb_`k'_`kt' = nu`k'_mat[`kt',1]						
			
			* > probability to have specific bin next obs given bin this obs
			mat t[`k', `kt'] = `numb_`k'_`kt'' / `numb_`k''
									
		}								
	}
	
	mat list t
		
		
	
*******************************************************************************
* 01c. Table SWA.5b: Print Transition Matrix to "CollectedResults.xlsx"
*******************************************************************************		

	putexcel set "${TABLES}CollectedResults.xlsx", modify sheet("Tab_SWA5_EarnMob")
		putexcel C15 = matrix(t) 	
	
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. OBSERVED DATA: LOAD ESTIMATION SAMPLE
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

	clear
	clear matrix

/* ----- load dataset ----- */ 	
	use "${DATA_CONFID}esample_plus.dta", clear	
	
	keep ID Age Empl Reti WAGE
	
	xtset ID Age
	
/* ----- data pre-view & rename ----- */	
	ren Age age
	
	drop if age>=60

	tab Reti Empl
	
/* ----- assessed variables ----- */
	sum WAGE
	
	replace WAGE = . if Empl!=1

	drop if mi(WAGE)
		
		
*******************************************************************************
* 02a. First stage: Determine Bins
*******************************************************************************	
	
	gen z = 1		// bin category base assignment -> adjusted in loop below

	global 	nbins = 5		// define number of equally sized bins
	local	nbins_0 = $nbins
	local	nbins_1 = $nbins - 1
	

	* --- generate and fill vector of mean values of bins
		* matrices:
		mat m = J(`nbins_0',1,.)		// mean resid; (nbins,1) matrix of missings
	
		* quantiles of residual wage distribution
		_pctile WAGE, n(`nbins_0')
		

		* change bin category
		local test = r(r1)
			forval j = 1(1)`nbins_1' {						/* change bin category */
				local	z`j' =  r(r`j')	
				replace	z = (`j' + 1) if  `z`j'' < WAGE
			}
		* > stepwise increase bin/percentile assignment till correct match per observation
		
				
		* > fill vector of mean resid and wage values
		forval j=1(1)`nbins_0'	{
			sum		WAGE  if z==`j', mean	// z indicates bin-category
			
			* fill mean wage 
			mat m[`j',1] = r(mean)
			
		}
	* > view result:
	mat list m
	
	forval r = 1(1)5 {
		sum WAGE if z==`r'
	}
		


*******************************************************************************
* 02b. Second stage: Derive Transition Matrices
*******************************************************************************	
	
/* ----- Preparations ----- */	
	global 	nbins = 5		// define number of equally sized bins
	local	nbins_0 = $nbins
	local	nbins_1 = $nbins - 1

	mat	t = J(`nbins_0',`nbins_0',0)				/* matrix for final transition matrix */
				
	* >>> delete pid if only one observation available
		by ID, sort 	: gen nr = _n
		by ID			: egen mnr = max(nr)
		drop if mnr==1		
							
	* > generate counter of observations
		by ID, sort		: gen order = sum(!mi(ID))

		
/* ----- generate indicator for change in quintile category ----- */			
		sort ID age
		
		by ID: gen zt = z[_n+1] - z 
		
		drop if mi(zt)

/* ----- Compute transition matrix ----- */					
	forval k = 1(1)`nbins_0' {
		disp `k'
		tab zt if z==`k', matcell(nu`k'_mat) matrow(bin)
		
		local numb_`k' = r(N)
		
		* > second loop over follow up observation:
		forval kt = 1(1)`nbins_0'	{		
			
			* > number of obs in specific bin next observation given bin this observation
			local numb_`k'_`kt' = nu`k'_mat[`kt',1]						
			
			* > probability to have specific bin next obs given bin this obs
			mat t[`k', `kt'] = `numb_`k'_`kt'' / `numb_`k''
									
		}								
	}
	
	mat list t


	
*******************************************************************************
* 02c. Table SWA.5a: Print Transition Matrix to "CollectedResults.xlsx"
*******************************************************************************		

	putexcel set "${TABLES}CollectedResults.xlsx", modify sheet("Tab_SWA5_EarnMob")
		putexcel C7 = matrix(t) 	
		
		