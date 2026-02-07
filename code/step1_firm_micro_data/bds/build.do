* Build panel from raw data. Extract a few variables of interest and stack all years.
clear all
set more off
do globals

** Derive firm-year datasets from establishment data for some variables.

clear all
forv y = 1997/2018 {
	append using "${work}/data/estabs`y'"
}

* clean up birth year: oldest birth date for each estab
bys luref (birth): gen birthcheck = birth[1]
drop birth
rename birthcheck birth

* firm death variable
bys luref: egen lastyear_est = max(year)
bys entre: egen lastyear_ent = max(year)
bys entre: egen lastyear_all = max(lastyear_est) 
gen entexit = lastyear_ent==lastyear_all
replace entexit = 0 if year==2018

* firm-year aggregates from establishment data
collapse (sum) employment_est=employment employees_est=employees /// 
		 (min) birth_est=birth (max) entexit, by(entref year) 						

* Follow definitions in BDS. Age is age of oldest establishment when 
* firm first appears, so store age of oldest establishment in each year.			

save "${work}/data/firmsall_from_estab", replace


** Create SIC conversion tables, based on BSD.

* Convert everything to SIC 2007 because ONS series are given for this 
* classification. Imputation based on highest fraction of workforce going 
* to one SIC code.

* SIC03 to SIC07: Imputation based on 2007-2017, years when both codes are present
clear all
forv y = 2007/2018 {
	append using "${work}/data/firms`y'"
}
keep if !missing(sic03) & !missing(sic07) 

* employment in each tabulated SIC bin
collapse (sum) employment, by(sic03 sic07)

* ascribe unique sic07 code based on employment
bys sic03 (emp): keep if _n==_N

* save conversion table
keep sic03 sic07
rename sic07 sic07imputed
save "${work}/data/sic03to07conv", replace

* SIC92 to SIC03
clear all
forv y = 2002/2003 {
	append using "${work}/data/firms`y'"
}
* NB. Imputation based on first observed sic03 code in 2003.

* fetch sic code given in 2003
gen sic03 = sic if year==2003
gsort entref -year
replace sic03 = sic03[_n-1] if entref==entref[_n-1] & missing(sic03)
keep if !missing(sic) & !missing(sic03) & year<2003

* employment in each tabulated SIC bin
collapse (sum) employment, by(sic sic03)

* ascribe unique sic03 code based on largest share of employment
bys sic (emp): keep if _n==_N

* save conversion table
keep sic sic03
rename sic sic92
rename sic03 sic03imputed
save "${work}/data/sic92to03conv", replace


** Infer SIC 2007 classification for all firms when missing.

* stack all years
clear all
forv y = 1997/2018 {
	append using "${work}/data/firms`y'.dta"
}

* SIC variable for each vintage
replace sic03 = sic 	if year==2003 | year==2004 | year==2005 	// sic switches to 2003 classification
replace sic = "" 		if year==2003 | year==2004 | year==2005
rename sic sic92 													// sic follows 1992 classification 	

* assign a single SIC code to each firm, based on max periods
 foreach v of varlist sic?? {
	
	* periods spent in each SIC
	bys entref `v': gen timeinsic = _N 				if !missing(`v')
	
	* assign unique sic based on max periods
	replace timeinsic = -timeinsic
	bys entref (timeinsic): replace `v' = `v'[1]	if !missing(`v')
	
	* clean up
	drop timeinsic 	
}

* use SIC 2007 for firms surviving until it appears
gsort entref -year
replace sic07 = sic07[_n-1] if entref==entref[_n-1] & missing(sic07)

* do the same with SIC 2003 
gsort entref -year
replace sic03 = sic03[_n-1] if entref==entref[_n-1] & missing(sic03)

* impute missing sic03
merge m:1 sic92 using "${work}/data/sic92to03conv", nogen
replace sic03 = sic03imputed if missing(sic03)

* impute missing sic07
merge m:1 sic03 using "${work}/data/sic03to07conv", nogen
replace sic07 = sic07imputed if missing(sic07)

drop sic??imputed
drop if missing(sic07)		// some firms for which there is no clear way to infer sic codes
drop if missing(entref) 	// some codes not matched once sic codes made unique for firms
	

