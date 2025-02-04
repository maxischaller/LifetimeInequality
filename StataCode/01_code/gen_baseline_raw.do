** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
** LIFECYCLE INEQUALITY -- SOEP DATA PREPARATION - GENERATE BASELINE PANEL
** ----------------------------------------------------------------------------
** ----------------------------------------------------------------------------
/*
Notes:
	- Script generates baseline sample from SOEP

	
Input:
	- SOEP33 "raw" datasets (cross-sections)
	
Output files - Baseline datasets:
	> data_base_raw.dta 
	> data_base_long.dta

Structure:
01 	Generate Base-dataset from SOEP - ppfad / phrf
02     Pull individual information - pgen / pequiv
03     Merge all datasets
04     Transform into Panel dataset

*/

clear
clear matrix
clear mata


#delimit;

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
/* 01. Generate Base-dataset from SOEP - ppfad / phrf */;
* ------------------------------------------------------;


/* ----------------[ automatically pull PPFAD ]----------------- */;
use    hhnr    persnr  sex     gebjahr psample 
       bahhnr  bbhhnr  bchhnr  bdhhnr  behhnr  bfhhnr  bghhnr  thhnr  uhhnr   
	   vhhnr   whhnr   xhhnr   yhhnr  zhhnr   
       banetto bbnetto bcnetto bdnetto benetto bfnetto bgnetto tnetto  unetto  
	   vnetto  wnetto  xnetto  ynetto  znetto  
       bapop   bbpop   bcpop   bdpop   bepop   bfpop   bgpop   tpop    upop    
	   vpop    wpop    xpop    ypop   zpop
using  "${SOEP33RAW}ppfad.dta";


/* --------------[ balanced / unbalanced design ]--------------- */;
keep if ( ( banetto >= 10 & banetto < 20 ) | ( bbnetto >= 10 & bbnetto < 20 ) | 
          ( bcnetto >= 10 & bcnetto < 20 ) | ( bdnetto >= 10 & bdnetto < 20 ) | 
		  ( benetto >= 10 & benetto < 20 ) | ( bfnetto >= 10 & bfnetto < 20 ) | 
		  ( bgnetto >= 10 & bgnetto < 20 ) | ( tnetto >= 10 & tnetto < 20 ) | 
          ( unetto >= 10 & unetto < 20 ) | ( vnetto >= 10 & vnetto < 20 ) | 
          ( wnetto >= 10 & wnetto < 20 ) | ( xnetto >= 10 & xnetto < 20 ) | 
          ( ynetto >= 10 & ynetto < 20 ) | ( znetto >= 10 & znetto < 20 ) );

		  
/* -----------------[ private housholds only.]------------------ */;
keep if ( ( bapop == 1 | bapop == 2 ) | ( bbpop == 1 | bbpop == 2 ) |
          ( bcpop == 1 | bcpop == 2 ) | ( bdpop == 1 | bdpop == 2 ) | 
		  ( bepop == 1 | bepop == 2 ) | ( bfpop == 1 | bfpop == 2 ) | 
		  ( bgpop == 1 | bgpop == 2 ) | ( tpop == 1 | tpop == 2 ) |
          ( upop == 1 | upop == 2 ) | ( vpop == 1 | vpop == 2 ) |
          ( wpop == 1 | wpop == 2 ) | ( xpop == 1 | xpop == 2 ) |
          ( ypop == 1 | ypop == 2 ) | ( zpop == 1 | zpop == 2 ) );

		  
/* ----------------------[ define sample ]---------------------- */;
keep if ( (psample == 1) | (psample == 2) | (psample == 3) | (psample == 4) |
          (psample == 5) | (psample == 6) | (psample == 8) );

		  	  
/* -----------------------[ sort ppfad ]------------------------ */;
sort persnr;
save "${TEMP_PATH}ppfad.dta", replace;
clear;


/* -----------------[ automatically pull PHRF ]----------------- */;
use    hhnr    persnr  prgroup 
       baphrf  bbphrf  bcphrf  bdphrf  bephrf  bfphrf  bgphrf  tphrf   uphrf   
	   vphrf   wphrf   xphrf   yphrf  zphrf
using  "${SOEP33RAW}phrf.dta";

sort  persnr;
save  "${TEMP_PATH}phrf.dta", replace;
clear;


