function [r, LB, UB, F, df1, df2, p] = fx_ICC(M, type, alpha, r0)
% Intraclass correlation
%   [r, LB, UB, F, df1, df2, p] = ICC(M, type, alpha, r0)
%
%   M is matrix of observations. Each row is an object of measurement and
%   each column is a judge or measurement.
%
%   'type' is a string that can be one of the six possible codes for the desired
%   type of ICC:
%       '1-1': The degree of absolute agreement among measurements made on
%         randomly seleted objects. It estimates the correlation of any two
%         measurements.
%       '1-k': The degree of absolute agreement of measurements that are
%         averages of k independent measurements on randomly selected
%         objects.
%       'C-1': case 2: The degree of consistency among measurements. Also known
%         as norm-referenced reliability and as Winer's adjustment for
%         anchor points. case 3: The degree of consistency among measurements maded under
%         the fixed levels of the column factor. This ICC estimates the
%         corrlation of any two measurements, but when interaction is
%         present, it underestimates reliability.
%       'C-k': case 2: The degree of consistency for measurements that are
%         averages of k independent measurements on randomly selected
%         onbjectgs. Known as Cronbach's alpha in psychometrics. case 3:  
%         The degree of consistency for averages of k independent
%         measures made under the fixed levels of column factor.
%       'A-1': case 2: The degree of absolute agreement among measurements. Also
%         known as criterion-referenced reliability. case 3: The absolute 
%         agreement of measurements made under the fixed levels of the column factor.
%       'A-k': case 2: The degree of absolute agreement for measurements that are
%         averages of k independent measurements on randomly selected objects.
%         case 3: he degree of absolute agreement for measurements that are
%         based on k independent measurements maded under the fixed levels
%         of the column factor.
%
%       ICC is the estimated intraclass correlation. LB and UB are upper
%       and lower bounds of the ICC with alpha level of significance. 
%
%       In addition to estimation of ICC, a hypothesis test is performed
%       with the null hypothesis that ICC = r0. The F value, degrees of
%       freedom and the corresponding p-value of the this test are
%       reported.
%
%       (c) Arash Salarian, 2008
%
%       Reference: McGraw, K. O., Wong, S. P., "Forming Inferences About
%       Some Intraclass Correlation Coefficients", Psychological Methods,
%       Vol. 1, No. 1, pp. 30-46, 1996
%

if nargin < 3
    alpha = .05;
end

if nargin < 4
    r0 = 0;
end

[n, k] = size(M);
[p, table] = anova_rm(M, 'off');

SSR = table{3,2};
SSE = table{4,2};
SSC = table{2,2};
SSW = SSE + SSC;

MSR = SSR / (n-1);
MSE = SSE / ((n-1)*(k-1));
MSC = SSC / (k-1);
MSW = SSW / (n*(k-1));

switch type
    case '1-1'
        [r, LB, UB, F, df1, df2, p] = ICC_case_1_1(MSR, MSE, MSC, MSW, alpha, r0, n, k);
    case '1-k'
        [r, LB, UB, F, df1, df2, p] = ICC_case_1_k(MSR, MSE, MSC, MSW, alpha, r0, n, k);
    case 'C-1'
        [r, LB, UB, F, df1, df2, p] = ICC_case_C_1(MSR, MSE, MSC, MSW, alpha, r0, n, k);
    case 'C-k'
        [r, LB, UB, F, df1, df2, p] = ICC_case_C_k(MSR, MSE, MSC, MSW, alpha, r0, n, k);
    case 'A-1'
        [r, LB, UB, F, df1, df2, p] = ICC_case_A_1(MSR, MSE, MSC, MSW, alpha, r0, n, k);
    case 'A-k'
        [r, LB, UB, F, df1, df2, p] = ICC_case_A_k(MSR, MSE, MSC, MSW, alpha, r0, n, k);
end