** Encode industry aggregates.

* NB. When merging in data from ONS, most series are given at a different 
* more aggregated level. These aggregates are created here.

* divisions (two digit level)
gen sic07div = substr(sic07,1,2)
destring sic07div, replace

* largest aggregates (sections in SIC lingo)
gen sic07agg = ""
replace sic07agg = "A" 	if sic07div<4
replace sic07agg = "B" 	if sic07div>4 & sic07div<10
replace sic07agg = "C" 	if sic07div>9 & sic07div<34
replace sic07agg = "D"	if sic07div==35
replace sic07agg = "E"	if sic07div>35 & sic07div<40
replace sic07agg = "F" 	if sic07div>40 & sic07div<44
replace sic07agg = "G" 	if sic07div>44 & sic07div<48
replace sic07agg = "H" 	if sic07div>48 & sic07div<54
replace sic07agg = "I"	if sic07div>54 & sic07div<57
replace sic07agg = "J" 	if sic07div>57 & sic07div<64
replace sic07agg = "K" 	if sic07div>63 & sic07div<67
replace sic07agg = "L"	if sic07div==68
replace sic07agg = "M"	if sic07div>68 & sic07div<76
replace sic07agg = "N" 	if sic07div>76 & sic07div<83
replace sic07agg = "OQ" if sic07div>83 & sic07div<89
replace sic07agg = "R" 	if sic07div>89 & sic07div<94
replace sic07agg = "S" 	if sic07div>93 & sic07div<97
replace sic07agg = "T"	if sic07div>96 & sic07div<99
replace sic07agg = "U" 	if sic07div==99

