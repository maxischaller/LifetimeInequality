** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- DERIVATION UNEMPLOYMENT DURATIONS 
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 01. Prepare dataset
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

/* ----- Load and Prepare Dataset ----- */		
	xtset ID Age
	
	drop if Age>=60	

	keep ID Age EDUC Reti Empl Empl_lag Empl_lead
	
	ge Enter=1 if Age>=(EDUC+8)
		replace Enter=0 if Enter==.	

		
/*-----  flag first observation of ID  -----*/
	gen id_first = 0	
		bysort ID (Age): replace id_first = 1 if _n == 1
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 02. Identify transitions between employment states
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		

	
/*----- E2UE: identify transition into unemployment (begin of new spell)  -----*/
	sort ID Age
	by ID : gen byte begin = Empl==0 & Empl_lag==1 & Reti==0
		label var begin "Flag Start of new Unemployment Spell"
	
				tab Empl Empl_lag if id_first==1, mis
				tab Empl begin if id_first==1, mis
				tab Empl begin, mis
		
		assert !mi(begin)
		assert begin==0 if Empl==1 
		assert Reti==1 if id_first==1 & Empl==0 & Empl_lag==1 & begin!=1
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 03. Compute number of unemployment spells by ID
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
/*----- counter for unemployment spells by ID -----*/	
* 	> how many times an ID enters unemployment
	by ID : gen uempl_spell = sum(begin)
		label var uempl_spell "Counter of Unemployment Spells"	

		
/*----- number of unemployment spells by ID -----*/
	by ID : egen nmbr_uempl_spell = max(uempl_spell)
		label var nmbr_uempl_spell "Number of unemployment spells of ID"
		*assert !mi(nmbr_uempl_spell)
			
		

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 04. Account for gaps in individual panels
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
		
/*-----  view gaps in panels  -----*/	
	sort ID Age
	by ID : gen diff = Age[_n]-Age[_n-1]
	
	tab diff Empl, mis
	tab diff Empl if Reti==0, mis
		assert id_first==1 if mi(diff) // diff only missing at first obs of panels
		
		count if diff>=2 & !mi(diff) & Empl==0 & Reti==0
		count if diff==2 & !mi(diff) & Empl==0 & Reti==0
		
	
	* >>> flag gaps
	by ID : gen byte flag_gap = ( ((Age[_n]-Age[_n-1])>1) & !mi(Age[_n-1]))
	
	tab diff flag_gap, mis // check!	
		assert flag_gap==1 if diff>=2 & !mi(diff)


	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 05. Unemployment durations
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
		
/*-----  Identify length of unemployment spells  -----*/
	sort ID Age
	*br ID Age Empl Empl_lag Reti id_first begin uempl_spell nmbr_uempl_spell diff flag_gap 
	
	* >>> generate unique identifiers for unemployment spell
	gen Dur = uniform() if begin==1
	
	* >>> extend across length of unemployment spells
	* 1) UE-spell continues w/o gaps to follow-up period		
		by ID: replace Dur = l.Dur if mi(Dur) & Empl==0 & Reti==0 & diff==1  // & Empl_lag==0 (does not change result)
		* > note for gaps: extension breaks off:
			* > re-run this procdure after gaps are fixed
		gen Dur_init = Dur
		* > need to do 2 things: 
			* a) fix ue-spell identifier across gap
			* b) later fix duration 
	
	
	* 2) Fix Case 1: continued UE-spell across gap 
		*** Notes:
		*	> only fixable if diff==2 & information on lagged-employment can be used to infer employment status in gap-year
		
		* > first generate a flag that marks affected spells
		by ID: gen byte flag_ueadj1 = mi(Dur) & Empl==0 & Reti==0 & diff==2 & flag_gap==1 & Empl[_n-1]==0
			tab flag_ueadj1, mis
		
		* gap-year identified via (flag_gap==1 & diff==2)
		by ID: replace Dur = Dur[_n-1] if mi(Dur) & Empl==0 & Reti==0 & Empl_lag==0 & diff==2 & flag_gap==1 & Empl[_n-1]==0
			
		* re-run fill-up procedure (after gaps filled)
		by ID: replace Dur = l.Dur if mi(Dur) & Empl==0 & Reti==0 & diff==1
		
		
		* > extend adjustment flag across affected spells
		bys Dur: egen length_adj = max(flag_ueadj1) if !mi(Dur)
			sort ID Age
			tab length_adj, mis 
			*list ID if length_adj==1
			
		
	* 3) Fix Case 2: UE-spell ends after gap	
		* > generate flag that marks affected spells
		by ID: gen byte flag_ueadj2 = diff==2 & flag_gap==1 & Reti==0 & Empl==1 & Empl_lag==0 & Empl[_n-1]==0 & !mi(Dur[_n-1])
			assert flag_ueadj2==0 if flag_ueadj1==1
			list ID if flag_ueadj2==1
			
		* > use flag to extend duration value manually (+1 in duration measure for unemployment in gap year)
		by ID: replace Dur = Dur[_n-1] if mi(Dur) & flag_ueadj2==1 & diff==2 & flag_gap==1
			* > no further length adjustment required here - duration already correct
	
	
