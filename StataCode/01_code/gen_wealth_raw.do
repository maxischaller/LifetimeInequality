** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SOEP DATA PREPARATION - GENERATE WEALTH DATA
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Script generates wealth data sample from SOEP

	
Input:
	- SOEP27: cross-sectional wealth data from 2007
	
Output files - Baseline datasets:
	> data_wealth_raw.dta 
	> data_wealth_long.dta

	
Structure:
01 	Generate Base-dataset from SOEP - ppfad / phrf
02  Pull individual information - pgen / pequiv
03  Merge all datasets
04  Transform into Panel dataset
05  Save wealth data for estimation sample

*/

clear
clear matrix
clear mata


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 01. Generate Base-dataset from SOEP - ppfad / phrf */
* ------------------------------------------------------

/* ----------------[ automatically pull PPFAD ]----------------- */
use    hhnr    persnr  sex     gebjahr psample  ///
       bahhnr  bbhhnr  bchhnr  bdhhnr  behhnr  bfhhnr  bghhnr  rhhnr   shhnr  /// 
	   thhnr   uhhnr   vhhnr   whhnr  xhhnr   yhhnr   zhhnr   ///
       banetto bbnetto bcnetto bdnetto benetto bfnetto bgnetto rnetto  snetto  ///
	   tnetto  unetto  vnetto  wnetto  xnetto  ynetto  znetto  ///
       bapop   bbpop   bcpop   bdpop   bepop   bfpop   bgpop   rpop    spop   /// 
	   tpop    upop    vpop    wpop   xpop    ypop    zpop ///
using  "${SOEP33RAW}ppfad.dta"


/* --------------[ balanced / unbalanced design ]--------------- */
keep if ( ( banetto >= 10 & banetto < 20 ) | ( bbnetto >= 10 & bbnetto < 20 ) | ///
          ( bcnetto >= 10 & bcnetto < 20 ) | ( bdnetto >= 10 & bdnetto < 20 ) | ///
		  ( benetto >= 10 & benetto < 20 ) | ( bfnetto >= 10 & bfnetto < 20 ) | ///
		  ( bgnetto >= 10 & bgnetto < 20 ) | ( tnetto >= 10 & tnetto < 20 ) | ///
          ( unetto >= 10 & unetto < 20 ) | ( vnetto >= 10 & vnetto < 20 ) | ///
          ( wnetto >= 10 & wnetto < 20 ) | ( xnetto >= 10 & xnetto < 20 ) | ///
          ( ynetto >= 10 & ynetto < 20 ) | ( znetto >= 10 & znetto < 20 ) )

		  
/* -----------------[ private housholds only.]------------------ */
keep if ( ( bapop == 1 | bapop == 2 ) | ( bbpop == 1 | bbpop == 2 ) |  ///
          ( bcpop == 1 | bcpop == 2 ) | ( bdpop == 1 | bdpop == 2 ) | ///
		  ( bepop == 1 | bepop == 2 ) | ( bfpop == 1 | bfpop == 2 ) | ///
		  ( bgpop == 1 | bgpop == 2 ) | ( tpop == 1 | tpop == 2 ) |	///
          ( upop == 1 | upop == 2 ) | ( vpop == 1 | vpop == 2 ) | ///
          ( wpop == 1 | wpop == 2 ) | ( xpop == 1 | xpop == 2 ) | ///
          ( ypop == 1 | ypop == 2 ) | ( zpop == 1 | zpop == 2 ) )

/* ----------------------[ define sample ]---------------------- */
keep if ( (psample == 1) | (psample == 2) | (psample == 3) | (psample == 4) | ///
          (psample == 5) | (psample == 6) | (psample == 8) )

		  
/* -----------------------[ sort ppfad ]------------------------ */
sort persnr
save "${TEMP_PATH}ppfad.dta", replace
clear


/* -----------------[ automatically pull PHRF ]----------------- */
use    hhnr    persnr  prgroup 	///
       baphrf  bbphrf  bcphrf  bdphrf  bephrf  bfphrf  bgphrf  rphrf   sphrf   ///
	   tphrf   uphrf   vphrf   wphrf  xphrf   yphrf   zphrf ///
