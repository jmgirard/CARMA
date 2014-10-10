function main
%MAIN Code for the main CARMA window and functions
% License: https://carma.codeplex.com/license

    % Create and center main window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_main = figure( ...
        'Position',[0 0 0 0], ...
        'Name','Continuous Affect Rating and Media Annotation', ...
        'NumberTitle','off', ...
		'ToolBar','none', ...
        'MenuBar','none', ...
        'Color',defaultBackground, ...
        'KeyPressFcn',@figure_main_KeyPress);
    % Create menu bar elements
    handles.menu_multimedia = uimenu(handles.figure_main, ...
        'Parent',handles.figure_main, ...
        'Label','Open Multimedia File', ...
        'Callback',@menu_multimedia_Callback);
    handles.menu_annotation = uimenu(handles.figure_main, ...
        'Parent',handles.figure_main, ...
        'Label','Import Annotation File', ...
        'Callback',@menu_annotation_Callback, ...
        'Enable','off');
    handles.menu_settings = uimenu(handles.figure_main, ...
        'Parent',handles.figure_main, ...
        'Label','Configure Settings', ...
        'Callback',@menu_settings_Callback);
    handles.menu_about = uimenu(handles.figure_main, ...
        'Parent',handles.figure_main, ...
        'Label','About CARMA', ...
        'Callback',@menu_about_Callback);
	% Maximize and lock window
    pause(.5);
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(.01);
    set(handles.figure_main,'Resize','off');
    % Create uicontrol elements
    handles.text_report = uicontrol('Style','edit', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.01 .02 .22 .05], ...
        'String','Open File', ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.text_filename = uicontrol('Style','edit', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.24 .02 .40 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.text_duration = uicontrol('Style','edit', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.65 .02 .22 .05], ...
        'FontSize',14.0, ...
        'Enable','off');
    handles.toggle_playpause = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.88 .02 .11 .05], ...
        'String','Play', ...
        'FontSize',14.0, ...
        'Callback',@toggle_playpause_Callback, ...
        'Enable','inactive');
    handles.slider = uicontrol('Style','slider', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.94 .09 .05 .89], ...
        'BackgroundColor',[.5 .5 .5], ...
        'KeyPressFcn',@figure_main_KeyPress);
    handles.axis_upper = uicontrol('Style','text', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.88 .965 .05 .02], ...
        'FontSize',10.0, ...
        'BackgroundColor',defaultBackground);
    handles.axis_lower = uicontrol('Style','text', ...
        'Parent',handles.figure_main, ...
        'Units','Normalized', ...
        'Position',[.88 .084 .05 .02], ...
        'FontSize',10.0, ...
        'BackgroundColor',defaultBackground);
    handles.axis_image = axes('Units','Normalized', ...
        'Parent',handles.figure_main, ...
        'Position',[.88 .109 .05 .853], ...
        'Box','on','XTick',[],'YTick',[],'Layer','top');
    % Check for and find Window Media Player (WMP) ActiveX Controller
    axctl = actxcontrollist;
    index = strcmp(axctl(:,1),'Windows Media Player');
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end
    % Load default settings or create them if default file is missing
    if exist(fullfile(ctfroot,'default.mat'),'file')~=0
        Settings = importdata(fullfile(ctfroot,'default.mat'));
        save(fullfile(ctfroot,'settings.mat'),'Settings');
    else
        Settings.axis_lower = 'very negative';
        Settings.axis_upper = 'very positive';
        Settings.axis_color1 = [1,0,0];
        Settings.axis_color2 = [1,1,0];
        Settings.axis_color3 = [0,1,0];
        Settings.axis_min = '-100';
        Settings.axis_max = '100';
        Settings.axis_steps = '9';
        Settings.sps = '1.00';
        save(fullfile(ctfroot,'default.mat'),'Settings');
        save(fullfile(ctfroot,'settings.mat'),'Settings');
    end
    % Invoke and configure WMP ActiveX Controller
    fp = getpixelposition(handles.figure_main);
    pause(.25);
    handles.wmp = actxcontrol(axctl{index,2},fp([3 4 3 4]).*[.01 .09 .865 .905],handles.figure_main);
    handles.wmp.stretchToFit = true;
    handles.wmp.uiMode = 'none';
    set(handles.wmp.settings,'autoStart',0);
	% Create timer
	handles.timer = timer( ...
        'ExecutionMode','fixedRate', ...
        'Period',0.05, ...
        'TimerFcn',{@timer_Callback,handles});
    % Save handles to guidata
    guidata(handles.figure_main,handles);
    make_changes(Settings,handles);
