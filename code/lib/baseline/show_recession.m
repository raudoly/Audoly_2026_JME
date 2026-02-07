function ts = show_recession(rme,st,p,save_results,shock_type)
% Compute aggregate response in a recession.

close all;

T = length(rme.log_omega);      % shock duration in months
Q = T/3;                        % ... in quarters
Y = T/12;                       % ... in years

%% Compute response to shocks in aggregates. 

% allocate memory for series 
u = zeros(T,1);

ue = zeros(T,1);
eu = zeros(T,1);
ee = zeros(T,1);

v_bsl = zeros(T,1);
v_alt = zeros(T,1);

gdp = zeros(T,1);
alp = zeros(T,1);

lp_wgt = zeros(T,1);  
lp_avg = zeros(T,1);
lp_opm = zeros(T,1);

w_wgt = zeros(T,1);
w_avg = zeros(T,1);
w_opm = zeros(T,1);

% compute aggregates along the path 
for t = 1:T 
    
    % unpack equilibrium in current period
    dL = rme.dL(:,t);
    dLp = rme.dLp(:,t);
    dKp = rme.dKp(:,t);
    chi = rme.chi(:,t);
    lambda_dF = rme.lambda_dF(:,t);
    
    % unemployment
    u(t) = 1 - sum(dLp);

    % lm transitions
    ue(t) = p.mu*sum(chi.*p.dP0) + (1 - p.mu)*sum(lambda_dF);
    eu(t) = p.mu*sum(~chi.*p.dP0);
    eu(t) = eu(t) + (1 - p.mu)*sum((~chi + rme.delta(t)*chi).*dL)/sum(dL);
    ee(t) = p.mu*sum(chi.*p.dP0); 
    ee(t) = ee(t) + (1 - p.mu)*p.s*(1 - rme.delta(t))*sum((p.sum_ab*lambda_dF).*chi.*dL)/sum(dL);
    
    % vacancies
    Z = (1 - p.mu)*(1 - sum(dL) + p.s*(1 - rme.delta(t))*sum(chi.*dL)); % search effort
    v_bsl(t) = Z*sum(lambda_dF)^(1/.5);
    v_alt(t) = Z*sum(lambda_dF)^(1/.7);

    % production/productivity
    gdp(t) = exp(rme.log_omega(t))*sum(p.p.*dLp);
    alp(t) = gdp(t)/(1 - u(t));

    % labor productivity decomposition
    lp_wgt(t) = sum(p.lnp.*dLp)/sum(dLp);
    lp_avg(t) = sum(p.lnp.*dKp)/sum(dKp);
    lp_opm(t) = lp_wgt(t) - lp_avg(t);

    % wage decomposition
    w_wgt(t) = sum(rme.w(:,t).*dLp)/sum(dLp);
    w_avg(t) = sum(rme.w(:,t).*dKp)/sum(dKp);
    w_opm(t) = w_wgt(t) - w_avg(t);
           
end

% stationary benchmarks
u_st = st.u;

ue_st = st.UE;
eu_st = st.EU;
ee_st = st.EE;

Z_st = (1 - p.mu)*(1 - sum(st.dL) + p.s*(1 - p.delta)*sum(st.chi.*st.dL)); % search effort
v_bsl_st = Z_st*sum(st.lambda_dF)^(1/.5);
v_alt_st = Z_st*sum(st.lambda_dF)^(1/.7);

gdp_st = sum(p.p.*st.dLp);
alp_st = gdp_st/(1 - u_st);

lp_wgt_st = sum(p.lnp.*st.dLp)/sum(st.dLp);
lp_avg_st = sum(p.lnp.*st.dKp)/sum(st.dKp);
lp_opm_st = lp_wgt_st - lp_avg_st;

w_wgt_st = sum(st.w.*st.dLp)/sum(st.dLp);
w_avg_st = sum(st.w.*st.dKp)/sum(st.dKp);
w_opm_st = w_wgt_st - w_avg_st;

% Construct series similarly to data
ts.ue = movmean(ue - ue_st,[12 12]);
ts.ue = ts.ue(12:12:T);

ts.eu = movmean(eu - eu_st,[12 12]);
ts.eu = ts.eu(12:12:T);

ts.ee = movmean(ee - ee_st,[12 12]);
ts.ee = ts.ee(12:12:T);

qr_sum = kron(eye(Q),ones(1,3));    % sum for quarter
qr_avg = qr_sum/3;                  % avg for quarter

ts.u = qr_avg*(u - u_st);
ts.u = ts.u(4:4:Q);

ts.gdp = qr_sum*gdp; % quarterly gdp
ts.gdp = log(ts.gdp) - log(3*gdp_st); % log-deviation 
ts.gdp = ts.gdp(4:4:Q); % one quarter each year

ts.alp = qr_avg*alp; % small approximation: average to get quarterly
ts.alp = log(ts.alp) - log(alp_st);
ts.alp = ts.alp(4:4:Q);

ts.w = qr_avg*w_wgt; 
ts.w = log(ts.w) - log(w_wgt_st);
ts.w = ts.w(4:4:Q);

ts.v = qr_avg*v_bsl; 
ts.v = log(ts.v) - log(v_bsl_st);
ts.v = ts.v(4:4:Q);

ts.v_alt = qr_avg*v_alt; 
ts.v_alt = log(ts.v_alt) - log(v_alt_st);
ts.v_alt = ts.v_alt(4:4:Q);


%% Benchmark aggregate series to data for UK Great Recession

