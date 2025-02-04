** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- PREPARE SIMULATED DATASETS FOR ANALYSIS
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Prepares estimation sample and simulated datasets for analysis
	- Generates permutation matrix for program effects derivation (perms.dta)

*/


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. PREPARE ESTIMATION DATASET (incl. MICROSIMULATED DATA)
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*** Notes:
	* - static microsimulated dataset based on estimation sample

	import delimited "${DATA_CONFID}esample_plus.txt", clear varn(1) case(preserve)
	
	keep if Ob==1
	
	xtset ID Age

	
/* ----- pre-view sample ----- */
	sum ID
	preserve
		duplicates drop ID, force
		sum ID
		tab EDUC
	restore
		
	
*******************************************************************************
* 01a. Save Adjusted SOEP Sample for Simulation-Data Matching
*******************************************************************************		

/* ----- generate match-id based on education ----- */	
	by EDUC ID, sort: gen match_id = _n==1
	by EDUC			: replace match_id = sum(match_id)

	
/* ----- re-transform observed wealth ----- */		
	replace Wealth_SOEP07 = . if Wealth_SOEP07==-99999
	
	
/* ----- save dataset with match_id ----- */	
	save "${DATA_CONFID}esample_plus.dta", replace
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. PREPARE SIMULATED DATASETS FOR MAIN-ANALYSIS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
	
*******************************************************************************
* 02a. Convert .txt to .dta datasets
*******************************************************************************	

foreach n in baseline involsep scenario_A scenario_B scenario_C scenario_D scenario_E b98g50 b97g50 b99g25 b99g75 b98g25 b98g75 b97g25 b97g75 {
		
	import delimited "${SIMDATA}data_`n'.txt", clear varn(1) case(preserve)
	
	xtset ID Age
	
	save "${SIMDATA}data_`n'.dta", replace	
	
}	
	
	
*******************************************************************************
* 02b. Merge & Generate additional variables 
*******************************************************************************
	
