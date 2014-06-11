function varargout = carma(varargin)
%CARMA Code for the main CARMA window and functions
% License: https://carma.codeplex.com/license

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @carma_OpeningFcn, ...
                   'gui_OutputFcn',  @carma_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before figure_carma is made visible.
function carma_OpeningFcn(hObject, ~, handles, varargin)
    % Initialize GUI data
    handles.output = hObject;
    movegui(gcf,'center');
    guidata(hObject, handles);
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
    make_changes(Settings,handles);
    % Invoke and configure WMP ActiveX Controller
    handles.wmp = actxcontrol(axctl{index,2},[10 60 720 480],handles.figure_carma);
    handles.wmp.stretchToFit = true;
    handles.wmp.uiMode = 'none';
    set(handles.wmp.settings,'autoStart',0);
    guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = carma_OutputFcn(hObject, ~, handles) 
    varargout{1} = handles.output;
    
% --- Called from multiple other functions
function program_reset(handles)
    % Update GUI elements to starting configuration
    set(handles.text_report,'String','Open File');
    set(handles.text_filename,'String','');
    set(handles.text_duration,'String','');
    set(handles.toggle_playpause,'Enable','Off','String','Play');
    set(handles.menu_multimedia,'Enable','On');
    set(handles.menu_annotation,'Enable','Off');
    set(handles.menu_settings,'Enable','On');
    set(handles.menu_about,'Enable','On');
    set(handles.slider,'Enable','Inactive');
    set(handles.slider,'Value',...
        get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2);
    drawnow;
    
% --- Executes on button press in toggle_playpause.
function toggle_playpause_Callback(hObject, ~, handles)
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
            mean_ratings = zeros(ceil(max(rating(:,1))),2);
            for i = 1:ceil(max(rating(:,1)))
                index = rating(:,1)>=i-1 & rating(:,1)<i;
                mean_ratings(i,:) = [i,mean(rating(index,2))];
            end
            % Open the collected annotations for viewing and exporting
            Settings = importdata(fullfile(ctfroot,'settings.mat')); 
            h = annotations('URL',handles.wmp.URL,'Settings',Settings,'Ratings',mean_ratings,'Duration',handles.dur);
            waitfor(h);
            program_reset(handles);
        end
    else
        % If toggle button is set to pause, send pause() command to WMP
        handles.wmp.controls.pause();
        set(hObject,'string','Resume');
    end

% --- Called from multiple other functions
function make_changes(Settings,handles)
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
    axes(handles.axis_image);
    set(gca,'XTick',[],'YTick',[],'XLim',[0,70],'YLim',[0,450]);
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
    
% --- Executes on button press in menu_multimedia.
function menu_multimedia_Callback(hObject, ~, handles)
    % Reset the GUI elements
    program_reset(handles);
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
    % Update GUI elements
    set(handles.slider,'Enable','On');
    set(handles.menu_annotation,'Enable','On');
    set(handles.text_report,'String','Press Play');
    set(handles.text_filename,'String',video_name);
    set(handles.text_duration,'String',datestr(info.Duration/24/3600,'HH:MM:SS.FFF'));
    set(handles.toggle_playpause,'Enable','On');
    handles.rating = [];
    guidata(hObject, handles);
    
% --- Executes on button press in menu_annotation. 
function menu_annotation_Callback(hObject, eventdata, handles)
    % Browse for an annotation file
    [filename,pathname] = uigetfile({'*.xls; *.xlsx; *.csv','CARMA Export Formats (*.xls, *.xlsx, *.csv)'},'Open Annotations');
    data = importdata(fullfile(pathname,filename));
    if ceil(handles.dur) ~= size(data.data,1) && floor(handles.dur) ~= size(data.data,1)
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
        annotations('URL',handles.wmp.URL,'Settings',Settings,'Ratings',Ratings,'Duration',handles.dur);
    end
    
% --- Executes on button press in menu_settings.
function menu_settings_Callback(hObject, ~, handles)
    % Run the menu_settings() function
    H = settings('carma',handles.figure_carma);
    waitfor(H);
    % Load and apply the configured menu_settings
    Settings = importdata(fullfile(ctfroot,'settings.mat'));
    make_changes(Settings,handles);
    guidata(hObject, handles);

% --- Executes on button press in menu_about.
function menu_about_Callback(hObject, ~, handles)
    % Display information menu_about CARMA
    line1 = 'Continuous Affect Rating and Media Annotation';
    line2 = 'Version 5.01 <06-11-2014>';
    line3 = 'Manual: http://carma.codeplex.com/documentation';
    line4 = 'Support: http://carma.codeplex.com/discussion';
    line5 = 'License: http://carma.codeplex.com/license';
    msgbox(sprintf('%s\n%s\n%s\n%s\n%s',line1,line2,line3,line4,line5),'About CARMA','help');
