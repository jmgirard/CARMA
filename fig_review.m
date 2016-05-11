function fig_review
%FIG_REVIEW Window for the review of existing ratings
% License: https://carma.codeplex.com/license

    % Create and maximize annotation window
    addpath('Functions');
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_review = figure( ...
        'Units','normalized', ...
        'Position',[0.1 0.1 0.8 0.8], ...
        'Name','CARMA: Review', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Visible','off', ...
        'Color',defaultBackground, ...
        'SizeChangedFcn',@figure_review_SizeChanged, ...
        'CloseRequestFcn',@figure_review_CloseRequest);
    %Create menu bar elements
    handles.menu_multimedia = uimenu(handles.figure_review, ...
        'Parent',handles.figure_review, ...
        'Label','Open Multimedia File', ...
        'Callback',@menu_multimedia_Callback);
    handles.menu_addseries = uimenu(handles.figure_review, ...
        'Parent',handles.figure_review, ...
        'Label','Add Annotation File', ...
        'Callback',@button_addseries_Callback);
    handles.menu_delseries = uimenu(handles.figure_review, ...
        'Parent',handles.figure_review, ...
        'Label','Remove Annotation Files', ...
        'Enable','off');
    handles.menu_delall = uimenu(handles.menu_delseries, ...
        'Parent',handles.menu_delseries, ...
        'Label','Remove All Files', ...
        'Callback',@menu_delall_Callback);
    handles.menu_delone = uimenu(handles.menu_delseries, ...
        'Parent',handles.menu_delseries, ...
        'Label','Remove Selected File', ...
        'Callback',@button_delseries_Callback);
    handles.menu_export = uimenu(handles.figure_review, ...
        'Parent',handles.figure_review, ...
        'Label','Export Mean Ratings', ...
        'Enable','off', ...
        'Callback',@menu_export_Callback);
    handles.menu_stats = uimenu(handles.figure_review, ...
        'Parent',handles.figure_review, ...
        'Label','Reliability Type');
    handles.menu_agree = uimenu(handles.menu_stats, ...
        'Parent',handles.menu_stats, ...
        'Label','Agreement ICC', ...
        'Checked','on', ...
        'Callback',@menu_agree_Callback);
    handles.menu_consist = uimenu(handles.menu_stats, ...
        'Parent',handles.menu_stats, ...
        'Label','Consistency ICC', ...
        'Callback',@menu_consist_Callback);
    pause(0.1);
    %Create uicontrol elements
    lc = .01; rc = .89;
    handles.axis_annotations = axes(...
        'Parent',handles.figure_review, ...
        'Units','Normalized', ...
        'OuterPosition',[0 0 1 1], ...
        'Position',[lc+.02 .04+.01 .87-.02 .35-.01], ...
        'TickLength',[0.01 0], ...
        'YLim',[-100,100],'YTick',[-100,-50,0,50,100],'YGrid','on',...
        'XLim',[0,10],'XTick',(1:10),'Box','on', ...
        'ButtonDownFcn',@axis_click_Callback);
    handles.listbox = uicontrol('Style','listbox', ...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'FontSize',10, ...
        'Position',[rc .485 .10 .50]);
    handles.button_addseries = uicontrol('Style','pushbutton', ...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'Position',[rc .445 3/100 3/100], ...
        'String','+', ...
        'FontSize',16, ...
        'TooltipString','Add Annotation File', ...
        'Callback',@button_addseries_Callback);
    handles.button_delseries = uicontrol('Style','pushbutton', ...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'Position',[rc+.005+3/100 .445 3/100 3/100], ...
        'String','–', ...
        'FontSize',16, ...
        'TooltipString','Remove Annotation File', ...
        'Callback',@button_delseries_Callback);
    handles.toggle_meanplot = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'Position',[rc+.01+6/100 .445 3/100 3/100], ...
        'String','m', ...
        'FontSize',14, ...
        'TooltipString','Toggle Mean Plot', ...
        'Enable','off', ...
        'Callback',@toggle_meanplot_Callback);
    handles.reliability = uitable(...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'Position',[rc .14 .10 .29], ...
        'ColumnName',[], ...
        'RowName',[], ...
        'Data',[], ...
        'FontSize',10);
    handles.toggle_playpause = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_review, ...
        'Units','Normalized', ...
        'Position',[rc .02 .10 .10], ...
        'String','Play', ...
        'FontSize',16.0, ...
        'Enable','off', ...
        'Callback',@toggle_playpause_Callback);
    handles.axis_guide = axes(...
        'Parent',handles.figure_review, ...
        'Units','Normalized', ...
        'Position',[.01 .42 .50 .565], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
    handles.axis_summary = axes('Units','normalized', ...
        'Parent',handles.figure_review, ...
        'OuterPosition',[.53 .42 .35 .565], ...
        'Box','on', ...
        'YLim',[-100,100], ...
        'YTick',[-100,-50,0,50,100], ...
        'YGrid','on', ...
        'XLim',[-1 1], ...
        'XTick',0, ...
        'XTickLabel','No Annotation Files Loaded', ...
        'NextPlot','add', ...
        'LooseInset',[0 0 0 0]);
    % Invoke and configure WMP ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_review);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    % Prepopulate variables
    set(handles.listbox,'String',{'<html><u>Annotation Files'},'Value',1);
    handles.AllFilenames = cell(0,1);
    handles.AllRatings = zeros(0,1);
    handles.MeanRatings = zeros(0,1);
    handles.axis_min = zeros(0,1);
    handles.axis_max = zeros(0,1);
    % Create timer
	handles.timer2 = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.20, ...
        'TimerFcn',{@timer2_Callback,handles});
    % Save handles to guidata
    guidata(handles.figure_review,handles);
    handles.figure_review.Visible = 'on';
    global stats; stats = 'agree';
