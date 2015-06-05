function fig_review
%FIG_REVIEW Window for the review of existing ratings
% License: https://carma.codeplex.com/license

    % Create and maximize annotation window
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
        'Label','Remove Annotation File', ...
        'Callback',@button_delseries_Callback);
    handles.menu_export = uimenu(handles.figure_review, ...
        'Parent',handles.figure_review, ...
        'Label','Export Mean Ratings', ...
        'Callback',@menu_export_Callback);
    pause(0.1);
    %Create uicontrol elements
    lc = .01; rc = .89;
    handles.axis_annotations = axes(...
        'Parent',handles.figure_review, ...
        'Units','Normalized', ...
        'OuterPosition',[0 0 1 1], ...
        'Position',[lc+.02 .04+.01 .87-.02 .15-.01], ...
        'TickLength',[0.01 0], ...
        'YLim',[-100,100],'YTick',[-100,0,100],'YGrid','on',...
        'XLim',[0,10],'XTick',[1:10],'Box','on', ...
        'ButtonDownFcn',@axis_click_Callback);
    handles.listbox = uicontrol('Style','listbox', ...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'FontSize',8, ...
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
    pos = getpixelposition(handles.figure_review);
    handles.reliability = uitable(...
        'Parent',handles.figure_review, ...
        'Units','normalized', ...
        'Position',[rc .14 .10 .29], ...
        'ColumnWidth',{pos(3)*.099*.65,pos(3)*.099*.25}, ...
        'ColumnName',[], ...
        'RowName',[], ...
        'Data',[], ...
        'FontSize',8);
    handles.toggle_playpause = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_review, ...
        'Units','Normalized', ...
        'Position',[rc .02 .10 .10], ...
        'String','Play', ...
        'FontSize',16.0, ...
        'Callback',@toggle_playpause_Callback);
    handles.axis_guide = axes(...
        'Parent',handles.figure_review, ...
        'Units','Normalized', ...
        'Position',[.01 .21 .87 .775], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
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
    catch err
        msgbox(err.message,'Error loading multimedia file.'); return;
    end
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_export_Callback(hObject,~)
    handles = guidata(hObject);
    global settings;
    [~,defaultname,ext] = fileparts(handles.MRL);
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
    [filename,pathname] = uiputfile({'*.xlsx','Excel 2007 Spreadsheet (*.xlsx)';...
        '*.xls','Excel 2003 Spreadsheet (*.xls)';...
        '*.csv','Comma-Separated Values (*.csv)'},...
        'Save as',defaultname);
    if isequal(filename,0), return; end
    % Create export file depending on selected file type
    [~,~,ext] = fileparts(filename);
    if strcmpi(ext,'.XLS') || strcmpi(ext,'.XLSX')
        % Create XLS/XLSX file if that is the selected file type
        [success,message] = xlswrite(fullfile(pathname,filename),output);
        if strcmp(message.identifier,'MATLAB:xlswrite:dlmwrite')
            % If Excel is not installed, create CSV file instead
            serror = errordlg('Exporting to .XLS/.XLSX requires Microsoft Excel to be installed. CARMA will now export to .CSV instead.');
            uiwait(serror);
            success = fx_cell2csv(fullfile(pathname,filename),output);
        end
    elseif strcmpi(ext,'.CSV')
        % Create CSV file if that is the selected file type
        success = fx_cell2csv(fullfile(pathname,filename),output);
    end
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

function button_addseries_Callback(hObject,~)
    handles = guidata(hObject);
    % Prompt user for import file.
    [filenames,pathname] = uigetfile({'*.xls; *.xlsx; *.csv','CARMA Export Formats (*.xls, *.xlsx, *.csv)'},'Open Annotations','MultiSelect','on');
    if ~iscell(filenames)
        if filenames==0, return; end
        filenames = {filenames};
    end
    for f = 1:length(filenames)
        filename = filenames{f};
        [~,~,data] = xlsread(fullfile(pathname,filename));
        % Check that the import file matches the multimedia file
        if isempty(handles.axis_min) || isempty(handles.axis_max)
            handles.axis_min = data{5,2};
            handles.axis_max = data{6,2};
        elseif handles.axis_min ~= data{5,2} || handles.axis_max ~= data{6,2}
            msgbox('Annotation files must have the same axis settings to be loaded together.','Error','Error');
            return;
        end
        if ~isempty(handles.AllRatings) && size(handles.AllRatings,1)~=size(data(10:end,:),1)
            msgbox('Annotation file must have the same sampling rate as the other annotation files.','Error','Error');
            return;
        else
            % Append the new file to the stored data
            handles.Seconds = cell2mat(data(10:end,1));
            handles.AllRatings = [handles.AllRatings,cell2mat(data(10:end,2))];
            [~,fn,~] = fileparts(filename);
            handles.AllFilenames = [handles.AllFilenames;fn];
            % Update mean series
            handles.MeanRatings = nanmean(handles.AllRatings,2);
            guidata(hObject,handles);
            update_plots(handles);
            % Update list box
            CS = get(gca,'ColorOrder');
            rows = {'<html><u>Annotation Files'};
            for i = 1:size(handles.AllRatings,2)
                colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
                rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',fx_rgbconv(CS(colorindex,:)),i,handles.AllFilenames{i})];
            end
            set(handles.listbox,'String',rows,'Value',size(handles.AllRatings,2)+1);
            % Update reliability box
            box = reliability(handles.AllRatings);
            set(handles.reliability,'Data',box);
            guidata(handles.figure_review,handles);
        end
    end
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
    else
        % Remove selected item from list
        handles.AllRatings(:,index) = [];
        handles.AllFilenames(index) = [];
        % Update mean series
        handles.MeanRatings = nanmean(handles.AllRatings,2);
        guidata(handles.figure_review,handles);
        update_plots(handles);
    end
    % Update list box
    set(handles.listbox,'Value',1);
    CS = get(gca,'ColorOrder');
    rows = {'<html><u>Annotation Files'};
    if isempty(handles.AllRatings)
        box = '';
        set(handles.toggle_meanplot,'Enable','off','Value',0);
    elseif size(handles.AllRatings,2)==1
        rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',fx_rgbconv(CS(1,:)),1,handles.AllFilenames{1})];
        box = reliability(handles.AllRatings);
        set(handles.toggle_meanplot,'Enable','off','Value',0);
    else
        for i = 1:size(handles.AllRatingsX,2)
            colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',fx_rgbconv(CS(colorindex,:)),i,handles.AllFilenames{i})];
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
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',fx_rgbconv([.8 .8 .8]),i,handles.AllFilenames{i})];
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
           rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',fx_rgbconv(CS(colorindex,:)),i,handles.AllFilenames{i})];
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
        set(gca,'YGrid','on','YTick',[handles.axis_min,handles.axis_max-(handles.axis_max-handles.axis_min)/2,handles.axis_max]);
        set(handles.axis_annotations,'ButtonDownFcn',@axis_click_Callback);
    elseif get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Max')
        axes(handles.axis_annotations); cla;
        set(handles.axis_annotations,'ButtonDownFcn',@axis_click_Callback);
        hold on;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2,'Color',[.8 .8 .8],'ButtonDownFcn',@axis_click_Callback);
        plot(handles.Seconds,handles.MeanRatings,'-','LineWidth',2,'Color',[1 0 0],'ButtonDownFcn',@axis_click_Callback);
        ylim([handles.axis_min,handles.axis_max]);
        xlim([0,ceil(max(handles.Seconds))+1]);
        set(gca,'YGrid','on','YTick',[handles.axis_min,handles.axis_max-(handles.axis_max-handles.axis_min)/2,handles.axis_max]);
        hold off;
    end
    guidata(handles.figure_review,handles);
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

function [box] = reliability( X )
    if k == 1
        box = {'[01] Mean',num2str(nanmean(X),'%.0f'); ...
            '[01] SD',num2str(nanstd(X),'%.0f')};
    elseif k > 1
        box = {'ICC(A,1)',num2str(fx_ICC(X,'A-1'),'%.3f'); ...
            'ICC(A,k)',num2str(fx_ICC(X,'A-k'),'%.3f')};
        for i = 1:k
            box = [box;{sprintf('[%02d] Mean',i),num2str(nanmean(X(:,i)),'%.0f');}];
        end
        for i = 1:k
            box = [box;{sprintf('[%02d] SD',i),num2str(nanstd(X(:,i)),'%.0f');}];
        end
    end
    
end