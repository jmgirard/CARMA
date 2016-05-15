function fig_collect_device
%FIG_COLLECT_DEVICE Window for the collection of ratings with a device
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
    global settings global_tic recording;
    % Create uicontrol elements
    handles.text_report = uicontrol('Style','edit', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.01 .02 .22 .05], ...
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
        'Enable','off');
    handles.axis_upper = uicontrol('Style','text', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.90 .9605 .08 .028], ...
        'FontSize',10.0, ...
        'FontWeight','bold', ...
        'BackgroundColor',defaultBackground);
    handles.axis_lower = uicontrol('Style','text', ...
        'Parent',handles.figure_collect, ...
        'Units','Normalized', ...
        'Position',[.90 .08 .08 .028], ...
        'FontSize',10.0, ...
        'FontWeight','bold', ...
        'BackgroundColor',defaultBackground);
    handles.axis_image = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.90 .109 .07 .853], ...
        'Box','off','XColor','none','YColor','none');
    handles.axis_rating = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.90 .109 .07 .853], ...
        'Clipping','on', ...
        'Box','on','Layer','top');
    handles.axis_guide = axes('Units','Normalized', ...
        'Parent',handles.figure_collect, ...
        'Position',[.01 .09 .86 .89], ...
        'Box','on','XTick',[],'YTick',[],'Color','black');
    % Update axis labels and slider parameters
    set(handles.axis_lower,'String',settings.axis_lower);
    set(handles.axis_upper,'String',settings.axis_upper);
    % Create and display custom color gradient in rating axis
    axes(handles.axis_image);
    hold on;
    image([colorGradient(settings.axis_color3,settings.axis_color2,225,100); ...
        colorGradient(settings.axis_color2,settings.axis_color1,225,100)]);
    set(handles.axis_image, ...
        'XLim',[0 100],'YLim',[0 450], ...
        'XTick',[],'YTick',[]);
    hold off;
    % Plot current value indicator on rating axis
    axis_range = settings.axis_max - settings.axis_min;
    midpoint = settings.axis_min + axis_range/2;
    axes(handles.axis_rating);
    hold on;
    handles.plot_line = plot(handles.axis_rating,[0 100],[midpoint midpoint],'-k','LineWidth',5);
    handles.plot_marker = plot(handles.axis_rating,50,midpoint,'kd','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor','w','MarkerSize',25);
    set(handles.axis_rating, ...
        'XLim',[0 100],'XTick',[], ...
        'YLim',[settings.axis_min settings.axis_max], ...
        'YTick',round(linspace(settings.axis_min,settings.axis_max,settings.axis_steps),2), ...
        'Box','on','Layer','top','Color','none');
    hold off;
    % Invoke and configure VLC ActiveX Controller
    handles.vlc = actxcontrol('VideoLAN.VLCPlugin.2',getpixelposition(handles.axis_guide),handles.figure_collect);
    handles.vlc.AutoPlay = 0;
    handles.vlc.Toolbar = 0;
    handles.vlc.FullscreenEnabled = 0;
    if strcmp(settings.input,'USB Joystick')
        try
            handles.joy = vrjoystick(1);
        catch
            e = errordlg('CARMA could not detect a joystick.','Error','modal');
            waitfor(e);
            quit force;
        end
    elseif strcmp(settings.input,'I-CubeX Slider')
        try
            handles.com = serial('COM3');
            fopen(handles.com);
        catch
            e = errordlg('CARMA could not connect to the COM3 port to access an I-CubeX Push Slider.','Error','modal');
            waitfor(e);
            quit force;
        end
        fwrite(handles.com,[240 125 0 90 0 247]); % send host mode message to digitizer
        fwrite(handles.com,[240 125 0 34 247]); % send reset message to digitizer
        fwrite(handles.com,[240 125 0 3 0 125 247]); % send interval message to digitizer to set sampling interval to 150 ms 
        fwrite(handles.com,[240 125 0 2 64 247]); % send resolution message to digitizer to set sampling resolution to 10-bit
        pause(3); % wait until the digitizer has sent host mode and reset confirmation messages
        try
            b = get(handles.com, 'BytesAvailable'); % find out how many bytes are in the buffer
            fread(handles.com,b); % empty buffer
        catch
            e = errordlg('CARMA connected to the COM3 port but did not find an I-CubeX Push Slider.','Error','modal');
            waitfor(e);
            quit force;
        end
        fwrite(handles.com,[240 125 0 1 64 247]); % send stream message to digitizer to turn on continuous sampling for input 1
        while get(handles.com, 'BytesAvailable') < 6 % wait for digitizer to send confirmation message (6 bytes)
        end
        fread(handles.com,6); % empty buffer of confirmation message bytes
    end
    % Create timer
    handles.timer = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.05, ...
        'TimerFcn',{@timer_Callback,handles}, ...
        'ErrorFcn',{@timer_ErrorFcn,handles});
    % Start system clock to improve VLC time stamp precision
    global_tic = tic;
    recording = 0;
    handles.figure_collect.Visible = 'on';
    guidata(handles.figure_collect,handles);
    start(handles.timer);
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
    global recording;
    % Escape if the playpause button is disabled
    if strcmp(get(handles.toggle_playpause,'enable'),'inactive'), return; end
    % Pause playback if the pressed key is spacebar
    if strcmp(eventdata.Key,'space') && get(handles.toggle_playpause,'value')
        handles.vlc.playlist.togglePause();
        recording = 0;
        set(handles.toggle_playpause,'String','Resume','Value',0);
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
        set(handles.menu_multimedia,'Enable','off');
        % Start three second countdown before starting
        set(handles.text_report,'String','...3...'); pause(1);
        set(handles.text_report,'String','..2..'); pause(1);
        set(handles.text_report,'String','.1.'); pause(1);
        set(hObject,'Enable','On','String','Pause');
        recording = 1;
        guidata(hObject,handles);
        % Send play() command to VLC and wait for it to start playing
        handles.vlc.playlist.play();
    else
        % If toggle button is set to pause, send pause() command to VLC
        handles.vlc.playlist.togglePause();
        recording = 0;
        set(hObject,'String','Resume','Value',0);
        guidata(hObject,handles);
    end
