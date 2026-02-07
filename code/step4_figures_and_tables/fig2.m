
clearvars;
close all;
clc;

addpath(['..' filesep 'lib' filesep 'utils']);

% Directories
project_dir = ['..' filesep '..'];
time_series_dir = [project_dir filesep 'data' filesep 'time_series'];
sim_dir = [project_dir filesep 'data' filesep 'model_simulations'];

figures_dir = [project_dir filesep 'figures'];
if ~exist(figures_dir,  'dir'); mkdir(figures_dir); end 

% Figure options
fig = figure_options();

% Data inputs
monthly_series = [time_series_dir filesep 'detrended' filesep 'monthly_series.csv'];  
yearly_series = [time_series_dir filesep 'detrended' filesep 'yearly_series.csv'];  

recessions = readtable([time_series_dir filesep 'recessions_uk' filesep 'dates.csv']);

recent_year_min = 1997;
recent_year_max = 2018;

dat_series_m = readtable(monthly_series);
dat_series_y = readtable(yearly_series);

select = year(dat_series_m.date)>=recent_year_min & year(dat_series_m.date)<=recent_year_max;
dat_series_m_recent = dat_series_m(select, :);

select = year(dat_series_y.date)>=recent_year_min & year(dat_series_y.date)<=recent_year_max;
dat_series_y_recent = dat_series_y(select, :);


%% -- Load model solution -- %%

aggregate_shocks = 'omega_and_delta_and_c0';
steady_state = 'baseline';

file_name = [sim_dir filesep 'baseline' filesep steady_state '_' aggregate_shocks];
load(file_name,  'simulation_output');



%% -- Plot worker reallocation across recessions -- %%
series_names = {'log_omega',  'lp_wgt_dev',  'lp_avg_dev',  'lp_opm_dev'};

year_after = 4;
n_months = year_after*12 + 1;

n_ts = length(series_names);
n_recessions = height(recessions) - 1; % Covid not in analysis

irf = zeros(n_months, n_ts, n_recessions);
df = simulation_output.gdp.sim_series_m;

for j_rec = 1:n_recessions
    episode_start = recessions.start_date(j_rec);
    episode_end = dateshift(episode_start + calmonths(n_months-1), 'end', 'month');

    df_episode = df((df.date>=episode_start) & (df.date<=episode_end), :);

    for j_ts = 1:n_ts
        y = df_episode{:, series_names{j_ts}};
        y = y - y(1);
        irf(:, j_ts, j_rec) = y;
    end

end

irf_avg = array2table(mean(irf, 3), 'VariableNames', series_names);
irf_std = array2table(std(irf, 0, 3), 'VariableNames', series_names);

% Great recession only
episode_start = recessions.start_date(n_recessions);
episode_end = dateshift(episode_start + calmonths(n_months-1), 'end', 'month');

df = simulation_output.gdp.sim_series_m_ma;
df = df((df.date>=episode_start) & (df.date<=episode_end), :);

irf_gr = zeros(n_months, n_ts);

for j_ts = 1:n_ts
    y = df{:, series_names{j_ts}};
    y = y - y(1);
    irf_gr(:, j_ts) = y;
end

irf_gr = array2table(irf_gr, 'VariableNames', series_names);

%% -- Plot responses decomposition -- %%

close all;

line_width = 2.0;
legend_names = { ...
    'Great Recession (start 2008m3)',  ... 
    'Average across recessions',  ... 
    '+/- 1 standard deviation',  ... 
};

% TFP shock
ylab = 'Aggregate shock: deviation from start of recession';

t = (0:n_months-1)';
y1 = irf_avg.log_omega;
y2 = irf_gr.log_omega;
y3 = irf_avg.log_omega - 1*irf_std.log_omega;
y4 = irf_avg.log_omega + 1*irf_std.log_omega;

f_decomp_irf_shocks = figure();
ax = axes();
plt = plot(t, [y1 y2 y3 y4]);

plt(1).LineStyle = '-';
plt(1).LineWidth = line_width;
plt(1).Color = fig.blue;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.green;

plt(3).LineStyle = ':';
plt(3).LineWidth = line_width;
plt(3).Color = fig.gray;

plt(4).LineStyle = ':';
plt(4).LineWidth = line_width;
plt(4).Color = fig.gray;

grid on;

