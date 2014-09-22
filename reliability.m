function [ICC31,ICC3k,alpha] = reliability( dat )
%RELIABILITY Code to compute the intraclass correlations and cronbach's alpha
% License: https://carma.codeplex.com/license

	k = size(dat,2); %number of raters
	n = size(dat,1); %number of targets
	mpt = mean(dat,2); %mean per target
    mpr = mean(dat); %mean per rater/rating
	tm = mean(mpt); %get total mean
	BSS = sum((mpt - tm).^2) * k; %between target sum sqrs
	BMS = BSS / (n - 1); %between targets mean squares
    WSS = sum(sum(bsxfun(@minus,dat,mpt).^2)); %within target sum sqrs
    RSS = sum((mpr - tm).^2) * n; %between rater sum sqrs
	ESS = WSS - RSS; %residual sum of squares
	EMS = ESS / ((k - 1) * (n - 1)); %residual mean sqrs

	ICC31 = (BMS - EMS) / (BMS + (k - 1) * EMS);
	ICC3k = (BMS - EMS) / BMS;

	VarTotal = var(sum(dat')); %variance of the items' sum
	SumVarX = sum(var(dat)); %sum of the item variance

	alpha = k/(k-1)*(VarTotal-SumVarX)/VarTotal;
end