function fig_review
%FIG_REVIEW Window for the review of existing ratings
% License: https://github.com/jmgirard/CARMA/blob/master/license.txt

    % Create and maximize annotation window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_review = figure( ...
        'Name','CARMA: Review Ratings', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Visible','off', ...
        'Color',defaultBackground, ...
        'ResizeFcn',@figure_review_Resize, ...
        'CloseRequestFcn',@figure_review_CloseRequest);
    %Create menu bar elements
    handles.menu_media = uimenu(handles.figure_review, ...
        'Label','Media');        
    handles.menu_openmedia = uimenu(handles.menu_media, ...
        'Label','Open Media File', ...
        'Callback',@menu_openmedia_Callback);
    handles.menu_volume = uimenu(handles.menu_media, ...
        'Label','Adjust Volume', ...
        'Callback',@menu_volume_Callback);
    handles.menu_closemedia = uimenu(handles.menu_media, ...
        'Label','Close Media File', ...
        'Enable','off', ...
        'Callback',@menu_closemedia_Callback);
    handles.menu_annotations = uimenu(handles.figure_review, ...
        'Label','Annotations');
    handles.menu_addseries = uimenu(handles.menu_annotations, ...
        'Label','Import Annotation Files', ...
        'Callback',@addseries_Callback);
    handles.menu_remsel = uimenu(handles.menu_annotations, ...
        'Label','Remove Selected Annotation File', ...
        'Callback',@remsel_Callback);
    handles.menu_remall = uimenu(handles.menu_annotations, ...
        'Label','Remove All Annotation Files', ...
        'Callback',@remall_Callback);
    handles.menu_export = uimenu(handles.menu_annotations, ...
        'Label','Export Mean Series to New File', ...
        'Enable','off', ...
        'Callback',@menu_export_Callback);
    handles.menu_analyze = uimenu(handles.figure_review, ...
        'Label','Analyze');
    handles.menu_analyzeratings = uimenu(handles.menu_analyze, ...
        'Label','Analyze Ratings', ...
        'Enable','off', ...
        'Callback',@analyzeratings_Callback);
    handles.menu_help = uimenu(handles.figure_review, ...
        'Label','Help');
    handles.menu_about = uimenu(handles.menu_help, ...
        'Label','About', ...
        'Callback',@menu_about_Callback);
    handles.menu_document = uimenu(handles.menu_help, ...
        'Label','Documentation', ...
        'Callback',@menu_document_Callback);
    handles.menu_report = uimenu(handles.menu_help, ...
        'Label','Report Issues', ...
        'Callback',@menu_report_Callback);
    % Set minimum size
    set(handles.figure_review,'Units','normalized','Position',[0.1,0.1,0.8,0.8],'Visible','on');
    drawnow;
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jFig = get(handle(handles.figure_review),'JavaFrame');
    jClient = jFig.fHG2Client;
    jWindow = jClient.getWindow;
    jWindow.setMinimumSize(java.awt.Dimension(1024,768));
    %Create uicontrol elements
    lc = .01; rc = .85;
    handles.axMin = zeros(0,1);
    handles.axMax = zeros(0,1);
    axMin = -100;
    axMax = 100;
    handles.axis_annotations = axes(handles.figure_review, ...
        'Units','Normalized', ...
        'OuterPosition',[lc+.02 .04+.01 .83-.02 .35-.01], ...
        'TickLength',[0.01 0], ...
        'YLim',[axMin,axMax], ...
        'YTick',linspace(axMin,axMax,5),'YGrid','on',...
        'XLim',[0,10],'XTick',(0:10),'Box','on', ...
        'PickableParts','none', ...
        'ButtonDownFcn',@axis_click_Callback);
    ti = get(handles.axis_annotations,'TightInset');
    set(handles.axis_annotations,'LooseInset',ti);
    %'Position',[lc+.02 .04+.01 .83-.02 .35-.01], ...
    global tsline;
    hold on;
    tsline = plot(handles.axis_annotations,[0,0],[axMin,axMax],'k');
    hold off;
    handles.listbox = uicontrol(handles.figure_review, ...
        'Style','listbox', ...
        'Units','normalized', ...
        'FontSize',9, ...
        'Position',[rc .42 .14 .565]);
    handles.push_addfile = uicontrol(handles.figure_review, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[rc .35 14/100 4.5/100], ...
        'String','Add Annotations', ...
        'FontSize',10, ...
        'Callback',@addseries_Callback);
    handles.push_remsel = uicontrol(handles.figure_review, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[rc .30 14/100 4.5/100], ...
        'String','Remove Selected', ...
        'FontSize',10, ...
        'Callback',@remsel_Callback);
    handles.push_remall = uicontrol(handles.figure_review, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[rc .25 14/100 4.5/100], ...
        'String','Remove All Files', ...
        'FontSize',10, ...
        'Callback',@remall_Callback);
    handles.toggle_meanplot = uicontrol(handles.figure_review, ...
        'Style','togglebutton', ...
        'Units','normalized', ...
        'Position',[rc .20 14/100 4.5/100], ...
        'String','Show Mean Plot', ...
        'FontSize',10, ...
        'Enable','off', ...
        'Callback',@meanplot_Callback);
    handles.push_analyze = uicontrol(handles.figure_review, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[rc .15 14/100 4.5/100], ...
        'String','Analyze Ratings', ...
        'FontSize',10, ...
        'Enable','off', ...
        'Callback',@analyzeratings_Callback);
    handles.axis_guide = axes(handles.figure_review, ...
        'Units','Normalized', ...
        'Position',[lc*2 .42 .50 .565], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
    handles.axis_summary = axes(handles.figure_review, ...
        'Units','normalized', ...
        'OuterPosition',[.53 .42 .305 .565], ...
        'Box','on', ...
        'YLim',[axMin,axMax], ...
        'YTick',linspace(axMin,axMax,5), ...
        'YGrid','on', ...
        'XLim',[-1 1], ...
        'XTick',0, ...
        'XTickLabel','No Annotation Files Loaded', ...
        'NextPlot','add', ...
        'LooseInset',[0 0 0 0]);
    handles.toggle_playpause = uicontrol(handles.figure_review, ...
        'Style','togglebutton', ...
        'Units','Normalized', ...
        'Position',[rc .02 .14 .10], ...
        'String','Play', ...
        'FontSize',16.0, ...
        'Enable','off', ...
        'Callback',@toggle_playpause_Callback);
    % Invoke and configure WMP ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_review);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    % Prepopulate variables
    set(handles.listbox,'String',{'<html><u>Annotation Files</u>'},'Value',1);
    handles.AllFilenames = cell(0,1);
    handles.AllRatings = zeros(0,1);
    handles.MeanRatings = zeros(0,1);
    handles.MRL = cell(0,1);
    % Create timer
	handles.timer2 = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.20, ...
        'TimerFcn',{@timer2_Callback,handles});
    % Save handles to guidata
    guidata(handles.figure_review,handles);
    handles.figure_review.Visible = 'on';
    addpath('Functions');