using  "${SOEP33RAW}phrf.dta"

sort  persnr
save  "${TEMP_PATH}phrf.dta", replace
clear


/* --------------[ automatically create pmaster ]--------------- */
use    "${TEMP_PATH}ppfad.dta"
merge  persnr using  "${TEMP_PATH}phrf.dta"

drop   if _merge == 2
drop   _merge
erase  "${TEMP_PATH}ppfad.dta"
erase  "${TEMP_PATH}phrf.dta"
sort   persnr
save   "${TEMP_PATH}pmaster.dta", replace




* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 02. Pull individual information - pgen / pequiv */
* ---------------------------------------------------
*** NOTES: 
	* > cross sections between 2003 and 2016


/* ----------------------( pull rpequiv )----------------------- */
use    hhnr    rhhnr   persnr  ///
       y1110101 lossc01 ///
using "${SOEP33RAW}rpequiv.dta"

sort persnr
save "${TEMP_PATH}rpequiv.dta", replace
clear


/* ----------------------( pull spequiv )----------------------- */
use    hhnr    shhnr   persnr  ///
       y1110102 lossc02 ///
using "${SOEP33RAW}spequiv.dta"

sort persnr
save "${TEMP_PATH}spequiv.dta", replace
clear


/* ----------------------( pull tpequiv )----------------------- */
use    hhnr    thhnr   persnr  ///
       y1110103 lossc03 ///
using "${SOEP33RAW}tpequiv.dta"

sort persnr
save "${TEMP_PATH}tpequiv.dta", replace
clear


/* ----------------------( pull upequiv )----------------------- */
use    hhnr    uhhnr   persnr  ///
       y1110104 lossc04 ///
using "${SOEP33RAW}upequiv.dta"

sort persnr
save "${TEMP_PATH}upequiv.dta", replace
clear


/* ----------------------( pull vpequiv )----------------------- */
use    hhnr    vhhnr   persnr /// 
       y1110105 lossc05 ///
using "${SOEP33RAW}vpequiv.dta"

sort persnr
save "${TEMP_PATH}vpequiv.dta", replace
clear


/* ----------------------( pull wpequiv )----------------------- */
use    hhnr    whhnr   persnr  ///
       y1110106 lossc06 ///
using "${SOEP33RAW}wpequiv.dta"

sort persnr
save "${TEMP_PATH}wpequiv.dta", replace
clear


/* ----------------------( pull xpequiv )----------------------- */
use    hhnr    xhhnr   persnr  ///
       y1110107 lossc07 ///
using "${SOEP33RAW}xpequiv.dta"

sort persnr
save "${TEMP_PATH}xpequiv.dta", replace
clear


/* ----------------------( pull ypequiv )----------------------- */
use    hhnr    yhhnr   persnr  ///
       y1110108 lossc08 ///
using "${SOEP33RAW}ypequiv.dta"

sort persnr
save "${TEMP_PATH}ypequiv.dta", replace
clear


/* ----------------------( pull zpequiv )----------------------- */
use    hhnr    zhhnr   persnr  ///
       y1110109 lossc09  ///
using "${SOEP33RAW}zpequiv.dta"

sort persnr
save "${TEMP_PATH}zpequiv.dta", replace
clear


/* ----------------------( pull bapequiv )---------------------- */
use    hhnr    bahhnr  persnr  ///
       y1110110 lossc10 ///
using "${SOEP33RAW}bapequiv.dta"

sort persnr
save "${TEMP_PATH}bapequiv.dta", replace
clear


/* ----------------------( pull bbpequiv )---------------------- */
use    hhnr    bbhhnr  persnr  ///
       y1110111 lossc11 ///
using "${SOEP33RAW}bbpequiv.dta"

sort persnr
save "${TEMP_PATH}bbpequiv.dta", replace
clear


/* ----------------------( pull bcpequiv )---------------------- */
use    hhnr    bchhnr  persnr  ///
       y1110112 lossc12 ///
using "${SOEP33RAW}bcpequiv.dta"

sort persnr
save "${TEMP_PATH}bcpequiv.dta", replace
clear


