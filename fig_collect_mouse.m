function fig_collect_mouse
%FIG_COLLECT_MOUSE Window for the collection of ratings using the mouse
% License: https://github.com/jmgirard/CARMA/blob/master/license.txt

    % Get default settings
    handles.settings = getpref('carma');
    % Create and center main window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_collect = figure( ...
        'Name','CARMA: Collect Ratings', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'NumberTitle','off', ...
        'Visible','off', ...
        'Color',defaultBackground, ...
        'ResizeFcn',@figure_collect_Resize, ...
        'KeyPressFcn',@figure_collect_KeyPress, ...
        'CloseRequestFcn',@figure_collect_CloseReq);
    % Create menu bar elements
    handles.menu_media = uimenu(handles.figure_collect, ...
        'Label','Media');        
    handles.menu_openmedia = uimenu(handles.menu_media, ...
        'Label','Open Media File', ...
        'Callback',@menu_openmedia_Callback);
    handles.menu_volume = uimenu(handles.menu_media, ...
        'Label','Adjust Volume', ...
        'Callback',@menu_volume_Callback);
    handles.menu_preview = uimenu(handles.menu_media, ...
        'Label','Preview Media File', ...
        'Enable','off', ...
        'Callback',@menu_preview_Callback);
    handles.menu_closemedia = uimenu(handles.menu_media, ...
        'Label','Close Media File', ...
        'Enable','off', ...
        'Callback',@menu_closemedia_Callback);
    handles.menu_settings = uimenu(handles.figure_collect, ...
        'Label','Settings');
    handles.menu_axislab = uimenu(handles.menu_settings, ...
        'Label','Set Axis Labels', ...
        'Callback',@menu_axislab_Callback);
    handles.menu_axisnum = uimenu(handles.menu_settings, ...
        'Label','Set Axis Numbers', ...
        'Callback',@menu_axisnum_Callback);
    handles.menu_colormap = uimenu(handles.menu_settings, ...
        'Label','Set Axis Colormap', ...
        'Callback',@menu_colormap_Callback);
    handles.menu_srate = uimenu(handles.menu_settings, ...
        'Label','Set Sampling Rate', ...
        'Callback',@menu_srate_Callback);
    handles.menu_bsize = uimenu(handles.menu_settings, ...
        'Label','Set Bin Size', ...
        'Callback',@menu_bsize_Callback);
    handles.menu_defaultdir = uimenu(handles.menu_settings, ...
        'Label','Set Default Folder', ...
        'Callback',@menu_defaultdir_Callback);
    handles.menu_help = uimenu(handles.figure_collect, ...
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
    set(handles.figure_collect,'Units','normalized','Position',[0.1,0.1,0.8,0.8],'Visible','on');
    drawnow;
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jFig = get(handle(handles.figure_collect),'JavaFrame');
    jClient = jFig.fHG2Client;
    jWindow = jClient.getWindow;
    jWindow.setMinimumSize(java.awt.Dimension(1024,768));
    % Create uicontrol elements
    handles.axis_info = axes(handles.figure_collect, ...
        'Units','normalized', ...
        'Position',[.01 .02 .86 .05], ...
        'XLim',[0,100],'YLim',[0,1], ...
        'XTick',(0:10:100),'TickLength',[0.005 0],'XTickLabel',[], ...
        'Box','on','Layer','top','YTick',[]);
    handles.timebar = rectangle(handles.axis_info, ...
        'Position',[0,0,0,1],'FaceColor',[0.000,0.447,0.741]);
    handles.text_filename = text(handles.axis_info, ...
        50,0.5,'Media Filename','HorizontalAlignment','center','Interpreter','none');
    handles.text_timestamp = text(handles.axis_info, ...
        05,0.5,'00:00:00','HorizontalAlignment','center');
    handles.text_duration = text(handles.axis_info, ...
        95,0.5,'00:00:00','HorizontalAlignment','center');
    handles.toggle_playpause = uicontrol(handles.figure_collect, ...
        'Style','togglebutton', ...
        'Units','Normalized', ...
        'Position',[.88 .02 .11 .05], ...
        'String','Begin Rating', ...
        'FontSize',12, ...
        'Callback',@toggle_playpause_Callback, ...
        'Enable','off');
    handles.text_upper = uicontrol(handles.figure_collect, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.88 .952 .11 .03], ...
        'FontSize',10.0, ...
        'FontWeight','bold', ...
        'BackgroundColor',defaultBackground);
    handles.text_lower = uicontrol(handles.figure_collect, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.88 .09 .11 .02], ...
        'FontSize',10.0, ...
        'FontWeight','bold', ...
        'BackgroundColor',defaultBackground);
    handles.slider = uicontrol('Style','slider', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.965 .12 .025 .83], ...
        'BackgroundColor',[.5 .5 .5], ...
        'KeyPressFcn',@figure_collect_KeyPress);
    handles.axis_rating = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'OuterPosition',[.88 .12 .075 .83], ...
        'Box','on','XTick',[],'Layer','top');
    handles.axis_guide = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.01 .09 .86 .89], ...
        'Box','on','XTick',[],'YTick',[],'Color','k');
    % Update axis labels and slider parameters
    set(handles.text_lower,'String',handles.settings.labLower);
    set(handles.text_upper,'String',handles.settings.labUpper);
    axMin = handles.settings.axMin;
    axMax = handles.settings.axMax;
    axMidpt = axMin + (axMax - axMin)/2;
    set(handles.slider, ...
        'SliderStep',[1/40,1/20], ...
        'Min',axMin,'Max',axMax,'Value',axMidpt);
    % Initialize rating axis
    axes(handles.axis_rating);
    set(handles.axis_rating,'XLim',[0,100],'YLim',[0,100]);
    c = eval(handles.settings.cmapstr);
    colormap(handles.axis_rating,c);
    handles.plot_patch = patch([0 100 100 0],[axMin axMin axMax axMax],[1 1 2 2]);
    set(handles.axis_rating, ...
        'XLim',[0 100],'XTick',[], ...
        'YLim',[axMin axMax], ...
        'YTick',round(linspace(axMin,axMax,handles.settings.axSteps),2), ...
        'Box','on','Layer','top','Color','w');
    li = get(handles.axis_rating,'LooseInset');
    ti = get(handles.axis_rating,'TightInset');
    ni = li; ni(2) = ti(2); ni(4) = ti(4);
    set(handles.axis_rating,'LooseInset',ni)
    % Invoke and configure VLC ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_collect);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    % Create timer
    handles.timer = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',round(1/handles.settings.sratenum,3), ...
        'TimerFcn',{@timer_Callback,handles}, ...
        'ErrorFcn',{@timer_ErrorFcn,handles});
    % Start system clock to improve VLC time stamp precision
    global global_tic;
    global_tic = tic;
    % Save handles to guidata
    handles.figure_collect.Visible = 'on';
    guidata(handles.figure_collect,handles);