%----------------------------------------
function [r, LB, UB, F, df1, df2, p] = ICC_case_1_1(MSR, MSE, MSC, MSW, alpha, r0, n, k)
r = (MSR - MSW) / (MSR + (k-1)*MSW);

F = (MSR/MSW) * (1-r0)/(1+(k-1)*r0);
df1 = n-1;
df2 = n*(k-1);
p = 1-fcdf(F, df1, df2);

FL = F / finv(1-alpha/2, n-1, n*(k-1));
FU = F * finv(1-alpha/2, n*(k-1), n-1);

LB = (FL - 1) / (FL + (k-1));
UB = (FU - 1) / (FU + (k-1));

%----------------------------------------
function [r, LB, UB, F, df1, df2, p] = ICC_case_1_k(MSR, MSE, MSC, MSW, alpha, r0, n, k)
r = (MSR - MSW) / MSR;

F = (MSR/MSW) * (1-r0);
df1 = n-1;
df2 = n*(k-1);
p = 1-fcdf(F, df1, df2);

FL = F / finv(1-alpha/2, n-1, n*(k-1));
FU = F * finv(1-alpha/2, n*(k-1), n-1);

LB = 1 - 1 / FL;
UB = 1 - 1 / FU;

%----------------------------------------
function [r, LB, UB, F, df1, df2, p] = ICC_case_C_1(MSR, MSE, MSC, MSW, alpha, r0, n, k)
r = (MSR - MSE) / (MSR + (k-1)*MSE);

F = (MSR/MSE) * (1-r0)/(1+(k-1)*r0);
df1 = n - 1;
df2 = (n-1)*(k-1);
p = 1-fcdf(F, df1, df2);

FL = F / finv(1-alpha/2, n-1, (n-1)*(k-1));
FU = F * finv(1-alpha/2, (n-1)*(k-1), n-1);

LB = (FL - 1) / (FL + (k-1));
UB = (FU - 1) / (FU + (k-1));

%----------------------------------------
function [r, LB, UB, F, df1, df2, p] = ICC_case_C_k(MSR, MSE, MSC, MSW, alpha, r0, n, k)
r = (MSR - MSE) / MSR;

F = (MSR/MSE) * (1-r0);
df1 = n - 1;
df2 = (n-1)*(k-1);
p = 1-fcdf(F, df1, df2);

FL = F / finv(1-alpha/2, n-1, (n-1)*(k-1));
FU = F * finv(1-alpha/2, (n-1)*(k-1), n-1);

LB = 1 - 1 / FL;
UB = 1 - 1 / FU;

%----------------------------------------
function [r, LB, UB, F, df1, df2, p] = ICC_case_A_1(MSR, MSE, MSC, MSW, alpha, r0, n, k)
r = (MSR - MSE) / (MSR + (k-1)*MSE + k*(MSC-MSE)/n);

a = (k*r0) / (n*(1-r0));
b = 1 + (k*r0*(n-1))/(n*(1-r0));
F = MSR / (a*MSC + b*MSE);
df1 = n - 1;
df2 = (a*MSC + b*MSE)^2/((a*MSC)^2/(k-1) + (b*MSE)^2/((n-1)*(k-1)));
p = 1-fcdf(F, df1, df2);

a = k*r/(n*(1-r));
b = 1+k*r*(n-1)/(n*(1-r));
v = (a*MSC + b*MSE)^2/((a*MSC)^2/(k-1) + (b*MSE)^2/((n-1)*(k-1)));

Fs = finv(1-alpha/2, n-1, v);
LB = n*(MSR - Fs*MSE)/(Fs*(k*MSC + (k*n - k - n)*MSE) + n*MSR);

Fs = finv(1-alpha/2, v, n-1);
UB = n*(Fs*MSR-MSE)/(k*MSC + (k*n - k - n)*MSE + n*Fs*MSR);

