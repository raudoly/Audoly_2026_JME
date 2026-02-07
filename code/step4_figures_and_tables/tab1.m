
clearvars;
close all;
clc;

addpath(['..' filesep 'lib' filesep 'utils']);
addpath(['..' filesep 'lib' filesep 'baseline']);
addpath(['..' filesep 'lib' filesep 'common']);

project_dir = ['..' filesep '..'];
params_dir = [project_dir filesep 'data' filesep 'model_parameters' filesep 'baseline'];

tables_dir = [project_dir filesep 'tables'];
if ~exist(tables_dir, 'dir'); mkdir(tables_dir); end


% Solve and simulate steady-state models
steady_state_parametrizations = { ...
    'baseline',         ...
    'min_c1',           ...
};

for j = 1:length(steady_state_parametrizations)
    model_version = steady_state_parametrizations{j};
    
    load([params_dir filesep 'par_steady_state_' model_version], 'par');
    
    p = initialize_inputs(model_version);
    p = initialize_parameters(par, p);
    
    st = solve_steady_state(p);
    st = prepare_steady_state(st, p);
    
    pn = firmpan(st, p);
    if pn.flag
        error('Problem with panel simulation.');
    end
    
    models.(model_version).p = p;
    models.(model_version).st = st;
    models.(model_version).sim_moments = compute_moments(pn, st, p);

end

% Calibrated parameters table
par_list = {...
    'beta', ...
    'n0', ...
    'delta', ...
    'c0', ...
    'c1', ...
    's', ...
    'mu', ...
    'b', ...
    'rho_p', ...
    'sig_p', ...
    };

par_values = zeros(length(par_list), length(steady_state_parametrizations));

for j = 1:length(steady_state_parametrizations)
    model_version = steady_state_parametrizations{j};
    
    par_values(:, j) = [...
        models.(model_version).p.beta; ...
        models.(model_version).p.n0; ...
        models.(model_version).p.delta; ...
        models.(model_version).p.c0; ...
        models.(model_version).p.c1; ...
        models.(model_version).p.s; ...
        models.(model_version).p.mu; ...
        models.(model_version).p.b; ...
        models.(model_version).p.rho_p; ...
        models.(model_version).p.sig_p; ...
    ];

end

par_table = array2table(par_values);
par_table.Properties.VariableNames = steady_state_parametrizations;
par_table.Properties.RowNames = par_list;
    
% Simulated moments table
moment_list = {...
    'ue', ...
    'eu', ...
    'ee', ...
    'empl_avg', ...
    'beta_dlemp_lnp', ...
    'jdst_shr_exit', ...
    'lemp_acl', ...
    'lpdy_iqr', ...
    'firm_size_pareto', ...
    'lwag_iqr', ...
    'beta_lnw_lnp', ...
    'beta_dlemp_lnw', ...
};

sim_moments = zeros(length(moment_list), length(steady_state_parametrizations));

for j = 1:length(steady_state_parametrizations)
    moments = models.(steady_state_parametrizations{j}).sim_moments;
    for k = 1:length(moment_list)
        sim_moments(k, j) = moments.(moment_list{k});
    end
end

moments = [zeros(length(moment_list), 1) sim_moments];
data_moments = load_data_moments;

for j = 1:length(moment_list)
    moments(j, 1) = data_moments.(moment_list{j});
end

moments_table = array2table(moments);
moments_table.Properties.VariableNames = ['data', steady_state_parametrizations];
moments_table.Properties.RowNames = moment_list;

% Format and show table
line_sep = repmat('-', 1, 80);

par_table_str = evalc('disp(par_table)');
par_table_str = regexprep(par_table_str, '\s+$', '');
par_table_str = regexprep(par_table_str, '<[^>]+>', '');

moments_table_str = evalc('disp(moments_table)');
moments_table_str = regexprep(moments_table_str, '\s+$', '');
moments_table_str = regexprep(moments_table_str, '<[^>]+>', '');

tab1_lines = {
    line_sep
    'TABLE 1: Calibrated parameters and targeted moments in steady-state model.'
    line_sep
    'Panel A and Panel B'
    line_sep
    par_table_str
    line_sep
    'Panel C and Panel D'
    line_sep
    moments_table_str
    line_sep
    };

tab1_text = strjoin(tab1_lines, newline);

disp(tab1_text);

tab1_file = fullfile(tables_dir, 'tab1.txt');
fid = fopen(tab1_file, 'w');
if fid == -1
    error('Could not open %s for writing.', tab1_file);
end
fprintf(fid, '%s\n', tab1_text);
fclose(fid);