end

% =========================================================

function menu_openmedia_Callback(hObject,~)
    handles = guidata(hObject);
    % Reset the GUI elements
    program_reset(handles);
    global ratings last_ts_vlc last_ts_sys;
    ratings = [];
    last_ts_vlc = 0;
    last_ts_sys = 0;
    handles.vlc.playlist.items.clear();
    % Browse for, load, and get text_duration for a media file
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file',handles.settings.defdir);
    if video_name==0, return; end
    try
        MRL = fullfile(video_path,video_name);
        handles.VID = MRL;
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
        if handles.dur == 0
            handles.vlc.playlist.items.clear();
            error('Could not read duration of media file. The file meta-data may be damaged. Transcoding the streams (e.g., with HandBrake) may fix this problem.');
        end
    catch err
        msgbox(err.message,'Error loading media file.'); return;
    end
    % Update GUI elements
    set(handles.timebar,'Position',[0 0 0 1]);
    set(handles.text_timestamp,'String','00:00:00');
    set(handles.text_filename,'String',video_name);
    set(handles.text_duration,'String',datestr(handles.dur/24/3600,'HH:MM:SS'));
    set(handles.menu_preview,'Enable','on');
    set(handles.menu_closemedia,'Enable','on');
    set(handles.toggle_playpause,'Enable','on');
    guidata(hObject,handles);
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
    guidata(handles.figure_collect,handles);
end

% ===============================================================================

function menu_preview_Callback(hObject,~)
    handles = guidata(hObject);
    winopen(handles.VID);
end

% ===============================================================================

function menu_closemedia_Callback(hObject,~)
    handles = guidata(hObject);
    handles.vlc.playlist.stop();
    handles.vlc.playlist.items.clear();
    set(handles.menu_settings,'Enable','on');
    set(handles.menu_closemedia,'Enable','off');
    set(handles.menu_preview,'Enable','off');
    set(handles.timebar,'Position',[0 0 0 1]);
    set(handles.text_timestamp,'String','00:00:00');
    set(handles.text_filename,'String','Media Filename');
    set(handles.text_duration,'String','00:00:00');
    guidata(handles.figure_collect,handles);
end

% ===============================================================================