/* --------------[ automatically create pmaster ]--------------- */;
use    "${TEMP_PATH}ppfad.dta";
merge  persnr
using  "${TEMP_PATH}phrf.dta";

drop   if _merge == 2;
drop   _merge;
erase  "${TEMP_PATH}ppfad.dta";
erase  "${TEMP_PATH}phrf.dta";
sort   persnr;
save   "${TEMP_PATH}pmaster.dta", replace;





* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
/* 02. Pull individual information - pgen / pequiv */;
* ---------------------------------------------------;
*** NOTES: 
	* > cross sections between 2003 and 2016


/* -----------------------( pull tpgen )------------------------ */;
use    hhnr    thhnr   persnr  
       partz03 partnr03 tbilzeit ttatzeit tvebzeit tuebstd lfs03  
       casmin03 stib03	labgro03 emplst03 expft03 exppt03 isced97_03 jobend03
using "${SOEP33RAW}tpgen.dta";

sort persnr;
save "${TEMP_PATH}tpgen.dta", replace;
clear;


/* ----------------------( pull tpequiv )----------------------- */;
use    hhnr    thhnr   persnr  
       d1110503 d1110703 d1110903 e1110103 e1110203 e1110303 e1110403 e1110503
       i1110103 i1110203 i1110303 i1111003 y1110103 l1110103 iself03 ioldy03
       m1112403 m1112603 iunby03 iunay03
using "${SOEP33RAW}tpequiv.dta";

sort persnr;
save "${TEMP_PATH}tpequiv.dta", replace;
clear;


/* -----------------------( pull upgen )------------------------ */;
use    hhnr    uhhnr   persnr  
       partz04 partnr04 ubilzeit utatzeit uvebzeit uuebstd lfs04  
       casmin04 stib04	labgro04 emplst04 expft04 exppt04 isced97_04 jobend04
using "${SOEP33RAW}upgen.dta";

sort persnr;
save "${TEMP_PATH}upgen.dta", replace;
clear;


/* ----------------------( pull upequiv )----------------------- */;
use    hhnr    uhhnr   persnr  
       d1110504 d1110704 d1110904 e1110104 e1110204 e1110304 e1110404 e1110504
       i1110104 i1110204 i1110304 i1111004 y1110104 l1110104 iself04 ioldy04
       m1112404 m1112604 iunby04 iunay04
using "${SOEP33RAW}upequiv.dta";

sort persnr;
save "${TEMP_PATH}upequiv.dta", replace;
clear;


/* -----------------------( pull vpgen )------------------------ */;
use    hhnr    vhhnr   persnr  
       partz05 partnr05 vbilzeit vtatzeit vvebzeit vuebstd lfs05  
       casmin05 stib05	labgro05 emplst05 expft05 exppt05 isced97_05 jobend05
using "${SOEP33RAW}vpgen.dta";

sort persnr;
save "${TEMP_PATH}vpgen.dta", replace;
clear;


/* ----------------------( pull vpequiv )----------------------- */;
use    hhnr    vhhnr   persnr  
       d1110505 d1110705 d1110905 e1110105 e1110205 e1110305 e1110405 e1110505
       i1110105 i1110205 i1110305 i1111005 y1110105 l1110105 iself05 ioldy05
       m1112405 m1112605 iunby05 iunay05
using "${SOEP33RAW}vpequiv.dta";

sort persnr;
save "${TEMP_PATH}vpequiv.dta", replace;
clear;


/* -----------------------( pull wpgen )------------------------ */;
use    hhnr    whhnr   persnr  
       partz06 partnr06 wbilzeit wtatzeit wvebzeit wuebstd lfs06  
       casmin06 stib06	labgro06 emplst06 expft06 exppt06 isced97_06 jobend06
using "${SOEP33RAW}wpgen.dta";

sort persnr;
save "${TEMP_PATH}wpgen.dta", replace;
clear;


/* ----------------------( pull wpequiv )----------------------- */;
use    hhnr    whhnr   persnr  
       d1110506 d1110706 d1110906 e1110106 e1110206 e1110306 e1110406 e1110506
       i1110106 i1110206 i1110306 i1111006 y1110106 l1110106 iself06 ioldy06
       m1112406 m1112606 iunby06 iunay06
using "${SOEP33RAW}wpequiv.dta";

sort persnr;
save "${TEMP_PATH}wpequiv.dta", replace;
clear;


