* Compute moments for model estimation.

clear all
prog drop _all
set more off
do globals

global y gva_mp_d 			// output measure  
global trimbot 02			// trim everything below this percentile
global trimtop 98			// trim everything above this percentile


use "${data}/abs_ard_sample"

* Drop some sectors (same as Riley et al. 2015).
drop if sic07agg=="A"	// farming
drop if sic07agg=="B" 	// mining, quarrying
drop if sic07agg=="D" 	// utilities, energy
drop if sic07agg=="E" 	// utilities, water

* Moments computed for pre-crisis period
drop if year<2002
drop if year>2007

* Age variable from bsd
merge 1:1 entref year using "${data}/firmspan", keepusing(age agecat) 
drop if _merge==2 // _some _merge==1, so age will be for subset
drop _merge

* Productivity and wage measures
gen lnp = ln(${y}/employment)
gen lnw = ln(totempcost_d/employment)

drop if lnp==. | lnw==.

* Trim productivity measure
bys year sic07agg: egen trim_bot = pctile(lnp), p(${trimbot})
bys year sic07agg: egen trim_top = pctile(lnp), p(${trimtop}) 

drop if lnp<trim_bot | lnp>trim_top

* Survey weights
bys year sic07agg empcat: egen aux = total(employment)
bys year sic07agg empcat: gen ewgt = bsd_empl_count/aux
drop aux

* set-up excel file for export
global row = 1
putexcel set "${tables}/ard_abs_moments.xlsx", modify sheet("moments_$y",replace)
putexcel A$row = "Variable Name"
putexcel B$row = "Variable Label"
putexcel C$row = "Value Weighted"
putexcel D$row = "Value Unweighted"
putexcel E$row = "Unweighted Count"

* Residual productivity & wages
egen ind_yr = group(year sic07agg)
areg lnp , a(ind_yr)
predict lnp_r, r
areg lnw, a(ind_yr)
predict lnw_r, r

* Residual productivity dispersion
sum lnp_r [fweight=bsd_empl_count], d
local iqrw = `r(p75)' - `r(p25)'
local idrw = `r(p90)' - `r(p10)'
sum lnp_r, d
local iqru = `r(p75)' - `r(p25)'
local idru = `r(p90)' - `r(p10)'

global row = $row + 1
putexcel A$row = "lpdy_iqr"
putexcel B$row = "IQR labor productivity"
putexcel C$row = `iqrw'
putexcel D$row = `iqru'
putexcel E$row = `r(N)'

global row = $row + 1
putexcel A$row = "lpdy_idr"
putexcel B$row = "IDR labor productivity"
putexcel C$row = `idrw'
putexcel D$row = `idru'
putexcel E$row = `r(N)'

* Residual productivity dispersion, young firms
sum lnp_r [fweight=bsd_empl_count] if agecat==1, d
local iqrw = `r(p75)' - `r(p25)'
local idrw = `r(p90)' - `r(p10)'
sum lnp_r if agecat==1, d
local iqru = `r(p75)' - `r(p25)'
local idru = `r(p90)' - `r(p10)'

global row = $row + 1
putexcel A$row = "lpdy_iqr_yng"
putexcel B$row = "IQR labor productivity, young firms"
putexcel C$row = `iqrw'
putexcel D$row = `iqru'
putexcel E$row = `r(N)'

global row = $row + 1
putexcel A$row = "lpdy_idr_yng"
putexcel B$row = "IDR labor productivity, young firms"
putexcel C$row = `idrw'
putexcel D$row = `idru'
putexcel E$row = `r(N)'

* Residual wage dispersion 
sum lnw_r [fweight=bsd_empl_count], d
local iqrw = `r(p75)' - `r(p25)'
local idrw = `r(p90)' - `r(p10)'
sum lnw_r, d
local iqru = `r(p75)' - `r(p25)'
local idru = `r(p90)' - `r(p10)'

global row = $row + 1
putexcel A$row = "lwag_iqr"
putexcel B$row = "IQR ln(wages per worker)"
putexcel C$row = `iqrw'
putexcel D$row = `iqru'
putexcel E$row = `r(N)'

global row = $row + 1
putexcel A$row = "lwag_idr"
putexcel B$row = "IDR ln(wages per worker)"
putexcel C$row = `idrw'
putexcel D$row = `idru'
putexcel E$row = `r(N)'

* Difference in average productivity
global row = $row + 1
putexcel A$row = "lpdy_avg_diff"
putexcel B$row = "Difference in average productivity (old - young)"
reg lnp_r i.agecat [pweight=ewgt]
putexcel C$row = _b[2.agecat]
reg lnp_r i.agecat 
putexcel D$row = _b[2.agecat]
putexcel E$row = `e(N)'

* Employment growth on log labor productivity
global row = $row + 1
gen d_lemp = ln(f1empl) - ln(empl)
putexcel A$row = "beta_dlemp_lnp"
putexcel B$row = "Reg. coefficient employment growth on log-productivity"
areg d_lemp lnp [pweight=ewgt], a(ind_yr)
putexcel C$row = _b[lnp]
areg d_lemp lnp, a(ind_yr)
putexcel D$row = _b[lnp]
putexcel E$row = `e(N)'

* Employment growth on log wages
global row = $row + 1
putexcel A$row = "beta_dlemp_lnw"
putexcel B$row = "Reg. coefficient employment growth on log-wage"
areg d_lemp lnw [pweight=ewgt], a(ind_yr)
putexcel C$row = _b[lnw]
areg d_lemp lnw, a(ind_yr)
putexcel D$row = _b[lnw]
putexcel E$row = `e(N)'

* log wages on log productivity
global row = $row + 1
putexcel A$row = "beta_lnw_lnp"
putexcel B$row = "Reg. coefficient log-wage on log-productivity"
areg lnw lnp [pweight=ewgt], a(ind_yr)
putexcel C$row = _b[lnp]
areg lnw lnp, a(ind_yr)
putexcel D$row = _b[lnp]
putexcel E$row = `e(N)'

