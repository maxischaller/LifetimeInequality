** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- REDUCED FORM JOB SEPARATIONS MODEL
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
NOTES:
	- script estimates reduced form involuntary job separations model 
	
INPUT:
	- "data_EstimSample.dta": estimation sample
	
	
OUTPUT: 
	- "params_jobsep.txt": estimated parameters as input for structural model 
	- "var_covar_jobsep.txt": estimated var-covar matrix as input for structural model	
		-> see Matlab: "calib.m"
	
	
Generated Tables and Figures:	
	- Table SWA.3 - Panel II: Parameter estimates: employment risks
	
*/	


	use "${DATA_CONFID}data_EstimSample.dta", clear
	

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***  ESTIMATION OF REDUCED FORM JOB SEPARATION RISK MODEL
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

/* -----( Table SWA.3 - Panel II: Parameter estimates: employment risks )------ */

*** Number of Involuntary Separations:
	estpost tab jobsep_nh if wl==1
		matrix list e(b)
		matrix jobsep_tab = e(b)
	
	tab jobsep_nh jobloss, mis
	tab jobsep_nh jobloss if wl==1, mis
	
	
logit jobsep_nh educ health age50 age55 age60 if wl==1, vce(cluster persnr)	
	eststo jobsep_nh
	
	* > save parameters for export
	matrix list e(b)	
		matrix params_jobsep = J(6,1,.)
		matrix params_jobsep[1,1] = e(b)[1,6]
		matrix params_jobsep[2,1] = e(b)[1,1]
		matrix params_jobsep[3,1] = e(b)[1,2]
		matrix params_jobsep[4,1] = e(b)[1,3]
		matrix params_jobsep[5,1] = e(b)[1,4]
		matrix params_jobsep[6,1] = e(b)[1,5]	
	
	matrix list r(table)
		matrix se_jobsep = J(6,1,.)
		matrix se_jobsep[1,1] = r(table)[2,6]
		matrix se_jobsep[2,1] = r(table)[2,1]
		matrix se_jobsep[3,1] = r(table)[2,2]
		matrix se_jobsep[4,1] = r(table)[2,3]
		matrix se_jobsep[5,1] = r(table)[2,4]
		matrix se_jobsep[6,1] = r(table)[2,5]
	
	matrix obs_jobsep = e(N)
	matrix ID_jobsep = e(N_clust)
	matrix ll_jobsep = e(ll)
	matrix chi2_jobsep = e(chi2)
	
	* > save standard errors / hessian matrix for export
	matrix list e(V)
		*** NOTE:
		*	> order of parameters is var-covar matrix of result does not fit specification in structural model (Matlab)
		* 		order: educ, health, age50, age55, age60, constant
		* 	> rewrite var-covar matrix: fill with appropriate elements
		*		order: constant, educ, health, age50, age55, age60		
		mat col1 = e(V)[6,6] \ e(V)[6,1 .. 5]'
		mat list col1
		
		mat col2 = e(V)[6,1] \ e(V)[1..5,1]
		mat list col2
		
		mat col3 = e(V)[6,2] \ e(V)[2,1] \ e(V)[2..5,2]
		mat list col3
		
		mat col4 = e(V)[6,3] \ e(V)[3,1..2]' \ e(V)[3..5,3]
		mat list col4
		
		mat col5 = e(V)[6,4] \ e(V)[4,1..3]' \ e(V)[4..5,4]
		mat list col5 
		
		mat col6 = e(V)[6,5] \ e(V)[5,1..4]' \ e(V)[5,5]
		mat list col6
		
		mat var_covar_jobsep = col1, col2, col3, col4, col5, col6
		mat list var_covar_jobsep
	
	
*** GENERATE TABLE SWA.3 - Panel II	
	label var educ "High Education"
	label var health "Good Health"
		
	estadd scalar jobsep_nmbr = jobsep_tab[1,2]	
	
/*** Output Table SWA.3 - Panel II: Involuntary job separations	
	esttab jobsep_nh using "${TABLES}Table_SWA3_Panel2_SepRisk.tex", replace ///
		fragment booktabs label b(3) p(3) alignment(S S) ///
		cells("b(fmt(3)star) se(fmt(4)par)") collabels("\multicolumn{1}{c}{Coefficient}" "\multicolumn{1}{c}{Standard Error}") ///
		stats(N N_clust jobsep_nmbr ll chi2, fmt(0 0 0 2 2) ///
			layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" ///
				"\multicolumn{1}{S}{@}" "\multicolumn{1}{S}{@}") ///
			labels(`"Observations"'`"Individuals"'`"Involuntary job separations"'`"Loglikelihood"' `"Chi2"'))	
*/	
	
*** Export to CollectedResults	
	putexcel set "${TABLES}CollectedResults.xlsx", sheet("Tab_SWA3_EmplRisk") modify 	
	
	putexcel B15 = matrix(params_jobsep)
	putexcel C15 = matrix(se_jobsep)
	putexcel B22 = matrix(obs_jobsep)
	putexcel B23 = matrix(ID_jobsep)
	putexcel B24 = matrix(jobsep_tab[1,2])
	putexcel B25 = matrix(ll_jobsep)
	putexcel B26 = matrix(chi2_jobsep)
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
***  EXPORT ESTIMATED PARAMETERS
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	

	clear

/* -----( Export estimated parameters )------ */

	mat list params_jobsep
	
	svmat params_jobsep
	
	export delimited params_jobsep1 using "${MATLABINPUT}params_jobsep.txt", novar replace
	
	
/* -----( Export estimated standard errors / hessian )------ */	
	clear
	
	mat list var_covar_jobsep
	
	svmat var_covar_jobsep
	
	export delimited _all using "${MATLABINPUT}var_covar_jobsep.txt", novar replace
	