end

% ===============================================================================

function menu_multimedia_Callback(hObject,~)
    handles = guidata(hObject);
    % Reset the GUI elements
    handles.vlc.playlist.items.clear();
    % Browse for, load, and get text_duration for a multimedia file
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file');
    if video_name==0, return; end
    try
        MRL = fullfile(video_path,video_name);
        MRL(MRL=='\') = '/';
        handles.MRL = sprintf('file://localhost/%s',MRL);
        handles.vlc.playlist.add(handles.MRL);
        handles.vlc.playlist.play();
        while handles.vlc.input.state ~= 3
            pause(0.001);
        end
        handles.vlc.playlist.togglePause();
        handles.vlc.input.time = 0;
        handles.dur = handles.vlc.input.length / 1000;
        set(handles.axis_annotations,'PickableParts','visible');
        set(handles.toggle_playpause,'Enable','on');
    catch err
        msgbox(err.message,'Error loading multimedia file.'); return;
    end
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_delall_Callback(hObject,~)
    handles = guidata(hObject);
    if get(handles.toggle_meanplot,'Value')==1
        msgbox('Please turn off mean plotting before removing annotation files.');
        return;
    end
    handles.AllRatings = zeros(0,1);
    handles.MeanRatings = zeros(0,1);
    handles.AllFilenames = cell(0,1);
    handles.axis_min = zeros(0,1);
    handles.axis_max = zeros(0,1);
    cla(handles.axis_annotations);
    set(handles.axis_annotations,'PickableParts','none');
    cla(handles.axis_summary);
    set(handles.axis_summary,'XLim',[-1,1],'XTick',0,'XTickLabel','No Annotation Files Loaded');
    % Update list box
    set(handles.listbox,'Value',1);
    rows = {'<html><u>Annotation Files'};
    box = '';
    set(handles.toggle_meanplot,'Enable','off','Value',0);
    set(handles.menu_delseries,'Enable','off');
    set(handles.menu_export,'Enable','off');
    set(handles.listbox,'String',rows);
    set(handles.reliability,'Data',box);
    % Update guidata with handles
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_export_Callback(hObject,~)
    handles = guidata(hObject);
    global settings;
    if ~isfield(handles,'MRL')
        defaultname = '';
        ext = '';
    else
        [~,defaultname,ext] = fileparts(handles.MRL);
    end
    output = [ ...
        {'Time of Rating'},{datestr(now)}; ...
        {'Multimedia File'},{sprintf('%s%s',defaultname,ext)}; ...
        {'Lower Label'},{settings.axis_lower}; ...
        {'Upper Label'},{settings.axis_upper}; ...
        {'Minimum Value'},{settings.axis_min}; ...
        {'Maximum Value'},{settings.axis_max}; ...
        {'Number of Steps'},{settings.axis_steps}; ...
        {'Second'},{'Rating'}; ...
        {'%%%%%%'},{'%%%%%%'}; ...
        num2cell([handles.Seconds,handles.MeanRatings])];
    defaultname = sprintf('%s_Mean',defaultname);
    %Prompt user for output filepath
    [filename,pathname] = uiputfile({'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
    if isequal(filename,0), return; end
    % Create export file as a CSV
    success = cell2csv(fullfile(pathname,filename),output);
    % Report saving success or failure
    if success
        h = msgbox('Export successful.');
        waitfor(h);
    else
        h = msgbox('Export error.');
        waitfor(h);
    end
end

% ===============================================================================

function menu_agree_Callback(hObject,~)
    handles = guidata(hObject);
    global stats;
    stats = 'agree';
    box = reliability(handles.AllRatings);
    set(handles.reliability,'Data',box);
    set(handles.menu_agree,'Checked','on');
    set(handles.menu_consist,'Checked','off');
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_consist_Callback(hObject,~)
    handles = guidata(hObject);
    global stats;
    stats = 'consist';
    box = reliability(handles.AllRatings);
    set(handles.reliability,'Data',box);
    set(handles.menu_agree,'Checked','off');
    set(handles.menu_consist,'Checked','on');
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function button_addseries_Callback(hObject,~)
    handles = guidata(hObject);
    % Prompt user for import file.
    [filenames,pathname] = uigetfile({'*.csv;*.xls;*.xlsx','CARMA Annotations (*.csv, *.xls, *.xlsx)'},'Open Annotations','MultiSelect','on');
    if ~iscell(filenames)
        if filenames==0, return; end
        filenames = {filenames};
    end
    for f = 1:length(filenames)
        filename = filenames{f};
        [~,~,ext] = fileparts(filename);
        if strcmpi(ext,'.csv')
            fileID = fopen(fullfile(pathname,filename),'r');
            axiscell = textscan(fileID,'%*s%f%[^\n\r]',2,'Delimiter',',','HeaderLines',4,'ReturnOnError',false);
            axis_min = axiscell{1}(1);
            axis_max = axiscell{1}(2);
            fclose(fileID);
            fileID = fopen(fullfile(pathname,filename),'r');
            datacell = textscan(fileID,'%f%f%[^\n\r]','Delimiter',',','HeaderLines',9,'ReturnOnError',false);
            secs = datacell{1};
            ratings = datacell{2};
            fclose(fileID);
        else
            [nums,~] = xlsread(fullfile(pathname,filename),'','','basic');
            axis_min = nums(5,2);
            axis_max = nums(6,2);
            secs = nums(10:end,1);
            ratings = nums(10:end,2);
        end
        % Check that the import file matches the multimedia file
        if isempty(handles.axis_min) || isempty(handles.axis_max)
            handles.axis_min = axis_min;
            handles.axis_max = axis_max;
        elseif handles.axis_min ~= axis_min || handles.axis_max ~= axis_max
            msgbox('Annotation files must have the same axis settings to be loaded together.','Error','Error');
            return;
        end
        if ~isempty(handles.AllRatings) && size(handles.AllRatings,1)~=size(ratings,1)
            msgbox('Annotation file must have the same sampling rate as the other annotation files.','Error','Error');
            return;
        else
            % Append the new file to the stored data
            handles.Seconds = secs;
            handles.AllRatings = [handles.AllRatings,ratings];
            [~,fn,~] = fileparts(filename);
            handles.AllFilenames = [handles.AllFilenames;fn];
            % Update mean series
            handles.MeanRatings = nanmean(handles.AllRatings,2);
            guidata(hObject,handles);
            % Update list box
            CS = get(gca,'ColorOrder');
            rows = {'<html><u>Annotation Files'};
            for i = 1:size(handles.AllRatings,2)
                colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
                rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(colorindex,:)),i,handles.AllFilenames{i})];
            end
            set(handles.listbox,'String',rows,'Value',size(handles.AllRatings,2)+1);
            % Update reliability box
            box = reliability(handles.AllRatings);
            set(handles.reliability,'Data',box);
            guidata(handles.figure_review,handles);
            % Enable menu options
            set(handles.menu_delseries,'Enable','on');
            set(handles.menu_export,'Enable','on');
        end
    end
    update_plots(handles);
    update_boxplots(handles.figure_review,[]);
    set(handles.toggle_meanplot,'Enable','on');
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function button_delseries_Callback(hObject,~)
    handles = guidata(hObject);
    % Get currently selected item
    index = get(handles.listbox,'Value')-1;
    % Cancel if the first row is selected
    if index == 0, return; end
    if size(handles.AllRatings,2)<2
        % Remove final item from list
        handles.AllRatings = zeros(0,1);
        handles.MeanRatings = zeros(0,1);
        handles.AllFilenames = cell(0,1);
        handles.axis_min = zeros(0,1);
        handles.axis_max = zeros(0,1);
        cla(handles.axis_annotations);
        set(handles.axis_annotations,'PickableParts','none');
        cla(handles.axis_summary);
        set(handles.axis_summary,'XLim',[-1,1],'XTick',0,'XTickLabel','No Annotation Files Loaded');
    else
        % Remove selected item from list
        handles.AllRatings(:,index) = [];
        handles.AllFilenames(index) = [];
        % Update mean series
        handles.MeanRatings = nanmean(handles.AllRatings,2);
        guidata(handles.figure_review,handles);
        update_plots(handles);
        update_boxplots(handles.figure_review,[]);
    end
    % Update list box
    set(handles.listbox,'Value',1);
    CS = get(gca,'ColorOrder');
    rows = {'<html><u>Annotation Files'};
    if isempty(handles.AllRatings)
        box = '';
        set(handles.toggle_meanplot,'Enable','off','Value',0);
        set(handles.menu_delseries,'Enable','off');
        set(handles.menu_export,'Enable','off');
    elseif size(handles.AllRatings,2)==1
        rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(1,:)),1,handles.AllFilenames{1})];
        box = reliability(handles.AllRatings);
        set(handles.toggle_meanplot,'Enable','off','Value',0);
    else
        for i = 1:size(handles.AllRatings,2)
            colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(colorindex,:)),i,handles.AllFilenames{i})];
        end
        box = reliability(handles.AllRatings);
        toggle_meanplot_Callback(handles.toggle_meanplot,[]);
    end
    set(handles.listbox,'String',rows);
    set(handles.reliability,'Data',box);
    % Update guidata with handles
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function toggle_meanplot_Callback(hObject,~)
    handles = guidata(hObject);
    update_plots(handles);
    if get(hObject,'Value')==get(hObject,'Max')
        %If toggle is set to on, update list box with mean series
        set(handles.listbox,'Value',size(handles.AllRatings,2)+2);
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv([.8 .8 .8]),i,handles.AllFilenames{i})];
        end
        rows = [cellstr(rows);'<html><font color="red">[M]</font> Mean Plot'];
        set(handles.listbox,'String',rows);
    elseif get(hObject,'Value')==get(hObject,'Min')
        %If toggle is set to off, update list box without mean series
        set(handles.listbox,'Value',1);
        CS = get(gca,'ColorOrder');
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
           colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
           rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(colorindex,:)),i,handles.AllFilenames{i})];
        end
        set(handles.listbox,'String',rows);
    end
    guidata(hObject,handles);