end

% ===============================================================================

function menu_openmedia_Callback(hObject,~)
    handles = guidata(hObject);
    % Reset the GUI elements
    handles.vlc.playlist.items.clear();
    % Browse for, load, and get text_duration for a media file
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file:');
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
        set(handles.toggle_playpause,'String','Play','Enable','on');
        set(handles.menu_closemedia,'Enable','on');
        set(handles.axis_annotations,'XLim',[0,ceil(handles.dur)],'XTick',round(linspace(0,handles.dur,11)),'PickableParts','Visible');
    catch err
        msgbox(err.message,'Error loading media file.','error'); return;
    end
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_volume_Callback(hObject,~)
    handles = guidata(hObject);
    ovol = handles.vlc.audio.volume;
    nvol = inputdlg(sprintf('Enter volume percentage:\n0=Mute, 100=Full Sound'),'',1,{num2str(ovol)});
    nvol = str2double(nvol);
    if isempty(nvol), return; end
    if isnan(nvol), return; end
    if nvol < 0, nvol = 0; end
    if nvol > 100, nvol = 100; end
    handles.vlc.audio.volume = nvol;
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_closemedia_Callback(hObject,~)
    handles = guidata(hObject);
    handles.vlc.playlist.stop();
    handles.vlc.playlist.items.clear();
    set(handles.menu_closemedia,'Enable','off');
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function menu_export_Callback(hObject,~)
    handles = guidata(hObject);
    if isempty(handles.MRL)
        %TODO: Pull this information from the annotation file
        ext = '';
        defaultname = 'Mean';
    else
        [~,name,ext] = fileparts(handles.MRL);
        defaultname = sprintf('%s_Mean',name);
    end
    %TODO: Grab axis labels and steps from annotation file
    output = [ ...
        {'Time of Rating'},{datestr(now)}; ...
        {'Multimedia File'},{sprintf('%s%s',defaultname,ext)}; ...
        {'Lower Label'},{''}; ...
        {'Upper Label'},{''}; ...
        {'Minimum Value'},{handles.axMin}; ...
        {'Maximum Value'},{handles.axMax}; ...
        {'Number of Steps'},{''}; ...
        {'Second'},{'Rating'}; ...
        {'%%%%%%'},{'%%%%%%'}; ...
        num2cell([handles.Seconds,handles.MeanRatings])];
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