/* -----------------------( pull xpgen )------------------------ */;
use    hhnr    xhhnr   persnr  
       partz07 partnr07 xbilzeit xtatzeit xvebzeit xuebstd lfs07  
       casmin07 stib07	labgro07 emplst07 expft07 exppt07 isced97_07 jobend07
using "${SOEP33RAW}xpgen.dta";

sort persnr;
save "${TEMP_PATH}xpgen.dta", replace;
clear;


/* ----------------------( pull xpequiv )----------------------- */;
use    hhnr    xhhnr   persnr  
       d1110507 d1110707 d1110907 e1110107 e1110207 e1110307 e1110407 e1110507
       i1110107 i1110207 i1110307 i1111007 y1110107 l1110107 iself07 ioldy07
       m1112407 m1112607 iunby07 iunay07
using "${SOEP33RAW}xpequiv.dta";

sort persnr;
save "${TEMP_PATH}xpequiv.dta", replace;
clear;


/* -----------------------( pull ypgen )------------------------ */;
use    hhnr    yhhnr   persnr  
       partz08 partnr08 ybilzeit ytatzeit yvebzeit yuebstd lfs08  
       casmin08 stib08	labgro08 emplst08 expft08 exppt08 isced97_08 jobend08
using "${SOEP33RAW}ypgen.dta";

sort persnr;
save "${TEMP_PATH}ypgen.dta", replace;
clear;


/* ----------------------( pull ypequiv )----------------------- */;
use    hhnr    yhhnr   persnr  
       d1110508 d1110708 d1110908 e1110108 e1110208 e1110308 e1110408 e1110508
       i1110108 i1110208 i1110308 i1111008 y1110108 l1110108 iself08 ioldy08
       m1112408 m1112608 iunby08 iunay08
using "${SOEP33RAW}ypequiv.dta";

sort persnr;
save "${TEMP_PATH}ypequiv.dta", replace;
clear;


/* ----------------------( pull zpequiv )----------------------- */;
use    hhnr    zhhnr   persnr  
       d1110509 d1110709 d1110909 e1110109 e1110209 e1110309 e1110409 e1110509
       i1110109 i1110209 i1110309 i1111009 y1110109 l1110109 iself09 ioldy09
       m1112409 m1112609 iunby09 iunay09
using "${SOEP33RAW}zpequiv.dta";

sort persnr;
save "${TEMP_PATH}zpequiv.dta", replace;
clear;


/* -----------------------( pull zpgen )------------------------ */;
use    hhnr    zhhnr   persnr  
       partz09 partnr09 zbilzeit ztatzeit zvebzeit zuebstd lfs09  
       casmin09 stib09	labgro09 emplst09 expft09 exppt09 isced97_09 jobend09
using "${SOEP33RAW}zpgen.dta";

sort persnr;
save "${TEMP_PATH}zpgen.dta", replace;
clear;


/* ----------------------( pull bapequiv )---------------------- */;
use    hhnr    bahhnr  persnr  
       d1110510 d1110710 d1110910 e1110110 e1110210 e1110310 e1110410 e1110510
       i1110110 i1110210 i1110310 i1111010 y1110110 l1110110 iself10 ioldy10
       m1112410 m1112610 iunby10 iunay10
using "${SOEP33RAW}bapequiv.dta";

sort persnr;
save "${TEMP_PATH}bapequiv.dta", replace;
clear;


/* -----------------------( pull bapgen )----------------------- */;
use    hhnr    bahhnr  persnr  
       partz10 partnr10 babilzeit batatzeit bavebzeit bauebstd lfs10  
       casmin10 stib10	labgro10 emplst10 expft10 exppt10 isced97_10 jobend10
using "${SOEP33RAW}bapgen.dta";

sort persnr;
save "${TEMP_PATH}bapgen.dta", replace;
clear;


/* ----------------------( pull bbpequiv )---------------------- */;
use    hhnr    bbhhnr  persnr  
       d1110511 d1110711 d1110911 e1110111 e1110211 e1110311 e1110411 e1110511
       i1110111 i1110211 i1110311 i1111011 y1110111 l1110111 iself11 ioldy11
       m1112411 m1112611 iunby11 iunay11
using "${SOEP33RAW}bbpequiv.dta";

sort persnr;
save "${TEMP_PATH}bbpequiv.dta", replace;
clear;