%----------------------------------------
function [r, LB, UB, F, df1, df2, p] = ICC_case_A_k(MSR, MSE, MSC, MSW, alpha, r0, n, k)
r = (MSR - MSE) / (MSR + (MSC-MSE)/n);

c = r0/(n*(1-r0));
d = 1 + (r0*(n-1))/(n*(1-r0));
F = MSR / (c*MSC + d*MSE);
df1 = n - 1;
df2 = (c*MSC + d*MSE)^2/((c*MSC)^2/(k-1) + (d*MSE)^2/((n-1)*(k-1)));
p = 1-fcdf(F, df1, df2);

a = r/(n*(1-r));
b = 1+r*(n-1)/(n*(1-r));
v = (a*MSC + b*MSE)^2/((a*MSC)^2/(k-1) + (b*MSE)^2/((n-1)*(k-1)));

Fs = finv(1-alpha/2, n-1, v);
LB = n*(MSR - Fs*MSE)/(Fs*(MSC-MSE) + n*MSR);

Fs = finv(1-alpha/2, v, n-1);
UB = n*(Fs*MSR - MSE)/(MSC - MSE + n*Fs*MSR);

function [p, table] = anova_rm(X, displayopt)
%   [p, table] = anova_rm(X, displayopt)
%   Single factor, tepeated measures ANOVA.
%
%   [p, table] = anova_rm(X, displayopt) performs a repeated measures ANOVA
%   for comparing the means of two or more columns (time) in one or more
%   samples(groups). Unbalanced samples (i.e. different number of subjects 
%   per group) is supported though the number of columns (followups)should 
%   be the same. 
%
%   DISPLAYOPT can be 'on' (the default) to display the ANOVA table, or 
%   'off' to skip the display. For a design with only one group and two or 
%   more follow-ups, X should be a matrix with one row for each subject. 
%   In a design with multiple groups, X should be a cell array of matrixes.
% 
%   Example: Gait-Cycle-times of a group of 7 PD patients have been
%   measured 3 times, in one baseline and two follow-ups:
%
%   patients = [
%    1.1015    1.0675    1.1264
%    0.9850    1.0061    1.0230
%    1.2253    1.2021    1.1248
%    1.0231    1.0573    1.0529
%    1.0612    1.0055    1.0600
%    1.0389    1.0219    1.0793
%    1.0869    1.1619    1.0827 ];
%
%   more over, a group of 8 controls has been measured in the same protocol:
%
%   controls = [
%     0.9646    0.9821    0.9709
%     0.9768    0.9735    0.9576
%     1.0140    0.9689    0.9328
%     0.9391    0.9532    0.9237
%     1.0207    1.0306    0.9482
%     0.9684    0.9398    0.9501
%     1.0692    1.0601    1.0766
%     1.0187    1.0534    1.0802 ];
%
%   We are interested to see if the performance of the patients for the
%   followups were the same or not:
%  
%   p = anova_rm(patients);
%
%   By considering the both groups, we can also check to see if the 
%   follow-ups were significantly different and also check two see that the
%   two groups had a different performance:
%
%   p = anova_rm({patients controls});
%
%
%   ref: Statistical Methods for the Analysis of Repeated Measurements, 
%     C. S. Daivs, Springer, 2002
%
%   Copyright 2008, Arash Salarian
%   mailto://arash.salarian@ieee.org
%

if nargin < 2
    displayopt = 'on';
end

if ~iscell(X)
    X = {X};
end

%number of groups
s = size(X,2);  

%subjects per group 
n_h = zeros(s, 1);
for h=1:s
    n_h(h) = size(X{h}, 1);    
end
n = sum(n_h);

%number of follow-ups
t = size(X{1},2);   

% overall mean
y = 0;
for h=1:s
    y = y + sum(sum(X{h}));
end
y = y / (n * t);

% allocate means
y_h = zeros(s,1);
y_j = zeros(t,1);
y_hj = zeros(s,t);
y_hi = cell(s,1);
for h=1:s
    y_hi{h} = zeros(n_h(h),1);