end

% ===============================================================================

function figure_main_KeyPress(hObject,eventdata)
    handles = guidata(hObject);
    % Escape if the playpause button is disabled
    if strcmp(get(handles.toggle_playpause,'enable'),'inactive'), return; end
    % Pause playback if the pressed key is spacebar
    if strcmp(eventdata.Key,'space') && get(handles.toggle_playpause,'value')
        handles.wmp.controls.pause();
        set(handles.toggle_playpause,'String','Resume','Value',0);
    else
        return;
    end
    guidata(hObject,handles);
end

% ===============================================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
	% If toggle button is set to play...
    if get(hObject,'Value')
        % Lock GUI elements to prevent interruption
        set(hObject,'Enable','Off','String','...');
        set(handles.menu_multimedia,'Enable','Off');
        set(handles.menu_annotation,'Enable','Off');
        set(handles.menu_settings,'Enable','Off');
        set(handles.menu_about,'Enable','Off');
        % Show three second countdown before starting
        set(handles.text_report,'String','...3...'); pause(1);
        set(handles.text_report,'String','..2..'); pause(1);
        set(handles.text_report,'String','.1.'); pause(1);
        set(hObject,'Enable','on','String','Pause');
        % Send play() command to WMP and start timer
        handles.wmp.controls.play();
		start(handles.timer);
		guidata(hObject,handles);
	% If toggle button is set to pause...
    else
        % Send pause() command to WMP and stop timer
        handles.wmp.controls.pause();
		stop(handles.timer);
        set(hObject,'String','Resume','Value',0);
    end
end

% ===============================================================================