/*

* level of industry deflators - mixes a bunch of levels 
gen str4 sic07defl = ""
foreach sec of numlist 1101/1107 2011/2017 3315 3316 { 
	replace sic07defl = "`sec'" if substr(sic07,1,4)=="`sec'" // four-digit level ones 
}
foreach div of numlist 101/109 202/206 231/237 239 241/245 251/257 259 301/304 309 351/353 491/495 681/683 691 692 { 
	replace sic07defl = "`div'" if substr(sic07,1,3)=="`div'" & missing(sic07defl) // three-digit level ones
}
replace sic07defl = substr(sic07,1,2) if missing(sic07defl) // two-digit level ones

* level reported in supply use tables - mixes a bunch of levels
gen sic07su = ""
replace sic07su = "06 & 07" 			if substr(sic07,1,2)=="06" | substr(sic07,1,2)=="07"
replace sic07su = "10.1" 				if substr(sic07,1,3)=="101"
replace sic07su = "10.2-3" 				if substr(sic07,1,3)=="102" | substr(sic07,1,3)=="103"
replace sic07su = "10.4" 				if substr(sic07,1,3)=="104" 
replace sic07su = "10.5" 				if substr(sic07,1,3)=="105"
replace sic07su = "10.6" 				if substr(sic07,1,3)=="106" 
replace sic07su = "10.7" 				if substr(sic07,1,3)=="107" 
replace sic07su = "10.8" 				if substr(sic07,1,3)=="108" 
replace sic07su = "10.9" 				if substr(sic07,1,3)=="109" 
forv i = 1/6 {
replace sic07su = "11.01-6 & 12" 		if substr(sic07,1,4)=="110`i'" 
}
replace sic07su = "11.07" 				if substr(sic07,1,4)=="1107"  
replace sic07su = "11.01-6 & 12" 		if substr(sic07,1,2)=="12" 
replace sic07su = "20.3"				if substr(sic07,1,3)=="203"
replace sic07su = "20.4"				if substr(sic07,1,3)=="204"
replace sic07su = "20.5"				if substr(sic07,1,3)=="205"
replace sic07su = "20A"					if substr(sic07,1,4)=="2011" | substr(sic07,1,4)=="2013" | substr(sic07,1,4)=="2015"
replace sic07su = "20B"					if substr(sic07,1,4)=="2014" | substr(sic07,1,4)=="2016" | substr(sic07,1,4)=="2017" | substr(sic07,1,3)=="206"
replace sic07su = "20C"					if substr(sic07,1,4)=="2012" | substr(sic07,1,3)=="202" 
replace sic07su = "23.5-6"				if substr(sic07,1,3)=="235" | substr(sic07,1,3)=="236"
foreach i of numlist 1/4 7/9 {
replace sic07su = "23OTHER" 			if substr(sic07,1,3)=="23`i'" 			
}
replace sic07su = "24.1-3"				if substr(sic07,1,3)=="241" | substr(sic07,1,3)=="242" | substr(sic07,1,3)=="243"
replace sic07su = "24.4-5"				if substr(sic07,1,3)=="244" | substr(sic07,1,3)=="245" 
replace sic07su = "25.4"				if substr(sic07,1,3)=="254"
foreach i of numlist 1/3 5/9 {
replace sic07su = "25OTHER"				if substr(sic07,1,3)=="25`i'"
} 
replace sic07su = "30.1"				if substr(sic07,1,3)=="301"
replace sic07su = "30.3"				if substr(sic07,1,3)=="303"
foreach i of numlist 2 4 9 {
replace sic07su = "30OTHER"				if substr(sic07,1,3)=="30`i'"
} 
replace sic07su = "33.15" 				if substr(sic07,1,4)=="3315"
replace sic07su = "33.16" 				if substr(sic07,1,4)=="3316"
foreach i of numlist 11/14 17 19 20 {
replace sic07su = "33OTHER" 			if substr(sic07,1,4)=="33`i'"
}
replace sic07su = "35.1"				if substr(sic07,1,3)=="351"
replace sic07su = "35.2-3"				if substr(sic07,1,3)=="352" | substr(sic07,1,3)=="353"
replace sic07su = "41, 42 & 43"			if substr(sic07,1,2)=="41" | substr(sic07,1,2)=="42" | substr(sic07,1,2)=="43"
replace sic07su = "49.1-2"				if substr(sic07,1,3)=="491" | substr(sic07,1,3)=="492"
replace sic07su = "49.3-5"				if substr(sic07,1,3)=="493" | substr(sic07,1,3)=="494" | substr(sic07,1,3)=="495"
replace sic07su = "59 & 60" 			if substr(sic07,1,2)=="59" | substr(sic07,1,2)=="60" 
replace sic07su = "65.1-2 & 65.3" 		if substr(sic07,1,3)=="651" | substr(sic07,1,3)=="652" | substr(sic07,1,3)=="653"
replace sic07su = "68.1-2" 				if substr(sic07,1,3)=="681" | substr(sic07,1,3)=="682"
replace sic07su = "68.3" 				if substr(sic07,1,3)=="683" 
replace sic07su = "69.1" 				if substr(sic07,1,3)=="691" 
replace sic07su = "69.2" 				if substr(sic07,1,3)=="692"
replace sic07su = "87 & 88"				if substr(sic07,1,2)=="87" | substr(sic07,1,2)=="88"
replace sic07su = substr(sic07,1,2) 	if missing(sic07su) // all remaining codes are two digits division

** industry deflators

* NB. Two available sets of industry deflators with different coverage:
* - GVA implied deflator
* - Industry deflators provided by ONS (based on supply-use table?)

* GVA implied deflators
merge m:1 sic07div year using "${work}/data/sic07divONSdefl", nogen
drop if entref==.

* industry deflators
merge m:1 sic07defl year using "${work}/data/industrydeflators", nogen
drop if entref==. 							

*/

** Dataset with all firm-year observations and clean industry.

* drop sectors marginally covered in BSD 					
drop if sic07agg=="T" 	// activities of household
drop if sic07agg=="U" 	// extra-territorial organizations

* all firm data, no selection
drop sic92 sic03
order entref year sic07*
compress
sort entref year
save "${work}/data/firmsall", replace 


** Dataset with only selected sectors. 

use "${work}/data/firmsall", clear

* selection of sectors (based on whether trend lines up with national accounts, see do-file check)
drop if sic07agg=="B" 	// mining, quarrying 
drop if sic07agg=="K"   // finance and insurance
drop if sic07agg=="OQ" 	// government (public administration, education, health)
drop if sic07agg=="R"	//  arts and entertainment

