function main
%CARMA Code for the main CARMA window and functions
% License: https://carma.codeplex.com/license

    % Create and center main window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_main = figure(...
        'Name','Continuous Affect Rating and Media Annotation',...
        'NumberTitle','off',...
        'MenuBar','none',...
        'Resize','off',...
        'Color',defaultBackground,...
        'KeyPressFcn',@figure_main_KeyPress);
    maximize(handles.figure_main);
    pause(0.1);
    % Create menu bar elements
    handles.menu_multimedia = uimenu(handles.figure_main,...
        'Parent',handles.figure_main,...
        'Label','Open Multimedia File',...
        'Callback',{@menu_multimedia_Callback,handles});
    handles.menu_annotation = uimenu(handles.figure_main,...
        'Parent',handles.figure_main,...
        'Label','Import Annotation File',...
        'Callback',{@menu_annotation_Callback,handles},...
        'Enable','off');
    handles.menu_settings = uimenu(handles.figure_main,...
        'Parent',handles.figure_main,...
        'Label','Configure Settings',...
        'Callback',{@menu_settings_Callback,handles});
    handles.menu_about = uimenu(handles.figure_main,...
        'Parent',handles.figure_main,...
        'Label','About CARMA',...
        'Callback',@menu_about_Callback);
    % Create uicontrol elements
    handles.text_report = uicontrol('Style','edit',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.01 .02 .22 .05],...
        'String','Open File',...
        'FontSize',14.0,...
        'Enable','off');
    handles.text_filename = uicontrol('Style','edit',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.24 .02 .40 .05],...
        'FontSize',14.0,...
        'Enable','off');
    handles.text_duration = uicontrol('Style','edit',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.65 .02 .22 .05],...
        'FontSize',14.0,...
        'Enable','off');
    handles.toggle_playpause = uicontrol('Style','togglebutton',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.88 .02 .11 .05],...
        'String','Play',...
        'FontSize',14.0,...
        'Callback',{@toggle_playpause_Callback,handles},...
        'Enable','inactive');
    handles.slider = uicontrol('Style','slider',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.94 .09 .05 .89],...
        'BackgroundColor',[.5 .5 .5],...
        'KeyPressFcn',@figure_main_KeyPress);
    handles.axis_image = axes('Units','Normalized',...
        'Parent',handles.figure_main,...
        'Position',[.88 .109 .05 .855],...
        'Box','on','XTick',[],'YTick',[],'Layer','top');
    handles.axis_upper = uicontrol('Style','text',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.88 .964 .05 .02],...
        'FontSize',10.0,...
        'BackgroundColor',defaultBackground);
    handles.axis_lower = uicontrol('Style','text',...
        'Parent',handles.figure_main,...
        'Units','Normalized',...
        'Position',[.88 .084 .05 .02],...
        'FontSize',10.0,...
        'BackgroundColor',defaultBackground);
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
        save(fullfile(ctfroot,'default.mat'),'Settings');
        save(fullfile(ctfroot,'settings.mat'),'Settings');
    end
    % Invoke and configure WMP ActiveX Controller
    sliderpos = getpixelposition(handles.slider);
    reportpos = getpixelposition(handles.text_report);
    handles.wmp = actxcontrol(axctl{index,2},[reportpos(1) sliderpos(2) sliderpos(3)*17.2 sliderpos(4)*.975],handles.figure_main);
    handles.wmp.stretchToFit = true;
    handles.wmp.uiMode = 'none';
    set(handles.wmp.settings,'autoStart',0);
    % Save handles to guidata
    guidata(handles.figure_main,handles);
    make_changes(Settings,handles);
end

% --- Executes when a key is pressed.
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

% --- Executes when menu_multimedia is clicked.
function menu_multimedia_Callback(hObject,~,handles)
    handles = guidata(handles.figure_main);
    % Browse for, load, and get text_duration for a multimedia file
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file');
    if video_name==0, return; end
    try
        handles.wmp.URL = fullfile(video_path,video_name);
        %TODO: Replace mmfileinfo() with wmp.currentMedia.text_duration
        info = mmfileinfo(fullfile(video_path,video_name));
        handles.dur = info.Duration;
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
    set(handles.text_duration,'String',datestr(info.Duration/24/3600,'HH:MM:SS.FFF'));
    set(handles.toggle_playpause,'Enable','On');
    handles.rating = [];
    guidata(hObject,handles);
end

% --- Executes when menu_annotation is clicked. 
function menu_annotation_Callback(~,~,handles)
    handles = guidata(handles.figure_main);
    [filename,pathname] = uigetfile({'*.xls; *.xlsx; *.csv','CARMA Export Formats (*.xls, *.xlsx, *.csv)'},'Open Annotations');
    if filename==0, return; end
    data = importdata(fullfile(pathname,filename));
    % Browse for an annotation file
    if floor(handles.dur) ~= size(data.data,1)
        msgbox('Annotation file must be the same duration as multimedia file.','Error','Error');
        return;
    else
        % Generate Settings and Ratings variables
        Settings.axis_lower = data.textdata{2,2};
        Settings.axis_upper = data.textdata{2,3};
        Settings.axis_min = num2str(data.data(1,1));
        Settings.axis_max = num2str(data.data(1,3));
        Settings.axis_steps = num2str(data.data(1,4));
        Ratings = data.data(:,5:6);
        % Execute the annotations() function
        annotations('URL',handles.wmp.URL,'Settings',Settings,'Ratings',Ratings,'Duration',handles.dur,'Filename',filename);
    end
end

% --- Executes when menu_settings is clicked.
function menu_settings_Callback(~,~,handles)
    handles = guidata(handles.figure_main);
    %Call the settings() function and wait for it
    settings();
    waitfor(findobj('Name','CARMA: Settings'));
    % Load and apply the configured menu_settings
    Settings = importdata(fullfile(ctfroot,'settings.mat'));
    make_changes(Settings,handles);
