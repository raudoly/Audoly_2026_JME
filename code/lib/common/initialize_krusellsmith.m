function ks = initialize_krusellsmith(st,p)
% Settings for Krusell-Smith solution.
    
% Length simulation 
ks.trim_beg = 12*50;                            % burnin periods (months)
ks.T = 12*200 + ks.trim_beg;                    % actual simulation length
ks.tsample = (ks.trim_beg+1):ks.T;              % simulation sample                  
ks.tsample_y = (ks.trim_beg/12+1):(ks.T/12);    % simulation sample yearly
ks.tsample_q = (ks.trim_beg/3+1):(ks.T/3);      % simulation sample quarterly

% Default settings for Krusell-Smith solution
ks.solve = false;
ks.save = false;
ks.verbose = true;

% Dimension reduction
ks.nm = 2;
st_m = summarize_measure(st.dL,p.p,ks.nm);
ks.log_st_m = log(st_m);
ks.degree_poly = 2;

% Simulate aggregate state
ks.ns = 15;
[log_omega,Q] = tauchen(ks.ns,0.0,p.rho_omega,p.sig_omega,4);
cumQ = cumsum(Q,2);
ks.log_omega = log_omega;
ks.tQ = Q';

rng(25031957);
dice = rand(1,ks.T);

ks.sim_state = [median(1:ks.ns) zeros(1,ks.T-1)]; % median = steady-state

for t = 2:ks.T
    ks.sim_state(t) = find(dice(t)<cumQ(ks.sim_state(t-1),:),1);
end

% TFP shocks [omega=TFP]
ks.sim_log_omega = ks.log_omega(ks.sim_state)'; 
ks.sim_omega = exp(ks.sim_log_omega);             
ks.sim_log_omega_poly = ks.sim_log_omega.^((1:ks.degree_poly)');
ks.log_omega_nodes = ks.log_omega'.^((1:ks.degree_poly)');

% Additional shocks [function of omega]
ks.b = p.b*exp(p.elast_b_to_omega*ks.log_omega');
ks.c0 = p.c0*exp(p.elast_c0_to_omega*ks.log_omega');
ks.delta = p.delta*exp(p.elast_delta_to_omega*ks.log_omega');

ks.sim_r = p.r*exp(p.elast_r_to_omega*ks.sim_log_omega);
ks.sim_b = p.b*exp(p.elast_b_to_omega*ks.sim_log_omega);
ks.sim_c0 = p.c0*exp(p.elast_c0_to_omega*ks.sim_log_omega);
ks.sim_delta = p.delta*exp(p.elast_delta_to_omega*ks.sim_log_omega);
ks.sim_beta = 1./(1 + ks.sim_r);