% data
d1 = readtable('dat/gr_trans.csv');
d2 = readtable('dat/gr_macro.csv');

% collect series
mod_ts = [ts.ue ts.eu ts.ee ts.u ts.v ts.v_alt ts.w ts.gdp ts.alp];
dat_ts = [d1.ue d1.eu d1.ee d2.u d2.v d2.v    d2.w d2.gdp d2.alp];

% plot aggregate response to shock
title_ts = { ...
    'UE', ...
    'EU', ...
    'EE', ...
    'Unemployment', ...
    'Vacancies (\alpha = .5)', ...
    'Vacancies (\alpha = .7)', ...
    'Wages', ...
    'GDP', ...
    'ALP'};

ts.t_axis = 2008:(2008 + Y);

figure;

for k = 1:length(title_ts)
  subplot(3,3,k);
  plot(...
    ts.t_axis,[0.0;mod_ts(:,k)],'-bx',...
    ts.t_axis,dat_ts(:,k),':ko',...
    'LineWidth',1.1);
  title(title_ts(k));
  legend('Model','Data','location','best')
end


%%% Same with individual plots to save

% UE
fig_ue = figure;
plot(ts.t_axis,[0.0;ts.ue],'-bx',ts.t_axis,d1.ue,':ko','LineWidth',1.1);
% title('UE rate','FontSize',14);
xlabel('Year (March)');
ylabel('Difference from pre-recession');
legend('Model','Data','location','best');

% EU 
fig_eu = figure;
plot(ts.t_axis,[0.0;ts.eu],'-bx',ts.t_axis,d1.eu,':ko','LineWidth',1.1);
% title('EU rate','FontSize',14);
xlabel('Year (March)');
ylabel('Difference from pre-recession');
legend('Model','Data','location','best');

% EE
fig_ee = figure;
plot(ts.t_axis,[0.0;ts.ee],'-bx',ts.t_axis,d1.ee,':ko','LineWidth',1.1);
xlabel('Year (March)');
ylabel('Difference from pre-recession');
legend('Model','Data','location','best');

% Vacancies
fig_v_bsl = figure;
plot(ts.t_axis,[0.0;ts.v],'-bx',ts.t_axis,d2.v,':ko','LineWidth',1.1);
xlabel('Year (Q1)');
ylabel('Log-difference from pre-recession');
legend('Model \alpha = .5','Data','location','best');

% Vacancies robustness (show different elasticity)
fig_v_alt = figure;
plot(ts.t_axis,[0.0;ts.v],'-bx',ts.t_axis,[0.0;ts.v_alt],'--bx',ts.t_axis,d2.v,':ko','LineWidth',1.1)
xlabel('Year (Q1)');
ylabel('Log-difference from pre-recession');
legend('model \alpha = .5','model \alpha = .7','data','location','best');

%% Benchmark changes in aggregate from peak-to-trough

% Official timing of UK Great Recession is 
% 2008q2 to 2009q2, so peak is 2008q1 (2008m3)
% and trough is 2009q2 (2009m6). 

ue_ma = movmean(ue,[12 12]);
eu_ma = movmean(eu,[12 12]);
ee_ma = movmean(ee,[12 12]);

p2t_ue = ue_st - ue_ma(15);
p2t_eu = eu_st - eu_ma(15);
p2t_ee = ee_st - ee_ma(15);

p2t_v_bsl = log(v_bsl_st) - log(v_bsl(15));
p2t_v_alt = log(v_alt_st) - log(v_alt(15));

tab_p2t = table(...
    [p2t_ue;p2t_eu;p2t_ee;p2t_v_bsl;p2t_v_alt],...
    [.0090952;-.0008187;0.0053274;.4893276;.4893276],...
    'VariableNames',{'Model','Data'},...
    'RowNames',{'ue','eu','ee','v_bsl','v_alt'});

disp('Peak-to-trough: Labor Market aggregates');
disp(tab_p2t);

%% Decomposition change in labor productivity

ts.lp_wgt = lp_wgt(12:12:T) - lp_wgt_st;
ts.lp_avg = lp_avg(12:12:T) - lp_avg_st;
ts.lp_opm = lp_opm(12:12:T) - lp_opm_st;

% decomposition plot
fig_decomp = figure;
plot(...
    ts.t_axis,[0.0;ts.lp_avg],'-x',...
    ts.t_axis,[0.0;ts.lp_opm],'-x',...
    'LineWidth',1.1);
line(xlim,[0 0],'Color','k');
% title('Productivity Decomposition');
xlabel('Year (m3)');
ylabel('Difference from pre-recession');
legend('Firm selection','Worker misallocation','Location','best');

%---------------
% Save results

if save_results

    if nargin<5
        suffix = '';
    else
        suffix = ['_',shock_type];
    end
        
    filename = '../tables/_make_tables.xlsx';
    sheetname = ['raw_gr_p2t',suffix];

    writetable(tab_p2t,filename,'Sheet',sheetname,'WriteRowNames',1);
    
    saveas(fig_decomp,['../figs/gr-decomp',suffix],'epsc');

    saveas(fig_v_bsl,'../figs/gr-v-bsl','epsc');
    saveas(fig_v_alt,'../figs/gr-v-alt','epsc');

    saveas(fig_ue,'../figs/gr-ue','epsc');
    saveas(fig_eu,'../figs/gr-eu','epsc');
    saveas(fig_ee,'../figs/gr-ee','epsc');
    
end

