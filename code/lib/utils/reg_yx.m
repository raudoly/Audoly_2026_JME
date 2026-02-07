function b = reg_yx(y, x)
% Wrapper univariate reg.

b = regress(y, [ones(length(x), 1) x]);
b = b(2);
