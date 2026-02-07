* Detrend time series
clear all
set more off

global data_dir ../../data/time_series
cap mkdir ${data_dir}/detrended/

local tmin = 1997
local tmax = 2018


** Quarterly series **********************
use ${data_dir}/clean/quarterly_series, clear

foreach ts of varlist u v w ue eu ee alp gdp {
	gen ln`ts' = ln(`ts')
}

* Detrending
local series_to_detrend lngdp lnalp alp u lnu lnv ue eu ee lnue lneu lnee lnw

foreach ts of local series_to_detrend {
	// tsfilter hp `ts'_hpf_dev = `ts', trend(`ts'_hpf_hat) smooth(10^5)
	tsfilter hp `ts'_hpf_dev = `ts', trend(`ts'_hpf_hat) smooth(1600) 
	tsfilter cf `ts'_bpf_dev = `ts', trend(`ts'_bpf_hat) minperiod(6) maxperiod(32)
}

* Export detrended series
local export_file ${data_dir}/detrended/quarterly_series.csv

gen date = dofq(qdate + 1) - 1 // last day of quarter
format date %tdDD-Mon-CCYY
sort qdate
order date qdate

export delimited *date `series_to_detrend' *_hat *_dev using `export_file', replace


** Yearly series **********************
use ${data_dir}/clean/yearly_series, clear

foreach ts of varlist u v w ue eu ee alp gdp {
	gen ln`ts' = ln(`ts')
}

* Detrending aggregates
foreach ts of varlist lngdp lnalp alp u lnu lnv lnw eu lneu {
	
	* HP-Filter detrending
	tsfilter hp `ts'_hpf_dev = `ts', trend(`ts'_hpf_hat) smooth(100)

	* BP-Filter detrending
	tsfilter cf `ts'_bpf_dev = `ts', trend(`ts'_bpf_hat) min(2) max(14)
	
}

* Stick closer to UE and EE because of missing values during GR
foreach ts of varlist ue ee lnue lnee {
	
	* HP-Filter detrending
	tsfilter hp `ts'_hpf_dev = `ts', trend(`ts'_hpf_hat) smooth(5)

	* BP-Filter detrending
	tsfilter cf `ts'_bpf_dev = `ts', trend(`ts'_bpf_hat) min(2) max(14)
	
}

* Detrending productivity decomposition
local productivity_concepts lp ec
local series_to_export

// keep if year>=`tmin' & year<=`tmax'

foreach pdy of local productivity_concepts {
	
	foreach part in wgt avg opm {
		local ts `pdy'_`part'
		local series_to_export `series_to_export' `ts' 
		tssmooth ma _ma = `ts', window(2 1 0) replace 
		drop `ts'
		ren _ma `ts'
	}
	
	foreach part in avg opm {	
		
		local ts `pdy'_`part'
		
		* Linear detrending
		qui reg `ts' year
		predict `ts'_lin_hat, xb
		predict `ts'_lin_dev, res
		
		* HP-Filter detrending
		tsfilter hp `ts'_hpf_dev = `ts', trend(`ts'_hpf_hat) smooth(100)

		* BP-Filter detrending
		tsfilter cf `ts'_bpf_dev = `ts', trend(`ts'_bpf_hat) min(2) max(14)

	}
	
	* Aggregate productivity decomposition
	gen `pdy'_wgt_lin_hat = `pdy'_avg_lin_hat + `pdy'_opm_lin_hat
	gen `pdy'_wgt_lin_dev = `pdy'_avg_lin_dev + `pdy'_opm_lin_dev 

	gen `pdy'_wgt_hpf_hat = `pdy'_avg_hpf_hat + `pdy'_opm_hpf_hat
	gen `pdy'_wgt_hpf_dev = `pdy'_avg_hpf_dev + `pdy'_opm_hpf_dev

	gen `pdy'_wgt_bpf_hat = `pdy'_avg_bpf_hat + `pdy'_opm_bpf_hat
	gen `pdy'_wgt_bpf_dev = `pdy'_avg_bpf_dev + `pdy'_opm_bpf_dev

}

* Scale micro data to ALP 
sum lp_wgt_hpf_dev if tin(`tmin',`tmax')
local std_micro = r(sd)
sum alp_hpf_dev if tin(`tmin',`tmax')
local std_macro = r(sd)
local scale = `std_macro'/`std_micro'

foreach v of varlist lp_* ec_* {
	replace `v' = `scale'*`v'
}

// sum alp_hpf_dev ln_gva_fc_lp_hpf_dev if tin(`tmin',`tmax')

* Detrending firm dynamics
foreach ts of varlist firms entr exit {
	
	tssmooth ma _ma = `ts', window(2 1 0) replace
	drop `ts'
	ren _ma `ts'
	
	gen ln`ts' = ln(`ts')
		
	* HP-Filter detrending
	tsfilter hp ln`ts'_hpf_dev = ln`ts', trend(ln`ts'_hpf_hat) smooth(100)

	* BP-Filter detrending
	tsfilter cf ln`ts'_bpf_dev = ln`ts', trend(ln`ts'_bpf_hat) min(2) max(14)
	
}


* Export detrended series
local export_file ${data_dir}/detrended/yearly_series.csv

gen date = mdy(12,31,year) 
format date %tdDD-Mon-CCYY
order date year
sort year

export delimited year date `series_to_export' *_hat *_dev using `export_file', replace

cap rm ${data_dir}/clean/monthly_series.dta
cap rm ${data_dir}/clean/quarterly_series.dta
cap rm ${data_dir}/clean/yearly_series.dta

