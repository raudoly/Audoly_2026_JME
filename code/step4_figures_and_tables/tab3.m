
clearvars;
close all;
clc;

addpath(['..' filesep 'lib' filesep 'utils']);

% Directories
project_dir = ['..' filesep '..'];
time_series_dir = [project_dir filesep 'data' filesep 'time_series'];
sim_dir = [project_dir filesep 'data' filesep 'model_simulations'];
tables_dir = [project_dir filesep 'tables'];
if ~exist(tables_dir, 'dir'); mkdir(tables_dir); end

% Data inputs
monthly_series = [time_series_dir filesep 'detrended' filesep 'monthly_series.csv'];  
% quarterly_series = [time_series_dir filesep 'detrended' filesep 'quarterly_series.csv'];  
yearly_series = [time_series_dir filesep 'detrended' filesep 'yearly_series.csv'];  

recessions = readtable([time_series_dir filesep 'recessions_uk' filesep 'dates.csv']);

recent_year_min = 1997;
recent_year_max = 2018;

dat_series_m = readtable(monthly_series);
dat_series_y = readtable(yearly_series);

select = year(dat_series_m.date)>=recent_year_min & year(dat_series_m.date)<=recent_year_max;
dat_series_m_recent = dat_series_m(select,:);

select = year(dat_series_y.date)>=recent_year_min & year(dat_series_y.date)<=recent_year_max;
dat_series_y_recent = dat_series_y(select,:);

%% Load simulation results 

% Baseline model
list_aggregate_shocks = { ...
    'omega_output', ...
    'omega_and_delta_and_c0', ...
};
list_steady_states = {'baseline'};
file_dir = [sim_dir filesep 'baseline'];

for j_aggregate_shock = 1:length(list_aggregate_shocks)
    for j_steady_state = 1:length(list_steady_states)
        
        steady_state = list_steady_states{j_steady_state};
        aggregate_shock = list_aggregate_shocks{j_aggregate_shock};
        
        file_name = [steady_state '_' aggregate_shock];
        load([file_dir filesep file_name], 'simulation_output');
        fdrs.(steady_state).(aggregate_shock) = simulation_output;
    end
end

% c_1 = 1 model
list_aggregate_shocks = {'omega_and_delta_and_c0'};
list_steady_states = {'min_c1'};
file_dir = [sim_dir filesep 'baseline'];

for j_aggregate_shock = 1:length(list_aggregate_shocks)
    for j_steady_state = 1:length(list_steady_states)
        
        steady_state = list_steady_states{j_steady_state};
        aggregate_shock = list_aggregate_shocks{j_aggregate_shock};
        
        file_name = [steady_state '_' aggregate_shock];
        load([file_dir filesep file_name], 'simulation_output');
        fdrs.(steady_state).(aggregate_shock) = simulation_output;
    end
end

% MPV2016 model
list_aggregate_shocks = {'omega_and_delta_and_c0'};
list_steady_states = {'c1_49_b_0'};
file_dir = [sim_dir filesep 'mpv2016'];

for j_aggregate_shock = 1:length(list_aggregate_shocks)
    for j_steady_state = 1:length(list_steady_states)
        
        steady_state = list_steady_states{j_steady_state};
        aggregate_shock = list_aggregate_shocks{j_aggregate_shock};
        
        file_name = [steady_state '_' aggregate_shock];
        load([file_dir filesep file_name], 'simulation_output');
        mpv2016.(steady_state).(aggregate_shock) = simulation_output;
    end
end

%% Variance decomposition in data

stats = { ...
    'share_var_lp_avg', ...
    'share_var_lp_opm', ...
    'share_var_tfp_shock', ...
    'share_var_firm_ladder', ...
    'share_var_ladder_interaction', ...
};

tab_data = zeros(length(stats), 1);

lp_avg = dat_series_m_recent.lp_avg_hpf_dev;
lp_avg = lp_avg(~isnan(lp_avg));
lp_opm = dat_series_m_recent.lp_opm_hpf_dev;
lp_opm = lp_opm(~isnan(lp_opm));

var_total = var(lp_avg + lp_opm);
C = cov([lp_avg, lp_opm]);  
share_var_lp_avg = sum(C(:, 1))/var_total;
share_var_lp_opm = sum(C(:, 2))/var_total;

tab_data(1:2, 1) = [share_var_lp_avg; share_var_lp_opm];
tab_data(3:5, 1) = NaN; % No structural decomposition for data

%% Variance decomposition in alternative models



tab_models = [
    decompose_variance(fdrs, 'baseline', 'omega_and_delta_and_c0', 'gdp', 'sim_series_m'), ...
    decompose_variance(fdrs, 'min_c1', 'omega_and_delta_and_c0', 'gdp', 'sim_series_m'), ...
    decompose_variance(fdrs, 'baseline', 'omega_output', 'gdp', 'sim_series_m'), ...
    decompose_variance(mpv2016, 'c1_49_b_0', 'omega_and_delta_and_c0', 'gdp', 'sim_series_m')];



%% Export decompositions

row_names = { ...
    'share_var_lp_avg', ...
    'share_var_lp_opm', ...
    'share_var_tfp_shock', ...
    'share_var_firm_ladder', ...
    'share_var_ladder_interaction', ...
};

var_names = { ...
    'data', ...
    'baseline', ...
    'min_c1', ...
    'omega_only', ...
    'mpv2016', ...
};

tab_all = array2table([tab_data, tab_models]);
tab_all.Properties.RowNames = row_names;
tab_all.Properties.VariableNames = var_names;

% Format and show table
line_sep = repmat('-', 1, 100);

tab_all_str = evalc('disp(tab_all)');
tab_all_str = regexprep(tab_all_str, '\s+$', '');
tab_all_str = regexprep(tab_all_str, '<[^>]+>', '');

tab3_lines = {
    line_sep
    'TABLE 3: Variance decomposition of the drivers of worker reallocation over the business cycle.'
    line_sep
    tab_all_str
    line_sep
    };

tab3_text = strjoin(tab3_lines, newline);

disp(tab3_text);

tab3_file = fullfile(tables_dir, 'tab3.txt');
fid = fopen(tab3_file, 'w');
if fid == -1
    error('Could not open %s for writing.', tab3_file);
end
fprintf(fid, '%s\n', tab3_text);
fclose(fid);



%% Local functions
function share_var = decompose_variance(model_output, steady_state, aggregate_shock, shock_type, series_type)

    series = model_output.(steady_state).(aggregate_shock).(shock_type).(series_type);

    log_omega = series.log_omega;
    lp_avg_dev = series.lp_avg_dev;
    lp_opm_dev = series.lp_opm_dev;

    var_total = var(log_omega + lp_avg_dev + lp_opm_dev);

    C = cov([log_omega + lp_avg_dev, lp_opm_dev]);  
    share_var_lp_avg = sum(C(:, 1))/var_total;
    share_var_lp_opm = sum(C(:, 2))/var_total;

    C = cov([log_omega, lp_avg_dev, lp_opm_dev]);
    share_var_tfp_shock = sum(C(:, 1))/var_total;
    share_var_firm_ladder = sum(C(:, 2))/var_total; 
    share_var_ladder_interaction = sum(C(:, 3))/var_total;

    share_var = [ ...
        share_var_lp_avg; ...
        share_var_lp_opm; ...
        share_var_tfp_shock; ...
        share_var_firm_ladder; ...
        share_var_ladder_interaction; ...
    ];

end

