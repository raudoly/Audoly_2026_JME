function [sim_series,reg_table] = simulate_panel_time_series(shocks,st,p,seed)
% Simulate a panel of firms along simulated sequence of shocks

% Default seed number
if nargin<4
    seed = 19510418;
end
    
rme = shocks.lp_micro.rme;
t = shocks.lp_micro.sim_series_m.date;

year_min = 1998;
year_max = 2018;

selected_dates = year(t)>=year_min & year(t)<=year_max;
T = sum(selected_dates);

% Select RME for these periods
rme_log_omega = rme.log_omega(selected_dates);
rme_phi = rme.phi(:,selected_dates);
rme_q = rme.q(:,selected_dates);
rme_h = rme.h(:,selected_dates);
rme_w = rme.w(:,selected_dates);

 
%% Incumbent firms at start of simulation -------------------

% Start from panel in steady-state equilibrium
pn = firmpan(st,p);

if pn.flag
    error('Flag=1 in simulation of stationary panel!');
end
                          
% Initial panel, cross-section of active firms at start of recession
empl_st = pn.emp(pn.active);   
agef_st = pn.age(pn.active);
lpdy_st = pn.lpdy(pn.active);
lwag_st = pn.lwag(pn.active);

lnp_st = pn.lnp(pn.active);  

% Interpolation first period
phi = griddedInterpolant(p.lnp,rme_phi(:,1));

q = griddedInterpolant(p.lnp,rme_q(:,1));
h = griddedInterpolant(p.lnp,rme_h(:,1));
w = griddedInterpolant(p.lnp,rme_w(:,1));

% First-period, incumbent firms
fprod_inc = p.rho_p*lnp_st + p.sig_p*randn(size(lnp_st));
phi_itp = phi(fprod_inc);
surv = phi_itp>=0.0;

fprod_inc(~surv) = [];

q_itp = q(fprod_inc);
h_itp = h(fprod_inc);

fempl_inc = (1 - p.mu)*(1 - p.delta)*(1 - q_itp + h_itp).*empl_st(surv);
fwage_inc = w(fprod_inc);
fagef_inc = agef_st(surv) + 1;

% Allocate memory, incumbent firms
ninc = sum(surv);

facti_inc = [true(ninc,1),false(ninc,T-1)];
fempl_inc = [fempl_inc,zeros(ninc,T-1)];
fprod_inc = [fprod_inc,zeros(ninc,T-1)];
fwage_inc = [fwage_inc,zeros(ninc,T-1)];
fagef_inc = [fagef_inc,zeros(ninc,T-1)]; 


%% Entrants after start of business cycle simulation --------

rng(seed);

% Number of actual entrants at each point in time
st_frac = sum(st.chi.*p.dP0);
bc_frac = sum((rme_phi>=0).*repmat(p.dP0,1,T),1);

n = pn.N/12; % steady-state monthly number of entrants   

bc_entr = round(n*bc_frac./st_frac);

% Pre-allocate arrays for entrants
facti = false(sum(bc_entr),T);
fprod = zeros(sum(bc_entr),T);
fempl = zeros(sum(bc_entr),T);
fwage = zeros(sum(bc_entr),T);
fagef = zeros(sum(bc_entr),T);

% Entry distribution
cdf_P0 = cumsum(p.dP0);                                    
sel = cdf_P0>.001 & cdf_P0<.999;            
qtl_P0 = griddedInterpolant(cdf_P0(sel),p.lnp(sel)); 

% Fill in initial productivity/size/wage 
% for entrants at each point in time
n_entr_cum = 0;

for t = 1:T
    n_entr = bc_entr(1,t);

    unif_draws = cdf_P0(find(rme_phi(:,t)>0,1)) + (1 - cdf_P0(find(rme_phi(:,t)>0,1)))*rand(n_entr,1);    
    
    select_firms = (n_entr_cum + 1):(n_entr_cum + n_entr);

    facti(select_firms,t) = true;
    fprod(select_firms,t) = qtl_P0(unif_draws);
    fempl(select_firms,t) = 1;
    fwage(select_firms,t) = w(fprod(select_firms,t)); % Wrong for t>1: overwritten below

    n_entr_cum = n_entr_cum + n_entr;
    
end




%% Business cycle simulation -----

% Stack arrays for all firms: Incumbents and entering during simulation
facti = [facti_inc;facti];
fempl = [fempl_inc;fempl];
fprod = [fprod_inc;fprod];
fwage = [fwage_inc;fwage];
fagef = [fagef_inc;fagef];

clear *_inc;