foreach n in baseline involsep scenario_A scenario_B scenario_C scenario_D scenario_E b98g50 b97g50 b99g25 b99g75 b98g25 b98g75 b97g25 b97g75 {

	use  "${SIMDATA}data_`n'.dta", clear
	
	/* ----- Scenarios A-C: merge baseline education choices ----- */
	* Notes:
	*	- to generate skill-groups for analysis consistent to baseline scenario
	
		if "`n'" == "scenario_A"{
			ren EDUC EDUC_scenA
			merge 1:1 ID Age using "${SIMDATA}data_baseline.dta", keepusing(EDUC) nogen	
			ren EDUC EDUC_base
			ren EDUC_scenA EDUC
		}
		
		if ("`n'" == "scenario_B")  {
			ren EDUC EDUC_scenB
			merge 1:1 ID Age using "${SIMDATA}data_baseline.dta", keepusing(EDUC) nogen
			ren EDUC EDUC_base
			ren EDUC_scenB EDUC		
		}
		
		if "`n'" == "scenario_C"{
			ren EDUC EDUC_scenC
			merge 1:1 ID Age using "${SIMDATA}data_baseline.dta", keepusing(EDUC) nogen
			ren EDUC EDUC_base
			ren EDUC_scenC EDUC		
		}		
		
	
	/* ----- drop simulated post-mortem observations ----- */
		drop if Alive == 0			
		sum Age	
	
	
	/* ----- generate additional variables ----- */
		gen RGE 	= WAGE	
		gen RGI 	= WAGE + GCI
		gen RI1		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2
		gen RI2		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB
		gen RI3		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB
		gen RI4		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB + EPB
		gen RI5		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB + EPB + DPB		
	
	
		
	/* ----- Run ProgramIncomes.do ----- */		
		drop if Age>=60
		qui ge RIX=.
		qui rename RI* RG*
		
		do "${CODE}proginc.do" `n'
		
		compress	
	
	
	
	/* ----- Save Main Datasets ----- */	
		* ----------------------------------------
		* >>> Baseline scenario
			if "`n'"=="baseline"{
				save "${SIMDATA}Base.dta", replace
			}	
		
		* >>> Baseline scenario + invol. separation simulation
			if "`n'"=="involsep"{
				save "${SIMDATA}Involsep.dta", replace
			}			
		
		* ----------------------------------------
		* >>> Scenario A (separation risk)	
			if "`n'"=="scenario_A"{
				save "${SIMDATA}A.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}		
		* >>> Scenario B (offer risk)	
			if "`n'"=="scenario_B"{
				save "${SIMDATA}B.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}			
		* >>> Scenario C (health risk)	
			if "`n'"=="scenario_C"{
				save "${SIMDATA}C.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}		

		* ----------------------------------------
		* >>> Scenario D (TaxPol: fixed behavior)	
			if "`n'"=="scenario_D"{
				save "${SIMDATA}D.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}			
		* >>> Scenario E (TaxPol: behavioral adjustments)	
			if "`n'"=="scenario_E"{
				save "${SIMDATA}E.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}		

			
	/* ----- Save Datasets - Preference parameter variations ----- */		
		* ----------------------------------------
		* >>> beta=0.99, gamma=1.75
			if "`n'"=="b99g75"{
				save "${SIMDATA}Base_b99g75.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}	
		* >>> beta=0.99, gamma=1.25
			if "`n'"=="b99g25"{
				save "${SIMDATA}Base_b99g25.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}
		
		* ----------------------------------------
		* >>> beta=0.98, gamma=1.50
			if "`n'"=="b98g50"{
				save "${SIMDATA}Base_b98g50.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}
		* >>> beta=0.98, gamma=1.25
			if "`n'"=="b98g25"{
				save "${SIMDATA}Base_b98g25.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}			
		* >>> beta=0.98, gamma=1.75
			if "`n'"=="b98g75"{
				save "${SIMDATA}Base_b98g75.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}
		
		* ----------------------------------------
		* >>> beta=0.97, gamma=1.50
			if "`n'"=="b97g50"{
				save "${SIMDATA}Base_b97g50.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}
		* >>> beta=0.97, gamma=1.25
			if "`n'"=="b97g25"{
				save "${SIMDATA}Base_b97g25.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}			
		* >>> beta=0.97, gamma=1.75
			if "`n'"=="b97g75"{
				save "${SIMDATA}Base_b97g75.dta", replace
				erase "${SIMDATA}data_`n'.dta"
			}		
	
}


*******************************************************************************
* 02c. Robustness results w/o interest income
*******************************************************************************	

	use  "${SIMDATA}data_baseline.dta", clear
	
	
	/* ----- drop simulated post-mortem observations ----- */
		drop if Alive == 0			
		sum Age	
		
	/* ----- generate additional variables ----- */
		gen RGE 	= WAGE	
		gen RGI 	= WAGE + GCI
		gen RI1		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2
		gen RI2		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB
		gen RI3		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB
		gen RI4		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB + EPB
		gen RI5		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB + EPB + DPB		
				
	/* ----- Run ProgramIncomes.do ----- */		
		drop if Age>=60
		qui ge RIX=.
		qui rename RI* RG*
		
		local n = "NoInt"
		do "${CODE}proginc.do" `n'
		compress		
	
	save "${SIMDATA}Base_NoInt.dta", replace

	
	
*******************************************************************************
* 02c. Robustness results: positive lifetime earnings
*******************************************************************************		
	
	use  "${SIMDATA}data_baseline.dta", clear
	
	
	/* ----- drop simulated post-mortem observations ----- */
		drop if Alive == 0			
		sum Age	
		
	/* ----- generate additional variables ----- */
		gen RGE 	= WAGE	
		gen RGI 	= WAGE + GCI
		gen RI1		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2
		gen RI2		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB
		gen RI3		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB
		gen RI4		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB + EPB
		gen RI5		= WAGE + GCI - ITAX - CTAX - HINS/2 - UINS/2 - PINS/2 + UIB + SAB + MPB + EPB + DPB		
				
	/* ----- Run ProgramIncomes.do ----- */		
		drop if Age>=60
		qui ge RIX=.
		qui rename RI* RG*
		
		local n = "PosLTEarn"
		do "${CODE}proginc.do" `n'
		compress		
	
	save "${SIMDATA}Base_PosLTEarn.dta", replace
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 03. GENERATE MATCHED SIMULATED DATASET: BASELINE SCENARIO
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
* Notes:
* 	- generates a subsample of simulated life-cycle trajectories from the baseline 
*		scenario by matching to the observed education- and age-structure observed
*		in the estimation sample
* 	- simulated joint distribution of education and ability types is preserved
	
	
/* ----- Add lead/lagged-employment variable to baseline simulation ----- */	
	use  "${SIMDATA}data_baseline.dta", clear
	*br ID Age Empl Reti
	sort ID Age
	cap drop Empl_lag Empl_lead
	by ID: gen Empl_lag = l.Empl
	by ID: gen Empl_lead = f.Empl
	
	save "${SIMDATA}data_baseline.dta", replace
	
	
/* ----- Random seed for sampling of life-cycle trajectories ----- */	
	set seed 79
		
	
/* ----- generate sample of life-cycle trajectories  ----- */		
	
	* --------------------------------------
	clear
	use "${DATA_CONFID}esample_plus.dta", clear

	duplicates drop ID, force

	tab EDUC, matcell(obsfreq)	

	* > life-cycle draws for each observed individual:
	local multsamp = 5
	disp `multsamp'
	
	* --------------------------------------
	forval yrs = 8/18 {
		clear
		use  "${SIMDATA}data_baseline.dta", clear
		keep ID TYPE EDUC
		duplicates drop ID, force	
		
		keep if EDUC == `yrs'
		
		* > identify frequency of trajectories for each type
		estpost tab TYPE EDUC, mis
		
		mat shares = e(colpct)
		*mat list shares
		
		local freq1 = round(shares[1,1]/100*obsfreq[`yrs'-7,1]) * `multsamp'
		disp `freq1'
			preserve	
				keep if TYPE == 1	
				*sum ID
				*tab TYPE EDUC
				*drop TYPE EDUC
		
				sample `freq1', count
				
				save "${TEMP_PATH}matchdata_ed`yrs'_t1.dta", replace
		
			restore	
	
	
		local freq2 = round(shares[1,2]/100*obsfreq[`yrs'-7,1]) * `multsamp'
		disp `freq2'
			preserve	
				keep if TYPE == 2
				*drop TYPE EDUC
		
				sample `freq2', count
				
				save "${TEMP_PATH}matchdata_ed`yrs'_t2.dta", replace
		
			restore	
		
		local freq3 = (obsfreq[`yrs'-7,1] * `multsamp') - `freq1' - `freq2'
		disp `freq3'
			preserve	
				keep if TYPE == 3
		
				sample `freq3', count
				
				save "${TEMP_PATH}matchdata_ed`yrs'_t3.dta", replace
		
			restore	

	}
	
	
	* --------------------------------------
	* >>> summarize IDs and merge their life-cycle trajectories
	clear

	forval yrs = 8/18 {
		forval types = 1/3 {
			append using "${TEMP_PATH}matchdata_ed`yrs'_t`types'.dta"		
		}		
	}
	
	* Education - type distribution
		tab EDUC TYPE, row
	
	
	
	
/* ----- merge life-cycle trajectories----- */	
	merge 1:m ID using "${SIMDATA}data_baseline.dta", ///
		gen(select_simdta) assert(match using) keep(match)
	
	
	
/* ----- generate match-id based on education ----- */		
	by EDUC ID, sort: gen match_id = _n == 1
	by EDUC: replace match_id = sum(match_id)		

	
/* ----- save ----- */	
	save "${SIMDATA}data_baseline_matched.dta", replace
	*use "${SIMDATA}data_baseline_matched.dta", clear

	
/* ----- clean-up ----- */	
	forval yrs = 8/18 {
		forval types = 1/3 {
			erase "${TEMP_PATH}matchdata_ed`yrs'_t`types'.dta"		
		}		
	}
	
	
*******************************************************************************
* 03b. Load observed Data/Individuals & match simulated Trajectories
*******************************************************************************	
	
	use "${DATA_CONFID}esample_plus.dta", clear
	
		ren ID o_ID
		keep o_ID match_id EDUC Age
	
		* > match_id equivalent to ID (only that it counts educ specific from 1)
	
	
		sum match_id
		
					
		forval x = 2/`multsamp' {
			preserve
				gen dupl_ID = `x'
				
				save "${TEMP_PATH}soepduplicates_draw`x'.dta", replace
				
			restore			
		}
		
		forval x = 2/`multsamp' {
			append using "${TEMP_PATH}soepduplicates_draw`x'.dta"		
		}
		
		* > after expanding: re-generate the matching-IDs
		drop match_id
		
		by EDUC o_ID dupl_ID, sort: gen match_id = _n == 1
		by EDUC: replace match_id = sum(match_id)
	
		sum match_id
	
	*expand `multsamp', gen(dupl_ID)
	
	merge 1:m match_id EDUC Age using "${SIMDATA}data_baseline_matched.dta", ///
		gen(simdta_merge) keep(3)
	
	
/* ----- save data-set with matched simulated spells ----- */	
* Notes:
*	> ob=1 indicates observed individual-age observerations
*	> this dataset only includes the matched simulated datapoints; a combined dataset 
*		also including the observed spells is created below

	save "${SIMDATA}data_baseline_ob1.dta", replace
	
		
	
/* ----- save a combined dataset ----- */
*** Notes:		
	* > containing observed data and matched simulated data	
	* > ob=1 identifies individual-age observations from estimation sample
	* > observed data with 'o_' prefix for variables
	
	local multsamp = 5
	
	* --- load observed data
	use "${DATA_CONFID}esample_plus.dta", clear
	
	
    * --- rename variables with observed-data identifier	
	ds Ob Age match_id EDUC, not
	
	foreach x of varlist `r(varlist)' {
		rename `x' o_`x'
	} 	
	
	
	* --- expand and merge simulated data
		forval x = 2/`multsamp' {
			preserve
				gen dupl_ID = `x'
				drop Ob
				
				save "${TEMP_PATH}soepduplicates_draw`x'.dta", replace
				
			restore			
		}
		
		forval x = 2/`multsamp' {
			append using "${TEMP_PATH}soepduplicates_draw`x'.dta"		
		}
		
		* > after expanding: re-generate the matching-IDs
		drop match_id
		
		by EDUC o_ID dupl_ID, sort: gen match_id = _n == 1
		by EDUC: replace match_id = sum(match_id)
	
		sum match_id
	
	*expand `multsamp', gen(dupl_ID)
	
	
	* >>> merge
	merge 1:m match_id EDUC Age using "${SIMDATA}data_baseline_matched.dta", ///
		gen(simdta_merge) keep(3)
	
	
	* >>> set duplicated observed data-points to missing:
	replace Ob = 0 if mi(Ob)
		tab Ob, mis
	
	foreach x of varlist o_* {
		replace `x' = . if Ob==0
	}
	
	sum o_*
	
		
/* ----- save a combined dataset ----- */
* Notes:
*	> since this dataset also includes SOEP derived information it is saved to
*		directory "Data/SOEP_confid/derived_confid/"
	save "${DATA_CONFID}data_ObsSimComb_ob1.dta", replace
	

	
	
/* ----- clean-up ----- */		
	forval x = 2/`multsamp' {
		erase "${TEMP_PATH}soepduplicates_draw`x'.dta"		
	}	


	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 04. PREPARE PERMUTATION MATRIX: PROGRAM EFFECTS DERIVATION
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
*** Notes:
* 	- generates basis for permutation matrix used to derive order-robust program contributions
*	 to redistributive and insurance effects of tax-transfer system (cp. Shorrocks, 2013)
	
	clear

/* ----- generate empty variables ----- */		
	set obs 24 // (4!)=24 (all possible order of programm applications)
	gen var1 = .
	gen var2 = . 
	gen var3 = . 
	gen var4 = .
	
	gen dcount = 1
	gen counter = sum(!mi(dcount))
	
	
/* ----- define permutations ----- */		
	local perm1 4 3 2 1
	local perm2 4 3 1 2
	local perm3 4 2 3 1 
	local perm4 4 2 1 3 
	local perm5 4 1 2 3 
	local perm6 4 1 3 2 
	local perm7 3 4 2 1 
	local perm8 3 4 1 2 
	local perm9 3 2 4 1 
	local perm10 3 2 1 4 
	local perm11 3 1 2 4 
	local perm12 3 1 4 2 
	local perm13 2 3 4 1 
	local perm14 2 3 1 4 
	local perm15 2 4 3 1 
	local perm16 2 4 1 3 
	local perm17 2 1 4 3 
	local perm18 2 1 3 4 
	local perm19 1 3 2 4 
	local perm20 1 3 4 2 
	local perm21 1 2 3 4 
	local perm22 1 2 4 3 
	local perm23 1 4 2 3 
	local perm24 1 4 3 2 
	
	
/* ----- fill variables ----- */		
	forval x = 1/24 {
		forval r = 1/4{
			local perm_var`r' = word("`perm`x''", `r')
			replace var`r' = `perm_var`r'' if counter==`x'					
		}
	}

/* ----- save permutations ----- */
	drop dcount counter
	
	save "${SIMDATA}perms.dta", replace 
