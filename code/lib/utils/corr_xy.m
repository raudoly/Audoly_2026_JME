function r = corr_xy(x, y, corr_type)
% Wrapper correlation coeff.

if nargin<3
    corr_type = 'Pearson';
end

R = corr([x y], 'Rows', 'complete', 'Type', corr_type);
r = R(2, 1);