* selected sectors 
order entref year birth turnover emp* sic*
compress
save "${work}/data/firmssel", replace


** Analysis sample. 

use "${work}/data/firmssel", clear

* birth from aggregated establishment data
merge 1:1 entref year using "${work}/data/firmsall_from_estab"
drop if _merge==2
drop _merge
replace birth = birth_est if birth_est!=. & birth_est<=2018 // age of oldest establishment in each year

* firm death indicator: all establishment dispappear with firm
bys entref (year): replace entexit = entexit[_n-1] if entexit==. & year!=2018
bys entref (year): replace entexit = entexit[_n+1] if entexit==. & year!=2018
replace entexit = 0 if entexit==. // not in estab data, just one-period in data

* drop observations below VAT threshold
gen tno_vat = .
replace tno_vat = 47 if year==1997 		// VAT theshold for 1996 tax year in K£
replace tno_vat = 48 if year==1998
replace tno_vat = 49 if year==1999
replace tno_vat = 50 if year==2000
replace tno_vat = 51 if year==2001
replace tno_vat = 52 if year==2002
replace tno_vat = 54 if year==2003
replace tno_vat = 55 if year==2004
replace tno_vat = 56 if year==2005
replace tno_vat = 58 if year==2006
replace tno_vat = 60 if year==2007
replace tno_vat = 61 if year==2008
replace tno_vat = 64 if year==2009
replace tno_vat = 67 if year==2010
replace tno_vat = 68 if year==2011
replace tno_vat = 70 if year==2012
replace tno_vat = 73 if year==2013
replace tno_vat = 77 if year==2014
replace tno_vat = 79 if year==2015
replace tno_vat = 81 if year==2016
replace tno_vat = 82 if year==2017
replace tno_vat = 83 if year==2018

drop if turnover<tno_vat
drop tno_vat

* exclude firms never employing anyone
bys entref: egen tmp = max(employees)
drop if tmp==0
drop tmp

* main analysis variables  
gen lemp = log(employment)
gen ltno = log(turnover)
gen lpdy = ltno - lemp		
drop if lpdy==. // exclude zeros

* alternative measure, using lag of employment
bys entref (year): gen emplag = employment[_n-1] if _n>1
gen lpdylag = ltno - log(emplag)

* encode industry classification
gen indclass = substr(sic07,1,4) 				
encode indclass, gen(sic07cls) 		// four-digit
drop indclass

* trim LP measure
bys year sic07cls: egen p99lpdy = pctile(lpdy), p(99)
bys year sic07cls: egen p01lemp = pctile(lemp), p(1)
drop if lpdy>=p99lpdy & lemp<=p01lemp
drop p99lpdy p01lemp

* Note: Some observations have an extremely large productivity given their employment.
* This is one way to drop most of them. 

* age definition
bys entref (year): gen tmp = birth[1] 			// birth year of oldest establishment when firm first observed with valid productivity
drop birth
rename tmp birth 
gen int age = year - birth  
drop if age==.

/*
* age definition
gen int age = .
bys entref (year): replace age = year-birth 	if _n==1 							// age of oldest establishment when firm first observed with valid productivity
bys entref (year): replace age = age[_n-1]+1 	if _n>=2 & year==year[_n-1]+1 		// firm ages naturally for each year in the sample
drop if age==.

* NB: This definition excludes firms with gaps in their history. We don't know if
* firms "reborn" are actual new firms or if the company was dormant for a few 
* years. I drop all subsequent observations after a gap.
*/

* age categories 
gen byte agecat = .
replace agecat = 1 if age<5
replace agecat = 2 if age>=5 & age!=.


* firm entry/exit indicators
bys entref (year): gen firm_first = _n==1 					// indicator for firm first observation
bys entref (year): gen firm_entry = firm_first & age<2 		// age of oldest establishment less than 2 when first observed
bys entref (year): gen firm_death = _n==_N & entexit==1		// all establishments associated with the firm die as well

* analysis sample
drop sic07 *_est entexit
sort entref year
compress
save "${work}/data/firmspan", replace
