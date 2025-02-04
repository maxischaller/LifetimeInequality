args n

** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- Generate Income and Employment Measures
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------


********************************************************************************
* Generate income measures
********************************************************************************
	* program incomes (annual)
	ge ui=RG2-RG1 		/* UI*/
	ge sab=RG3-RG2 		/* SAB*/
	ge DB=RG5-RG4   	/* DB*/

	* Suppress tax on disability benefits 
	replace ITAX=0 if DB>0

	ge ssctax=UINS/2+HINS/2
	ge tax=-(ssctax+ITAX+CTAX)

	ge DeferredComp=RG4-RG3 /* earnings-related pension benefits*/
	ge InvestmentInc=RGI-RGE
	
	if ("`n'"=="NoInt") {
		ge PersonalIncome=WAGE+DeferredComp 	//+InvestmentInc not included
		ge WAGEInterest=WAGE					//+InvestmentInc not included	
		sum PersonalIncome
	}
	else {
		ge PersonalIncome=WAGE+DeferredComp+InvestmentInc
		ge WAGEInterest=WAGE+InvestmentInc	
	}
	
	ge Transfers=ui+sab+DB
	ge DispPersonalIncome=PersonalIncome+tax
	ge TranAugDispPersonalIncome=DispPersonalIncome+Transfers

	* Sum over lifetime 
	foreach v in WAGE DeferredComp WAGEInterest ssctax ITAX CTAX tax Transfers ui sab DB TranAugDispPersonalIncome{
	bys ID: egen `v'_LT=sum(`v')
	}


	* >>> Up-shift liftime distributions by one-year gross minimum wage earnings
	if "`n'"=="PosLTEarn" {	
		replace WAGEInterest_LT = WAGEInterest_LT + 17680
		replace TranAugDispPersonalIncome_LT = TranAugDispPersonalIncome_LT + 17680
	}


	ge inc0_LT=WAGEInterest_LT
	ge inc1_LT=DeferredComp_LT
	ge inc2_LT=tax_LT
	ge inc3_LT=ui_LT 
	ge inc4_LT=sab_LT
	ge inc5_LT=DB_LT

	ge inc0=WAGEInterest
	ge inc1=DeferredComp
	ge inc2=tax
	ge inc3=ui
	ge inc4=sab
	ge inc5=DB		
	

********************************************************************************
* Adjust for wealth test 
********************************************************************************

	* social assistance without wealth adjustment
	ge di=WAGEInterest+ui+DB+tax-GCI+CTAX
	ge inc4A=max(8400-di,0)
	replace inc4A=0 if Age<(EDUC+8)
	replace inc4A=0 if ui>0
	bys ID: egen inc4A_LT=sum(inc4A)

	* social assistance with wealth adjustment (consistency check)
	ge wt=10000+500*(Age-20)
	ge maxIF=max(8400-max(Wealth-wt,0),0)
	replace maxIF=0 if ui>0
	ge saj=max(maxIF-di,0)
	replace saj=0 if Age<(EDUC+8)
	ge diff=saj-inc4
	su diff
	drop diff saj maxIF wt



********************************************************************************
* Generate skill groups
********************************************************************************
*** As simulated:
if ("`n'"=="baseline") | ("`n'"=="involsep") | ("`n'"=="scenario_D") | ("`n'"=="scenario_E") | ("`n'"=="PosLTEarn") | ("`n'"=="NoInt") {
	egen ty=group(TYPE EDUC)
}

* -----------------------------------------------------
*** Scenarios A-C:
* >>> types based on baseline scenario education
if ("`n'"=="scenario_A") | ("`n'"=="scenario_B") | ("`n'"=="scenario_C") {
	egen ty=group(TYPE EDUC_base)
}


* -----------------------------------------------------
*** Robustness scenario simulates:
if ("`n'"=="b99g75") | ("`n'"=="b98g50") | ("`n'"=="b97g50") | ("`n'"=="b99g25") | ("`n'"=="b99g75") | ("`n'"=="b98g25") | ("`n'"=="b98g75") | ("`n'"=="b97g25") | ("`n'"=="b97g75") {
	egen ty=group(TYPE EDUC)
}

  
* > Summarize types:  
sum ty


********************************************************************************
* Employment measures
********************************************************************************

	ge Enter=1 if Age>=(EDUC+8)
	replace Enter=0 if Enter==.

	* Number of unemployment spells per person 
	sort ID Age
	ge enterU=1 if l.Empl==1 & Empl==0 & Reti==0
	bys ID: egen TenterU=sum(enterU)
	replace TenterU=0 if TenterU==.

	* Length of unemloyment spells
	sort ID Age
	set seed 532
	ge Dur=uniform() if enterU==1
	replace Dur=l.Dur if l.Dur~=. & Empl==0 & Reti==0
	bys Dur: gen length=_N
	replace length=. if enterU~=1



********************************************************************************
* Health-related measures
********************************************************************************

	replace Health=1 if Enter==0
	ge BadHealth=1-Health

	
	* Number of bad health spells per person 
	sort ID Age
	ge enterH=1 if l.Health==1 & Health==0
	bys ID: egen TenterH=sum(enterH)
	replace TenterH=0 if TenterH==.
	 
	* Length of bad health spells
	sort ID Age
	ge DurH=uniform() if enterH==1
	replace DurH=l.DurH if l.DurH~=. & Health==0
	bys DurH: gen lengthH=_N
	replace lengthH=. if enterH~=1


********************************************************************************
* Generate Transfer program indicators
********************************************************************************	
	gen ClaimUI=1 if ui>0
		replace ClaimUI=0 if ClaimUI==.
	bys ID: egen NClaimUI=sum(ClaimUI)

	gen ClaimDB=1 if DB>0
		replace ClaimDB=0 if ClaimDB==.
	bys ID: egen NClaimDB=sum(ClaimDB)

	gen Claimsab=1 if sab>0 
		replace Claimsab=0 if Claimsab==.
	bys ID: egen NClaimsab=sum(Claimsab)
	*bys ID: egen msab=mean(sab)