/* -----------------------( pull bbpgen )----------------------- */;
use    hhnr    bbhhnr  persnr  
       partz11 partnr11 bbbilzeit bbtatzeit bbvebzeit bbuebstd lfs11  
       casmin11 stib11	labgro11 emplst11 expft11 exppt11 isced97_11 jobend11
using "${SOEP33RAW}bbpgen.dta";

sort persnr;
save "${TEMP_PATH}bbpgen.dta", replace;
clear;


/* ----------------------( pull bcpequiv )---------------------- */;
use    hhnr    bchhnr  persnr  
       d1110512 d1110712 d1110912 e1110112 e1110212 e1110312 e1110412 e1110512
       i1110112 i1110212 i1110312 i1111012 y1110112 l1110112 iself12 ioldy12
       m1112412 m1112612 iunby12 iunay12
using "${SOEP33RAW}bcpequiv.dta";

sort persnr;
save "${TEMP_PATH}bcpequiv.dta", replace;
clear;


/* -----------------------( pull bcpgen )----------------------- */;
use    hhnr    bchhnr  persnr  
       partz12 partnr12 bcbilzeit bctatzeit bcvebzeit bcuebstd lfs12  
       casmin12 stib12	labgro12 emplst12 expft12 exppt12 isced97_12 jobend12
using "${SOEP33RAW}bcpgen.dta";

sort persnr;
save "${TEMP_PATH}bcpgen.dta", replace;
clear;


/* ----------------------( pull bdpequiv )---------------------- */;
use    hhnr    bdhhnr  persnr  
       d1110513 d1110713 d1110913 e1110113 e1110213 e1110313 e1110413 e1110513
       i1110113 i1110213 i1110313 i1111013 y1110113 l1110113 iself13 ioldy13
       m1112413 m1112613 iunby13 iunay13
using "${SOEP33RAW}bdpequiv.dta";

sort persnr;
save "${TEMP_PATH}bdpequiv.dta", replace;
clear;


/* -----------------------( pull bdpgen )----------------------- */;
use    hhnr    bdhhnr  persnr  
       partz13 partnr13 bdbilzeit bdtatzeit bdvebzeit bduebstd lfs13  
       casmin13 stib13	labgro13 emplst13 expft13 exppt13 isced97_13 jobend13
using "${SOEP33RAW}bdpgen.dta";

sort persnr;
save "${TEMP_PATH}bdpgen.dta", replace;
clear;


/* ----------------------( pull bepequiv )---------------------- */;
use    hhnr    behhnr  persnr  
       d1110514 d1110714 d1110914 e1110114 e1110214 e1110314 e1110414 e1110514
       i1110114 i1110214 i1110314 i1111014 y1110114 l1110114 iself14 ioldy14
       m1112414 m1112614 iunby14 iunay14
using "${SOEP33RAW}bepequiv.dta";

sort persnr;
save "${TEMP_PATH}bepequiv.dta", replace;
clear;


/* -----------------------( pull bepgen )----------------------- */;
use    hhnr    behhnr  persnr  
       partz14 partnr14 bebilzeit betatzeit bevebzeit beuebstd lfs14  
       casmin14 stib14	labgro14 emplst14 expft14 exppt14 isced97_14 jobend14
using "${SOEP33RAW}bepgen.dta";

sort persnr;
save "${TEMP_PATH}bepgen.dta", replace;
clear;


/* ----------------------( pull bfpequiv )---------------------- */;
use    hhnr    bfhhnr  persnr  
       d1110515 d1110715 d1110915 e1110115 e1110215 e1110315 e1110415 e1110515
       i1110115 i1110215 i1110315 i1111015 y1110115 l1110115 iself15 ioldy15
       m1112415 m1112615 iunby15 iunay15
using "${SOEP33RAW}bfpequiv.dta";

sort persnr;
save "${TEMP_PATH}bfpequiv.dta", replace;
clear;


/* -----------------------( pull bfpgen )----------------------- */;
use    hhnr    bfhhnr  persnr  
       partz15 partnr15 bfbilzeit bftatzeit bfvebzeit bfuebstd lfs15  
       casmin15 stib15	labgro15 emplst15 expft15 exppt15 isced97_15 jobend15
using "${SOEP33RAW}bfpgen.dta";

