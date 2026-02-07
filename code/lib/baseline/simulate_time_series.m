function detrended_series = simulate_time_series(rme, st, p)
% Simulate aggregate time series in a Rank-Monotonic Equilibrium.
% Detrended series: deviation from steady-state

% Monthly time series
u = zeros(rme.T, 1);
v = zeros(rme.T, 1);

ue = zeros(rme.T, 1);
eu = zeros(rme.T, 1);
ee = zeros(rme.T, 1);

gdp = zeros(rme.T, 1);
alp = zeros(rme.T, 1);

lp_wgt = zeros(rme.T, 1);
lp_avg = zeros(rme.T, 1);
lp_opm = zeros(rme.T, 1);

ec_wgt = zeros(rme.T, 1);
ec_avg = zeros(rme.T, 1);
ec_opm = zeros(rme.T, 1);

firm_entr = zeros(rme.T, 1);
firm_exit = zeros(rme.T, 1);
firms = zeros(rme.T, 1);

for t = 1:rme.T

    % Unemployment rate
    u_tm1 = 1 - sum(rme.dL(:, t));
    u(t) = 1 - sum(rme.dLp(:, t));
    
    % Vacancies. Reasonable to assume \eta = 1 since \lambda~=ue<1 in the data
    % vacancies_t = \lambda_t * Z_t 
    v(t) = sum(rme.lambda_dF(:, t))*(1 - p.mu)*(u_tm1 + (1 - rme.delta(t))*p.s*sum(rme.chi(:, t).*rme.dL(:, t))); 

    % Labor market transition rates
    ue_flow_entrepreneurs = p.mu*u_tm1*sum(rme.chi(:, t).*p.dP0); 
    eu_flow_entrepreneurs = p.mu*(1 - u_tm1)*sum(~rme.chi(:, t).*p.dP0);
    ee_flow_entrepreneurs = p.mu*(1 - u_tm1)*sum(rme.chi(:, t).*p.dP0);

    ue_flow_workers = (1 - p.mu)*u_tm1*sum(rme.lambda_dF(:, t)); 
    eu_flow_workers = (1 - p.mu)*sum((~rme.chi(:, t) + rme.delta(t)*rme.chi(:, t)).*rme.dL(:, t));
    ee_flow_workers = (1 - p.mu)*(1 - rme.delta(t))*sum(rme.q(:, t).*rme.chi(:, t).*rme.dL(:, t));
    
    ue(t) = (ue_flow_entrepreneurs + ue_flow_workers)/u_tm1;
    eu(t) = (eu_flow_entrepreneurs + eu_flow_workers)/(1 - u_tm1);
    ee(t) = (ee_flow_entrepreneurs + ee_flow_workers)/(1 - u_tm1);
    
    % Aggregate output
    gdp(t) = exp(rme.log_omega(t))*sum(p.p.*rme.dLp(:, t));
    alp(t) = rme.log_omega(t) + sum(p.lnp.*rme.dLp(:, t))/sum(rme.dLp(:, t));

    % Productivity decomposition [No aggregate shock]
    lp_wgt(t) = sum(p.lnp.*rme.dLp(:, t))/sum(rme.dLp(:, t));
    lp_avg(t) = sum(p.lnp.*rme.dKp(:, t))/sum(rme.dKp(:, t));
    lp_opm(t) = lp_wgt(t) - lp_avg(t);

    % Employment cost decomposition
    active_t = rme.chi(:, t)==1; 
    
    ec_wgt(t) = sum(log(rme.w(active_t, t)).*rme.dLp(active_t, t))/sum(rme.dLp(:, t));
    ec_avg(t) = sum(log(rme.w(active_t, t)).*rme.dKp(active_t, t))/sum(rme.dKp(:, t));
    ec_opm(t) = ec_wgt(t) - ec_avg(t);

    % Firms
    firms(t) = sum(rme.dKp(:, t));
    firm_entr(t) = p.mu*sum(rme.chi(:, t).*p.dP0);
    firm_exit(t) = sum(rme.chi(:, t).*rme.dK(:, t));


end

% Shimer correction for transition rates
ue = -log(1 - ue); 
eu = -log(1 - eu);
ee = -log(1 - ee);

% Deviations from trend
lm_stats = compute_lm_stats(st, p);

ue_st = -log(1 - lm_stats.ue);
eu_st = -log(1 - lm_stats.eu);
ee_st = -log(1 - lm_stats.ee);

ue_dev = ue - ue_st;
eu_dev = eu - eu_st;
ee_dev = ee - ee_st;

lnue_dev = log(ue) - log(ue_st);
lneu_dev = log(eu) - log(eu_st);
lnee_dev = log(ee) - log(ee_st);

u_dev = u - lm_stats.u;

lnu_dev = log(u) - log(lm_stats.u);
lnv_dev = log(v) - log(lm_stats.v);

gdp_st = sum(p.p.*st.dLp);
alp_st = sum(p.lnp.*st.dLp)/sum(st.dLp);

lngdp_dev = log(gdp) - log(gdp_st);
alp_dev = alp - alp_st;

lp_wgt_st = sum(p.lnp.*st.dLp)/sum(st.dLp);
lp_avg_st = sum(p.lnp.*st.dKp)/sum(st.dKp);
lp_opm_st = lp_wgt_st - lp_avg_st;

lp_wgt_dev = lp_wgt - lp_wgt_st;
lp_avg_dev = lp_avg - lp_avg_st;
lp_opm_dev = lp_opm - lp_opm_st;

active_st = st.chi==1;
ec_wgt_st = sum(log(st.w(active_st)).*st.dLp(active_st))/sum(st.dLp);
ec_avg_st = sum(log(st.w(active_st)).*st.dKp(active_st))/sum(st.dKp);
ec_opm_st = ec_wgt_st - ec_avg_st; 

ec_wgt_dev = ec_wgt - ec_wgt_st;
ec_avg_dev = ec_avg - ec_avg_st;
ec_opm_dev = ec_opm - ec_opm_st;

firms_st = sum(st.dKp);
firm_entr_st = p.mu*sum(st.chi.*p.dP0);
firm_exit_st = sum(st.chi.*st.dK);

lnfirms_dev = log(firms) - log(firms_st);
lnentr_dev = log(firm_entr) - log(firm_entr_st);
lnexit_dev = log(firm_exit) - log(firm_exit_st);

log_omega = rme.log_omega;

% All simulated series in deviation from trend 
detrended_series = table(...
    lngdp_dev, ...
    alp_dev, ...
    u_dev, ...
    lnu_dev, ...
    lnv_dev, ...
    ue_dev, ...
    eu_dev, ...
    ee_dev, ...
    lnue_dev, ...
    lneu_dev, ...
    lnee_dev, ...
    lp_wgt_dev, ...
    lp_avg_dev, ...
    lp_opm_dev, ...    
    ec_wgt_dev, ...
    ec_avg_dev, ...
    ec_opm_dev, ...
    lnfirms_dev, ...
    lnentr_dev, ...
    lnexit_dev, ...
    log_omega);
    
    