for t = 2:T
   
    % Interpolation this period
    phi = griddedInterpolant(p.lnp,rme_phi(:,t));

    q = griddedInterpolant(p.lnp,rme_q(:,t));
    h = griddedInterpolant(p.lnp,rme_h(:,t));
    w = griddedInterpolant(p.lnp,rme_w(:,t));

    % Realization idiosyncratic productivity (incumbents)
    inc = facti(:,t-1);
    fprod(inc,t) = p.rho_p*fprod(inc,t-1) + p.sig_p*randn(sum(inc),1); 

    % Exit for incumbent firms
    phi_itp = phi(fprod(inc,t));
    facti(inc,t) = phi_itp>=0;

    % Check if there are surviving firms   
    surv = facti(:,t-1) & facti(:,t);
    
    if ~any(surv)
        error('No surviving firms.');
    end

    % Growth rate for surviving incumbents
    q_itp = q(fprod(surv,t));
    h_itp = h(fprod(surv,t));
    
    fempl(surv,t) = (1 - p.mu)*(1 - p.delta)*(1 - q_itp + h_itp).*fempl(surv,t-1);     
    fwage(surv,t) = w(fprod(surv,t));

    % Move age forward: firms age on first month each year 
    if rem(t,12)==1 
        fagef(surv,t) = fagef(surv,t-1) + 1;
    else
        fagef(surv,t) = fagef(surv,t-1);
    end
    
end


%% Construct yearly aggregates similar to data -----

% Extract yearly panel over aggregate shock simulation
acti = facti(:,12:12:T);
agef = fagef(:,12:12:T);
empl = fempl(:,12:12:T);