/* ----------------------( pull bdpequiv )---------------------- */
use    hhnr    bdhhnr  persnr  ///
       y1110113 lossc13 ///
using "${SOEP33RAW}bdpequiv.dta"

sort persnr
save "${TEMP_PATH}bdpequiv.dta", replace
clear


/* ----------------------( pull bepequiv )---------------------- */
use    hhnr    behhnr  persnr  ///
       y1110114 lossc14 ///
using "${SOEP33RAW}bepequiv.dta"

sort persnr
save "${TEMP_PATH}bepequiv.dta", replace
clear


/* ----------------------( pull bfpequiv )---------------------- */
use    hhnr    bfhhnr  persnr  ///
       y1110115 lossc15 ///
using "${SOEP33RAW}bfpequiv.dta"

sort persnr
save "${TEMP_PATH}bfpequiv.dta", replace
clear


/* ----------------------( pull bgpequiv )---------------------- */
use    hhnr    bghhnr  persnr  ///
       y1110116 lossc16 ///
using "${SOEP33RAW}bgpequiv.dta"

sort persnr
save "${TEMP_PATH}bgpequiv.dta", replace
clear


/* -------------------------( pull rh )------------------------- */
use    hhnr    rhhnr   ///
       rh32    rh4202  rh5002  rh5102 ///
using "${SOEP33RAW}rh.dta"

sort rhhnr
save "${TEMP_PATH}rh.dta", replace
clear


/* -------------------------( pull sh )------------------------- */
use    hhnr    shhnr   ///
       sh32    sh4202  sh5002  sh5102 ///
using "${SOEP33RAW}sh.dta"

sort shhnr
save "${TEMP_PATH}sh.dta", replace
clear


/* -------------------------( pull th )------------------------- */
use    hhnr    thhnr  /// 
       th30    th4002  th4902  th5002 ///
using "${SOEP33RAW}th.dta"

sort thhnr
save "${TEMP_PATH}th.dta", replace
clear


/* -------------------------( pull uh )------------------------- */
use    hhnr    uhhnr   ///
       uh30    uh4002  uh4902  uh5002 ///
using "${SOEP33RAW}uh.dta"

sort uhhnr
save "${TEMP_PATH}uh.dta", replace
clear


/* -------------------------( pull vh )------------------------- */
use    hhnr    vhhnr   ///
       vh29    vh3902  vh42    vh5202 ///
using "${SOEP33RAW}vh.dta"

sort vhhnr
save "${TEMP_PATH}vh.dta", replace
clear


/* -------------------------( pull wh )------------------------- */
use    hhnr    whhnr   ///
       wh29    wh3902  wh42    wh5202 ///
using "${SOEP33RAW}wh.dta"

sort whhnr
save "${TEMP_PATH}wh.dta", replace
clear


/* -------------------------( pull xh )------------------------- */
use    hhnr    xhhnr   ///
       xh29    xh3902  xh42    xh5202 ///
using "${SOEP33RAW}xh.dta"

sort xhhnr
save "${TEMP_PATH}xh.dta", replace
clear


/* -------------------------( pull yh )------------------------- */
use    hhnr    yhhnr   ///
       yh30    yh4002  yh43    yh5302 ///
using "${SOEP33RAW}yh.dta"

sort yhhnr
save "${TEMP_PATH}yh.dta", replace
clear


/* -------------------------( pull zh )------------------------- */
use    hhnr    zhhnr   ///
       zh30    zh4002  zh43    zh5302 ///
using "${SOEP33RAW}zh.dta"

sort zhhnr
save "${TEMP_PATH}zh.dta", replace
clear


/* ------------------------( pull bah )------------------------- */
use    hhnr    bahhnr  ///
       bah30   bah4002 bah43   bah5402 ///
using "${SOEP33RAW}bah.dta"

sort bahhnr
save "${TEMP_PATH}bah.dta", replace
clear


/* ------------------------( pull bbh )------------------------- */
use    hhnr    bbhhnr  ///
       bbh30   bbh4002 bbh43   bbh5202 ///
using "${SOEP33RAW}bbh.dta"

sort bbhhnr
save "${TEMP_PATH}bbh.dta", replace
clear


