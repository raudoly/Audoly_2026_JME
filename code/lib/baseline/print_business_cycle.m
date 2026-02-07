function print_business_cycle(rme,ks,st,p,save_results,suffix)
% Compute business cycle stats.

if nargin<5
    save_results = false;
end

if nargin<6
    suffix = '';
end

% Simulate and detrend quarterly time series
detrended_series = simulate_time_series(rme,st,p);
detrended_series = detrended_series(ks.tsample_q,:);

% Compute business cycle stats on simulated data
series = {...
    'lngdp_dev',...
    'lnalp_dev',...
    'u_dev',...
    'lnu_dev',...
    'lnv_dev',...
    'ue_dev',...
    'eu_dev',...
    'ee_dev',...
    'lnue_dev',...
    'lneu_dev',...
    'lnee_dev'};

N = length(series);

std_sim = zeros(N,1);
acl_sim = zeros(N,1);
corr_with_gdp_sim = zeros(N,1);

for j = 1:N
    std_sim(j) = std(detrended_series{:,series(j)});
    acl_sim(j) = corr_xy(detrended_series{1:end-1,series(j)},detrended_series{2:end,series(j)});
    corr_with_gdp_sim(j) = corr_xy(detrended_series{:,'lngdp_dev'},detrended_series{:,series(j)});
end

cyclicality_stats = table(std_sim,acl_sim,corr_with_gdp_sim);
cyclicality_stats.Properties.RowNames = series;

% Results
disp('Business cycle stats:');
disp(cyclicality_stats);

% Classify recessions
% erg_dist_omega = null(ks.tQ - eye(ks.ns));
% erg_dist_omega = erg_dist_omega/sum(erg_dist_omega);
% 
% std_log_omega = sqrt(sum((ks.log_omega.^2).*erg_dist_omega));
% 
% shock_sml = -2*std_log_omega<=rme.log_omega & rme.log_omega<-std_log_omega; 
% shock_big = -2*std_log_omega>rme.log_omega;

% Cyclicality productivity decomposition
% lp_wgt_st = sum(p.lnp.*st.dLp)/sum(st.dLp);
% lp_avg_st = sum(p.lnp.*st.dKp)/sum(st.dKp);
% lp_opm_st = lp_wgt_st - lp_avg_st;
% 
% avg_sml_lp_avg = mean(lp_avg(shock_sml) - lp_avg_st);
% avg_sml_lp_opm = mean(lp_opm(shock_sml) - lp_opm_st);
% avg_sml_lp_wgt = mean(lp_wgt(shock_sml) - lp_wgt_st);
% 
% avg_big_lp_avg = mean(lp_avg(shock_big) - lp_avg_st);
% avg_big_lp_opm = mean(lp_opm(shock_big) - lp_opm_st);
% avg_big_lp_wgt = mean(lp_wgt(shock_big) - lp_wgt_st);
% 
% table_decomposition = table(...
%     [avg_sml_lp_avg;avg_sml_lp_opm;avg_sml_lp_wgt],...
%     [avg_big_lp_avg;avg_big_lp_opm;avg_big_lp_wgt],...
%     'VariableNames',{'SmallerShocks','LargerShocks'},...
%     'RowNames',{'firm sel.','misalloc.','net effect'});

% disp('Productivity decomposition:')
% disp(table_decomposition);

if save_results       
    
    filename = '../tables/_make_tables.xlsx';
    
    sheetname = ['raw_cyc_stats',suffix];
    writetable(tab_cyclicality,filename,'Sheet',sheetname,'WriteRowNames',1);
    
    % sheetname = ['raw_cyc_dec',suffix];
    % writetable(table_decomposition,filename,'Sheet',sheetname,'WriteRowNames',1);

end


function r = corr_xy(x,y)
% Wrapper around corr.

R = corr([x y]);
r = R(2,1);