sort persnr;
save "${TEMP_PATH}bfpgen.dta", replace;
clear;


/* ----------------------( pull bgpequiv )---------------------- */;
use    hhnr    bghhnr  persnr  
       d1110516 d1110716 d1110916 e1110116 e1110216 e1110316 e1110416 e1110516
       i1110116 i1110216 i1110316 i1111016 y1110116 l1110116 iself16 ioldy16
       m1112416 m1112616 iunby16 iunay16
using "${SOEP33RAW}bgpequiv.dta";

sort persnr;
save "${TEMP_PATH}bgpequiv.dta", replace;
clear;


/* -----------------------( pull bgpgen )----------------------- */;
use    hhnr    bghhnr  persnr  
       partz16 partnr16 bgbilzeit bgtatzeit bgvebzeit bguebstd lfs16  
       casmin16 stib16	labgro16 emplst16 expft16 exppt16 isced97_16 jobend16
using "${SOEP33RAW}bgpgen.dta";

sort persnr;
save "${TEMP_PATH}bgpgen.dta", replace;
clear;




* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;
/* 03. Merge all datasets */;
* --------------------------;

use   "${TEMP_PATH}pmaster.dta";
erase "${TEMP_PATH}pmaster.dta";

/* -----------( merge together by person: ALL Waves )----------- */;

/* -----------------------( merge TPGEN )----------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}tpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}tpgen.dta";


/* ----------------------( merge TPEQUIV )---------------------- */;     
sort  persnr;
merge persnr
using "${TEMP_PATH}tpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}tpequiv.dta";


/* -----------------------( merge UPGEN )----------------------- */;        
sort  persnr;
merge persnr
using "${TEMP_PATH}upgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}upgen.dta";


/* ----------------------( merge UPEQUIV )---------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}upequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}upequiv.dta";


/* -----------------------( merge VPGEN )----------------------- */;       
sort  persnr;
merge persnr
using "${TEMP_PATH}vpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}vpgen.dta";


/* ----------------------( merge VPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}vpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}vpequiv.dta";


/* -----------------------( merge WPGEN )----------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}wpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}wpgen.dta";


/* ----------------------( merge WPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}wpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}wpequiv.dta";


/* -----------------------( merge XPGEN )----------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}xpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}xpgen.dta";


/* ----------------------( merge XPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}xpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}xpequiv.dta";


/* -----------------------( merge YPGEN )----------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}ypgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}ypgen.dta";


/* ----------------------( merge YPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}ypequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}ypequiv.dta";


/* ----------------------( merge ZPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}zpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}zpequiv.dta";


/* -----------------------( merge ZPGEN )----------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}zpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}zpgen.dta";


/* ---------------------( merge BAPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}bapequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bapequiv.dta";


/* ----------------------( merge BAPGEN )----------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}bapgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bapgen.dta";


/* ---------------------( merge BBPEQUIV )---------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}bbpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bbpequiv.dta";


/* ----------------------( merge BBPGEN )----------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}bbpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bbpgen.dta";


/* ---------------------( merge BCPEQUIV )---------------------- */;        
sort  persnr;
merge persnr
using "${TEMP_PATH}bcpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bcpequiv.dta";


/* ----------------------( merge BCPGEN )----------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}bcpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bcpgen.dta";


/* ---------------------( merge BDPEQUIV )---------------------- */;        
sort  persnr;
merge persnr
using "${TEMP_PATH}bdpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bdpequiv.dta";


/* ----------------------( merge BDPGEN )----------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}bdpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bdpgen.dta";


/* ---------------------( merge BEPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}bepequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bepequiv.dta";


/* ----------------------( merge BEPGEN )----------------------- */;        
sort  persnr;
merge persnr
using "${TEMP_PATH}bepgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bepgen.dta";


/* ---------------------( merge BFPEQUIV )---------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}bfpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bfpequiv.dta";


/* ----------------------( merge BFPGEN )----------------------- */;     
sort  persnr;
merge persnr
using "${TEMP_PATH}bfpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bfpgen.dta";


/* ---------------------( merge BGPEQUIV )---------------------- */;          
sort  persnr;
merge persnr
using "${TEMP_PATH}bgpequiv.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bgpequiv.dta";