end

% group means
for h=1:s
    y_h(h) = sum(sum(X{h})) / (n_h(h) * t);
end

% follow-up means
for j=1:t
    y_j(j) = 0;
    for h=1:s
        y_j(j) = y_j(j) + sum(X{h}(:,j));
    end
    y_j(j) = y_j(j) / n;
end

% group h and time j mean
for h=1:s
    for j=1:t
        y_hj(h,j) = sum(X{h}(:,j) / n_h(h));
    end
end

% subject i'th of group h mean
for h=1:s
    for i=1:n_h(h)
        y_hi{h}(i) = sum(X{h}(i,:)) / t;
    end
end

% calculate the sum of squares
ssG = 0;
ssSG = 0;
ssT = 0;
ssGT = 0;
ssR = 0;

for h=1:s
    for i=1:n_h(h)
        for j=1:t
            ssG  = ssG  + (y_h(h) - y)^2;
            ssSG = ssSG + (y_hi{h}(i) - y_h(h))^2;
            ssT  = ssT  + (y_j(j) - y)^2;
            ssGT = ssGT + (y_hj(h,j) - y_h(h) - y_j(j) + y)^2;
            ssR  = ssR  + (X{h}(i,j) - y_hj(h,j) - y_hi{h}(i) + y_h(h))^2;
        end
    end
end

% calculate means
if s > 1
    msG  = ssG  / (s-1);
    msGT = ssGT / ((s-1)*(t-1));
end
msSG = ssSG / (n-s);
msT  = ssT  / (t-1);
msR  = ssR  / ((n-s)*(t-1));


% calculate the F-statistics
if s > 1
    FG  = msG  / msSG;
    FGT = msGT / msR;
end
FT  = msT  / msR;
FSG = msSG / msR;


% single or multiple sample designs?
if s > 1
    % case for multiple samples
    pG  = 1 - fcdf(FG, s-1, n-s);
    pT  = 1 - fcdf(FT, t-1, (n-s)*(t-1));
    pGT = 1 - fcdf(FGT, (s-1)*(t-1), (n-s)*(t-1));
    pSG = 1 - fcdf(FSG, n-s, (n-s)*(t-1));

    p = [pT, pG, pSG, pGT];

    table = { 'Source' 'SS' 'df' 'MS' 'F' 'Prob>F'
        'Time'  ssT t-1 msT FT pT
        'Group' ssG s-1 msG FG pG
        'Ineratcion' ssGT (s-1)*(t-1) msGT FGT pGT
        'Subjects (matching)' ssSG n-s msSG FSG pSG
        'Error' ssR (n-s)*(t-1) msR  [] []
        'Total' [] [] [] [] []
        };
    table{end, 2} = sum([table{2:end-1,2}]);
    table{end, 3} = sum([table{2:end-1,3}]);

    if (isequal(displayopt, 'on'))
        digits = [-1 -1 0 -1 2 4];
        statdisptable(table, 'multi-sample repeated measures ANOVA', 'ANOVA Table', '', digits);
    end
else
    % case for only one sample
    pT  = 1 - fcdf(FT, t-1, (n-s)*(t-1));
    pSG = 1 - fcdf(FSG, n-s, (n-s)*(t-1));

    p = [pT, pSG];

    table = { 'Source' 'SS' 'df' 'MS' 'F' 'Prob>F'
        'Time'  ssT t-1 msT FT pT
        'Subjects (matching)' ssSG n-s msSG FSG pSG
        'Error' ssR (n-s)*(t-1) msR  [] []
        'Total' [] [] [] [] []
        };
    table{end, 2} = sum([table{2:end-1,2}]);
    table{end, 3} = sum([table{2:end-1,3}]);

    if (isequal(displayopt, 'on'))
        digits = [-1 -1 0 -1 2 4];
        statdisptable(table, 'repeated measures ANOVA', 'ANOVA Table', '', digits);
    end
end