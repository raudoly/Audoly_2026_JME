* Compute moments for model estimation.
clear all
prog drop _all
set more off
do globals

* settings
global ind sic07agg 		// industry decomposition level (same as ABS/ARD)			
global emp employment		// employment measure
global age_max 46 			// maximum age to include
global trimbot 02			// trim everything below this percentile
global trimtop 98			// trim everything above this percentile


use "${data}/firmspan"

* moments computed for pre-crisis period
drop if year<2002
drop if year>2007

* trim productivity measure 
bys year ${ind}: egen pbot = pctile(lpdy), p(${trimbot})
bys year ${ind}: egen ptop = pctile(lpdy), p(${trimtop})

drop if lpdy<pbot | lpdy>ptop 

* excel file for export
global row = 1
putexcel set "${tables}/bsd_moments.xlsx", modify sheet("main_moments",replace)
putexcel A$row = "Variable Name"
putexcel B$row = "Variable Label"
putexcel C$row = "Value"
putexcel D$row = "Count"

* average firm size
global row = $row + 1
sum ${emp}, d
putexcel A$row = "empl_avg"
putexcel B$row = "Average firm employment"
putexcel C$row = `r(mean)'
putexcel D$row = `r(N)'


* characteristics young firms
preserve

collapse (count) firms=entref (sum) firm_death  empl=${emp}, by(year agecat)
reshape wide firms empl firm_death, i(year) j(agecat)

tsset year
gen share_firm_yng = firms1/(firms1 + firms2)
gen share_empl_yng = empl1/(empl1 + empl2)
gen exit_rate_yng = 2*firm_death1/(L.firms1 + firms1)

* share in employment  
global row = $row + 1
sum share_empl_yng 
putexcel A$row = "empl_shr_yng"
putexcel B$row = "Share of empl. at young firms"
putexcel C$row = `r(mean)'
putexcel D$row = `r(N)'

* share in all firms
global row = $row + 1
sum share_firm_yng 
putexcel A$row = "firm_shr_yng"
putexcel B$row = "Share of young firms"
putexcel C$row = `r(mean)'
putexcel D$row = `r(N)'

* exit rate
global row = $row + 1
sum exit_rate_yng 
putexcel A$row = "exit_shr_yng"
putexcel B$row = "Firm exit rate young firms"
putexcel C$row = `r(mean)'
putexcel D$row = `r(N)'

restore

* exit rate, all
preserve

collapse (sum) firm_death (count) firms=entref, by(year)
tsset year
gen exit_rate = 2*firm_death/(L.firms + firms)
list year exit_rate

global row = $row + 1
sum exit_rate if year<2017
putexcel A$row = "exit_shr"
putexcel B$row = "Firm exit rate"
putexcel C$row = `r(mean)'
putexcel D$row = `r(N)'

restore

* notion of productivity
xtset entref year
egen ind_yr = group(year ${ind})
areg lpdy, a(ind_yr)
predict lpdy_res, r  

* autocorrelation labor productivity
global row = $row + 1
pwcorr lpdy_res L.lpdy_res
putexcel A$row = "lpdy_acl"
putexcel B$row = "Autocorrelation labor productivity"
putexcel C$row = `r(rho)'
putexcel D$row = `r(N)'

// global row = $row + 1
// pwcorr lpdy_res L.lpdy_res if age<${age_max}
// putexcel A$row = "lpdy_acl_up_age_${age_max}"
// putexcel B$row = "Autocorrelation labor productivity, firms up to age ${age_max}"
// putexcel C$row = `r(rho)'
// putexcel D$row = `r(N)'

* residual productivity dispersion
global row = $row + 1
sum lpdy_res, d
di r(p75) - r(p25)
local iqr = `r(p75)' - `r(p25)'
putexcel A$row = "lpdy_iqr"
putexcel B$row = "IQR labor productivity"
putexcel C$row = `iqr'
putexcel D$row = `r(N)'

global row = $row + 1
di r(p90) - r(p10)
local idr = `r(p90)' - `r(p10)'
putexcel A$row = "lpdy_idr"
putexcel B$row = "IDR labor productivity"
putexcel C$row = `idr'
putexcel D$row = `r(N)'

* residual productivity dispersion, younger firms
global row = $row + 1
sum lpdy_res if agecat==1, d
di r(p75) - r(p25)
local iqr = `r(p75)' - `r(p25)'
putexcel A$row = "lpdy_iqr_yng"
putexcel B$row = "IQR labor productivity, young firms"
putexcel C$row = `iqr'
putexcel D$row = `r(N)'

global row = $row + 1
di r(p90) - r(p10)
local idr = `r(p90)' - `r(p10)'
putexcel A$row = "lpdy_idr_yng"
putexcel B$row = "IDR labor productivity, young firms"
putexcel C$row = `idr'
putexcel D$row = `r(N)'

* difference in average productivity
global row = $row + 1
reg lpdy_res i.agecat
putexcel A$row = "lpdy_avg_diff"
putexcel B$row = "Difference in average productivity (old - young)"
putexcel C$row = _b[2.agecat]
putexcel D$row = `e(N)'

* autocorrelation employment
global row = $row + 1
pwcorr lemp L.lemp
putexcel A$row = "lemp_acl"
putexcel B$row = "Autocorrelation log-employment"
putexcel C$row = `r(rho)'
putexcel D$row = `r(N)'

* employment growth on labor productivity
global row = $row + 1
gen d_lemp = F1.lemp - lemp
areg d_lemp lpdy, a(ind_yr)
putexcel A$row = "beta_dlemp_lpdy"
putexcel B$row = "Reg. coefficient employment growth on productivity"
putexcel C$row = _b[lpdy]
putexcel D$row = `e(N)'


** Firm-size distribution (size=employment size)
use "${work}/data/firmspan", clear

* normalize employment by avg employment
bys year: egen aux = mean(employment)
gen emplnorm = employment/aux
drop aux

* export tail probability for a range of relative sizes
preserve
    forv y = 0/4 {
        gen tail10p`y' = emplnorm>=10^`y'
    }
    collapse (sum) tail10p* (count) N=entref, by(year)
    foreach v of varlist tail10p* {
        replace `v' = `v'/N
    }
    sort year
    list tail10*
    collapse (mean) tail10p0 tail10p1 tail10p2 tail10p3 tail10p4
    list tail10*
    export excel using "${tables}/bsd_moments.xlsx", first(var) sheet("firm_size_tail",replace)
restore

