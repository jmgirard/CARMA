function fig_collect_vrjoy
%FIG_COLLECT_VRJOY Window for the collection of ratings with a joystick
% License: https://carma.codeplex.com/license

    % Get default settings
    if isdeployed
        handles.settings = importdata(fullfile(ctfroot,'DARMA','default.mat'));
    else
        handles.settings = importdata('default.mat');
    end
    % Create and center main window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_collect = figure( ...
        'Units','normalized', ...
        'Name','CARMA: Collect Ratings', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'NumberTitle','off', ...
        'Visible','off', ...
        'Color',defaultBackground, ...
        'SizeChangedFcn',@figure_collect_SizeChanged, ...
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
    handles.menu_settings = uimenu(handles.figure_collect, ...
        'Label','Settings');
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
    pause(0.1);
    set(handles.figure_collect,'Position',[0.1 0.1 0.8 0.8]);
    % Create uicontrol elements
    handles.axis_info = axes(handles.figure_collect, ...
        'Units','normalized', ...
        'Position',[.01 .02 .63 .05], ...
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
        'FontSize',14.0, ...
        'Callback',@toggle_playpause_Callback, ...
        'Enable','off');
    handles.axis_upper = uicontrol(handles.figure_collect, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.90 .9605 .08 .028], ...
        'FontSize',10.0, ...
        'FontWeight','bold', ...
        'BackgroundColor',defaultBackground);
    handles.axis_lower = uicontrol(handles.figure_collect, ...
        'Style','text', ...
        'Units','Normalized', ...
        'Position',[.90 .08 .08 .028], ...
        'FontSize',10.0, ...
        'FontWeight','bold', ...
        'BackgroundColor',defaultBackground);
    handles.axis_image = axes('Units','Normalized', ...
        'Position',[.90 .109 .07 .853], ...
        'Box','off','XColor','none','YColor','none');
    handles.axis_rating = axes(handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.90 .109 .07 .853], ...
        'Clipping','on', ...
        'Box','on','Layer','top');
    handles.axis_guide = axes(handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.01 .09 .86 .89], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
    % Update axis labels and slider parameters
    set(handles.axis_lower,'String',handles.settings.axis_lower);
    set(handles.axis_upper,'String',handles.settings.axis_upper);
    % Create and display custom color gradient in rating axis
    axes(handles.axis_image);
    hold on;
    image([colorGradient(handles.settings.axis_color3,handles.settings.axis_color2,225,100); ...
        colorGradient(handles.settings.axis_color2,handles.settings.axis_color1,225,100)]);
    set(handles.axis_image, ...
        'XLim',[0 100],'YLim',[0 450], ...
        'XTick',[],'YTick',[]);
    hold off;
    % Plot current value indicator on rating axis
    axis_range = handles.settings.axis_max - handles.settings.axis_min;
    midpoint = handles.settings.axis_min + axis_range/2;
    axes(handles.axis_rating);
    hold on;
    handles.plot_line = plot(handles.axis_rating,[0 100],[midpoint midpoint],'-k','LineWidth',5);
    handles.plot_marker = plot(handles.axis_rating,50,midpoint,'kd','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','w','MarkerSize',25);
    set(handles.axis_rating, ...
        'XLim',[0 100],'XTick',[], ...
        'YLim',[handles.settings.axis_min,handles.settings.axis_max], ...
        'YTick',round(linspace(handles.settings.axis_min,handles.settings.axis_max,handles.settings.axis_steps),2), ...
        'Box','on','Layer','top','Color','none');
    hold off;
    % Invoke and configure VLC ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_collect);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    try
        handles.joy = vrjoystick(1);
    catch
        e = errordlg('CARMA could not detect a joystick. Please connect a USB joystick and then restart CARMA.','Error','modal');
        waitfor(e);
        quit force;
    end
    % Create timer
    handles.recording = 0;
    handles.timer = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.05, ...
        'TimerFcn',{@timer_Callback,handles}, ...
        'ErrorFcn',{@timer_ErrorFcn,handles});
    % Start system clock to improve VLC time stamp precision
    global global_tic recording;
    global_tic = tic;
    recording = 0;
    % Save handles to guidata
    handles.figure_collect.Visible = 'on';
    guidata(handles.figure_collect,handles);
    addpath('Functions');
    start(handles.timer);
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
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file',handles.settings.defaultdir);
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
    set(handles.toggle_playpause,'Enable','on');
    guidata(hObject,handles);