/* ------------------------( pull bch )------------------------- */
use    hhnr    bchhnr  ///
       bch30   bch4002 bch43   bch5202 ///
using "${SOEP33RAW}bch.dta"

sort bchhnr
save "${TEMP_PATH}bch.dta", replace
clear


/* ------------------------( pull bdh )------------------------- */
use    hhnr    bdhhnr  ///
       bdh30   bdh4002 bdh43   bdh5202 ///
using "${SOEP33RAW}bdh.dta"

sort bdhhnr
save "${TEMP_PATH}bdh.dta", replace
clear


/* ------------------------( pull beh )------------------------- */
use    hhnr    behhnr  ///
       beh32   beh4302 beh46   beh5502 ///
using "${SOEP33RAW}beh.dta"

sort behhnr
save "${TEMP_PATH}beh.dta", replace
clear


/* ------------------------( pull bfh )------------------------- */
use    hhnr    bfhhnr  ///
       bfh25   bfh3902 bfh42   bfh5005 ///
using "${SOEP33RAW}bfh.dta"

sort bfhhnr
save "${TEMP_PATH}bfh.dta", replace
clear


/* ------------------------( pull bgh )------------------------- */
use    hhnr    bghhnr  ///
       bgh17   bgh50 bgh54   bgh6905 ///
using "${SOEP33RAW}bgh.dta"

sort bghhnr
save "${TEMP_PATH}bgh.dta", replace
clear



* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 03. Merge all datasets */
* --------------------------

use   "${TEMP_PATH}pmaster.dta"
erase "${TEMP_PATH}pmaster.dta"

/* -----------( merge together by person: ALL Waves )----------- */

/* ----------------------( merge RPEQUIV )---------------------- */       
sort  persnr
merge persnr using "${TEMP_PATH}rpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}rpequiv.dta"


/* ----------------------( merge SPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}spequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}spequiv.dta"


/* ----------------------( merge TPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}tpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}tpequiv.dta"


/* ----------------------( merge UPEQUIV )---------------------- */          
sort  persnr
merge persnr using "${TEMP_PATH}upequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}upequiv.dta"


/* ----------------------( merge VPEQUIV )---------------------- */          
sort  persnr
merge persnr using "${TEMP_PATH}vpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}vpequiv.dta"


/* ----------------------( merge WPEQUIV )---------------------- */          
sort  persnr
merge persnr using "${TEMP_PATH}wpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}wpequiv.dta"


/* ----------------------( merge XPEQUIV )---------------------- */          
sort  persnr
merge persnr using "${TEMP_PATH}xpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}xpequiv.dta"


/* ----------------------( merge YPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}ypequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}ypequiv.dta"


/* ----------------------( merge ZPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}zpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}zpequiv.dta"


/* ---------------------( merge BAPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}bapequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bapequiv.dta"


/* ---------------------( merge BBPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}bbpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bbpequiv.dta"


/* ---------------------( merge BCPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}bcpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bcpequiv.dta"


/* ---------------------( merge BDPEQUIV )---------------------- */          
sort  persnr
merge persnr using "${TEMP_PATH}bdpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bdpequiv.dta"


/* ---------------------( merge BEPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}bepequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bepequiv.dta"


/* ---------------------( merge BFPEQUIV )---------------------- */         
sort  persnr
merge persnr using "${TEMP_PATH}bfpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bfpequiv.dta"


/* ---------------------( merge BGPEQUIV )---------------------- */          
sort  persnr
merge persnr using "${TEMP_PATH}bgpequiv.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bgpequiv.dta"



/* ------------------------------------------------------------- */
/* ------------------------------------------------------------- */
/* -----------( merge together by household: Wave R)------------ */

/* ------------------------( merge RH )------------------------- */
sort  rhhnr
merge rhhnr using "${TEMP_PATH}rh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}rh.dta"


/* -----------( merge together by household: Wave S)------------ */

/* ------------------------( merge SH )------------------------- */
sort  shhnr
merge shhnr using "${TEMP_PATH}sh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}sh.dta"


/* -----------( merge together by household: Wave T)------------ */

/* ------------------------( merge TH )------------------------- */
sort  thhnr
merge thhnr using "${TEMP_PATH}th.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}th.dta"