function menu_axislab_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    prompt = {'Upper axis label:','Lower axis label:'};
    defaultans = {settings.labUpper,settings.labLower};
    labels = inputdlg(prompt,'',1,defaultans);
    if ~isempty(labels)
        settings.labUpper = labels{1};
        settings.labLower = labels{2};
        set(handles.text_upper,'String',settings.labUpper);
        set(handles.text_lower,'String',settings.labLower);
        setpref('carma',{'labUpper','labLower'},{settings.labUpper,settings.labLower});
        handles.settings = settings;
        guidata(handles.figure_collect,handles);
    end
end

% ===============================================================================

function menu_axisnum_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    prompt = {'Axis Minimum Value:','Axis Maximum Value:','Number of Axis Steps:'};
    defaultans = {num2str(settings.axMin),num2str(settings.axMax),num2str(settings.axSteps)};
    numbers = inputdlg(prompt,'',1,defaultans);
    if ~isempty(numbers)
        settings.axMin = str2double(numbers{1});
        settings.axMax = str2double(numbers{2});
        settings.axSteps = str2double(numbers{3});
        set(handles.axis_rating, ...
            'YLim',[settings.axMin,settings.axMax], ...
            'YTick',round(linspace(settings.axMin,settings.axMax,settings.axSteps),2));
        set(handles.plot_patch,'YData',[settings.axMin settings.axMin settings.axMax settings.axMax]);
        setpref('carma',{'axMin','axMax','axSteps'},{settings.axMin,settings.axMax,settings.axSteps});
        handles.settings = settings;
        guidata(handles.figure_collect,handles);
    end
end

% ===============================================================================

function menu_colormap_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    d = dialog('Position',[0 0 500 200],'Name','Set Axis Colormap','Visible','off');
    movegui(d,'center');
    set(d,'Visible','on');
    uicontrol(d, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.10 .50 .80 .40], ...
        'String','CARMA displays a colormap gradient as a visual representation of the rating scale. Several preset colormaps are available (and more can be added upon request through the CARMA website). Select a colormap below:');
    popup_cmap = uicontrol(d, ...
        'Style','popup', ...
        'Units','Normalized', ...
        'Position',[.10 .35 .80 .20], ...
        'String',{'Parula','Jet','Hot','Cool','Spring','Summer','Autumn','Winter','Bone'}, ...
        'Value',settings.cmapval);
    uicontrol(d, ...
        'Style','pushbutton', ...
        'Units','Normalized', ...
        'Position',[.30 .10 .40 .20], ...
        'FontWeight','bold', ...
        'String','Submit', ...
        'Callback',@push_save_Callback);
    stop(handles.timer);
    uiwait(d);
    handles.settings = settings;
    guidata(handles.figure_collect,handles);
    start(handles.timer);
    function push_save_Callback(~,~)
        cmapval = popup_cmap.Value;
        cmapstr = popup_cmap.String{cmapval};
        cmapstr = lower(cmapstr);
        settings.cmapval = cmapval;
        settings.cmapstr = cmapstr;
        axes(handles.axis_rating);
        c = eval(cmapstr);
        colormap(handles.axis_rating,c);
        setpref('carma',{'cmapval','cmapstr'},{cmapval,cmapstr});
        delete(d);
    end
end

% ===============================================================================

function menu_srate_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    d = dialog('Position',[0 0 500 200],'Name','Set Sampling Rate','Visible','off');
    movegui(d,'center');
    set(d,'Visible','on');
    uicontrol(d, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.10 .50 .80 .40], ...
        'String','CARMA can sample the slider at different frequencies. Higher sampling rates provide more data redundancy but also impose a larger computational load. A sampling rate of 20 or 30 Hz is recommended for modern computers and 10 Hz is recommended for older or slower computers. Select a sampling rate below:');
    popup_srate = uicontrol(d, ...
        'Style','popup', ...
        'Units','Normalized', ...
        'Position',[.10 .35 .80 .20], ...
        'String',{'10 Hz','20 Hz','30 Hz'}, ...
        'Value',settings.srateval);
    uicontrol(d, ...
        'Style','pushbutton', ...
        'Units','Normalized', ...
        'Position',[.30 .10 .40 .20], ...
        'FontWeight','bold', ...
        'String','Submit', ...
        'Callback',@push_save_Callback);
    stop(handles.timer);
    uiwait(d);
    handles.settings = settings;
        guidata(handles.figure_collect,handles);
    start(handles.timer);
    function push_save_Callback(~,~)
        srateval = popup_srate.Value;
        sratenum = popup_srate.String{srateval};
        sratenum = str2double(sratenum(1,1:2));
        settings.srateval = srateval;
        settings.sratenum = sratenum;
        setpref('carma',{'srateval','sratenum'},{srateval,sratenum});
        if handles.timer.Running, stop(handles.timer); end
        set(handles.timer,'Period',round(1/settings.sratenum,3));
        if ~handles.timer.Running, start(handles.timer); end
        delete(d);
    end
