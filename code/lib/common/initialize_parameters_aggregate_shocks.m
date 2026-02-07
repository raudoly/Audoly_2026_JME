function p = initialize_parameters_aggregate_shocks(p, par)
% Add aggregate shock parameters to parameter struct. 

p.rho_omega = par(1);
p.sig_omega = par(2);

p.elast_delta_to_omega = par(3);
p.elast_c0_to_omega = par(4);

p.elast_b_to_omega = par(5);
p.elast_r_to_omega = par(6);