/* -----------( merge together by household: Wave U)------------ */

/* ------------------------( merge UH )------------------------- */
sort  uhhnr
merge uhhnr using "${TEMP_PATH}uh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}uh.dta"


/* -----------( merge together by household: Wave V)------------ */

/* ------------------------( merge VH )------------------------- */
sort  vhhnr
merge vhhnr using "${TEMP_PATH}vh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}vh.dta"


/* -----------( merge together by household: Wave W)------------ */

/* ------------------------( merge WH )------------------------- */
sort  whhnr
merge whhnr using "${TEMP_PATH}wh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}wh.dta"


/* -----------( merge together by household: Wave X)------------ */

/* ------------------------( merge XH )------------------------- */
sort  xhhnr
merge xhhnr using "${TEMP_PATH}xh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}xh.dta"


/* -----------( merge together by household: Wave Y)------------ */

/* ------------------------( merge YH )------------------------- */
sort  yhhnr
merge yhhnr using "${TEMP_PATH}yh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}yh.dta"


/* -----------( merge together by household: Wave Z)------------ */

/* ------------------------( merge ZH )------------------------- */
sort  zhhnr
merge zhhnr using "${TEMP_PATH}zh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}zh.dta"


/* -----------( merge together by household: Wave BA)----------- */

/* ------------------------( merge BAH )------------------------ */
sort  bahhnr
merge bahhnr using "${TEMP_PATH}bah.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bah.dta"


/* -----------( merge together by household: Wave BB)----------- */

/* ------------------------( merge BBH )------------------------ */
sort  bbhhnr
merge bbhhnr using "${TEMP_PATH}bbh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bbh.dta"


/* -----------( merge together by household: Wave BC)----------- */

/* ------------------------( merge BCH )------------------------ */
sort  bchhnr
merge bchhnr using "${TEMP_PATH}bch.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bch.dta"


/* -----------( merge together by household: Wave BD)----------- */

/* ------------------------( merge BDH )------------------------ */
sort  bdhhnr
merge bdhhnr using "${TEMP_PATH}bdh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bdh.dta"


/* -----------( merge together by household: Wave BE)----------- */

/* ------------------------( merge BEH )------------------------ */
sort  behhnr
merge behhnr using "${TEMP_PATH}beh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}beh.dta"


/* -----------( merge together by household: Wave BF)----------- */

/* ------------------------( merge BFH )------------------------ */
sort  bfhhnr
merge bfhhnr using "${TEMP_PATH}bfh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bfh.dta"


/* -----------( merge together by household: Wave BG)----------- */

/* ------------------------( merge BGH )------------------------ */
sort  bghhnr
merge bghhnr using "${TEMP_PATH}bgh.dta"
drop   if _merge == 2
drop   _merge
erase "${TEMP_PATH}bgh.dta"


/* --------------------------( done! )-------------------------- */
label data "SOEPINFO: Magic at Work! http://panel.gsoep.de/soepinfo/"
save  "${TEMP_PATH}data_wealth_raw.dta", replace
desc




* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 04. Transform into Panel dataset */
* ------------------------------------

	
clear

use "${TEMP_PATH}data_wealth_raw.dta", clear	
	
	
drop ?hhnr ?pop ?netto ?phrf psample prgroup baphrf bapop bahhnr banetto

