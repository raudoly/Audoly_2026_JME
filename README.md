# Firm Dynamics and Random Search over the Business Cycle

This is the replication package for my paper "Firm Dynamics and Random Search over the Business Cycle" published in the _Journal of Monetary Economics_.

If you find this package helpful in your work, please consider citing the paper:

```
@article{audoly2026firm,
  title={Firm Dynamics and Random Search over the Business Cycle},
  author={Audoly, Richard},
  journal={Journal of Monetary Economics},
  doi = {https://doi.org/10.1016/j.jmoneco.2026.103902},
  year={Forthcoming},
  publisher={Elsevier}
}
```

## Directory structure

- `code/`: replication scripts
- `data/`: replication input data and intermediate artifacts
- `figures/`: final figures produced by replication scripts [created by running the code]
- `tables/`: final tables produced by replication scripts [created by running the code]


## Software requirements

- Stata (last run on Stata/SE 18)
- MATLAB (last run on R2023a)
  - The figure scripts call `recessionplot`, which is provided by the MATLAB Econometrics Toolbox.


## Replication steps

*  Step 1: Firm-level micro data
*  Step 2: Time series data
*  Step 3: Solve and simulate alternative models
*  Step 4: Generate figures and tables


## Step 1: Firm-level micro data

This step derives several key statistics from confidential British firm-level data.


### Inputs

The raw firm-level data is confidential and cannot be shared. Access can be requested from the [UK Data Service](https://ukdataservice.ac.uk/find-data/access-conditions/).

The relevant datasets are:
- Business Structure Database (BSD): [http://doi.org/10.5255/UKDA-SN-6697-10](http://doi.org/10.5255/UKDA-SN-6697-10)
- Annual Business Survey (ABS): [http://doi.org/10.5255/UKDA-SN-7451-15](http://doi.org/10.5255/UKDA-SN-7451-15)
- Annual Respondents Database (ARD): [http://doi.org/10.5255/UKDA-SN-6644-5](http://doi.org/10.5255/UKDA-SN-6644-5)

### Scripts

Scripts are located in `code/step1_firm_micro_data/`. The scripts do not need to be run to reproduce the paper.

### Outputs

The moments and time series derived from this step are already included in the replication package given the confidential nature of the underlying data. The scripts do not need to be run to reproduce the paper.


## Step 2: Time series data

This step constructs the time-series inputs used by the model code.


### Inputs

- `data/time_series/raw/`
  - Raw ONS/BHPS/ABS/BSD inputs used to construct macro series.
- `data/time_series/recessions_uk/`
  - `dates.csv`
  - `quarters.csv`

### Scripts

Scripts are located in `code/step2_time_series_data/`:

- `clean_series.do`
  - Reads raw inputs and constructs monthly/quarterly/yearly series in Stata format.
- `detrend_series.do`
  - Applies detrending (HP and band-pass filters) and exports the detrended series used by the model.
  - Removes intermediate Stata `.dta` artifacts after exporting the final `.csv` files.
- `prepare_model_series.m`
  - Interpolates the yearly detrended series to a monthly frequency and exports `monthly_series.csv`.

### How to run

Run from the `code/step2_time_series_data/` folder.

1. Stata:
   - Run `clean_series.do`
   - Run `detrend_series.do`

2. MATLAB:
   - Run `prepare_model_series.m`

### Outputs

#### Model input data

These files are created under `data/time_series/detrended/`:

- `quarterly_series.csv`
- `yearly_series.csv`
- `monthly_series.csv`


## Step 3: Solve and simulate alternative models

This step solves and simulates alternative model specifications and stores the solution and simulation output used to generate paper figures and tables. The code will take several hours to run.


### Inputs

- `data/model_parameters/`
  - Calibration inputs for the steady state and aggregate shocks.
- `data/time_series/detrended/monthly_series.csv`
  - Constructed in Step 2.

### Scripts

Scripts are located in `code/step3_model_solutions_simulations/`:

- `aggregate_shocks_simulations.m`
  - Solves for multiple model configurations.
  - Simulates business cycles and finds sequences of shocks matching target data series.
  - Saves solutions to `data/model_solutions/` and simulations to `data/model_simulations/`.

### How to run

Run from the `code/step3_model_solutions_simulations/` folder.

- MATLAB:
  - Run `aggregate_shocks_simulations.m`

### Outputs

This script writes under `data/`:

- `data/model_solutions/<model_type>/`
  - Solution objects (e.g., `theta_<steady_state>_<aggregate_shocks>`).
- `data/model_simulations/<model_type>/`
  - Simulation output files named `<steady_state>_<aggregate_shocks>.mat` (stored as `simulation_output`).


## Step 4: Generate figures and tables

This step generates the final figures and tables using the time series (Step 2) and model simulation output (Step 3).


### Inputs

- `data/time_series/detrended/`
  - `monthly_series.csv`
  - `yearly_series.csv`
- `data/time_series/recessions_uk/dates.csv`
- `data/model_simulations/`
  - Simulation output files produced in Step 3.
- `data/model_parameters/`
  - Used to re-solve steady-state models for some tables.


### Scripts

Scripts are located in `code/step4_figures_and_tables/`:

- `fig1.m`
- `fig2.m`
- `tab1.m`
- `tab2.m`
- `tab3.m`


### How to run

Run from the `code/step4_figures_and_tables/` folder.

- MATLAB:
  - Run `fig1.m`
  - Run `fig2.m`
  - Run `tab1.m`
  - Run `tab2.m`
  - Run `tab3.m`


### Outputs

#### Figures

These files are created under `figures/`:

- `fig1a.*`, `fig1b.*`, `fig1c.*`, `fig1d.*`, `fig1e.*`, `fig1f.*`
- `fig2a.*`, `fig2b.*`, `fig2c.*`, `fig2d.*`

The file extension is controlled by the MATLAB `figure_options()` helper.


#### Tables

These files are created under `tables/`:

- `tab1.txt`
- `tab2.txt`
- `tab3.txt`