end

% =========================================================

function timer_Callback(~,~,handles)
    handles = guidata(handles.figure_collect);
    global settings ratings last_ts_vlc last_ts_sys global_tic recording;
    if recording == 0
        if strcmp(settings.input,'USB Joystick')
            [joystatus,~,~] = read(handles.joy); %ranges from -1 to 1
            y = joystatus(2) * -1; %read y value and reverse its sign
            axis_range = settings.axis_max - settings.axis_min;
            axis_middle = settings.axis_min + axis_range / 2;
            val = axis_middle + y * axis_range / 2; %scale to user axis
            set(handles.plot_line,'XData',[0 100],'YData',[val val]);
            set(handles.plot_marker,'XData',50,'YData',val,'MarkerFaceColor','white');
        elseif strcmp(settings.input,'I-CubeX Slider')
            while get(handles.com,'BytesAvailable') < 7  % wait for digitizer to send hi-res data message (7 bytes) 
            end
            comstatus = fread(handles.com,7); % read data from buffer
            y = comstatus(5)*8 + comstatus(6); % calculate the sensor value from MSB and LSB
            val = settings.axis_min + y * (settings.axis_max - settings.axis_min) / 1044;
            set(handles.plot_line,'XData',[0 100],'YData',[val val]);
            set(handles.plot_marker,'XData',50,'YData',val,'MarkerFaceColor','white');
            drawnow(); %update the joystick indicator position
        end
        return;
    end
    % While playing
    if handles.vlc.input.state == 3
        ts_vlc = handles.vlc.input.time / 1000;
        ts_sys = toc(global_tic);
        if ts_vlc == last_ts_vlc && last_ts_vlc ~= 0
            ts_diff = ts_sys - last_ts_sys;
            ts_vlc = ts_vlc + ts_diff;
        else
            last_ts_vlc = ts_vlc;
            last_ts_sys = ts_sys;
        end
        if strcmp(settings.input,'USB Joystick')
            [joystatus,~,~] = read(handles.joy); %ranges from -1 to 1
            y = joystatus(2) * -1; %read y value and reverse its sign
            axis_range = settings.axis_max - settings.axis_min;
            axis_middle = settings.axis_min + axis_range / 2;
            val = axis_middle + y * axis_range / 2; %scale to user axis
            set(handles.plot_line,'XData',[0 100],'YData',[val val]);
            set(handles.plot_marker,'XData',50,'YData',val,'MarkerFaceColor','red');
        elseif strcmp(settings.input,'I-CubeX Slider')
            while get(handles.com,'BytesAvailable') < 7  % wait for digitizer to send hi-res data message (7 bytes) 
            end
            comstatus = fread(handles.com,7); % read data from buffer
            y = comstatus(5)*8 + comstatus(6); % calculate the sensor value from MSB and LSB
            val = settings.axis_min + y * (settings.axis_max - settings.axis_min) / 1044;
            set(handles.plot_line,'XData',[0 100],'YData',[val val]);
            set(handles.plot_marker,'XData',50,'YData',val,'MarkerFaceColor','red');
            drawnow(); %update the joystick indicator position
        end
        ratings = [ratings; ts_vlc, val];
        set(handles.text_report,'string',datestr(handles.vlc.input.time/1000/24/3600,'HH:MM:SS'));
        drawnow();
    % After playing
    elseif handles.vlc.input.state == 5 || handles.vlc.input.state == 6
        handles.vlc.playlist.stop();
        set(handles.toggle_playpause,'Value',0);
        recording = 0;
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
    global settings;
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
        stop(handles.timer);
        delete(handles.timer);
        if strcmp(settings.input,'I-CubeX Slider')
            fclose(handles.com);
        end
        delete(gcf);
    end
end

% =========================================================

function program_reset(handles)
    handles = guidata(handles.figure_collect);
    global settings recording;
    % Update GUI elements to starting configuration
    set(handles.text_report,'String','Open File');
    set(handles.text_filename,'String','');
    set(handles.text_duration,'String','');
    set(handles.toggle_playpause,'Enable','off','String','Play');
    set(handles.menu_multimedia,'Enable','on');
    axis_range = settings.axis_max - settings.axis_min;
    midpoint = settings.axis_min + axis_range/2;
    set(handles.plot_line,'XData',[0 100],'YData',[midpoint midpoint]);
    set(handles.plot_marker,'XData',50,'YData',midpoint);
    drawnow();
    recording = 0;
    guidata(handles.figure_collect,handles);
end