local z = 2001
foreach y in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 {
	foreach w in y11101 lossc {
		foreach x in `w'`y' {
			rename `x' `w'`z'
		}
	}
	local z = `z' + 1
}

rename rh32 loans12001 
rename rh4202 loans22001
rename rh5002 loans32001
rename rh5102 finsav2001

rename sh32 loans12002
rename sh4202 loans22002
rename sh5002 loans32002
rename sh5102 finsav2002

rename th30 loans12003
rename th4002 loans22003
rename th4902 loans32003
rename th5002 finsav2003

rename uh30 loans12004
rename uh4002 loans22004
rename uh4902 loans32004
rename uh5002 finsav2004

rename vh29 loans12005
rename vh3902 loans22005
rename vh42 loans32005
rename vh5202 finsav2005

rename wh29 loans12006
rename wh3902 loans22006
rename wh42 loans32006
rename wh5202 finsav2006

rename xh29 loans12007
rename xh3902 loans22007
rename xh42 loans32007
rename xh5202 finsav2007

rename yh30 loans12008
rename yh4002 loans22008
rename yh43 loans32008
rename yh5302 finsav2008

rename zh30 loans12009
rename zh4002 loans22009
rename zh43 loans32009
rename zh5302 finsav2009

rename bah30 loans12010
rename bah4002 loans22010
rename bah43 loans32010
rename bah5402 finsav2010

rename bbh30 loans12011
rename bbh4002 loans22011
rename bbh43 loans32011
rename bbh5202 finsav2011

rename bch30 loans12012
rename bch4002 loans22012
rename bch43 loans32012
rename bch5202 finsav2012

rename bdh30 loans12013
rename bdh4002 loans22013
rename bdh43 loans32013
rename bdh5202 finsav2013

rename beh32 loans12014
rename beh4302 loans22014
rename beh46 loans32014
rename beh5502 finsav2014

rename bfh25 loans12015
rename bfh3902 loans22015
rename bfh42 loans32015
rename bfh5005 finsav2015

rename bgh17 loans12016
rename bgh50 loans22016
rename bgh54 loans32016
rename bgh6905 finsav2016

reshape long loans1@ loans2@ loans3@ finsav@ y11101@ lossc@, i(persnr) j(svyyear) string

rename y11101 cpi

destring svyyear, replace

xtset persnr svyyear

recode finsav loans1 loans2 loans3 (-3=.) (-2=0) (-1=.)

drop if loans1==. | loans2==. | loans3==. | finsav==. | cpi==. | lossc==.

replace loans1 = loans1 * 12

replace loans3 = loans3 * 12

replace finsav = finsav * 12



/* --------------------------( save panel dataset )-------------------------- */
	save "${TEMP_PATH}data_wealth_long.dta", replace



* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 04. Transform Wealth Data - Imputation */
* -----------------------------------------

	use "${TEMP_PATH}data_wealth_long.dta", clear

	sort persnr svyyear
	merge m:m persnr svyyear using "${SOEP27RAW}pwealth.dta"
	tab _merge
	keep if _merge == 1 | _merge == 3
	drop _merge


	gen grwealth = ((    e0100b + e0100c + e0100d + e0100e + f0100a + f0100b + f0100c + f0100d + f0100e + i0100a + i0100b + i0100c + i0100d + i0100e + b0100a + b0100b + b0100c + b0100d + b0100e + t0100a + t0100b + t0100c + t0100d + t0100e) / 5)
				  /* p0100a + p0100b + p0100c + p0100d + p0100e + e0100a + */

			
	gen debts1 = ((p0010a + p0010b + p0010c + p0010d + p0010e) / 5)
		replace debts1=0
	gen debts2 = ((e0010a + e0010b + e0010c + e0010d + e0010e) / 5)
	gen debts3 = ((c0100a + c0100b + c0100c + c0100d + c0100e) / 5)


	keep persnr svyyear hhnr sex gebjahr finsav loans1 loans2 loans3 grwealth debts1 debts2 debts3 cpi lossc

	replace finsav = finsav * (106.9/cpi)
	replace grwealth = grwealth * (106.9/cpi)
	replace debts1 = debts1 * (106.9/cpi)
	replace debts2 = debts2 * (106.9/cpi)
	replace debts3 = debts3 * (106.9/cpi)

	gen netwealth = grwealth - debts1 - debts2 - debts3

	gen impwealth = netwealth if svyyear == 2007
	gen impdebts1 = debts1    if svyyear == 2007
	gen impdebts2 = debts2    if svyyear == 2007
	gen impdebts3 = debts3    if svyyear == 2007

	sum _all

	sort persnr svyyear
	save "${TEMP_PATH}wealth_temp.dta", replace

	keep if impwealth != . & svyyear == 2007
		sum _all

	keep persnr impwealth impdebts1 impdebts2 impdebts3
		
	sort persnr
	merge 1:m persnr using "${TEMP_PATH}wealth_temp.dta" 
	keep if _merge == 3
	drop _merge


*********************************************************************************
* >>> baseline data panel
	sort persnr svyyear
	merge m:m persnr svyyear using "${TEMP_PATH}data_base_long.dta" // 1:1 merge for equivalent result
	keep if _merge == 3
	drop _merge


/* recode and rename variables */
	recode ioldy tatzeit   (-1=.) (-3=.) 
	recode tatzeit (-2=0)	

				
/* generate variables */
	xtset persnr svyyear

	gen age = svyyear-gebjahr
			
	gen pensioner = (ioldy > 0 & ioldy < .)
		replace pensioner = . if ioldy == .

	gen work = ((tatzeit >= 20 & tatzeit <.) & pensioner == 0)
		replace work = . if tatzeit == . | pensioner == .
	
/* generate lagged variables */
	gen wl = l.work
	gen wl2 = l2.work


********************************************************************************
*** imputed wealth information
	xtset persnr svyyear
	
	gen totsav = finsav

	gen wealth_test = 10000 + 500*(age-20) // age-specific disregard
		preserve
			collapse (mean) wealth_test, by(age)
			list
		restore
	
	gen wealth_test_checklag =  l.impwealth-l.wealth_test
	
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2008 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2008 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2008 & wl == 0 & wl2 == 0
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2009 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2009 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2009 & wl == 0 & wl2 == 0
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2010 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2010 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2010 & wl == 0 & wl2 == 0			
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2011 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2011 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2011 & wl == 0 & wl2 == 0
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2012 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2012 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2012 & wl == 0 & wl2 == 0
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2013 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2013 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2013 & wl == 0 & wl2 == 0
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2014 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2014 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2014 & wl == 0 & wl2 == 0			
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2015 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2015 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2015 & wl == 0 & wl2 == 0
	replace impwealth = (l.impwealth + l.totsav - lossc)                                      			* 1.01 if svyyear == 2016 & wl == 1
	replace impwealth = (l.impwealth            - lossc)                                      			* 1.01 if svyyear == 2016 & wl == 0 & wl2 == 1
	replace impwealth = (l.impwealth            - lossc - max(0,min(8400,l.impwealth-l.wealth_test))) 	* 1.01 if svyyear == 2016 & wl == 0 & wl2 == 0			
	

	replace impwealth = f.impwealth / 1.01 - totsav + f.lossc        		if svyyear == 2006 & work == 1
	replace impwealth = f.impwealth / 1.01          + f.lossc        		if svyyear == 2006 & work == 0
	replace impwealth = impwealth + max(0,min(8400,impwealth-wealth_test))  if svyyear == 2006 & work == 0 & wl == 0
	replace impwealth = f.impwealth / 1.01 - totsav + f.lossc        		if svyyear == 2005 & work == 1
	replace impwealth = f.impwealth / 1.01          + f.lossc        		if svyyear == 2005 & work == 0
	replace impwealth = impwealth + max(0,min(8400,impwealth-wealth_test))  if svyyear == 2005 & work == 0 & wl == 0
	replace impwealth = f.impwealth / 1.01 - totsav + f.lossc        		if svyyear == 2004 & work == 1
	replace impwealth = f.impwealth / 1.01          + f.lossc        		if svyyear == 2004 & work == 0
	replace impwealth = impwealth + max(0,min(8400,impwealth-wealth_test))  if svyyear == 2004 & work == 0 & wl == 0
	replace impwealth = f.impwealth / 1.01 - totsav + f.lossc        		if svyyear == 2003 & work == 1
	replace impwealth = f.impwealth / 1.01          + f.lossc        		if svyyear == 2003 & work == 0
	replace impwealth = impwealth + max(0,min(8400,impwealth-wealth_test))  if svyyear == 2003 & work == 0 & wl == 0			
	
	
	sum impwealth
	
	
	
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 05. Prepare Wealth Data for Estimation Sample */
* ------------------------------------------------	
	
/* ----- keep non-missing ----- */				
	drop if impwealth == . | totsav == .
	
/* ---------( save )------------- */	
	keep persnr svyyear totsav impwealth netwealth  

	compress

	save "${TEMP_PATH}data_wealth.dta", replace
