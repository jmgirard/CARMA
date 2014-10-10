function [box] = reliability( X )
%RELIABILITY Code to populate the reliability box based on number of raters
% License: https://carma.codeplex.com/license

	k = size(X,2);
    PCC = corr(X,'type','Pearson');
	cAlpha = k/(k-1)*(var(sum(X'))-sum(var(X)))/var(sum(X'));
    
    if k == 1
        box = {'# Raters','1';...
            '[01] Mean',num2str(mean(X),'%.0f');...
            '[01] SD',num2str(std(X),'%.0f')};
    elseif k == 2
        box = {'# Raters','2';...
            'Correlation',num2str(PCC(1,2),'%.3f');...
            'Cronbach A',num2str(cAlpha,'%.3f');...
            '[01] Mean',num2str(mean(X(:,1)),'%.0f');...
            '[02] Mean',num2str(mean(X(:,2)),'%.0f');...
            '[01] SD',num2str(std(X(:,1)),'%.0f');...
            '[02] SD',num2str(std(X(:,2)),'%.0f')};
    elseif k > 2
        box = {'# Raters',num2str(k,'%d')};
        box = [box;{'Cronbach A',num2str(cAlpha,'%.3f')}];
        for i = 1:k
            box = [box;{sprintf('[%02d] Mean',i),num2str(mean(X(:,i)),'%.0f');}];
        end
        for i = 1:k
            box = [box;{sprintf('[%02d] SD',i),num2str(std(X(:,i)),'%.0f');}];
        end
    end
    
end