% Solve and simulate different versions of the model
% Save solution and simulation output to compare across versions

clearvars;
close all;
clc;

% List of model versions to solve and simulate
model_versions = { ...
    'baseline', 'baseline', 'omega_output'; ...
    'baseline', 'baseline', 'omega_and_delta'; ...
    'baseline', 'baseline', 'omega_and_r'; ...
    'baseline', 'baseline', 'omega_and_delta_and_c0'; ...
    'baseline', 'min_c1', 'omega_and_delta_and_c0'; ...
    'mpv2016', 'c1_49_b_0', 'omega_and_delta_and_c0'; ...
};

for j_model = 1:size(model_versions, 1)

    % Choose version of model
    model_type = model_versions{j_model, 1};
    steady_state = model_versions{j_model, 2};
    aggregate_shocks = model_versions{j_model, 3};

    model_parametrization = [steady_state '_' aggregate_shocks];

    fprintf('\n-----------------------------------------------------\n');
    fprintf('Solving model version:\n');
    fprintf('\t%s\n', model_type);
    fprintf('\t%s\n', steady_state);
    fprintf('\t%s\n', aggregate_shocks);
    fprintf('\n-----------------------------------------------------\n');

    % Directories
    project_dir = ['..' filesep '..'];
    params_dir = [project_dir filesep 'data' filesep 'model_parameters' filesep model_type];
    time_series_dir = [project_dir filesep 'data' filesep 'time_series'];

    sol_dir = [project_dir filesep 'data' filesep 'model_solutions' filesep model_type];
    if ~exist(sol_dir, 'dir'); mkdir(sol_dir); end

    sim_dir = [project_dir filesep 'data' filesep 'model_simulations' filesep model_type];
    if ~exist(sim_dir, 'dir'); mkdir(sim_dir); end

    addpath(['..' filesep 'lib' filesep 'utils']);
    addpath(['..' filesep 'lib' filesep model_type]);
    addpath(['..' filesep 'lib' filesep 'common']);

    % Data inputs
    monthly_series = [time_series_dir filesep 'detrended' filesep 'monthly_series.csv'];  

    %% Steady-state at calibrated parameters 
    load([params_dir filesep 'par_steady_state_' steady_state]);

    p = initialize_inputs(steady_state);
    p = initialize_parameters(par, p);

    st = solve_steady_state(p);
    st = prepare_steady_state(st, p);

    %% Krusell-Smith solution 
    file_name = [params_dir filesep 'par_aggregate_shocks_' model_parametrization];
    load(file_name, 'par');

    p = initialize_parameters_aggregate_shocks(p, par);

    ks = initialize_krusellsmith(st, p);

    ks.filename = [sol_dir filesep 'theta_' model_parametrization];
    ks.solve = 1;
    ks.save = 1;

    ks = solve_krusellsmith(ks, st, p);

    %% Business cycle simulation
    phi = solve_surplus_krusellsmith(ks.sim_log_omega, ks, st, p);
    rme = solve_rme(transpose(ks.sim_log_omega), phi, st, p);

    sim_series_m = simulate_time_series(rme, st, p);
    sim_series_m = sim_series_m(ks.tsample, :);
    sim_cyclicality_stats = compute_cyclicality_stats(sim_series_m, 0);

    % simulation_output.shocks_solution.rme = rme;
    simulation_output.shocks_solution.sim_series_m = sim_series_m;
    simulation_output.shocks_solution.cyclicality_stats = sim_cyclicality_stats;

    %% Sequence of shocks to match actual time series
    recent_year_min = 1997;
    recent_year_max = 2018;

    dat_series_m = readtable(monthly_series);

    select = year(dat_series_m.date)>=recent_year_min & year(dat_series_m.date)<=recent_year_max;
    dat_series_m_recent = dat_series_m(select, :);

    names_short = {'gdp', 'lp_micro'};
    names_ts = {'lngdp_hpf_dev', 'lp_wgt_hpf_dev'};

    for k = 1:length(names_short)
        
        disp(['Finding model shocks for ' names_ts{k}]);

        % Find shock corresponding to data
        dat_restricted_series_m = dat_series_m(isfinite(dat_series_m{:, names_ts{k}}), :);
        log_omega = find_shocks_periodbyperiod(ks, st, p, dat_restricted_series_m, names_ts{k});
        
        % Simulate series
        phi = solve_surplus_krusellsmith(log_omega, ks, st, p);
        rme = solve_rme(log_omega, phi, st, p);

        sim_series_m = simulate_time_series(rme, st, p);
        sim_series_m_ma = smoothdata(sim_series_m, 'movmean', [12 12]);
        
        sim_series_m.date = dat_restricted_series_m.date;
        sim_series_m_ma.date = dat_restricted_series_m.date;

        select = year(sim_series_m.date)>=recent_year_min & year(sim_series_m.date)<=recent_year_max;
        sim_series_m_recent = sim_series_m(select, :);
        sim_series_m_ma_recent = sim_series_m_ma(select, :);

        sim_cyclicality_stats = compute_cyclicality_stats(sim_series_m, 0);
        
        % simulation_output.(names_short{k}).rme = rme;
        simulation_output.(names_short{k}).sim_series_m = sim_series_m;
        simulation_output.(names_short{k}).sim_series_m_ma = sim_series_m_ma;
        simulation_output.(names_short{k}).sim_series_m_recent = sim_series_m_recent;
        simulation_output.(names_short{k}).sim_series_m_ma_recent = sim_series_m_ma_recent;
        simulation_output.(names_short{k}).cyclicality_stats = sim_cyclicality_stats;

    end

    % Store simulation output
    save([sim_dir filesep model_parametrization], 'simulation_output');

end 

