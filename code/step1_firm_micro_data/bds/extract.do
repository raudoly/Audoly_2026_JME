* Extract all available firm and establishment yearly waves. Harmonize variable 
* types and names, which obviously change every other wave, to stack everything
* in a panel. Valid for the 10th edition.

clear all
set more off
do globals

** Import firm waves.

forv y = 1997/2018 {
	
	di _n(3)
	di "Starting firm wave `y':"
	
	* extract/format variables for each wave
	if `y'<2017 { 
		use entref employ* birth turnover sic* year active using "${raw}/eu_bsd_`y'_restricted", clear
	}
	else {
		use entref employ* birth_date death_date turnover sic* using "${raw}/eu_bsd_`y'_restricted", clear
		if `y'==2017 {
			tostring birth_date death_date, replace
			replace birth_date = "0" + birth_date if length(birth_date)==7
			replace death_date = "0" + death_date if length(death_date)==7
		}
		if `y'==2018 {
			destring employ* turnover, replace
			replace birth_date = "0" + birth_date if length(birth_date)==7
			replace death_date = "0" + death_date if length(death_date)==7
		}
		destring entref, replace
		gen int year = `y'
		
		* create birth/death year
		gen birth = substr(birth_date,-4,4)
		gen death = substr(death_date,-4,4)
		replace birth = "" if birth=="0001"
		replace death = "" if death=="0001"
		gen active = missing(death) 		// active = death year is not available
		drop death birth_date death_date
	}
	
	* drop if firm id is non-valid
	drop if entref==.

	* restrict sample to active firms
	keep if active==1 					// if active==1, the death variable is missing
	drop active
	
	* convert all sic codes to string 
	foreach v of varlist sic* {
		if substr("`:type `v''",1,3)!="str" {
			tostring `v', replace
		}
		replace `v' = "0"+`v' if length(`v')==4 	// sometimes leading zero is dropped
		replace `v' = "" if length(`v')<5 			// make sure all missing if not length five 
	}
	
	* convert all birth/death 
	if `y'>=2009 {
		destring birth, replace
	}
	
	* get rid of duplicates (always about 25,000 in each wave)
	duplicates report entref year
	duplicates drop entref year, force
	
	* tidy up and save yearly data
	order entref year
	compress
	save "${work}/data/firms`y'", replace

}


** Import establishment waves.

forv y = 1997/2018 {
	
	di _n(3)
	di "Starting establishment wave `y':"

	
	* extract/format variables for each wave
	if `y'>2016 {
		use luref entref employment employees birth* using "${raw}/lu_bsd_`y'_restricted", clear
		gen int year = `y'
	}
	else {
		use luref entref year employment employees birth* using "${raw}/lu_bsd_`y'_restricted", clear
	}
	foreach v of varlist luref entref {
		if substr("`:type `v''",1,3)=="str" {
			destring `v', replace
		}
	}
	
	* harmonize birth year variable
	if `y'>2009  & `y'<2013{
		drop birth_date
	}
	if `y'>2012 & `y'!=2017 {
		tostring birth_date, replace
		gen birth = substr(birth_date,-4,4)
		replace birth = "" if birth=="0001"
		drop birth_date
	}
	if `y'==2017 {
		tostring birthdate, replace
		gen birth = substr(birthdate,-4,4)
		replace birth = "" if birth=="0001"
		drop birthdate
	}
	cap destring birth, replace
	
	* get rid of duplicates
	duplicates report year luref
	duplicates drop year luref, force
	
	* tidy up and save yearly data
	order luref entref year
	compress
	save "${work}/data/estabs`y'", replace
	
}


