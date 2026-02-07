function stats_table = show_fit_business_cycle(sim, dat, save_it, model_version)
% Show fit to business cycle stats.

if nargin<3
	save_it = 0;
end

rownames = sim.Properties.RowNames;
colnames = {'Simulation', 'Data'};

std_fit = table(sim.std, dat.std, 'VariableNames', colnames, 'RowNames', strcat('std_', rownames));
acl_fit = table(sim.acl, dat.acl, 'VariableNames', colnames, 'RowNames', strcat('acl_', rownames));
cor_fit = table(sim.cor, dat.cor, 'VariableNames', colnames, 'RowNames', strcat('cor_', rownames));
% min_fit = table(sim.min,dat.min,'VariableNames',colnames,'RowNames',strcat('min_',rownames));
% max_fit = table(sim.max,dat.max,'VariableNames',colnames,'RowNames',strcat('max_',rownames));

stats_table = [std_fit;acl_fit;cor_fit];

if nargout<1
    disp('Summary fit cyclicality stats:');
    disp(stats_table);
end

% disp('Range fit cyclicality stats:')
% range_stats_table = [min_fit;max_fit];
% disp(range_stats_table);

if save_it
    wb_name = 'tables/02_fit_aggregate_shocks.xlsx';
    sheet_name = ['fit_',model_version];
    if length(sheet_name)>31
        sheet_name = sheet_name(1:31);
    end
    writetable(stats_table, wb_name, 'Sheet', sheet_name, 'WriteRowNames', 1);
end