ax.XLim = [t(1), t(end)];
ax.YLim = [-0.04, +0.02];
xlabel('Month after start of recession');
ylabel(ylab);
yline(0);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_decomp_irf_shocks, fig.size{:});


% Weighted term 
ylab = 'Worker ladder: deviation from start of recession';

t = (0:n_months-1)';
y1 = irf_gr.lp_wgt_dev;
y2 = irf_avg.lp_wgt_dev;
y3 = irf_avg.lp_wgt_dev - 1*irf_std.lp_wgt_dev;
y4 = irf_avg.lp_wgt_dev + 1*irf_std.lp_wgt_dev;

f_decomp_irf_wgt = figure();
ax = axes();
plt = plot(t, [y1 y2 y3 y4]);

plt(1).LineStyle = '-';
plt(1).LineWidth = line_width;
plt(1).Color = fig.blue;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.green;

plt(3).LineStyle = ':';
plt(3).LineWidth = line_width;
plt(3).Color = fig.gray;

plt(4).LineStyle = ':';
plt(4).LineWidth = line_width;
plt(4).Color = fig.gray;

grid on;

ax.XLim = [t(1), t(end)];
ax.YLim = [-0.07, +0.01];
xlabel('Month after start of recession');
ylabel(ylab);
yline(0);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_decomp_irf_wgt, fig.size{:});

% Unweighted term 
ylab = 'Firm ladder: deviation from start of recession';

t = (0:n_months-1)';
y1 = irf_gr.lp_avg_dev;
y2 = irf_avg.lp_avg_dev;
y3 = irf_avg.lp_avg_dev - 1*irf_std.lp_avg_dev;
y4 = irf_avg.lp_avg_dev + 1*irf_std.lp_avg_dev;

f_decomp_irf_avg = figure();
ax = axes();
plt = plot(t, [y1 y2 y3 y4]);

plt(1).LineStyle = '-';
plt(1).LineWidth = line_width;
plt(1).Color = fig.blue;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.green;

plt(3).LineStyle = ':';
plt(3).LineWidth = line_width;
plt(3).Color = fig.gray;

plt(4).LineStyle = ':';
plt(4).LineWidth = line_width;
plt(4).Color = fig.gray;

grid on;

ax.XLim = [t(1), t(end)];
ax.YLim = [-0.07, +0.01];
xlabel('Month after start of recession');
ylabel(ylab);
yline(0);
legend(plt, legend_names, 'location', 'best');

set(ax, fig.font{:});
set(f_decomp_irf_avg, fig.size{:});

% Interaction term
ylab = 'OP: deviation from start of recession';

t = (0:n_months-1)';
y1 = irf_gr.lp_opm_dev;
y2 = irf_avg.lp_opm_dev;
y3 = irf_avg.lp_opm_dev - 1*irf_std.lp_opm_dev;
y4 = irf_avg.lp_opm_dev + 1*irf_std.lp_opm_dev;

f_decomp_irf_opm = figure();
ax = axes();
plt = plot(t, [y1 y2 y3 y4]);

plt(1).LineStyle = '-';
plt(1).LineWidth = line_width;
plt(1).Color = fig.blue;

plt(2).LineStyle = '-';
plt(2).LineWidth = line_width;
plt(2).Color = fig.green;

plt(3).LineStyle = ':';
plt(3).LineWidth = line_width;
plt(3).Color = fig.gray;

plt(4).LineStyle = ':';
plt(4).LineWidth = line_width;
plt(4).Color = fig.gray;

grid on;

ax.XLim = [t(1),  t(end)];
ax.YLim = [-0.02,  +0.01];
xlabel('Month after start of recession');
ylabel(ylab);
yline(0);
legend(plt,  legend_names,  'location',  'best');

set(ax,  fig.font{:});
set(f_decomp_irf_opm,  fig.size{:});

% Save graphs
exportgraphics(f_decomp_irf_shocks,  [figures_dir filesep 'fig2a' fig.fmt]);    
exportgraphics(f_decomp_irf_wgt,  [figures_dir filesep 'fig2b' fig.fmt]);
exportgraphics(f_decomp_irf_avg,  [figures_dir filesep 'fig2c' fig.fmt]);
exportgraphics(f_decomp_irf_opm,  [figures_dir filesep 'fig2d' fig.fmt]);
