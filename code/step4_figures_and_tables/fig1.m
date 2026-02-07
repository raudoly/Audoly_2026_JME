
clearvars;
close all;
clc;

addpath(['..' filesep 'lib' filesep 'utils']);

% Directories
project_dir = ['..' filesep '..'];
time_series_dir = [project_dir filesep 'data' filesep 'time_series'];
sim_dir = [project_dir filesep 'data' filesep 'model_simulations'];

figures_dir = [project_dir filesep 'figures'];
if ~exist(figures_dir, 'dir'); mkdir(figures_dir); end 

% Figure options
fig = figure_options();

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

list_aggregate_shocks = {'omega_and_delta_and_c0'};
list_steady_states = {'baseline', 'min_c1'};
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


%% -- Labor productivity decompositions: Baseline vs least curvature -- %%

close all;
line_width = 2.0;
marker_size = 7;

span_y = [-0.025, +0.025];
legend_names = {'Data', 'Baseline', 'Least curvature (c_1 = 1)'};

% Weighted firm productivity
ylab = 'Weighted average of LP_{i,t}: deviation from trend';

t1 = dat_series_y_recent.date;
y1 = dat_series_y_recent.lp_wgt_hpf_dev;

t2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.lp_wgt_dev + fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.log_omega;

t3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.lp_wgt_dev + fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.log_omega;

f_lp_wgt = figure();
ax = axes();
plt = plot(t1, y1, t2, y2, t3, y3);

plt(1).LineStyle = '--';
plt(1).LineWidth = line_width;
plt(1).Color = fig.black;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = fig.black;
plt(1).MarkerSize = marker_size;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.blue;

plt(3).LineStyle = '-';
plt(3).LineWidth = line_width;
plt(3).Color = fig.red;

grid on;

ylim(ax, span_y);

recessionplot('axes', ax, 'recessions', [recessions.start_date, recessions.end_date]);
ylabel(ylab);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_lp_wgt, fig.size{:});

% Unweighted firm productivity
ylab = 'Unweighted average of LP_{i, t}: deviation from trend';

t1 = dat_series_y_recent.date;
y1 = dat_series_y_recent.lp_avg_hpf_dev;

t2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.lp_avg_dev + fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.log_omega;

t3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.lp_avg_dev + fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.log_omega;

f_lp_avg = figure();
ax = axes();
plt = plot(t1, y1, t2, y2, t3, y3);

plt(1).LineStyle = '--';
plt(1).LineWidth = line_width;
plt(1).Color = fig.black;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = fig.black;
plt(1).MarkerSize = marker_size;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.blue;

plt(3).LineStyle = '-';
plt(3).LineWidth = line_width;
plt(3).Color = fig.red;

grid on;

ylim(ax, span_y);

recessionplot('axes', ax, 'recessions', [recessions.start_date, recessions.end_date]);
ylabel(ylab);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_lp_avg, fig.size{:});

% OP productivity term 
ylab = 'Interaction term of LP_{i, t}: deviation from trend';

t1 = dat_series_y_recent.date;
y1 = dat_series_y_recent.lp_opm_hpf_dev;

t2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.lp_opm_dev;

t3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.lp_opm_dev;

f_lp_opm = figure();
ax = axes();
plt = plot(t1, y1, t2, y2, t3, y3);

plt(1).LineStyle = '--';
plt(1).LineWidth = line_width;
plt(1).Color = fig.black;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = fig.black;
plt(1).MarkerSize = marker_size;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.blue;

plt(3).LineStyle = '-';
plt(3).LineWidth = line_width;
plt(3).Color = fig.red;

grid on;

ylim(ax, span_y);

recessionplot('axes', ax, 'recessions', [recessions.start_date, recessions.end_date]);
ylabel(ylab);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_lp_opm, fig.size{:});

%  Weighted employment cost
ylab = 'Weighted average of EC_{i, t}: deviation from trend';

t1 = dat_series_y_recent.date;
y1 = dat_series_y_recent.ec_wgt_hpf_dev;

t2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.ec_wgt_dev;

t3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.ec_wgt_dev;

f_ec_wgt = figure();
ax = axes();
plt = plot(t1, y1, t2, y2, t3, y3);

plt(1).LineStyle = '--';
plt(1).LineWidth = line_width;
plt(1).Color = fig.black;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = fig.black;
plt(1).MarkerSize = marker_size;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.blue;

plt(3).LineStyle = '-';
plt(3).LineWidth = line_width;
plt(3).Color = fig.red;

grid on;
ylim(ax, span_y);

recessionplot('axes', ax, 'recessions', [recessions.start_date, recessions.end_date]);
ylabel(ylab);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_ec_wgt, fig.size{:});

% Unweighted employment cost
ylab = 'Unweighted average of EC_{i, t}: deviation from trend';

t1 = dat_series_y_recent.date;
y1 = dat_series_y_recent.ec_avg_hpf_dev;

t2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.ec_avg_dev;

t3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.ec_avg_dev;

f_ec_avg = figure();
ax = axes();
plt = plot(t1, y1, t2, y2, t3, y3);

plt(1).LineStyle = '--';
plt(1).LineWidth = line_width;
plt(1).Color = fig.black;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = fig.black;
plt(1).MarkerSize = marker_size;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.blue;

plt(3).LineStyle = '-';
plt(3).LineWidth = line_width;
plt(3).Color = fig.red;

grid on;
ylim(ax, span_y);

recessionplot('axes', ax, 'recessions', [recessions.start_date, recessions.end_date]);
ylabel(ylab);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_ec_avg, fig.size{:});

% Employment cost interaction term 
ylab = 'Interaction term of EC_{i, t}: deviation from trend';

t1 = dat_series_y_recent.date;
y1 = dat_series_y_recent.ec_opm_hpf_dev;

t2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y2 = fdrs.baseline.(aggregate_shock).lp_micro.sim_series_m_ma_recent.ec_opm_dev;

t3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.date;
y3 = fdrs.min_c1.(aggregate_shock).lp_micro.sim_series_m_ma_recent.ec_opm_dev;

f_ec_opm = figure();
ax = axes();
plt = plot(t1, y1, t2, y2, t3, y3);

plt(1).LineStyle = '--';
plt(1).LineWidth = line_width;
plt(1).Color = fig.black;
plt(1).Marker = 's';
plt(1).MarkerFaceColor = fig.black;
plt(1).MarkerSize = marker_size;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.blue;

plt(3).LineStyle = '-';
plt(3).LineWidth = line_width;
plt(3).Color = fig.red;

grid on;
ylim(ax, span_y);

recessionplot('axes', ax, 'recessions', [recessions.start_date, recessions.end_date]);
ylabel(ylab);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_ec_opm, fig.size{:});

% Save plots
exportgraphics(f_lp_wgt, [figures_dir filesep 'fig1a' fig.fmt]);
exportgraphics(f_lp_avg, [figures_dir filesep 'fig1c' fig.fmt]);
exportgraphics(f_lp_opm, [figures_dir filesep 'fig1e' fig.fmt]);
exportgraphics(f_ec_wgt, [figures_dir filesep 'fig1b' fig.fmt]);
exportgraphics(f_ec_avg, [figures_dir filesep 'fig1d' fig.fmt]);
exportgraphics(f_ec_opm, [figures_dir filesep 'fig1f' fig.fmt]);