function timer_Callback(~,~,handles)
	handles = guidata(handles.figure_main);
	% While playing
    if strcmp(handles.wmp.playState,'wmppsPlaying')
		% Query the slider position and update time stamp
		handles.rating = [handles.rating; handles.wmp.controls.currentPosition,get(handles.slider,'value')];
		set(handles.text_report,'string',datestr(handles.wmp.controls.currentPosition/24/3600,'HH:MM:SS'));
		drawnow();
	% After playing
	elseif strcmp(handles.wmp.playState,'wmppsStopped')
		handles.wmp.controls.stop();
		stop(handles.timer);
		set(handles.text_report,'string','Processing...');
		% Average ratings per second of playback
		rating = handles.rating;
        mean_ratings = [];
        sps = str2double(handles.sps);
        anchors = [0,(1/sps:1/sps:handles.dur)];
        for i = 1:length(anchors)-1
            s_start = anchors(i);
            s_end = anchors(i+1);
            index = (rating(:,1) >= s_start) & (rating(:,1) < s_end);
            bin = rating(index,2:end);
            mean_ratings = [mean_ratings;s_end,mean(bin)];
        end
		% Prompt user to save the collected annotations
		Settings = importdata(fullfile(ctfroot,'settings.mat'));
		axis_min = str2double(Settings.axis_min);
		axis_max = str2double(Settings.axis_max);
		axis_steps = str2double(Settings.axis_steps);
		[~,defaultname,ext] = fileparts(handles.wmp.URL);
		[filename,pathname] = uiputfile({'*.xlsx','Excel 2007 Spreadsheet (*.xlsx)';...
			'*.xls','Excel 2003 Spreadsheet (*.xls)';...
			'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
		if ~isequal(filename,0) && ~isequal(pathname,0)
			% Add metadata to mean ratings and timestamps
			output = [ ...
                {'Time of Rating'},{datestr(now)}; ...
                {'Multimedia File'},{sprintf('%s%s',defaultname,ext)}; ...
                {'Lower Label'},{Settings.axis_lower}; ...
                {'Upper Label'},{Settings.axis_upper}; ...
                {'Minimum Value'},{axis_min}; ...
                {'Maximum Value'},{axis_max}; ...
                {'Number of Steps'},{axis_steps}; ...
                {'Second'},{'Rating'}; ...
                {'%%%%%%'},{'%%%%%%'}; ...
                num2cell(mean_ratings)];
			% Create export file depending on selected file type
			[~,~,ext] = fileparts(filename);
			if strcmpi(ext,'.XLS') || strcmpi(ext,'.XLSX')
				% Create XLS/XLSX file if that is the selected file type
				[success,message] = xlswrite(fullfile(pathname,filename),output);
				if strcmp(message.identifier,'MATLAB:xlswrite:dlmwrite')
					% If Excel is not installed, create CSV file instead
					serror = errordlg('Exporting to .XLS/.XLSX requires Microsoft Excel to be installed. CARMA will now export to .CSV instead.');
					uiwait(serror);
					success = cell2csv(fullfile(pathname,filename),output);
				end
			elseif strcmpi(ext,'.CSV')
				% Create CSV file if that is the selected file type
				success = cell2csv(fullfile(pathname,filename),output);
			end
			% Report saving success or failure
			if success
				h = msgbox('Export successful.');
				waitfor(h);
			else
				h = msgbox('Export error.','','error');
				waitfor(h);
			end
		else
			filename = 'Unsaved';
		end
		% Open the collected annotations for viewing and exporting
		annotations('URL',handles.wmp.URL,'Settings',Settings,'Ratings',mean_ratings,'Duration',handles.dur,'Filename',filename);
		program_reset(handles);
	% While transitioning
	else
		return;
    end
	guidata(handles.figure_main,handles);
end

% ===============================================================================

function make_changes(Settings,handles)
    handles = guidata(handles.figure_main);
    % Convert strings to numbers for convenience
    axis_min = str2double(Settings.axis_min);
    axis_max = str2double(Settings.axis_max);
    axis_steps = str2double(Settings.axis_steps);
    % Update axis labels and slider parameters
    set(handles.axis_lower,'String',Settings.axis_lower);
    set(handles.axis_upper,'String',Settings.axis_upper);
    set(handles.slider,'SliderStep',[1/(axis_steps-1) 1/(axis_steps-1)], ...
        'Min',axis_min,'Max',axis_max,'Value',axis_max-(axis_max-axis_min)/2);
    % Initialize rating axis
    axes(handles.axis_image);
    set(gca,'XLim',[0,70],'YLim',[0,450]);
    axis ij; hold on;
    % Create and display custom color gradient in rating axis
    image([colorGradient(Settings.axis_color1,Settings.axis_color2,225,70); ...
        colorGradient(Settings.axis_color2,Settings.axis_color3,225,70)]);
    % Plot hash-marks on rating axis
    for i = 1:axis_steps-1
        plot([1,5],[450,450]*i/axis_steps,'k-');
        plot([65,70],[450,450]*i/axis_steps,'k-');
    end
    % Plot numerical labels on rating axis
    lin = linspace(axis_max,axis_min,axis_steps);
    for i = 1:length(lin)
        text(37.5,(((450*(i-1))/axis_steps)+((450*i)/axis_steps))/2,sprintf('%.2f',lin(i)),'HorizontalAlignment','center');
    end
    hold off;
	guidata(handles.figure_main,handles);
end

% ===============================================================================

function program_reset(handles)
    handles = guidata(handles.figure_main);
    % Update GUI elements to starting configuration
    set(handles.text_report,'String','Open File');
    set(handles.text_filename,'String','');
    set(handles.text_duration,'String','');
    set(handles.toggle_playpause,'Enable','Off','String','Play');
    set(handles.menu_multimedia,'Enable','On');
    set(handles.menu_annotation,'Enable','Off');
    set(handles.menu_settings,'Enable','On');
    set(handles.menu_about,'Enable','On');
    set(handles.slider,'Value',get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2);
    drawnow();
	guidata(handles.figure_main,handles);
end
% ===============================================================================

function menu_multimedia_Callback(hObject,~)
    handles = guidata(hObject);
    % Browse for, load, and get text_duration for a multimedia file
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file');
    if video_name==0, return; end
    try
        handles.wmp.URL = fullfile(video_path,video_name);
        handles.wmp.controls.play();
        while ~strcmp(handles.wmp.playState,'wmppsPlaying')
            pause(0.001);
        end
        handles.wmp.controls.pause();
        handles.wmp.controls.currentPosition = 0;
        handles.dur = handles.wmp.currentMedia.duration;
    catch err
        msgbox(err.message,'Error loading multimedia file.'); return;
    end
    % Reset the GUI elements
    program_reset(handles);
    % Update GUI elements
    set(handles.slider,'Enable','On');
    set(handles.menu_annotation,'Enable','On');
    set(handles.text_report,'String','Press Play');
    set(handles.text_filename,'String',video_name);
    set(handles.text_duration,'String',datestr(handles.dur/24/3600,'HH:MM:SS'));
    set(handles.toggle_playpause,'Enable','On');
    handles.rating = [];
    guidata(hObject,handles);
end

% ===============================================================================

function menu_annotation_Callback(hObject,~)
    handles = guidata(hObject);
    [filename,pathname] = uigetfile({'*.xls; *.xlsx; *.csv','CARMA Export Formats (*.xls, *.xlsx, *.csv)'},'Open Annotations');
    if filename==0, return; end
    [~,~,data] = xlsread(fullfile(pathname,filename));
    % Browse for an annotation file
    if floor(handles.dur) ~= data{end,1}
        msgbox('Annotation file must be the same duration as multimedia file.','Error','Error');
        return;
    else
        % Generate Settings and Ratings variables
        Settings.axis_lower = data{3,2};
        Settings.axis_upper = data{4,2};
        Settings.axis_min = num2str(data{5,2});
        Settings.axis_max = num2str(data{6,2});
        Settings.axis_steps = num2str(data{7,2});
        Ratings = cell2mat(data(10:end,:));
        % Execute the annotations() function
        annotations('URL',handles.wmp.URL,'Settings',Settings,'Ratings',Ratings,'Duration',handles.dur,'Filename',filename);
    end
end

% ===============================================================================

function menu_settings_Callback(hObject,~)
    handles = guidata(hObject);
    %Call the settings() function and wait for it
    settings();
    uiwait(findobj('Name','CARMA: Settings'));
    Settings = importdata(fullfile(ctfroot,'settings.mat'));
    make_changes(Settings,handles);
    handles.sps = Settings.sps;
    guidata(hObject,handles);
end

% ===============================================================================

function menu_about_Callback(~,~)
    % Display information menu_about CARMA
    line1 = 'Continuous Affect Rating and Media Annotation';
    line2 = 'Version 8.00 <10-10-2014>';
    line3 = 'Manual: http://carma.codeplex.com/documentation';
    line4 = 'Support: http://carma.codeplex.com/discussion';
    line5 = 'License: http://carma.codeplex.com/license';
    msgbox(sprintf('%s\n%s\n%s\n%s\n%s',line1,line2,line3,line4,line5),'About CARMA','help');
end
