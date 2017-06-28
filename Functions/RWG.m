function [REL] = RWG(DATA,RANGE,NULL,SCALE)
% Calculate the within-group reliability coefficient 
%   [REL] = RWG(DATA,TYPE)
%
%   DATA is a numerical matrix of ratings (missing values = NaN).
%   Each row is a single target and each column is a single rater.
%
%   RANGE is a scalar corresponding to the number of categories on a
%   discrete scale or the full range of a continuous scale.
%
%   NULL is an (optional) string indicating what type of null model to use:
%   options include 'uniform' or 'triangular'. 'Uniform' is the default.
%
%   SCALE is an (optional) string indicating that the measurement scale is 
%   either a 'discrete' or 'continuous'. 'Discrete' is the default.
%
%   (c) Jeffrey M Girard, 2015
%
%   Reference: James, L. R., Demaree, R. G., & Wolf, G. (1984).
%   Estimating within-group interrater reliability with and without response bias.
%   Journal of Applied Psychology, 69(1), 85–98.

%% Check inputs
if isempty(DATA), REL=NaN; return; end
if nargin < 3, NULL = 'uniform'; SCALE = 'discrete'; end
if nargin < 4, SCALE = 'discrete'; end

%% Remove any missing values
[rowindex,~] = find(~isfinite(DATA));
DATA(rowindex,:) = [];

%% Calculate observed variance for all targets
ssqx = var(DATA,0,2);

%% Calculate expected variance under various null models
if strcmpi(NULL,'uniform')
    if strcmpi(SCALE,'discrete')
        sigmasqe = ((RANGE ^ 2) - 1) / 12;
    elseif strcmpi(SCALE,'continuous')
        sigmasqe = ((RANGE - 1) ^ 2) / 12;
    else
        error('Error: SCALE must be set to ''discrete'' or ''continuous''');
    end
elseif strcmpi(NULL,'triangular')
    if strcmpi(SCALE,'discrete')
        if mod(RANGE,2) == 0
            sigmasqe = (RANGE ^ 2 + 2 * RANGE - 2) / 24;
        else
            sigmasqe = ((RANGE - 1) * (RANGE + 3)) / 24;
        end
    elseif strcmpi(SCALE,'continuous')
        %TODO: Find formula for continuous triangular distribution
    else
        error('Error: SCALE must be set to ''discrete'' or ''continuous''');
    end
else
    error('Error: NULL must be set to ''uniform'' or ''triangular''');
end

%% Calculate the average within-group reliability index
REL_i = 1 - (ssqx / sigmasqe);
REL = mean(REL_i);

end