end

% =========================================================

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

function menu_defaultdir_Callback(hObject,~)
    handles = guidata(hObject);
    settings = handles.settings;
    path = uigetdir(settings.defaultdir,'Select a new default folder:');
    if isequal(path,0), return; end
    settings.defaultdir = path;
    if isdeployed
        save(fullfile(ctfroot,'CARMA','default.mat'),'settings');
    else
        save('default.mat','settings');
    end
    handles.settings = settings;
    guidata(handles.figure_collect,handles);
end

% ===============================================================================

function menu_about_Callback(~,~)
    global version;
    msgbox(sprintf('CARMA version %.2f\nJeffrey M Girard (c) 2014-2017\nhttp://carma.codeplex.com\nGNU General Public License v3',version),'About','Help');
end

% ===============================================================================

function menu_document_Callback(~,~)
    web('http://carma.codeplex.com/documentation','-browser');
end

% ===============================================================================

function menu_report_Callback(~,~)
    web('http://carma.codeplex.com/discussions','-browser');
end

% =========================================================

function figure_collect_KeyPress(hObject,eventdata)
    handles = guidata(hObject);
    global recording;
    % Escape if the playpause button is disabled
    if strcmp(get(handles.toggle_playpause,'Enable'),'off'), return; end
    % Pause playback if the pressed key is spacebar
    if strcmp(eventdata.Key,'space') && get(handles.toggle_playpause,'value')
        handles.vlc.playlist.togglePause();
        recording = 0;
        set(handles.toggle_playpause,'String','Resume Rating','Value',0);
    else
        return;
    end
    guidata(hObject,handles);
end

% =========================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
    global recording;
    if get(hObject,'Value')
        % If toggle button is set to play, update GUI elements
        set(hObject,'Enable','Off','String','...');
        set(handles.menu_media,'Enable','off');
        set(handles.menu_settings,'Enable','off');
        set(handles.menu_help,'Enable','off');
        % Start three second countdown before starting
        set(hObject,'String','...3...'); pause(1);
        set(hObject,'String','..2..'); pause(1);
        set(hObject,'String','.1.'); pause(1);
        set(hObject,'Enable','On','String','Pause Rating');
        recording = 1;
        guidata(hObject,handles);
        % Send play() command to VLC and wait for it to start playing
        handles.vlc.playlist.play();
    else
        % If toggle button is set to pause, send pause() command to VLC
        handles.vlc.playlist.togglePause();
        recording = 0;
        set(hObject,'String','Resume Rating','Value',0);
        set(handles.menu_help,'Enable','on');
        guidata(hObject,handles);
    end
end

% =========================================================

