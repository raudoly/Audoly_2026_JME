function log_omega = find_shocks_periodbyperiod(ks, st, p, monthly_series, target_var)
% Search for aggregate shocks matching business cycle incrementally month-by-month.

dat_ts = monthly_series{:, target_var};
dates_monthly = monthly_series.date;

T = length(dat_ts);

log_omega = zeros(T, 1);
conv_flag = false(T, 1);
score = zeros(T, 1);
sim_ts = zeros(T, 1);

% Start from steady-state
log_omega_tm1 = 0.0;
n_t = st.n;

% Solver options
problem.solver = 'fzero';
problem.options = optimset('TolX', 1e-4);
problem.x0 = 0.0;

for t = 1:T

    % Solve for shocks
    problem.objective = @(x) gap_to_series(x, n_t, log_omega_tm1, dat_ts(t), target_var, ks, st, p);

    [eps_omega_t, fval, flag_solver, ~] = fzero(problem);

    conv_flag(t) = flag_solver<1;
    score(t) = abs(fval);

    % Update to next period
    [log_omega_t, np_t] = simulate_period(eps_omega_t, n_t, log_omega_tm1, ks, st, p);

    switch target_var
        case 'lngdp_hpf_dev'
            sim_ts(t) = sim_gdp_dev(log_omega_t, np_t, st, p);
        case 'u_hpf_dev'
            sim_ts(t) = sim_u_dev(np_t, st);
        otherwise
            sim_ts(t) = sim_lp_dev(log_omega_t, np_t, st, p);
    end

    log_omega(t) = p.rho_omega*log_omega_tm1 + p.sig_omega*eps_omega_t;
    log_omega_tm1 = log_omega(t);
    n_t = np_t;

    if mod(t, 60)==0
        fprintf('Done with period %s\n', dates_monthly(t));
    end

end

% Diagnose procedure
fprintf('\n\nFraction of periods not converging: %1.4f\n', mean(conv_flag));

% recessions_uk = [recessions.start_date, recessions.end_date];

% plot(dates_monthly, score);
% recessionplot('recessions', recessions_uk);
% ylabel('Error: absolute log-deviation');
% line(xlim, [5e-3 5e-3], 'Color', 'k');

% figure();
% plot(dates_monthly, [sim_ts, dat_ts]);
% ylabel('Target series');
% recessionplot('recessions', recessions_uk);
% legend('Simulation', 'Data', 'location', 'best');

check_shock_sequence(log_omega, p);

% Check statistical properties of sequence of shocks fitting aggregate time series data.
function check_shock_sequence(log_omega, p)

cor_omega_fit = corr([log_omega(1:end-1) log_omega(2:end)]);
cor_omega_fit = cor_omega_fit(2, 1);

std_omega_fit = std(log_omega);

parameter_value = [p.rho_omega; p.sig_omega/sqrt(1 - p.rho_omega^2)];
shock_sequence_fit = [cor_omega_fit; std_omega_fit]; 

check_shock_sequence = table(parameter_value, shock_sequence_fit);
check_shock_sequence.Properties.RowNames = {'cor_log_omega', 'std_log_omega'};

disp(check_shock_sequence); 


function [log_omega_t, np_t] = simulate_period(eps_omega_t, n_t, log_omega_tm1, ks, st, p)

m_t = build_endogenous_regressors(n_t.*p.dP, ks, p);   

log_omega_t = p.rho_omega*log_omega_tm1 + p.sig_omega*eps_omega_t;
c0_t = p.c0*exp(p.elast_c0_to_omega*log_omega_t);
delta_t = p.delta*exp(p.elast_delta_to_omega*log_omega_t);

X_t = [log_omega_t.^((1:ks.degree_poly)'); m_t];
y_t = ks.theta*X_t;

S_t = exp(y_t(1:p.np, 1)).*st.S;
U_t = exp(y_t(p.np+1, 1))*st.U;

phi_t = S_t - U_t;

[chi_t, ~, h_t, ~, q_t] = solve_firm_policy_shocks(phi_t, n_t, delta_t, c0_t, p);
np_t = chi_t.*((1 - delta_t)*(1 - q_t).*n_t + h_t);

function gap = gap_to_series(eps_omega_t, n_t, log_omega_tm1, dat_dev, target_var, ks, st, p)
% Input to fzero call above

[log_omega_t, np_t] = simulate_period(eps_omega_t, n_t, log_omega_tm1, ks, st, p);

switch target_var
    case 'lngdp_hpf_dev'
        sim_dev = sim_gdp_dev(log_omega_t, np_t, st, p);
    case 'u_hpf_dev'
        sim_dev = sim_u_dev(np_t, st);
    otherwise
        sim_dev = sim_lp_dev(log_omega_t, np_t, st, p);
end

gap = sim_dev - dat_dev;


function y_dev = sim_gdp_dev(log_omega_t, np_t, st, p)

y_t = log_omega_t + log(sum(p.p.*np_t.*p.dP));
y_st = log(sum(p.p.*st.dL));

y_dev = y_t - y_st; 

function y_dev = sim_lp_dev(log_omega_t, np_t, st, p)

y_t = log_omega_t + sum(p.lnp.*np_t.*p.dP)/sum(np_t.*p.dP);
y_st = sum(p.lnp.*st.dL)/sum(st.dL);

y_dev = y_t - y_st; 

function y_dev = sim_u_dev(np_t, st)

y_t = 1 - sum(np_t.*p.dP);
y_st = 1 - sum(st.dL);

y_dev = y_t - y_st;

