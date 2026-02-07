% Simulate moments from steady-state of the model
function moments = simulate_moments(st, p)

% Labor market stats
lm_stats = simulate_lm_stats(st, p);

% Basic firm stats
sim_number_firms = round(1e6*st.chi.*p.dP);
sim_lpdy = repelem(log(p.p), sim_number_firms);
sim_lwag = repelem(log(st.w), sim_number_firms);
sim_empl = repelem(st.n, sim_number_firms);

lpdy_iqr = diff(quantile(sim_lpdy, [.25; .75]));
lpdy_idr = diff(quantile(sim_lpdy, [.10; .90]));

lwag_iqr = diff(quantile(sim_lwag, [.25; .75]));
lwag_idr = diff(quantile(sim_lwag, [.10; .90]));

empl_avg = mean(sim_empl);
% empl_avg = sum(st.n.*p.dP)/sum(p.dP);

% Right tail of firm-size distribution
[ccdf_emp_sim, norm_emp_sim] = ecdf(sim_empl/empl_avg, 'Function', 'survivor');

norm_emp_sim = norm_emp_sim(1:end-1);
ccdf_emp_sim = ccdf_emp_sim(1:end-1);

select = norm_emp_sim>=1.0;
pareto_coef = reg_yx(log(ccdf_emp_sim(select)), log(norm_emp_sim(select)));
firm_size_pareto = -pareto_coef;

norm_emp = [1; 10; 100; 1000; 10000];
ccdf_emp = 999.0*ones(size(norm_emp));

firm_size_tail = table(norm_emp, ccdf_emp);

for j = 1:height(firm_size_tail)

    is_greater_j = norm_emp_sim>=firm_size_tail.norm_emp(j);

    if any(is_greater_j)
        norm_emp_index = find(is_greater_j,1);
        firm_size_tail.ccdf_emp(j) = ccdf_emp_sim(norm_emp_index);
    end

end

% OP covariance term
empl_share = sim_empl/sum(sim_empl);

op_cov = sum((sim_lpdy - mean(sim_lpdy)).*(empl_share - mean(empl_share)));
op_cov = op_cov/sum(sim_number_firms);
op_cor = corr_xy(sim_lpdy, empl_share);
op_rankcor = corr_xy(sim_lpdy, empl_share, 'Spearman');

% Pack up
moments.u = lm_stats.u;
moments.v = lm_stats.v;

moments.ue = lm_stats.ue;
moments.eu = lm_stats.eu;
moments.ee = lm_stats.ee;

moments.lpdy_iqr = lpdy_iqr;
moments.lpdy_idr = lpdy_idr;
moments.lwag_iqr = lwag_iqr;
moments.lwag_idr = lwag_idr;
moments.empl_avg = empl_avg;

moments.firm_size_pareto = firm_size_pareto;
moments.firm_size_tail = firm_size_tail;

moments.op_cov = op_cov;
moments.op_cor = op_cor;
moments.op_rankcor = op_rankcor;



    


