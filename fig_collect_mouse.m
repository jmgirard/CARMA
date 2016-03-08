function fig_collect_mouse
%FIG_COLLECT_MOUSE Window for the collection of ratings using the mouse
% License: https://carma.codeplex.com/license

    % Create and center main window
    addpath('Functions');
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_collect = figure( ...
        'Units','normalized', ...
        'Name','CARMA: Collect', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'NumberTitle','off', ...
        'Visible','off', ...
        'Color',defaultBackground, ...
        'SizeChangedFcn',@figure_collect_SizeChanged, ...
        'KeyPressFcn',@figure_collect_KeyPress, ...
        'CloseRequestFcn',@figure_collect_CloseReq);
    % Create menu bar elements
    handles.menu_multimedia = uimenu(handles.figure_collect, ...
        'Parent',handles.figure_collect, ...
        'Label','Open Multimedia File', ...
        'Callback',@menu_multimedia_Callback);
    pause(0.1);
    set(handles.figure_collect,'Position',[0.1 0.1 0.8 0.8]);
    % Create uicontrol elements
    handles.text_report = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.01 .02 .22 .05], ...
        'String','Open File', ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.text_filename = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.24 .02 .40 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.text_duration = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.65 .02 .22 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.toggle_playpause = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.88 .02 .11 .05], ...
        'String','Play', ...
        'FontSize',14.0, ...
        'Callback',@toggle_playpause_Callback, ...
        'Enable','inactive');
    handles.slider = uicontrol('Style','slider', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.94 .09 .05 .89], ...
        'BackgroundColor',[.5 .5 .5], ...
        'KeyPressFcn',@figure_collect_KeyPress);
    handles.axis_upper = uicontrol('Style','text', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.88 .965 .05 .02], ...
        'FontSize',10.0, ...
        'BackgroundColor',defaultBackground);
    handles.axis_lower = uicontrol('Style','text', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.88 .084 .05 .02], ...
        'FontSize',10.0, ...
        'BackgroundColor',defaultBackground);
    handles.axis_image = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.88 .109 .05 .853], ...
        'Box','on','XTick',[],'YTick',[],'Layer','top');
    handles.axis_guide = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.01 .09 .86 .89], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
    % Update axis labels and slider parameters
    global settings;
    set(handles.axis_lower,'String',settings.axis_lower);
    set(handles.axis_upper,'String',settings.axis_upper);
    set(handles.slider,...
        'SliderStep',[1/(settings.axis_steps-1) 1/(settings.axis_steps-1)],...
        'Min',settings.axis_min,...
        'Max',settings.axis_max,...
        'Value',settings.axis_max-(settings.axis_max-settings.axis_min)/2);
    % Initialize rating axis
    axes(handles.axis_image);
    set(gca,'XLim',[0,70],'YLim',[0,450]);
    axis ij; hold on;
    % Create and display custom color gradient in rating axis
    image([colorGradient(settings.axis_color1,settings.axis_color2,225,70); ...
        colorGradient(settings.axis_color2,settings.axis_color3,225,70)]);
    % Plot hash-marks on rating axis
    for i = 1:settings.axis_steps-1
        plot([1,5],[450,450]*i/settings.axis_steps,'k-');
        plot([65,70],[450,450]*i/settings.axis_steps,'k-');
    end
    % Plot numerical labels on rating axis
    axis_labels = linspace(settings.axis_max,settings.axis_min,settings.axis_steps);
    for i = 1:length(axis_labels)
        xval = 37.5;
        yval = (((450*(i-1))/settings.axis_steps)+((450*i)/settings.axis_steps))/2;
        text(xval-1,yval,sprintf('%.2f',axis_labels(i)),'HorizontalAlignment','center','Color','black','Fontweight','bold');
        text(xval+1,yval,sprintf('%.2f',axis_labels(i)),'HorizontalAlignment','center','Color','black','Fontweight','bold');
        text(xval,yval-1,sprintf('%.2f',axis_labels(i)),'HorizontalAlignment','center','Color','black','Fontweight','bold');
        text(xval,yval+1,sprintf('%.2f',axis_labels(i)),'HorizontalAlignment','center','Color','black','Fontweight','bold');
        text(xval,yval,sprintf('%.2f',axis_labels(i)),'HorizontalAlignment','center','Color','white','Fontweight','bold');
    end
    hold off;
    % Invoke and configure VLC ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_collect);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    % Create timer
    handles.timer = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.05, ...
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