function menu_about_Callback(~,~)
    global version;
    msgbox(sprintf('CARMA version %.2f\nJeffrey M Girard (c) 2014-2017\nhttp://carma.jmgirard.com\nGNU General Public License v3',version),'About','Help');
end

% ===============================================================================

function menu_document_Callback(~,~)
    web('https://github.com/jmgirard/CARMA/wiki','-browser');
end

% ===============================================================================

function menu_report_Callback(~,~)
    web('https://github.com/jmgirard/CARMA/issues','-browser');
end

% ===============================================================================

function addseries_Callback(hObject,~)
    handles = guidata(hObject);
    if get(handles.toggle_meanplot,'Value')==1
        msgbox('Please turn off mean plotting before adding annotation files.');
        return;
    end
    % Prompt user for import file.
    [filenames,pathname] = uigetfile({'*.csv;*.xlsx;*.xls','CARMA Annotations (*.csv, *.xlsx, *.xls)'},'Open Annotations','','MultiSelect','on');
    if ~iscell(filenames)
        if filenames==0, return; end
        filenames = {filenames};
    end
    w = waitbar(0,'Importing annotation files...');
    for f = 1:length(filenames)
        filename = filenames{f};
        [~,~,ext] = fileparts(filename);
        if strcmp(ext,'.csv')
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
        % Get settings from import file
        if isempty(handles.axMin) || isempty(handles.axMax)
            handles.axMin = axis_min;
            handles.axMax = axis_max;
        elseif handles.axMin ~= axis_min || handles.axMax ~= axis_max
            msgbox('Annotation files must have the same axis settings to be loaded together.','Error','Error');
            waitbar(1);
            return;
        end
        % Check that the import file matches the media file
        if ~isempty(handles.AllRatings) && size(handles.AllRatings,1)~=size(ratings,1)
            msgbox('Annotation file must have the same bin size as the other annotation files.','Error','Error');
            waitbar(1);
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
        end
        waitbar(f/length(filenames));
    end
    update_plots(handles);
    update_boxplots(handles.figure_review,[]);
    % Update list box
    CS = get(gca,'ColorOrder');
    rows = {'<html><u>Annotation Files</u>'};
    for i = 1:size(handles.AllRatings,2)
        colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
        disp = handles.AllFilenames{i};
        rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(colorindex,:)),i,disp)];
    end
    set(handles.listbox,'String',rows,'Value',1);
    delete(w);
    set(handles.menu_analyzeratings,'Enable','on');
    set(handles.push_analyze,'Enable','on');
    if size(handles.AllRatings,2)>1
        set(handles.menu_export,'Enable','on');
        set(handles.toggle_meanplot,'Enable','on');
    end
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function remsel_Callback(hObject,~)
    handles = guidata(hObject);
    if get(handles.toggle_meanplot,'Value')==1
        msgbox('Please turn off mean plotting before removing annotation files.');
        return;
    end
    % Get currently selected item
    index = get(handles.listbox,'Value')-1;
    % Cancel if the first row is selected
    if index == 0, return; end
    % Cancel if only one row remains
    if size(handles.AllRatings,2)<2
        handles.AllRatings = zeros(0,1);
        handles.MeanRatings = zeros(0,1);
        handles.AllFilenames = cell(0,1);
        handles.axMin = zeros(0,1);
        handles.axMax = zeros(0,1);
        cla(handles.axis_annotations);
        cla(handles.axis_summary);
        set(handles.axis_annotations,'PickableParts','none');
        set(handles.axis_summary,'XLim',[-1,1],'XTick',0,'XTickLabel','No Annotation Files Loaded');
        guidata(handles.figure_review,handles);
    else
        % Remove the selected item from program
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
        set(handles.toggle_meanplot,'Enable','off','Value',0);
        set(handles.menu_export,'Enable','off');
        set(handles.menu_analyzeratings,'Enable','off');
        set(handles.push_analyze,'Enable','off');
    elseif size(handles.AllRatings,2)==1
        disp = handles.AllFilenames{1};
        rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(1,:)),1,disp)];
        set(handles.toggle_meanplot,'Enable','off','Value',0);
        set(handles.menu_export,'Enable','off');
    else
        for i = 1:size(handles.AllRatings,2)
            colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
            disp = handles.AllFilenames{i};
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(colorindex,:)),i,disp)];
        end
        meanplot_Callback(handles.toggle_meanplot,[]);
    end
    set(handles.listbox,'String',rows);
    % Update guidata with handles
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function remall_Callback(hObject,~)
    handles = guidata(hObject);
    if get(handles.toggle_meanplot,'Value')==1
        msgbox('Please turn off mean plotting before removing annotation files.');
        return;
    end
    handles.AllRatings = zeros(0,1);
    handles.MeanRatings = zeros(0,1);
    handles.AllFilenames = cell(0,1);
    handles.Seconds = zeros(0,1);
    handles.axMin = zeros(0,1);
    handles.axMax = zeros(0,1);
    cla(handles.axis_annotations);
    cla(handles.axis_summary);
    set(handles.axis_annotations,'PickableParts','none');
    % Update list box
    set(handles.listbox,'Value',1);
    rows = {'<html><u>Annotation Files'};
    set(handles.toggle_meanplot,'Enable','off','Value',0);
    set(handles.menu_export,'Enable','off');
    set(handles.menu_analyzeratings,'Enable','off');
    set(handles.push_analyze,'Enable','off');
    set(handles.listbox,'String',rows);
    % Update guidata with handles
    guidata(handles.figure_review,handles);
