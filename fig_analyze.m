function [] = fig_analyze(ratings, filenames, axMin, axMax)
%FIG_ANALYZE Window for the display of rating statistics
%   License: https://github.com/jmgirard/CARMA/blob/master/LICENSE.txt

    if isempty(ratings), return; end
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_analyze = figure( ...
        'Name','CARMA: Analyze Ratings', ...
        'Units','pixels', ...
        'Position',[0 0 500 550], ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Visible','off', ...
        'Resize','off', ...
        'Color',defaultBackground);
    movegui(handles.figure_analyze,'center');
    uicontrol('Style','text', ...
        'Parent',handles.figure_analyze, ...
        'Units','normalized', ...
        'Position',[.05 .925 .90 .04], ...
        'HorizontalAlignment','center', ...
        'FontSize',12, ...
        'String','Axis Configuration');
    handles.configuration = uitable(...
        'Parent',handles.figure_analyze, ...
        'Units','normalized', ...
        'Position',[.05 .800 .90 .10], ...
        'ColumnName',{'Axis Minimum Value','Axis Maximum Value'}, ...
        'ColumnWidth',{224,224}, ...
        'RowName',[], ...
        'Data',{axMin,axMax}, ...
        'FontSize',11);
    jscrollpane = findjobj(handles.configuration);
    jTable = jscrollpane.getViewport.getView;
    cellStyle = jTable.getCellStyleAt(0,0);
    cellStyle.setHorizontalAlignment(cellStyle.CENTER);
    jTable.repaint;
    uicontrol('Style','text', ...
        'Parent',handles.figure_analyze, ...
        'Units','normalized', ...
        'Position',[.05 .72 .90 .04], ...
        'HorizontalAlignment','center', ...
        'FontSize',12, ...
        'String','Descriptive Statistics');
    handles.descriptives = uitable(...
        'Parent',handles.figure_analyze, ...
        'Units','normalized', ...
        'Position',[.05 .42 .90 .275], ...
        'ColumnName',{'Annotation File','Mean','SD'}, ...
        'ColumnWidth',{230 100 100}, ...
        'RowName',[], ...
        'Data',[], ...
        'FontSize',10);
    set(findjobj(handles.descriptives),'VerticalScrollBarPolicy',javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
    % Reliability Table
    uicontrol('Style','text', ...
        'Parent',handles.figure_analyze, ...
        'Units','normalized', ...
        'Position',[.05 .35 .90 .04], ...
        'HorizontalAlignment','center', ...
        'FontSize',12, ...
        'String','Inter-Rater Agreement and Reliability');
    handles.reliability = uitable(...
        'Parent',handles.figure_analyze, ...
        'Units','normalized', ...
        'Position',[.05 .05 .90 .275], ...
        'ColumnName',{'Index of Agreement/Reliability','Estimate'}, ...
        'ColumnWidth',{348,100}, ...
        'RowName',[], ...
        'Data',[], ...
        'FontSize',10);
    index = isnan(ratings);
    X2 = ratings;
    X2(index,:) = [];
	r = size(X2,2);
    % Calculate and display descriptives
    desc = get(handles.descriptives,'Data');
    for i = 1:r
        desc{i,1} = filenames{i};
        desc{i,2} = num2str(nanmean(ratings(:,i)),'%.3f');
        desc{i,3} = num2str(nanstd(ratings(:,i)),'%.3f');
    end
    set(handles.descriptives,'Data',desc);
    % Calculate and display reliability
    if r == 1
        reli = [];
    elseif r > 1
        reli{1,1} = ' Single-Score Agreement ICC';
        reli{1,2} = num2str(ICC_A_1(X2),'%0.3f');
        reli{2,1} = ' Single-Score Consistency ICC';
        reli{2,2} = num2str(ICC_C_1(X2),'%0.3f');
        reli{3,1} = ' Average-Score Agreement ICC';
        reli{3,2} = num2str(ICC_A_k(X2),'%0.3f');
        reli{4,1} = ' Average-Score Consistency ICC';
        reli{4,2} = num2str(ICC_C_k(X2),'%0.3f');
        reli{5,1} = ' Mean of Rectangular RWG scores';
        reli{5,2} = num2str(RWG(round(X2),axMax-axMin,'uniform'),'%0.3f');
        reli{6,1} = ' Mean of Triangular RWG scores';
        reli{6,2} = num2str(RWG(round(X2),axMax-axMin,'triangular'),'%0.3f');
    else
        return;
    end
    set(handles.reliability,'Data',reli);
    set(handles.figure_analyze,'Visible','on');
end