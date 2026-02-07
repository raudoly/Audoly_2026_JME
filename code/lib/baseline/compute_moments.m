function moments = compute_moments(pn, st, p)
% Compute summary statistics.

% pn: 	simulated panel of firms
% st: 	steady-state solution
% p: 	parameters

age_max_yng = 5; % Definition for age of young firms

% Labor market moments
lm_stats = compute_lm_stats(st, p);

% Shimer correction, similar to data
moments.ue = -log(1 - lm_stats.ue);
moments.eu = -log(1 - lm_stats.eu);
moments.ee = -log(1 - lm_stats.ee);

% Macro firm dynamics moments
% (directly from model solution)
moments.empl_avg = sum(st.dL)/sum(st.dK);
moments.exit_shr = 12*sum(~st.chi.*st.dK)/sum(st.dK);

% Micro firm dynamics moments
% (from panel simulation)
acti = pn.active(:);
death = pn.death(acti);
lpdy = pn.lpdy(acti);
lwag = pn.lwag(acti);
age = pn.age(acti);
emp = pn.emp(acti);

moments.empl_avg_sim = mean(emp);
moments.exit_shr_sim = sum(death)/sum(acti);

moments.firm_shr_yng = mean(age<age_max_yng);
moments.empl_shr_yng = sum(emp(age<age_max_yng))/sum(emp);
moments.exit_shr_yng = sum(death(age<age_max_yng))/sum(age<age_max_yng);

% Labor productivity/wage dispersion measures
moments.lpdy_iqr = iqr(lpdy);
moments.lpdy_idr = idr(lpdy);

moments.lwag_iqr = iqr(lwag);
moments.lwag_idr = idr(lwag);

moments.lpdy_iqr_yng = iqr(lpdy(age<age_max_yng));
moments.lpdy_idr_yng = idr(lpdy(age<age_max_yng));

% Difference in average labor productivity
moments.lpdy_avg_diff = mean(lpdy(age>=age_max_yng)) - mean(lpdy(age<age_max_yng));

% Autocorrelation labor productivity and employment
acti_now = pn.active(:, 2:end);
acti_lag = pn.active(:, 1:end-1);

surv = acti_now(:) & acti_lag(:);

lpdy_now = pn.lpdy(:, 2:end);
lpdy_now = lpdy_now(:);
lpdy_now = lpdy_now(surv);
lpdy_lag = pn.lpdy(:, 1:end-1);
lpdy_lag = lpdy_lag(:);
lpdy_lag = lpdy_lag(surv);

moments.lpdy_acl = corr_xy(lpdy_now, lpdy_lag);

lemp_now = pn.lemp(:, 2:end);
lemp_now = lemp_now(:);
lemp_now = lemp_now(surv);
lemp_lag = pn.lemp(:, 1:end-1);
lemp_lag = lemp_lag(:);
lemp_lag = lemp_lag(surv);

moments.lemp_acl = corr_xy(lemp_now, lemp_lag);

% Regression employment growth on productivity
dlemp = lemp_now - lemp_lag;

moments.beta_dlemp_lnp = reg_yx(dlemp, lpdy_lag);

% Regression employment growth on wages
lwag_lag = pn.lwag(:, 1:end-1);
lwag_lag = lwag_lag(:);
lwag_lag = lwag_lag(surv);

moments.beta_dlemp_lnw = reg_yx(dlemp, lwag_lag);

% Regression wages on productivity
moments.beta_lnw_lnp = reg_yx(lwag, lpdy);

% Job destruction exit
emp_now = pn.emp(:, 2:end);
emp_lag = pn.emp(:, 1:end-1);

shrink = (emp_lag - emp_now)>0.0;
shrink = shrink(:);

jdest_surv = sum(emp_lag(shrink & surv) - emp_now(shrink & surv));
jdest_exit = sum(emp_lag(acti_lag & ~acti_now));

moments.jdst_shr_exit = jdest_exit/(jdest_exit + jdest_surv);

% Right tail of firm-size distribution
[ccdf_emp_sim, norm_emp_sim] = ecdf(emp/moments.empl_avg_sim, 'Function', 'survivor');

norm_emp_sim = norm_emp_sim(1:end-1);
ccdf_emp_sim = ccdf_emp_sim(1:end-1);

select = norm_emp_sim>=1.0;
pareto_coef = reg_yx(log(ccdf_emp_sim(select)), log(norm_emp_sim(select)));

moments.firm_size_pareto = -pareto_coef;

norm_emp = [1; 10; 100; 1000; 10000];
ccdf_emp = 999.0*ones(size(norm_emp));

moments.firm_size_tail = table(norm_emp, ccdf_emp);

for j = 1:height(moments.firm_size_tail)

    is_greater_j = norm_emp_sim>=moments.firm_size_tail.norm_emp(j);

    if any(is_greater_j)
        norm_emp_index = find(is_greater_j, 1);
        moments.firm_size_tail.ccdf_emp(j) = ccdf_emp_sim(norm_emp_index);
    end

end

% OP covariance term
emp_share = emp/sum(emp);

moments.op_cov = sum((lpdy - mean(lpdy)).*(emp_share - mean(emp_share)))/sum(acti);
moments.op_cor = corr_xy(lpdy, emp_share);
moments.op_rankcor = corr_xy(lpdy, emp_share, 'Spearman');


% - Local functions - %

% Inter-decile range
function y = idr(x)

y = diff(prctile(x, [10; 90]));



