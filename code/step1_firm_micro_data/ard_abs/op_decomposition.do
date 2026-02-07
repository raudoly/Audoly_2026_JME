* Reallocation decompositions on ARD-ABS sample

clear all
set more off
do globals

global saveit 1				// save output?
global trimbot 02			// trim everything below this percentile
global trimtop 98			// trim everything above this percentile
global wgt [pweight=ewgt] 	// employment weights



** Programs

prog drop _all

* OP decomposition
prog op_decomp
args lp n sheetName
preserve

	drop if `lp'==.
	// drop if year>2015
	// drop if year<2002
	
	* Truncate micro measure
	bys year sic07agg: egen pbot = pctile(`lp'), p(${trimbot})
	bys year sic07agg: egen ptop = pctile(`lp'), p(${trimtop})
	
	drop if `lp'<pbot | `lp'>ptop

	* Employment weight
	bys year sic07agg empcat: egen N = total(`n')
	gen lp_weighted = `lp'*`n'/N

	* Decomposition within stratas
	collapse (mean) lp_unweighted=`lp' bsd_empl_count ///
		(sum) lp_weighted (count) cnt=entref, ///
		 by(year sic07agg empcat)

	* Define aggregates
	bys year: egen N = total(bsd_empl_count)
	gen stratwgt = bsd_empl_count/N

	gen lp = stratwgt*lp_weighted
	gen mu = stratwgt*lp_unweighted
	gen op = stratwgt*(lp_weighted - lp_unweighted)

	collapse (sum) lp mu op cnt, by(year)

	if "`sheetName'"!="" {
		order year
		sort year
		export excel ///
			using "${tables}/ard_abs_decomposition.xlsx", ///
			sheet("`sheetName'",replace) first(var)
	}
	else {
	
		* Plot series, in deviation from pre-recession trend
		gen _index = 100/lp if year==2007
		egen scale = max(_index)
		
		gen select_lin_trend = year>=2002 & year<=2007 // years before GR to detrend
 		// gen select_lin_trend = year<=2007
		
		foreach v of varlist lp mu op {
			replace `v' = `v'*scale
			qui reg `v' year if select_lin_trend==1
			predict `v'_hat, xb
			predict `v'_dev, res
			
		}
		
		twoway connected lp_dev year, sort xline(2007) name(lp_`lp',replace) 
		twoway connected mu_dev year, sort xline(2007) name(mu_`lp',replace) 
		twoway connected op_dev year, sort xline(2007) name(op_`lp',replace)
		
	}
	
restore
end


** ABS/ARD sample

use "${data}/abs_ard_sample", clear

* Drop some sectors (same as in Riley et al. 2015).
drop if sic07agg=="A"	// farming
drop if sic07agg=="B" 	// mining, quarrying
drop if sic07agg=="D" 	// utilities, energy
drop if sic07agg=="E" 	// utilities, water

* Quality-adjusted employment (same as in Lentz and Mortensen 2008)
bys sic07agg year: gen _wage = totempcost_defl
bys sic07agg year: gen _emp = employment

gen emp_adj = (_emp/_wage)*totempcost_defl
sort entref year
drop _*

* Labor productivity/wage measures
drop gva_bp*
ren totempcost* wages*

foreach v of varlist gva* {
	gen `v'_pw = `v'/empl
	gen ln_`v'_pw = ln(`v'_pw)
	label var `v'_pw "GVA/N"
	label var ln_`v'_pw "ln GVA/N"
	
	gen `v'_pw_adj = `v'/emp_adj
	gen ln_`v'_pw_adj = ln(`v'/emp_adj)
	label var `v'_pw_adj "GVA/N*"
	label var ln_`v'_pw_adj "ln GVA/N*"
}

foreach v of varlist wages*  {
	gen `v'_pw = `v'/empl
	gen ln_`v'_pw = ln(`v'_pw)
	label var `v'_pw "W/N"
	label var ln_`v'_pw "ln W/N"
}

label var year "Year"


** OP decomposition using different measures

* In levels
foreach v of varlist gva*pw wages*pw {
	//op_decomp `v' empl ""
	op_decomp `v' empl "`v'"
}

* In logs
foreach v of varlist ln_gva*pw ln_wages*pw {
	// op_decomp `v' empl ""
	op_decomp `v' empl "`v'"	
}

* Using adjusted employment
foreach v of varlist gva_fc_defl_pw_adj ln_gva_fc_defl_pw_adj {
	// op_decomp `v' emp_adj ""
	op_decomp `v' emp_adj "`v'"	
}