end

% ===============================================================================

function meanplot_Callback(hObject,~)
    handles = guidata(hObject);
    update_plots(handles);
    if get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Max')
        %If toggle is set to on, update list box with mean series
        set(handles.listbox,'Value',size(handles.AllRatings,2)+2);
        set(handles.toggle_meanplot,'String','Hide Mean Plot');
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            disp = handles.AllFilenames{i};
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv([.8 .8 .8]),i,disp)];
        end
        rows = [cellstr(rows);'<html><font color="red">[M]</font> Mean Plot'];
        set(handles.listbox,'String',rows);
    elseif get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Min')
        %If toggle is set to off, update list box without mean series
        set(handles.listbox,'Value',1);
        set(handles.toggle_meanplot,'String','Show Mean Plot');
        CS = get(gca,'ColorOrder');
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
           colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
           disp = handles.AllFilenames{i};
           rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(colorindex,:)),i,disp)];
        end
        set(handles.listbox,'String',rows);
    end
    guidata(hObject,handles);
end

% ===============================================================================

function analyzeratings_Callback(hObject,~)
    handles = guidata(hObject);
    fig_analyze(handles.AllRatings,handles.AllFilenames,handles.axMin,handles.axMax);
end

% ===============================================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
    if get(hObject,'Value')==get(hObject,'Max')
        % Do this when play/resume toggle is clicked
        handles.vlc.playlist.play();
        start(handles.timer2);
        set(hObject,'String','Pause');
        set(handles.menu_media,'Enable','off');
        set(handles.menu_annotations,'Enable','off');
        set(handles.menu_export,'Enable','off');
        set(handles.menu_analyze,'Enable','off');
        set(handles.menu_help,'Enable','off');
        set(handles.push_addfile,'Enable','off');
        set(handles.push_remsel,'Enable','off');
        set(handles.push_remall,'Enable','off');
        set(handles.toggle_meanplot,'Enable','off');
        set(handles.push_analyze,'Enable','off');
    else
        % Do this when pause toggle is clicked
        handles.vlc.playlist.togglePause();
        stop(handles.timer2);
        set(hObject,'String','Resume');
        set(handles.menu_media,'Enable','on');
        set(handles.menu_annotations,'Enable','on');
        set(handles.menu_analyze,'Enable','on');
        set(handles.menu_help,'Enable','on');
        set(handles.push_addfile,'Enable','on');
        set(handles.push_remsel,'Enable','on');
        set(handles.push_remall,'Enable','on');
        if size(handles.AllRatings,2)>1
            set(handles.menu_export,'Enable','on');
            set(handles.toggle_meanplot,'Enable','on');
        end
        if ~isempty(handles.AllRatings)
            set(handles.menu_analyzeratings,'Enable','on');
            set(handles.push_analyze,'Enable','on');
        end
    end
    guidata(hObject, handles);
    drawnow();
