clearvars;
close all;
clc;

addpath(['..' filesep 'lib' filesep 'utils']);
addpath(['..' filesep 'lib' filesep 'baseline']);
addpath(['..' filesep 'lib' filesep 'common']);

% Directories
project_dir = ['..' filesep '..'];
time_series_dir = [project_dir filesep 'data' filesep 'time_series'];
par_dir = [project_dir filesep 'data' filesep 'model_parameters'];
sim_dir = [project_dir filesep 'data' filesep 'model_simulations'];

tables_dir = [project_dir filesep 'tables'];
if ~exist(tables_dir, 'dir'); mkdir(tables_dir); end


%% -- Data stats -- %%

monthly_series = [time_series_dir filesep 'detrended' filesep 'monthly_series.csv'];  
dat_series_m = readtable(monthly_series);
dat_cyclicality_stats = compute_cyclicality_stats(dat_series_m, 1);


%% -- Load model simulations -- %%

% Baseline steady-state model
list_aggregate_shocks = { ...
    'omega_output', ...
    'omega_and_r', ...
    'omega_and_delta', ...
    'omega_and_delta_and_c0', ...
};

list_steady_states = {'baseline'};

for j_aggregate_shock = 1:length(list_aggregate_shocks)
    for j_steady_state = 1:length(list_steady_states)
        
        steady_state = list_steady_states{j_steady_state};
        aggregate_shock = list_aggregate_shocks{j_aggregate_shock};
        
        file_name = [par_dir filesep 'baseline' filesep 'par_aggregate_shocks_' steady_state '_' aggregate_shock];
        load(file_name, 'par');
        p = initialize_inputs();
        p = initialize_parameters_aggregate_shocks(p, par);

        file_name = [sim_dir filesep 'baseline' filesep steady_state '_' aggregate_shock];
        load(file_name, 'simulation_output');
        fdrs.(steady_state).(aggregate_shock) = simulation_output;
        fdrs.(steady_state).(aggregate_shock).p = p;
    end
end

% c_1 = 1 steady-state model
list_aggregate_shocks = {'omega_and_delta_and_c0'};
list_steady_states = {'min_c1'};

for j_aggregate_shock = 1:length(list_aggregate_shocks)
    for j_steady_state = 1:length(list_steady_states)
        
        steady_state = list_steady_states{j_steady_state};
        aggregate_shock = list_aggregate_shocks{j_aggregate_shock};
        
        file_name = [par_dir filesep 'baseline' filesep 'par_aggregate_shocks_' steady_state '_' aggregate_shock];
        load(file_name, 'par');
        p = initialize_inputs();
        p = initialize_parameters_aggregate_shocks(p, par);

        file_name = [sim_dir filesep 'baseline' filesep steady_state '_' aggregate_shock];
        load(file_name, 'simulation_output');
        fdrs.(steady_state).(aggregate_shock) = simulation_output;
        fdrs.(steady_state).(aggregate_shock).p = p;
    end
end


%% -- Business cycle properties table in FDRS model -- %%

% Parameters
tab_cyclicality_parameters = table( ...
    select_params(fdrs.baseline.omega_output.p), ...
    select_params(fdrs.baseline.omega_and_r.p), ...
    select_params(fdrs.baseline.omega_and_delta.p), ...
    select_params(fdrs.baseline.omega_and_delta_and_c0.p), ...
    select_params(fdrs.min_c1.omega_and_delta_and_c0.p));

tab_cyclicality_parameters.Properties.VariableNames = { ...
    'baseline_omega_output', ...
    'baseline_omega_and_r', ...
    'baseline_omega_and_delta', ...
    'baseline_omega_and_delta_and_c0', ...
    'min_c1_omega_and_delta_and_c0'};

tab_cyclicality_parameters.Properties.RowNames = { ...
    'rho_omega', ...
    'sig_omega', ...
    'elast_r_to_omega', ...
    'elast_delta_to_omega', ... 
    'elast_c0_to_omega'};

% Cyclicality stats
tab_cyclicality_stats = table( ...
    select_stats(dat_cyclicality_stats), ...
    select_stats(fdrs.baseline.omega_output.shocks_solution.cyclicality_stats), ...
    select_stats(fdrs.baseline.omega_and_r.shocks_solution.cyclicality_stats), ...
    select_stats(fdrs.baseline.omega_and_delta.shocks_solution.cyclicality_stats), ...
    select_stats(fdrs.baseline.omega_and_delta_and_c0.shocks_solution.cyclicality_stats), ...
    select_stats(fdrs.min_c1.omega_and_delta_and_c0.shocks_solution.cyclicality_stats));

tab_cyclicality_stats.Properties.VariableNames = { ...
    'data', ...
    'baseline_omega_output', ...
    'baseline_omega_and_r', ...
    'baseline_omega_and_delta', ...
    'baseline_omega_and_delta_and_c0', ...
    'min_c1_omega_and_delta_and_c0'};

tab_cyclicality_stats.Properties.RowNames = { ...
    'acl_lngdp', ...
    'std_lngdp', ...
    'std_ue', ...
    'std_eu', ...
    'std_ee'};

% Format and show table
line_sep = repmat('-', 1, 200);

tab_cyclicality_parameters_str = evalc('disp(tab_cyclicality_parameters)');
tab_cyclicality_parameters_str = regexprep(tab_cyclicality_parameters_str, '\s+$', '');
tab_cyclicality_parameters_str = regexprep(tab_cyclicality_parameters_str, '<[^>]+>', '');

tab_cyclicality_stats_str = evalc('disp(tab_cyclicality_stats)');
tab_cyclicality_stats_str = regexprep(tab_cyclicality_stats_str, '\s+$', '');
tab_cyclicality_stats_str = regexprep(tab_cyclicality_stats_str, '<[^>]+>', '');

tab2_lines = {
    'TABLE 2: Cyclical properties of full model with alternative aggregate shocks.'
    line_sep
    'Panel A: Aggregate shock parameters'
    line_sep
    tab_cyclicality_parameters_str
    line_sep
    'Panel B: Business cycle moments'
    line_sep
    tab_cyclicality_stats_str
    line_sep
    };

tab2_text = strjoin(tab2_lines, newline);

disp(tab2_text);

tab2_file = fullfile(tables_dir, 'tab2.txt');
fid = fopen(tab2_file, 'w');
if fid == -1
    error('Could not open %s for writing.', tab2_file);
end
fprintf(fid, '%s\n', tab2_text);
fclose(fid);




%% -- Local functions -- %%

function selected_parameters = select_params(p)

    selected_parameters = [
        p.rho_omega;
        p.sig_omega;
        p.elast_r_to_omega;
        p.elast_delta_to_omega;
        p.elast_c0_to_omega;
    ];

end

function selected_stats = select_stats(stats)

    row_names = stats.Properties.RowNames;

    selected_stats = [
        stats.acl(strcmp(row_names, 'lngdp'));
        stats.std(strcmp(row_names, 'lngdp'));
        stats.std(strcmp(row_names, 'ue'));
        stats.std(strcmp(row_names, 'eu'));
        stats.std(strcmp(row_names, 'ee'));
    ];

end