/*----- compute durations unemployment spells -----*/		
	* >>> derive length of each UE-spell in sample
	bys Dur : gen length = _N if !mi(Dur)
		bys Dur_init: gen length_init = _N if !mi(Dur_init)
		
	* >>> adjust length in Fix Case 1 (see above):
	sort ID Age
	replace length = length + length_adj
	
	sum length*
	
	
/*----- remove unemployment spells with gaps >2 years  -----*/		
	*list ID if diff>2 & !mi(diff) & Reti==0
	by ID : gen byte flag_gap_remove1 = diff[_n+1]>2 & !mi(diff[_n+1]) & !mi(Dur)
	
	bys Dur: egen flag_gap_remove2 = max(flag_gap_remove1) if !mi(Dur)
		sort ID Age
		tab flag_gap_remove2, mis
	replace length = . if flag_gap_remove2==1
	
	replace Dur = . if flag_gap_remove2==1	
	

	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* 06. Hazard model
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	*br ID Age Empl Empl_lag Reti Empl_lead begin diff Dur length
	
	
/*----- duration counter variable -----*/	
	bys Dur (Age): gen ue_dur = _n if !mi(Dur)	
		sort ID Age

	* >>> accounting for gaps
	* Problem:
	* 	> if entry is at start of panel: diff is missing
	gen ue_dur2_helper = ue_dur if ue_dur==1
		replace ue_dur2_helper = diff if mi(ue_dur2_helper) & !mi(Dur)
	
	bys Dur (Age): gen ue_dur2 = sum(ue_dur2_helper) if !mi(Dur)
		sort ID Age
		
	tab ue_dur ue_dur2 	// missings match into each other
	sum ue_dur ue_dur2
		
		
/*----- outcome: censoring indicator variable -----*/		
	* >>> 0 if ongoing spell or right-censored // 1 if exit to employment
	gen ue_cens = 0 if !mi(Dur)	
		tab ue_dur ue_cens, mis
		tab ue_dur2 ue_cens, mis
				
	* >>> end of spell: exit to employment
	replace ue_cens = 1 if !mi(ue_cens) & Empl_lead==1 & !mi(Empl_lead)	
		tab ue_dur ue_cens, mis
		tab ue_dur2 ue_cens, mis
	
	
/*----- flag completed spells -----*/		
	bys Dur: egen ue_complete = max(ue_cens) if !mi(ue_cens)
		sort ID Age
	
	
	
*******************************************************************************
* 06b. Logit model
*******************************************************************************		
	
	drop ue_dur
	ren ue_dur2 ue_dur

/*----- view duration values and group together -----*/		
	* > group durations >5 years
	tab ue_dur ue_cens, mis
		replace ue_dur = 6 if ue_dur>6 & !mi(ue_dur)	
	
	* >>> check if each duration dummies has both event values
	tab ue_dur ue_cens, mis
	
	
/*----- generate duration dummies -----*/	
	tab ue_dur, gen(ue_dur_dummy)
	
		
/*----- logit model to predict hazards -----*/	
	* > semi-parametric hazard model specification
	logit ue_cens ue_dur_dummy1-ue_dur_dummy6, nocons vce(cluster ID)
	
	
/*----- predict hazards -----*/		
	predict ue_haz, pr 
		tab ue_haz ue_dur	
	
	
*******************************************************************************		
/*----- logit model to predict hazards -----*/	
	gen educ_lvl = .
		replace educ_lvl = 0 if EDUC<=11
		replace educ_lvl = 1 if EDUC>=12
	
	* > semi-parametric hazard model specification
	logit ue_cens i.educ_lvl ue_dur_dummy1-ue_dur_dummy6, nocons vce(cluster ID)
	
	predict ue_haz_ed, pr
		tab ue_haz_ed ue_dur if educ_lvl==0
		tab ue_haz_ed ue_dur if educ_lvl==1
	
	