end

% ===============================================================================

function timer2_Callback(~,~,handles)
    handles = guidata(handles.figure_review);
    global tsline;
    if handles.vlc.input.state == 3
        % While playing, update annotations plot
        ts = handles.vlc.input.time/1000;
        set(tsline,'XData',[ts,ts]);
        drawnow();
    elseif handles.vlc.input.state == 6 || handles.vlc.input.state == 5
        % When done, send stop() command to VLC
        stop(handles.timer2);
        update_plots(handles);
        set(handles.toggle_playpause,'String','Play','Value',0);
        set(handles.menu_media,'Enable','on');
        set(handles.menu_annotations,'Enable','on');
        set(handles.menu_analyze,'Enable','on');
        set(handles.menu_help,'Enable','on');
        set(handles.push_addfile,'Enable','on');
        set(handles.push_remsel,'Enable','on');
        set(handles.push_remall,'Enable','on');
        set(handles.push_analyze,'Enable','on');
        if size(handles.AllRatings,2)>1
            set(handles.menu_export,'Enable','on');
            set(handles.toggle_meanplot,'Enable','on');
        end
        handles.vlc.input.time = 0;
    else
        % Otherwise, wait
        return;
    end
end

% ===============================================================================

function axis_click_Callback(hObject,~)
    handles = guidata(hObject);
    global tsline;
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
    set(tsline,'XData',[ts,ts]);
    drawnow();
end

% ===============================================================================

function update_plots(handles)
    handles = guidata(handles.figure_review);
    global tsline;
    if isempty(handles.AllRatings), return; end
    if get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Min')
        axes(handles.axis_annotations); cla;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2,'ButtonDownFcn',@axis_click_Callback);
        hold on;
        ylim([handles.axMin,handles.axMax]);
        xlim([0,ceil(max(handles.Seconds))]);
        set(handles.axis_annotations,'YTick',linspace(handles.axMin,handles.axMax,5),'YGrid','on','TickLength',[0.005 0]);
        set(handles.axis_annotations,'ButtonDownFcn',@axis_click_Callback);
        handles.CS = get(gca,'ColorOrder');
        tsline = plot(handles.axis_annotations,[0,0],[handles.axMin,handles.axMax],'k');
        hold off;
    elseif get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Max')
        axes(handles.axis_annotations); cla;
        set(handles.axis_annotations,'ButtonDownFcn',@axis_click_Callback);
        hold on;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2,'Color',[.8 .8 .8],'ButtonDownFcn',@axis_click_Callback);
        plot(handles.Seconds,handles.MeanRatings,'-','LineWidth',2,'Color',[1 0 0],'ButtonDownFcn',@axis_click_Callback);
        ylim([handles.axMin,handles.axMax]);
        xlim([0,ceil(max(handles.Seconds))]);
        set(handles.axis_annotations,'YTick',linspace(handles.axMin,handles.axMax,5),'YGrid','on');
        tsline = plot(handles.axis_annotations,[0,0],[handles.axMin,handles.axMax],'k');
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
        'YLim',[handles.axMin,handles.axMax],...
        'YTick',linspace(handles.axMin,handles.axMax,5));
end

% ===============================================================================

function figure_review_Resize(hObject,~)
    handles = guidata(hObject);
    if isfield(handles,'figure_review') && isfield(handles,'vlc')
        % Update the size and position of the VLC controller
        move(handles.vlc,getpixelposition(handles.axis_guide));
    end
end

% =========================================================

function figure_review_CloseRequest(hObject,~)
    handles = guidata(hObject);
    delete(timerfind);
    delete(handles.figure_review);
end