function timer_Callback(~,~,handles)
    handles = guidata(handles.figure_collect);
    global ratings last_ts_vlc last_ts_sys global_tic recording;
    % Before playing
    if recording == 0
        [joystatus,~,~] = read(handles.joy); %ranges from -1 to 1
        y = joystatus(2) * -1; %read y value and reverse its sign
        axis_range = handles.settings.axis_max - handles.settings.axis_min;
        axis_middle = handles.settings.axis_min + axis_range / 2;
        val = axis_middle + y * axis_range / 2; %scale to user axis
        set(handles.plot_line,'XData',[0 100],'YData',[val val]);
        set(handles.plot_marker,'XData',50,'YData',val,'MarkerFaceColor','white');
        return;
    end
    % While playing
    if handles.vlc.input.state == 3
        try
            % Read status of the joystick
            [joystatus,~,~] = read(handles.joy);
        catch
            %If failed, recreate the joystick
            handles.joy = vrjoystick(1);
            guidata(handles.figure_collect,handles);
            return;
        end
        ts_vlc = handles.vlc.input.time / 1000;
        ts_sys = toc(global_tic);
        if ts_vlc == last_ts_vlc && last_ts_vlc ~= 0
            ts_diff = ts_sys - last_ts_sys;
            ts_vlc = ts_vlc + ts_diff;
        else
            last_ts_vlc = ts_vlc;
            last_ts_sys = ts_sys;
        end
        y = joystatus(2) * -1; %read y value and reverse its sign
        axis_range = handles.settings.axis_max - handles.settings.axis_min;
        axis_middle = handles.settings.axis_min + axis_range / 2;
        val = axis_middle + y * axis_range / 2; %scale to user axis
        set(handles.plot_line,'XData',[0 100],'YData',[val val]);
        set(handles.plot_marker,'XData',50,'YData',val,'MarkerFaceColor','red');
        ratings = [ratings; ts_vlc, val];
        frac = (ts_vlc / handles.dur) * 100;
        set(handles.timebar,'Position',[0 0 frac 1]);
        set(handles.text_timestamp,'String',datestr(handles.vlc.input.time/1000/24/3600,'HH:MM:SS'));
        drawnow();
    % After playing
    elseif handles.vlc.input.state == 5 || handles.vlc.input.state == 6
        recording = 0;
        handles.vlc.playlist.stop();
        set(handles.toggle_playpause,'Value',0);
        % Average ratings per second of playback
        rating = ratings;
        disp(rating);
        anchors = [0,(handles.settings.binsizenum:handles.settings.binsizenum:floor(handles.dur))];
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
        [filename,pathname] = uiputfile({'*.csv','Comma-Separated Values (*.csv)'},'Save as',fullfile(handles.settings.defaultdir,defaultname));
        if ~isequal(filename,0) && ~isequal(pathname,0)
            % Add metadata to mean ratings and timestamps
            output = [ ...
                {'Time of Rating'},{datestr(now)}; ...
                {'Multimedia File'},{sprintf('%s%s',defaultname,ext)}; ...
                {'Lower Label'},{handles.settings.axis_lower}; ...
                {'Upper Label'},{handles.settings.axis_upper}; ...
                {'Minimum Value'},{handles.settings.axis_min}; ...
                {'Maximum Value'},{handles.settings.axis_max}; ...
                {'Number of Steps'},{handles.settings.axis_steps}; ...
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
    global ratings;
    handles.vlc.playlist.togglePause();
    stop(handles.timer);
    msgbox(sprintf('Timer callback error:\n%s\nAn error log has been saved.',event.Data.message),'Error','error');
    csvwrite(fullfile(handles.settings.folder,sprintf('%s.csv',datestr(now,30))),ratings);
    guidata(handles.figure_collect,handles);
end

% =========================================================

function figure_collect_SizeChanged(hObject,~)
    handles = guidata(hObject);
    if isfield(handles,'figure_collect')
        pos = getpixelposition(handles.figure_collect);
        % Force to remain above a minimum size
        if pos(3) < 1024 || pos(4) < 600
            setpixelposition(handles.figure_collect,[pos(1) pos(2) 1024 600]);
            movegui(handles.figure_collect,'center');
            set(handles.toggle_playpause,'FontSize',12);
        else
            set(handles.toggle_playpause,'FontSize',14);
        end
        % Update the size and position of the VLC controller
        if isfield(handles,'vlc')
            move(handles.vlc,getpixelposition(handles.axis_guide));
        end
    end
end

% =========================================================

function figure_collect_CloseReq(hObject,~)
    handles = guidata(hObject);
    global recording;
    % Pause playback and rating
    if handles.vlc.input.state==3,handles.vlc.playlist.togglePause(); end
    set(handles.toggle_playpause,'String','Resume Rating','Value',0);
    recording = 0;
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
        %If ratings are not being collected, exit CARMA
        if strcmp(handles.timer.Running,'on'), stop(handles.timer); end
        delete(timerfind);
        delete(handles.figure_collect);
    end
end

% =========================================================

function program_reset(handles)
    global recording;
    handles = guidata(handles.figure_collect);
    recording = 0;
    % Update GUI elements to starting configuration
    set(handles.timebar,'Position',[0 0 0 1]);
    set(handles.text_timestamp,'String','00:00:00');
    set(handles.text_filename,'String','Media Filename');
    set(handles.text_duration,'String','00:00:00');
    set(handles.toggle_playpause,'Enable','off','String','Begin Rating');
    set(handles.menu_media,'Enable','on');
    set(handles.menu_settings,'Enable','on');
    set(handles.menu_preview,'Enable','off');
    set(handles.menu_help,'Enable','on');
    guidata(handles.figure_collect,handles);
end
