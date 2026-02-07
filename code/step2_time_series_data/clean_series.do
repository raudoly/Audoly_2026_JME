* Prepare all macro series. Some of these series are derived 
* from admin micro-level data (see 'firm_micro' folder).
clear all
set more off

global data_dir ../../data/time_series
cap mkdir ${data_dir}/clean/


** Monthly series *****************

* UK transition rates from BHPS
import excel using ${data_dir}/raw/bhps_transition_rates.xlsx, clear first 
* var definition: variables have been applied Shimer's correction already
* transition = - ln(1 - flow_t/stock_{t-1})

gen mdate = mofd(date)
format mdate %tm
tsset mdate, monthly

ren *transitionrate *
ren ww ee
ren (w? ?w) (e? ?e)

* There is a break in the series because of BHPS becoming
* Understanding Society. So it seems all raw transition rates
* between August 2008 and December 2009 are missing. 
* Smooth over using an MA with large window.  


foreach ts of varlist ue eu ee {
		
	tssmooth ma _ma = `ts', window(12 0 12) replace
	drop `ts'
	ren _ma `ts'
	
}

keep mdate ue eu ee

save _transition_rates, replace

* ONS monthly aggregates
foreach ts in v w u {
	import delimited using ${data_dir}/raw/ons_`ts'_m, clear
	gen mdate = mofd(date(date,"YM"))
	format mdate %tm
	drop date
	save _`ts', replace
}

* All monthly time series together
use _transition_rates, replace

merge 1:1 mdate using _v, nogen
merge 1:1 mdate using _w, nogen
merge 1:1 mdate using _u, nogen

rm _v.dta
rm _w.dta
rm _u.dta
rm _transition_rates.dta

replace u = u/100

order mdate
tsset mdate

save ${data_dir}/clean/monthly_series, replace


** Quarterly series *******************

* UK recessions
import delimited using ${data_dir}/recessions_uk/quarters.csv, clear

gen qdate = qofd(date(date,"DMY"))
format qdate %tq
drop date

save _recessions, replace 

* Quarterly aggregates
foreach ts in alp gdp { 
	import delimited using ${data_dir}/raw/ons_`ts'_q, clear
	gen qdate = quarterly(date,"YQ")
	format qdate %tq
	drop date 
	save _`ts', replace
}

* All quarterly series together
use ${data_dir}/clean/monthly_series, clear

gen qdate = qofd(dofm(mdate))
format qdate %tq
collapse ? ??, by(qdate) 

merge 1:1 qdate using _alp, nogen
merge 1:1 qdate using _gdp, nogen
merge 1:1 qdate using _recessions, nogen

replace alp = alp/100

rm _alp.dta
rm _gdp.dta
rm _recessions.dta

order qdate
tsset qdate

save ${data_dir}/clean/quarterly_series, replace



** Yearly series ****************

* BSD aggregates 
import excel using ${data_dir}/raw/bsd_firm_demographics.xlsx, clear first case(lower)
save _bsd_firm_demographics, replace

* Productivity measures
local productivity_concept ln_gva_fc ln_wages

foreach j of local productivity_concept {
    import excel using ${data_dir}/raw/abs_ard_op_decomp.xlsx, clear first case(lower) sheet("op_`j'_defl_pw")
    ren ?? `j'_??
    save _`j', replace
}

* Add to all other series
use ${data_dir}/clean/quarterly_series, clear

gen year = yofd(dofq(qdate))
collapse (mean) ? ?? ??? (max) recession, by(year)

merge 1:1 year using _bsd_firm_demographics, nogen
rm _bsd_firm_demographics.dta

foreach j of local productivity_concept {
    merge 1:1 year using _`j', nogen
    rm _`j'.dta
}

ren ln_gva_fc_lp lp_wgt
ren ln_gva_fc_mu lp_avg
ren ln_gva_fc_op lp_opm

ren ln_wages_lp ec_wgt
ren ln_wages_mu ec_avg
ren ln_wages_op ec_opm

order year
tsset year

save ${data_dir}/clean/yearly_series, replace