end

% ===============================================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
    if get(hObject,'Value')==get(hObject,'Max')
        % Send play() command to VLC and start timer
        handles.vlc.playlist.play();
        start(handles.timer2);
        set(hObject,'String','Pause');
        set(handles.menu_multimedia,'Enable','off');
        set(handles.menu_export,'Enable','off');
    else
        % Send pause() command to VLC and stop timer
        handles.vlc.playlist.togglePause();
        stop(handles.timer2);
        set(hObject,'String','Resume','Value',0);
        set(handles.menu_multimedia,'Enable','on');
        set(handles.menu_export,'Enable','on');
    end
    guidata(hObject, handles);
end

% ===============================================================================

function timer2_Callback(~,~,handles)
    handles = guidata(handles.figure_review);
    if handles.vlc.input.state == 3
        % While playing, update annotations plot
        ts = handles.vlc.input.time/1000;
        update_plots(handles);
        hold on;
        plot(handles.axis_annotations,[ts,ts],[handles.axis_min,handles.axis_max],'k');
        hold off;
        drawnow();
    elseif handles.vlc.input.state == 6 || handles.vlc.input.state == 5
        % When done, send stop() command to VLC
        stop(handles.timer2);
        update_plots(handles);
        set(handles.toggle_playpause,'String','Play','Value',0);
        set(handles.menu_export,'Enable','on');
        handles.vlc.input.time = 0;
    else
        % Otherwise, wait
        return;
    end