end

% ===============================================================================

function menu_bsize_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    d = dialog('Position',[0 0 500 200],'Name','Set Bin Size','Visible','off');
    movegui(d,'center');
    set(d,'Visible','on');
    uicontrol(d, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.10 .50 .80 .40], ...
        'String','CARMA averages slider samples into temporal bins which are output in annotation files. The duration of each bin is configurable. Smaller bins preserve the most information but may be more noisy and autocorrelated.');
    popup_bsize = uicontrol(d, ...
        'Style','popup', ...
        'Units','Normalized', ...
        'Position',[.10 .35 .80 .20], ...
        'String',{'0.25 seconds','0.50 seconds','1.00 seconds','2.00 seconds','4.00 seconds'}, ...
        'Value',settings.bsizeval);
    uicontrol(d, ...
        'Style','pushbutton', ...
        'Units','Normalized', ...
        'Position',[.30 .10 .40 .20], ...
        'FontWeight','bold', ...
        'String','Submit', ...
        'Callback',@push_save_Callback);
    stop(handles.timer);
    uiwait(d);
    handles.settings = settings;
    guidata(handles.figure_collect,handles);
    start(handles.timer);
    function push_save_Callback(~,~)
        bsizeval = popup_bsize.Value;
        bsizenum = popup_bsize.String{bsizeval};
        bsizenum = str2double(bsizenum(1,1:4));
        settings.bsizeval = bsizeval;
        settings.bsizenum = bsizenum;
        setpref('carma',{'bsizeval','bsizenum'},{bsizeval,bsizenum});
        delete(d);
    end
end

% ===============================================================================

function menu_defaultdir_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    path = uigetdir(settings.defdir,'Select a new default folder:');
    if isequal(path,0), return; end
    settings.defdir = path;
    setpref('carma','defdir',path);
    handles.settings = settings;
    guidata(handles.figure_collect,handles);
end

% =========================================================

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

% =========================================================

function figure_collect_KeyPress(hObject,eventdata)
    handles = guidata(hObject);
    % Escape if the playpause button is disabled
    if strcmp(get(handles.toggle_playpause,'Enable'),'off'), return; end
    % Pause playback if the pressed key is spacebar
    if strcmp(eventdata.Key,'space') && get(handles.toggle_playpause,'Value')
        handles.vlc.playlist.togglePause();
        stop(handles.timer);
        set(handles.toggle_playpause,'String','Resume Rating','Value',0);
    else
        return;
    end
    guidata(hObject,handles);
end

% =========================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
    if get(hObject,'Value')
        % If toggle button is set to play, update GUI elements
        start(handles.timer);
        set(hObject,'Enable','off','String','...');
        set(handles.menu_media,'Enable','off');
        set(handles.menu_settings,'Enable','off');
        set(handles.menu_help,'Enable','off');
        uicontrol(handles.slider);
        % Start three second countdown before starting
        set(hObject,'String','...3...'); pause(1);
        set(hObject,'String','..2..'); pause(1);
        set(hObject,'String','.1.'); pause(1);
        set(hObject,'Enable','On','String','Pause Rating');
        guidata(hObject,handles);
        % Send play() command to VLC and wait for it to start playing
        handles.vlc.playlist.play();
    else
        % If toggle button is set to pause, send pause() command to VLC
        handles.vlc.playlist.togglePause();
        stop(handles.timer);
        set(hObject,'String','Resume Rating','Value',0);
        set(handles.menu_help,'Enable','on');
        guidata(hObject,handles);
    end
end

% =========================================================