% Ouput measures
rme_omega = exp(rme_log_omega');

output = facti.*rme_omega.*exp(fprod).*fempl;  
output = output*kron(eye(T/12),ones(12,1)); 
output = acti.*output;

empcost = fwage.*fempl;
empcost = empcost*kron(eye(T/12),ones(12,1));
empcost = acti.*empcost;

lp = log(output) - log(empl);
ec = log(empcost) - log(empl);


%% Business cycle regressions -------

yearmin_reg = 2002;
yearmax_reg = 2016;

year_post = 2008;

acti_now = acti(:,1:end-1);
acti_fow = acti(:,2:end);
empl_now = empl(:,1:end-1);
empl_fow = empl(:,2:end);
% agef_now = agef(:,1:end-1);

lp_now = lp(:,1:end-1);
ec_now = ec(:,1:end-1);

year_now = repmat(year_min:year_max-1,size(acti,1),1); 

select = acti_now(:) & acti_fow(:);
select = select & year_now(:)>=yearmin_reg & year_now(:)<=yearmax_reg;

year_reg = year_now(select);
lp_reg = lp_now(select);
ec_reg = ec_now(select);
lemp_reg = log(empl_now(select));
d_lemp_reg = log(empl_fow(select)) - log(empl_now(select));

clear *_now *_fow select;

% Not sure year dummies are needed since model is stationary
% yr_unique = unique(year_reg);
% nyr_unique = length(yr_unique);
% yr_dum = zeros(length(year_reg),length(yr_unique) - 1);

% for k = 2:nyr_unique
%     yr_dum(:,k-1) = (year_reg==yr_unique(k));
% end

post = year_reg>=year_post;

cst = ones(size(post));

b_dlemp_lpdy = regress(d_lemp_reg,[cst lp_reg post.*lp_reg lemp_reg]);
b_dlemp_lwag = regress(d_lemp_reg,[cst ec_reg post.*ec_reg lemp_reg]);

% Regression table
lpdy_sim = b_dlemp_lpdy(2:3);
lpdy_dat = [0.102; -0.031];

lwag_sim = b_dlemp_lwag(2:3);
lwag_dat = [0.136;-0.012];

reg_table = table(lpdy_sim,lpdy_dat,lwag_sim,lwag_dat);
reg_table.Properties.RowNames = {'var','var x post'};

% Show regressions
disp('Regression results:');
disp(reg_table);


%% OP Decomposition on model-simulated data --------

% Select firm age band to make sure panel isn't aging
agemin = 2;
agemax = 40;

% Decomposition in stationary equilibrium
age_valid = agef_st>=agemin & agef_st<=agemax; 
empshare = empl_st(age_valid)/sum(empl_st(age_valid));

lp_wgt_st = sum(empshare.*lpdy_st(age_valid));
lp_avg_st = mean(lpdy_st(age_valid));
% lp_opm_st = lp_wgt_st - lp_avg_st;

ec_wgt_st = sum(empshare.*lwag_st(age_valid));
ec_avg_st = mean(lwag_st(age_valid));
% ec_opm_st = ec_wgt_st - ec_avg_st;

rme_omega = exp(rme_log_omega');

output = facti.*rme_omega.*exp(fprod).*fempl;  
output = output*kron(eye(T/12),ones(12,1)); 
output = acti.*output;

empcost = fwage.*fempl;
empcost = empcost*kron(eye(T/12),ones(12,1));
empcost = acti.*empcost;

lp = log(output) - log(empl);
ec = log(empcost) - log(empl);

% Decomposition over business cycle simulation
nyr = T/12;

lp_wgt_dev = zeros(nyr,1);
lp_avg_dev = zeros(nyr,1);
lp_opm_dev = zeros(nyr,1);

ec_wgt_dev = zeros(nyr,1);
ec_avg_dev = zeros(nyr,1);
ec_opm_dev = zeros(nyr,1);

for k = 1:nyr
    
    select = acti(:,k) &  agef(:,k)>=agemin & agef(:,k)<=agemax;
    empshare = empl(select,k)/sum(empl(select,k));

    lp_wgt_dev(k) = sum(empshare.*lp(select,k)) - lp_wgt_st;
    lp_avg_dev(k) = mean(lp(select,k)) - lp_avg_st;
    lp_opm_dev(k) = lp_wgt_dev(k) - lp_avg_dev(k);

    ec_wgt_dev(k) = sum(empshare.*ec(select,k)) - ec_wgt_st;
    ec_avg_dev(k) = mean(ec(select,k)) - ec_avg_st;
    ec_opm_dev(k) = ec_wgt_dev(k) - ec_avg_dev(k);

end

% Also compute some firm dynamics stats
firms_st = sum(agef_st>=agemin & agef_st<=agemax);

lnfirms_dev = zeros(nyr,1);

for k = 1:nyr
    firms_bc = sum(acti(:,k) & agef(:,k)>=agemin & agef(:,k)<=agemax);    
    lnfirms_dev(k) = log(firms_bc) - log(firms_st);
end

% All simulated series together
date = datetime(transpose(year_min:year_max),12,31);

sim_series = table(...
    date,...
    lp_wgt_dev,...
    lp_avg_dev,...
    lp_opm_dev,...
    ec_wgt_dev,...
    ec_avg_dev,...
    ec_opm_dev,...
    lnfirms_dev);

% % Show results
% close all;
% 
% yearmin_fig = 2000;
% yearmax_fig = 2016;
% 
% select = sim_series.sim_year>=yearmin_fig & sim_series.sim_year<=yearmax_fig;
% sim_series = sim_series(select,:);
% 
% select = data.yearly_series.year>=yearmin_fig & data.yearly_series.year<=yearmax_fig;
% dat_series = data.yearly_series(select,:);
% 
% % LP: employment-weighted sum
% t = dat_series.date;
% y = [sim_series.lnpdy_lp_dev,dat_series.ln_gva_fc_lp_hpf_dev,dat_series.ln_gva_fc_lp_bpf_dev];
% ylab = 'Employment-weighted sum of LP_{i,t} (dev. from trend)';
% fig_lnpdy_lp = plot_fit_series(t,y,ylab,data.recessions);
% 
% % LP: raw average
% t = dat_series.date;
% y = [sim_series.lnpdy_mu_dev,dat_series.ln_gva_fc_mu_hpf_dev,dat_series.ln_gva_fc_mu_bpf_dev];
% ylab = 'Average of LP_{i,t} (dev. from trend)';
% fig_lnpdy_mu = plot_fit_series(t,y,ylab,data.recessions);
% 
% % LP: OP misallocation
% t = dat_series.date;
% y = [sim_series.lnpdy_op_dev,dat_series.ln_gva_fc_op_hpf_dev,dat_series.ln_gva_fc_op_bpf_dev];
% ylab = 'OP decomposition of LP_{i,t} (dev. from trend)';
% fig_lnpdy_op = plot_fit_series(t,y,ylab,data.recessions);
% 
% % Wages: employment-weighted sum
% t = dat_series.date;
% y = [sim_series.lnwages_lp_dev,dat_series.ln_wages_lp_hpf_dev,dat_series.ln_wages_lp_bpf_dev];
% ylab = 'Employment-weighted sum of W_{i,t} (dev. from trend)';
% fig_lnwages_lp = plot_fit_series(t,y,ylab,data.recessions);
% 
% % Wages: raw average
% t = dat_series.date;
% y = [sim_series.lnwages_mu_dev,dat_series.ln_wages_mu_hpf_dev,dat_series.ln_wages_mu_bpf_dev];
% ylab = 'Average of W_{i,t} (dev. from trend)';
% fig_lnwages_mu = plot_fit_series(t,y,ylab,data.recessions);
% 
% % Wages: OP misallocation
% t = dat_series.date;
% y = [sim_series.lnwages_op_dev,dat_series.ln_wages_op_hpf_dev,dat_series.ln_wages_op_bpf_dev];
% ylab = 'OP decomposition of W_{i,t} (dev. from trend)';
% fig_lnwages_op = plot_fit_series(t,y,ylab,data.recessions);
% 
% % Number of active businesses
% t = dat_series.date;
% y = [sim_series.lnfirms_dev,dat_series.lnfirms_hpf_dev,dat_series.lnfirms_bpf_dev];
% ylab = 'Number of firms (log dev. from trend)';
% fig_lnfirms = plot_fit_series(t,y,ylab,data.recessions);



end