function menu_multimedia_Callback(hObject,~)
    handles = guidata(hObject);
    % Reset the GUI elements
    program_reset(handles);
    handles.vlc.playlist.items.clear();
    global ratings last_ts_vlc last_ts_sys;
    ratings = [];
    last_ts_vlc = 0;
    last_ts_sys = 0;
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
    catch err
        msgbox(err.message,'Error loading multimedia file.'); return;
    end
    % Update GUI elements
    set(handles.text_report,'String','Press Play');
    set(handles.text_filename,'String',video_name);
    set(handles.text_duration,'String',datestr(handles.dur/24/3600,'HH:MM:SS'));
    set(handles.toggle_playpause,'Enable','On');
    guidata(hObject,handles);
end

% =========================================================

function figure_collect_KeyPress(hObject,eventdata)
    handles = guidata(hObject);
    % Escape if the playpause button is disabled
    if strcmp(get(handles.toggle_playpause,'enable'),'inactive'), return; end
    % Pause playback if the pressed key is spacebar
    if strcmp(eventdata.Key,'space') && get(handles.toggle_playpause,'value')
        handles.vlc.playlist.togglePause();
        stop(handles.timer);
        set(handles.toggle_playpause,'String','Resume','Value',0);
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
        set(hObject,'Enable','Off','String','...');
        set(handles.menu_multimedia,'Enable','off');
        uicontrol(handles.slider);
        % Start three second countdown before starting
        set(handles.text_report,'String','...3...'); pause(1);
        set(handles.text_report,'String','..2..'); pause(1);
        set(handles.text_report,'String','.1.'); pause(1);
        set(hObject,'Enable','On','String','Pause');
        guidata(hObject,handles);
        % Send play() command to VLC and wait for it to start playing
        handles.vlc.playlist.play();
    else
        % If toggle button is set to pause, send pause() command to VLC
        handles.vlc.playlist.togglePause();
        stop(handles.timer);
        handles.recording = 0;
        set(hObject,'String','Resume','Value',0);
        guidata(hObject,handles);
    end
end

% =========================================================

function timer_Callback(~,~,handles)
    handles = guidata(handles.figure_collect);
    global settings ratings last_ts_vlc last_ts_sys global_tic;
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
        val = get(handles.slider,'value');
        ratings = [ratings; ts_vlc, val];
        set(handles.text_report,'string',datestr(handles.vlc.input.time/1000/24/3600,'HH:MM:SS'));
        drawnow();
    % After playing
    elseif handles.vlc.input.state == 5 || handles.vlc.input.state == 6
        stop(handles.timer);
        handles.vlc.playlist.stop();
        set(handles.toggle_playpause,'Value',0);
        set(handles.text_report,'string','Processing...');
        % Average ratings per second of playback
        rating = ratings;
        %disp(rating);
        anchors = [0,(1/settings.sps:1/settings.sps:floor(handles.dur))];
        mean_ratings = nan(length(anchors)-1,2);
        mean_ratings(:,1) = anchors(2:end)';
        for i = 1:length(anchors)-1
            s_start = anchors(i);
            s_end = anchors(i+1);
            index = (rating(:,1) >= s_start) & (rating(:,1) < s_end);
            bin = rating(index,2:end);
            mean_ratings(i,:) = [s_end,nanmean(bin)];
        end
        % Prompt user to save the collected annotations
        [~,defaultname,ext] = fileparts(handles.MRL);
        [filename,pathname] = uiputfile({'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
        if ~isequal(filename,0) && ~isequal(pathname,0)
            % Add metadata to mean ratings and timestamps
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

function timer_ErrorFcn(~,~,handles)
    handles = guidata(handles.figure_collect);
    handles.vlc.playlist.togglePause();
    stop(handles.timer);
    msgbox('Timer callback error.','Error','error');
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
    % Pause playback and rating
    if handles.vlc.input.state==3,handles.vlc.playlist.togglePause(); end
    if strcmp(handles.timer.Running,'on'), stop(handles.timer); end
    set(handles.toggle_playpause,'String','Resume','Value',0);
    guidata(handles.figure_collect,handles);
    pause(.1); 
    if handles.vlc.input.state==4
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
        delete(handles.timer);
        delete(gcf);
    end
end

% =========================================================

function program_reset(handles)
    handles = guidata(handles.figure_collect);
    % Update GUI elements to starting configuration
    set(handles.text_report,'String','Open File');
    set(handles.text_filename,'String','');
    set(handles.text_duration,'String','');
    set(handles.toggle_playpause,'Enable','off','String','Play');
    set(handles.menu_multimedia,'Enable','on');
    set(handles.slider,'Value',get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2);
    drawnow();
    guidata(handles.figure_collect,handles);
end