end

% --- Executes when menu_about is clicked.
function menu_about_Callback(~,~)
    % Display information menu_about CARMA
    line1 = 'Continuous Affect Rating and Media Annotation';
    line2 = 'Version 7.01 <09-23-2014>';
    line3 = 'Manual: http://carma.codeplex.com/documentation';
    line4 = 'Support: http://carma.codeplex.com/discussion';
    line5 = 'License: http://carma.codeplex.com/license';
    msgbox(sprintf('%s\n%s\n%s\n%s\n%s',line1,line2,line3,line4,line5),'About CARMA','help');
end

% --- Executes on button press in toggle_playpause.
function toggle_playpause_Callback(hObject,~,handles)
    handles = guidata(handles.figure_main);
    if get(hObject,'Value')
        % If toggle button is set to play, update GUI elements
        set(hObject,'Enable','Off','String','...');
        set(handles.menu_multimedia,'Enable','Off');
        set(handles.menu_annotation,'Enable','Off');
        set(handles.menu_settings,'Enable','Off');
        set(handles.menu_about,'Enable','Off');
        % Start three second countdown before starting
        set(handles.text_report,'String','...3...'); pause(1);
        set(handles.text_report,'String','..2..'); pause(1);
        set(handles.text_report,'String','.1.'); pause(1);
        set(hObject,'Enable','On','String','Pause');
        % Send play() command to WMP and wait for it to start playing
        handles.wmp.controls.play();
        while ~strcmp(handles.wmp.playState,'wmppsPlaying'), pause(0.01); end
        % While playing, collect 10 ratings per second and update the current timestamp
        while strcmp(handles.wmp.playState,'wmppsPlaying') && get(hObject,'value')
            pause(0.1);
            handles.rating = [handles.rating; handles.wmp.controls.currentPosition,get(handles.slider,'value')];
            set(handles.text_report,'string',datestr(handles.wmp.controls.currentPosition/24/3600,'HH:MM:SS.FFF'));
            drawnow;
        end
        guidata(hObject, handles);
        % When finished playing, send stop() command to WMP
        if get(hObject,'Value')
            handles.wmp.controls.stop();
            set(handles.text_report,'string','Processing...');
            % Average ratings per second of playback
            rating = handles.rating;
            if floor(handles.dur) == 0, rounddir = 1; else rounddir = floor(handles.dur); end
            mean_ratings = zeros(rounddir,2);
            for i = 1:rounddir
                index = rating(:,1)>=i-1 & rating(:,1)<i;
                mean_ratings(i,:) = [i,mean(rating(index,2))];
            end
            % Prompt user to save the collected annotations
            Settings = importdata(fullfile(ctfroot,'settings.mat'));
            axis_min = str2double(Settings.axis_min);
            axis_max = str2double(Settings.axis_max);
            axis_steps = str2double(Settings.axis_steps);
            [~,defaultname,~] = fileparts(handles.wmp.URL);
            [filename,pathname] = uiputfile({'*.xlsx','Excel 2007 Spreadsheet (*.xlsx)';...
                '*.xls','Excel 2003 Spreadsheet (*.xls)';...
                '*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
            if ~isequal(filename,0) && ~isequal(pathname,0)
                % Add metadata to mean ratings and timestamps
                sz = size(mean_ratings,1);
                output = [...
                    {'Filename','Lower Label','Upper Label','Minimum Value','Midpoint Value','Maximum Value','Number of Steps','Second','Rating'};...
                    cellstr(repmat(handles.wmp.URL,sz,1)),...
                    cellstr(repmat(Settings.axis_lower,sz,1)),...
                    cellstr(repmat(Settings.axis_upper,sz,1)),...
                    num2cell(repmat(axis_min,sz,1)),...
                    num2cell(repmat(axis_max-(axis_max-axis_min)/2,sz,1)),...
                    num2cell(repmat(axis_max,sz,1)),...            
                    num2cell(repmat(axis_steps,sz,1)),...
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
                    h = msgbox('Export error.');
                    waitfor(h);
                end
            else
                filename = 'Unsaved';
            end
            % Open the collected annotations for viewing and exporting
            annotations('URL',handles.wmp.URL,'Settings',Settings,'Ratings',mean_ratings,'Duration',handles.dur,'Filename',filename);
            program_reset(handles);
        end
    else
        % If toggle button is set to pause, send pause() command to WMP
        handles.wmp.controls.pause();
        set(hObject,'String','Resume','Value',0);
    end
end

% --- Called from multiple other functions.
function make_changes(Settings,handles)
    handles = guidata(handles.figure_main);
    % Convert strings to numbers for convenience
    axis_min = str2double(Settings.axis_min);
    axis_max = str2double(Settings.axis_max);
    axis_steps = str2double(Settings.axis_steps);
    % Update axis labels and slider parameters
    set(handles.axis_lower,'String',Settings.axis_lower);
    set(handles.axis_upper,'String',Settings.axis_upper);
    set(handles.slider,'SliderStep',[1/(axis_steps-1) 1/(axis_steps-1)],...
        'Min',axis_min,'Max',axis_max,'Value',axis_max-(axis_max-axis_min)/2);
    % Initialize rating axis
    set(handles.figure_main,'CurrentAxes',handles.axis_image);
    set(gca,'XLim',[0,70],'YLim',[0,450]);
    axis ij; hold on;
    % Create and display custom color gradient in rating axis
    image([colorGradient(Settings.axis_color1,Settings.axis_color2,225,70);...
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
end

% --- Called from multiple other functions.
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
    drawnow;
end