/* ----------------------( merge BGPGEN )----------------------- */;         
sort  persnr;
merge persnr
using "${TEMP_PATH}bgpgen.dta";
drop   if _merge == 2;
drop   _merge;
erase "${TEMP_PATH}bgpgen.dta";	
	
	
	
/* --------------------------( done! )-------------------------- */;
label data "SOEPINFO: Magic at Work! http://panel.gsoep.de/soepinfo/";
save  "${TEMP_PATH}data_base_raw.dta", replace;
desc;





* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/* 04. Transform into Panel dataset */
* ------------------------------------


clear

use "${TEMP_PATH}data_base_raw.dta", clear;	
	
	

drop ?hhnr ?pop ?netto ?phrf ??hhnr ??pop ??netto ??phrf;

local z = 2003;
foreach y in 03 04 05 06 07 08 09 10 11 12 13 14 15 16 {;
	foreach w in partz partnr stib labgro emplst expft exppt casmin isced97_ jobend d11105 d11107 d11109 e11101 e11102 e11103 e11104 e11105 i11101 i11102 i11103 i11110 l11101 iself ioldy m11124 m11126 y11101 lfs iunby iunay {;
		foreach x in `w'`y' {;
			rename `x' `w'`z';
		};
	};
local z = `z' + 1;
};

rename tbilzeit  bilzeit2003;
rename ubilzeit  bilzeit2004;
rename vbilzeit  bilzeit2005;
rename wbilzeit  bilzeit2006;
rename xbilzeit  bilzeit2007;
rename ybilzeit  bilzeit2008;
rename zbilzeit  bilzeit2009;
rename babilzeit bilzeit2010;
rename bbbilzeit bilzeit2011;
rename bcbilzeit bilzeit2012;
rename bdbilzeit bilzeit2013;
rename bebilzeit bilzeit2014;
rename bfbilzeit bilzeit2015;
rename bgbilzeit bilzeit2016;

rename ttatzeit  tatzeit2003;
rename utatzeit  tatzeit2004;
rename vtatzeit  tatzeit2005;
rename wtatzeit  tatzeit2006;
rename xtatzeit  tatzeit2007;
rename ytatzeit  tatzeit2008;
rename ztatzeit  tatzeit2009;
rename batatzeit tatzeit2010;
rename bbtatzeit tatzeit2011;
rename bctatzeit tatzeit2012;
rename bdtatzeit tatzeit2013;
rename betatzeit tatzeit2014;
rename bftatzeit tatzeit2015;
rename bgtatzeit tatzeit2016;

rename tvebzeit  vebzeit2003;
rename uvebzeit  vebzeit2004;
rename vvebzeit  vebzeit2005;
rename wvebzeit  vebzeit2006;
rename xvebzeit  vebzeit2007;
rename yvebzeit  vebzeit2008;
rename zvebzeit  vebzeit2009;
rename bavebzeit vebzeit2010;
rename bbvebzeit vebzeit2011;
rename bcvebzeit vebzeit2012;
rename bdvebzeit vebzeit2013;
rename bevebzeit vebzeit2014;
rename bfvebzeit vebzeit2015;
rename bgvebzeit vebzeit2016;

rename tuebstd  uebzeit2003;
rename uuebstd  uebzeit2004;
rename vuebstd  uebzeit2005;
rename wuebstd  uebzeit2006;
rename xuebstd  uebzeit2007;
rename yuebstd  uebzeit2008;
rename zuebstd  uebzeit2009;
rename bauebstd uebzeit2010;
rename bbuebstd uebzeit2011;
rename bcuebstd uebzeit2012;
rename bduebstd uebzeit2013;
rename beuebstd uebzeit2014;
rename bfuebstd uebzeit2015;
rename bguebstd uebzeit2016;

reshape long partz@ partnr@ stib@ labgro@ emplst@ expft@ exppt@ casmin@ d11105@ d11107@ d11109@ e11101@ e11102@ e11103@ e11104@ e11105@ isced97_@ jobend@ i11101@ i11102@ i11103@ i11110@ l11101@ iself@ ioldy@ m11124@ m11126@ y11101@ lfs@ bilzeit@ tatzeit@ vebzeit@ uebzeit@ iunby@ iunay@, i(persnr) j(svyyear) string;
			  
destring svyyear, replace;

rename isced97_ isced97;


/* --------------------------( save panel dataset )-------------------------- */;

	save "${TEMP_PATH}data_base_long.dta", replace;