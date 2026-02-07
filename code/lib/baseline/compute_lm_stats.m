function lm_stats = compute_lm_stats(st, p)
% Labor market stocks and flows.

% Stocks
L = sum(st.dL);
u = 1 - L;

% Posted vacancies
v = sum(st.lambda_dF)*(1 - p.mu)*(u + (1 - p.delta)*p.s*sum(st.chi.*st.dL));

% Job flows
ue_flow_entrepreneurs = p.mu*u*sum(st.chi.*p.dP0); 
eu_flow_entrepreneurs = p.mu*L*sum(~st.chi.*p.dP0);
ee_flow_entrepreneurs = p.mu*L*sum(st.chi.*p.dP0);

ue_flow_workers = (1 - p.mu)*u*sum(st.lambda_dF);
eu_flow_workers = (1 - p.mu)*sum((~st.chi + p.delta*st.chi).*st.dL);
ee_flow_workers = (1 - p.mu)*(1 - p.delta)*sum(st.q.*st.chi.*st.dL);

eu_flow_firm_exit = (1 - p.mu)*sum(~st.chi.*st.dL);    

% Monthly transition probabilities 
ue = (ue_flow_entrepreneurs + ue_flow_workers)/u;
eu = (eu_flow_entrepreneurs + eu_flow_workers)/L;
ee = (ee_flow_entrepreneurs + ee_flow_workers)/L;

% Share of worker EU dur to exit
eu_shr_exit = eu_flow_firm_exit/(eu_flow_entrepreneurs + eu_flow_workers); 

% Pack up
lm_stats.L = L;
lm_stats.u = u;
lm_stats.v = v;

lm_stats.ue = ue;
lm_stats.eu = eu;
lm_stats.ee = ee;

lm_stats.eu_shr_exit = eu_shr_exit;