end

% ===============================================================================

function axis_click_Callback(hObject,~)
    handles = guidata(hObject);
    % Jump VLC playback to clicked position
    coord = get(handles.axis_annotations,'CurrentPoint');
    duration = handles.vlc.input.length;
    if coord(1,1) > 0 && coord(1,1)*1000 < duration
        % if clicked on a valid position, go to that position
        handles.vlc.input.time = coord(1,1)*1000;
    else
        % if clicked on an invalid position, go to video start
        handles.vlc.input.time = 0;
    end
    pause(.05);
    % While playing, update annotations plot
    ts = handles.vlc.input.time/1000;
    update_plots(handles);
    hold on;
    plot(handles.axis_annotations,[ts,ts],[handles.axis_min,handles.axis_max],'k');
    hold off;
    drawnow();
end

% ===============================================================================

function update_plots(handles)
    handles = guidata(handles.figure_review);
    if isempty(handles.AllRatings), return; end
    if get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Min')
        axes(handles.axis_annotations); cla;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2,'ButtonDownFcn',@axis_click_Callback);
        ylim([handles.axis_min,handles.axis_max]);
        xlim([0,ceil(max(handles.Seconds))+1]);
        set(gca,'YGrid','on','YTick',linspace(handles.axis_min,handles.axis_max,5));
        set(handles.axis_annotations,'ButtonDownFcn',@axis_click_Callback);
    elseif get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Max')
        axes(handles.axis_annotations); cla;
        set(handles.axis_annotations,'ButtonDownFcn',@axis_click_Callback);
        hold on;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2,'Color',[.8 .8 .8],'ButtonDownFcn',@axis_click_Callback);
        plot(handles.Seconds,handles.MeanRatings,'-','LineWidth',2,'Color',[1 0 0],'ButtonDownFcn',@axis_click_Callback);
        ylim([handles.axis_min,handles.axis_max]);
        xlim([0,ceil(max(handles.Seconds))+1]);
        set(gca,'YGrid','on','YTick',linspace(handles.axis_min,handles.axis_max,5));
        hold off;
    end
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function update_boxplots(hObject,~)
    handles = guidata(hObject);
    cla(handles.axis_summary);
    axes(handles.axis_summary);
    a = sprintf('[%02d],',1:size(handles.AllRatings,2));
    b = strsplit(a,',')';
    boxplot(handles.AllRatings,b(1:end-1));
    set(handles.axis_summary,...
        'YLim',[handles.axis_min,handles.axis_max],...
        'YTick',linspace(handles.axis_min,handles.axis_max,5));