function timer_Callback(~,~,handles)
    handles = guidata(handles.figure_collect);
    global ratings last_ts_vlc last_ts_sys global_tic;
    % While playing
    if handles.vlc.input.state == 3
        ts_vlc = handles.vlc.input.time/1000;
        ts_sys = toc(global_tic);
        if ts_vlc == last_ts_vlc && last_ts_vlc ~= 0
            ts_diff = ts_sys - last_ts_sys;
            ts_vlc = ts_vlc + ts_diff;
        else
            last_ts_vlc = ts_vlc;
            last_ts_sys = ts_sys;
        end
        val = get(handles.slider,'Value');
        ratings = [ratings; ts_vlc, val];
        frac = (ts_vlc / handles.dur) * 100;
        set(handles.timebar,'Position',[0 0 frac 1]);
        drawnow();
        guidata(handles.figure_collect,handles);
    % After playing
    elseif handles.vlc.input.state == 5 || handles.vlc.input.state == 6
        stop(handles.timer);
        handles.vlc.playlist.stop();
        set(handles.toggle_playpause,'Value',0);
        % Average ratings per second of playback
        rating = ratings;
        disp(rating);
        anchors = [0,(handles.settings.bsizenum:handles.settings.bsizenum:floor(handles.dur))];
        mean_ratings = nan(length(anchors)-1,2);
        mean_ratings(:,1) = anchors(2:end)';
        for i = 1:length(anchors)-1
            s_start = anchors(i);
            s_end = anchors(i+1);
            index = (rating(:,1) >= s_start) & (rating(:,1) < s_end);
            bin = rating(index,2:end);
            if isempty(bin), continue; end
            mean_ratings(i,:) = [s_end,nanmean(bin)];
        end
        % Prompt user to save the collected annotations
        [~,defaultname,ext] = fileparts(handles.MRL);
        [filename,pathname] = uiputfile({'*.csv','Comma-Separated Values (*.csv)'},'Save as',fullfile(handles.settings.defir,defaultname));
        if ~isequal(filename,0) && ~isequal(pathname,0)
            % Add metadata to mean ratings and timestamps
            output = [ ...
                {'Time of Rating'},{datestr(now)}; ...
                {'Multimedia File'},{sprintf('%s%s',defaultname,ext)}; ...
                {'Lower Label'},{handles.settings.labLower}; ...
                {'Upper Label'},{handles.settings.labUpper}; ...
                {'Minimum Value'},{handles.settings.axMin}; ...
                {'Maximum Value'},{handles.settings.axMax}; ...
                {'Number of Steps'},{handles.settings.axSteps}; ...
                {'Second'},{'Rating'}; ...
                {'%%%%%%'},{'%%%%%%'}; ...
                num2cell(mean_ratings)];
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
        program_reset(handles);
    % While transitioning or paused
    else
        return;
    end
end

% =========================================================

function timer_ErrorFcn(hObject,event,~)
    disp(event.Data);
    handles = guidata(hObject);
    handles.vlc.playlist.togglePause();
    stop(handles.timer);
    msgbox(sprintf('Timer callback error:\n%s\nAn error log has been saved.',event.Data.message),'Error','error');
    csvwrite(fullfile(handles.settings.defdir,sprintf('%s.csv',datestr(now,30))),ratings);
    guidata(handles.figure_collect,handles);
end

% =========================================================

function figure_collect_Resize(hObject,~)
    handles = guidata(hObject);
    if isfield(handles,'axis_guide') && isfield(handles,'vlc')
        fpos = getpixelposition(handles.axis_guide);
        move(handles.vlc,[fpos(1) fpos(2) fpos(3) fpos(4)]);
    end
end

% =========================================================

function program_reset(handles)
    handles = guidata(handles.figure_collect);
    % Update GUI elements to starting configuration
    set(handles.timebar,'Position',[0 0 0 1]);
    set(handles.text_timestamp,'String','00:00:00');
    set(handles.text_filename,'String','Media Filename');
    set(handles.text_duration,'String','00:00:00');
    set(handles.toggle_playpause,'Enable','off','String','Begin Rating');
    set(handles.menu_media,'Enable','on');
    set(handles.menu_settings,'Enable','on');
    set(handles.menu_closemedia,'Enable','off');
    set(handles.menu_preview,'Enable','off');
    set(handles.menu_help,'Enable','on');
    set(handles.slider,'Value',get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2);
    drawnow();
    guidata(handles.figure_collect,handles);
end

% =========================================================

function figure_collect_CloseReq(hObject,~)
    handles = guidata(hObject);
    % Pause playback and rating
    if handles.vlc.input.state==3,handles.vlc.playlist.togglePause(); end
    if strcmp(handles.timer.Running,'on'), stop(handles.timer); end
    set(handles.toggle_playpause,'String','Resume Rating','Value',0);
    guidata(handles.figure_collect,handles);
    if handles.vlc.input.state==4 || handles.vlc.input.state==3
        %If ratings are being collected, prompt user to cancel them
        choice = questdlg('Do you want to cancel your current ratings?', ...
            'CARMA','Yes','No','No');
        switch choice
            case 'Yes'
                handles.vlc.playlist.stop();
                program_reset(handles);
            case 'No'
                return;
        end
    else
        %If ratings are not being collected, exit DARMA
        if strcmp(handles.timer.Running','on'), stop(handles.timer); end
        delete(timerfind);
        delete(handles.figure_collect);
    end
end