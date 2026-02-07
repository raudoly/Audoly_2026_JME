* Build clean "panel" extracts for analysis.
clear all
set more off
do globals


** Prepare inputs from BSD

* Employment variables and some counts to compute weights are 
* taken directly from the BSD, ie, the "population" of firms 
* in the UK. Everything is at the enterprise ("entref") level 
* there.

use "${data}/firmsall", clear

* Variables from previous/next period
xtset entref year
gen f1employment = F1.employment
gen f1turnover = F1.turnover

* Employment categories
gen empcat = .

replace empcat = 1 if employment>=0 	& employment<10 	// micro
replace empcat = 2 if employment>=10 	& employment<50		// small 
replace empcat = 3 if employment>=50 	& employment<250 	// medium			
replace empcat = 4 if employment>=250 	& employment!=.		// large
 
* Cell counts
bys year empcat sic07agg: egen bsd_empl_count = count(entref)
bys year empcat sic07agg: egen bsd_firm_count = total(employment)  

* NB. This is the industry level that
* makes the most sense to define these
* cells given the size of the sample in 
* ARD/ABS.

* Auxiliary data from BSD
xtset, clear
sort entref year
ren sic07 bsd_sic07
keep entref year *turnover *employment bsd_* 
save "${work}/data/bsdaux", replace 


** ARD surveys: 1997-2008

* Format individual files
local fileparts cag cng mtg pdg prg reg stg whg

forv y = 1997/2007 {
	foreach part of local fileparts {
		
		use "${raw_ard}/dat`y'`part'_restricted", clear
		drop if missing(entref)
		
		* Convert all sic codes to string
		if substr("`:type sic92'",1,3)!="str" {
			tostring sic92, replace
		}
		replace sic92 = "0"+sic92 if length(sic92)==4  
		replace sic92 = "" if length(sic92)<5
		
		tempfile dat`y'`part'
		save `dat`y'`part''
		
	}
}

* Stack everything 
clear all
forv y = 1997/2007 {
	foreach part of local fileparts {
		append using `dat`y'`part''
	}
}

drop if entref==""
// duplicates report ruref year 	
duplicates drop ruref year, force // drop handful of duplicates

* Convert industry classification to 2007
gen sic03 = sic92 if year>=2003

merge m:1 sic92 using "${work}/data/sic92to03conv"
drop if _merge==2
replace sic03 = sic03imp if sic03=="" 
drop sic03imputed _merge

merge m:1 sic03 using "${work}/data/sic03to07conv"
drop if _merge==2
drop _merge
ren sic07imputed sic07

drop if sic07==""

* NB. About 3,000 not converted from 1997. 
* Is there a way to improve on conversion table?

* Variables of interest
ren turnover turnover_idbr
ren empment employment_idbr
ren wq450 totempcost

keep entref ruref year sic07 turnover_idbr employment_idbr totempcost gva* wq11 wq12

* Save ARD data
compress
sort entref year
order entref ruref year sic07
save "${work}/data/ardall", replace


** ABS survey: 2009 onwards

clear all

forv y = 2008/2017 {
	append using "${raw_abs}/`y'/dat`y'_final_restricted"
	drop wq9 // type change
}

append using "${raw_abs}/2018/dat2018_revised_restricted" 		// last years ...
append using "${raw_abs}/2019/dat2019_provisional_restricted"	// ...not final

drop if entref=="" // duplicates report ruref year

replace year = 2015 if year==15
replace year = 2016 if year==16
replace year = 2017 if year==17
replace year = 2018 if year==18
replace year = 2019 if year==19

* Variables of interest
ren turnover turnover_idbr
ren empment employment_idbr
ren wq450 totempcost 
ren wq611 gva_mp
ren wq612 gva_fc
ren wq630 gva_bp // Basic price: not available in ARD?

keep entref ruref year sic07 turnover_idbr employment_idbr totempcost gva* wq11 wq12
	
* Save ABS data
compress
sort entref year
order entref ruref year sic07
save "${work}/data/absall", replace


** Analysis dataset with all survey years

clear all

foreach part in abs ard {
	append using "${work}/data/`part'all"
}

* Start and end date of return
tostring wq11, gen(aux)
replace aux = "0"+aux if length(aux)==5 
replace aux = "" if length(aux)<6
gen fromdate = date(aux,"DMY",2020)
format fromdate %td
drop aux wq11

tostring wq12, gen(aux)
replace aux = "0"+aux if length(aux)==5 
replace aux = "" if length(aux)<6
gen todate = date(aux,"DMY",2020)
format todate %td
drop aux wq12

drop if fromdate==. & todate==.

* Check timing survey
gen surveyperiod = mofd(todate) - mofd(fromdate)
sum surveyperiod, d

gen diffBSD = mofd(todate) - mofd(mdy(3,15,year)) // BSD snapshot: March yearly 
sum diffBSD, d

* Drop some industries, similarly to BSD
do ../ons/sic07definitions

drop if sic07agg=="K"   // finance and insurance
drop if sic07agg=="L"	// real estate
drop if sic07agg=="OQ" 	// government (public administration, education, health)

* Deflate output variables
merge m:1 sic07defl year using "${work}/data/industrydeflators"
drop if _merge==2 // sectors not covered in survey

foreach v of varlist turnov totempcost gva* {
	gen `v'_defl = `v'*100/deflind
}

drop _merge deflind

* Variables of interest at enterprise level
foreach v of varlist turnov* totempcost* gva* {
	bys entref year: egen tot = total(`v')
	bys entref year: egen cnt = count(`v')
	drop `v'
	ren tot `v'
	replace `v' = . if cnt==0 // missing not 0 if all missing
	drop cnt
}

bys entref year: egen aux = total(emp)
bys entref year (emp): keep if _n==_N // keep industry code with largest emp.
drop emp 
ren aux employment_idbr

* Merge in employment variables from BSD
destring entref, replace
drop if entref==.
merge 1:1 entref year using "${work}/data/bsdaux"
drop if _merge!=3
drop _merge

* Are the SIC07 codes the same?
// gen aux = sic07==bsd_sic07
// tab aux
// drop aux

* Employment categories
gen empcat = .

replace empcat = 1 if employment>=0 	& employment<10 	// micro
replace empcat = 2 if employment>=10 	& employment<50		// small 
replace empcat = 3 if employment>=50 	& employment<250 	// medium			
replace empcat = 4 if employment>=250 	& employment!=.		// large
  
* Analysis sample
sort entref year
keep entref year sic07* totempcost* gva* employment f1empl bsd_*_count empcat
save "${work}/data/abs_ard_sample", replace