end

% ===============================================================================

function figure_review_SizeChanged(hObject,~)
    handles = guidata(hObject);
    if isfield(handles,'figure_review')
        pos = getpixelposition(handles.figure_review);
        % Force to remain above a minimum size
        if pos(3) < 1024 || pos(4) < 600
            setpixelposition(handles.figure_review,[pos(1) pos(2) 1024 600]);
            movegui(handles.figure_review,'center');
        end
        % Update the size and position of the VLC controller
        if isfield(handles,'vlc')
            move(handles.vlc,getpixelposition(handles.axis_guide));
        end
        rel_width = getpixelposition(handles.reliability);
        handles.reliability.ColumnWidth = {floor(rel_width(3)/2)-1};
    end
end

% =========================================================

function figure_review_CloseRequest(hObject,~)
    handles = guidata(hObject);
    % Remove timer as part of cleanup
    delete(handles.timer2);
    delete(gcf);
end

% =========================================================

function [box] = reliability(X)
    global stats;
    k = size(X,2);
    if k == 1
        box = {'[01] Mean',num2str(nanmean(X),'%.0f'); ...
            '[01] SD',num2str(nanstd(X),'%.0f')};
    elseif k > 1
        if strcmp(stats,'agree')
            box = {'ICC(A,1)',num2str(ICC_A_1(X),'%.3f'); ...
                'ICC(A,k)',num2str(ICC_A_k(X),'%.3f')};
        elseif strcmp(stats,'consist')
            box = {'ICC(C,1)',num2str(ICC_C_1(X),'%.3f'); ...
                'ICC(C,k)',num2str(ICC_C_k(X),'%.3f')};
        end
        for i = 1:k
            box = [box;{sprintf('[%02d] Mean',i),num2str(nanmean(X(:,i)),'%.0f');}];
        end
        for i = 1:k
            box = [box;{sprintf('[%02d] SD',i),num2str(nanstd(X(:,i)),'%.0f');}];
        end
    end
    
end