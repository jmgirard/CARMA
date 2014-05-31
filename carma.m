function varargout = carma(varargin)
%CARMA Code for the main CARMA window and functions
% Jeffrey M Girard, 05/2014
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

function carma_OpeningFcn(hObject, ~, handles, varargin)
%CARMA_OPENINGFCN Runs when opening CARMA window
    handles.output = hObject;
    guidata(hObject, handles); %Update GUI data
    axctl = actxcontrollist; %Find ActiveX Controllers
    index = strcmp(axctl(:,1),'Windows Media Player'); %Find WMP ActiveX Controller
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end %Quit if not found
    if exist('default.mat','file')~=0
        Settings = importdata('default.mat');
        save('settings.mat','Settings');
    else
        Settings.axis_lower = 'very negative';
        Settings.axis_upper = 'very positive';
        Settings.axis_color1 = [1,0,0];
        Settings.axis_color2 = [1,1,0];
        Settings.axis_color3 = [0,1,0];
        Settings.axis_min = '1';
        Settings.axis_max = '9';
        Settings.axis_steps = '9';
        save('default.mat','Settings');
        save('settings.mat','Settings');
    end
    make_changes(Settings,handles);
    handles.wmp = actxcontrol(axctl{index,2},[10 60 720 480],handles.figure1); %Create WMP window
    handles.wmp.stretchToFit = true; %Configure WMP Settings
    handles.wmp.uiMode = 'none'; %Configure WMP Settings
    set(handles.wmp.settings,'autoStart',0); %Configure WMP Settings
    guidata(hObject, handles); %Update GUI data

function varargout = carma_OutputFcn(hObject, ~, handles) 
    varargout{1} = handles.output;

function open_file_Callback(hObject, ~, handles)
%OPEN_FILE_CALLBACK Runs when selecting the Open File menu option
    program_reset(handles); %Run PROGRAM_RESET function
    [video_name,video_path] = uigetfile({'*.*','All Files (*.*)'},'Select an audio or video file'); %GUI prompt for multimedia file
    if video_name==0, return; end %Cancel function if no file is selected
    try
        handles.wmp.URL = fullfile(video_path,video_name); %Open multimedia file in WMP window
        info = mmfileinfo(fullfile(video_path,video_name)); %Determine file duration
        handles.dur = info.Duration; %Save file duration to GUI data
    catch err
        msgbox(err.message,'Error'); return; %Cancel function if file cannot be opened
    end
    set(handles.slider,'enable','on'); %Enable slider to be used
    set(handles.settings,'enable','on'); %Enable settings button to be used
    set(handles.report,'string','Press Play'); %Update Report window
    set(handles.filename,'string',video_name); %Update Video Name window
    set(handles.duration,'string',datestr(info.Duration/24/3600,'HH:MM:SS.FFF')); %Update Duration window
    set(handles.playpause,'enable','on'); %Enable play button to be used
    handles.rating = zeros(ceil(info.Duration),1); %Initialize rating vector
    guidata(hObject, handles); %Update GUI data

function settings_Callback(hObject, ~, handles)
%SETTINGS_CALLBACK Runs when selecting the Settings menu option
    H = settings('carma',handles.figure1);
    waitfor(H);
    Settings = importdata('settings.mat');
    make_changes(Settings,handles);
    guidata(hObject, handles); %Update GUI data

function about_Callback(hObject, ~, handles)
%ABOUT_CALLBACK Runs when selecting About menu option
    line1 = 'Continuous Affect Rating and Media Annotation';
    line2 = 'Version 3.01 <05-31-2014>';
    line3 = 'Manual: http://carma.codeplex.com/documentation';
    line4 = 'Support: http://carma.codeplex.com/discussion';
    line5 = 'License: http://carma.codeplex.com/license';
    msgbox(sprintf('%s\n%s\n%s\n%s\n%s',line1,line2,line3,line4,line5),'About CARMA','help'); %Display CARMA information

function playpause_Callback(hObject, ~, handles)
%PLAYPAUSE_CALLBACK Runs when selecting the Play button
    set(hObject,'enable','off'); %Disable the Play button
    set(handles.open_file,'enable','off'); %Disable the Open File menu option
    set(handles.settings,'enable','off'); %Disable the Settings menu option
    set(handles.about,'enable','off'); %Disable the About menu option
    set(handles.report,'string','Get Ready'); %Update Report window
    set(hObject,'string','3'); pause(1); %Countdown on Play button
    set(hObject,'string','2'); pause(1); %Countdown on Play button
    set(hObject,'string','1'); pause(1); %Countdown on Play button
    set(hObject,'string','...'); %Update Play button
    for i = 1:ceil(handles.dur)
        temp = []; %Preallocate temporary ratings vector
        handles.wmp.controls.play(); %Send play command to WMP ActiveX Controller
        pause(0.05); %Pause to make sure video begins playing before starting ratings
        timer = tic; %Start timer
        while toc(timer) < 1.0
            temp = [temp; get(handles.slider,'value')]; %Collect ratings until timer hits 1 sec
        end
        handles.rating(i) = mean(temp); %Add mean rating for that second to ratings vector
        set(handles.report,'string',datestr(i/24/3600,'HH:MM:SS.FFF')); %Show elapsed time in seconds
    end
    handles.wmp.controls.pause(); %Send pause command to WMP ActiveX Controller
    set(handles.report,'string','Processing...'); %Update Report window
    guidata(hObject, handles); %Update GUI data
    save_rating(handles); %Run SAVE_RATING function
    
function save_rating(handles)
%SAVE_RATING Runs at the completion of rating
    [~,defaultname,~] = fileparts(get(handles.filename,'string')); %Get multimedia file name without path or extensions
    [filename,pathname] = uiputfile({'*.xls; *.xlsx','Excel Spreadsheets (*.xls, *.xlsx)';'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname); %Prompt user for save path
    if ~isequal(filename,0) && ~isequal(pathname,0)
        rating = handles.rating; %Get ratings vector
        Settings = importdata('settings.mat');
        % Add metadata to ratings vector
        output = [...
            {'Filename:',get(handles.filename,'string')};...
            {'Axis Labels:',sprintf('"%s" to "%s"',get(handles.axis_lower,'string'),get(handles.axis_upper,'string'))};...
            {'Axis Range:',sprintf('%d to %d',get(handles.slider,'min'),get(handles.slider,'max'))};...
            {'Number of Axis Steps:',Settings.axis_steps};...
            {'Second','Rating'};...
            num2cell(1:length(rating))',num2cell(rating)];
        [~,~,ext] = fileparts(filename);
        if strcmpi(ext,'.XLS') || strcmpi(ext,'.XLSX')
            [success,message] = xlswrite(fullfile(pathname,filename),output); %Write output to Excel spreadsheet
            if strcmp(message.identifier,'MATLAB:xlswrite:dlmwrite')
                serror = errordlg('Exporting to .XLS/.XLSX requires Microsoft Excel to be installed. CARMA will now export to .CSV instead.');
                uiwait(serror);
                success = cell2csv(fullfile(pathname,filename),output); %If no Excel, write output to CSV instead
            end
        elseif strcmpi(ext,'.CSV')
            success = cell2csv(fullfile(pathname,filename),output); %Write output to CSV
        end
    else
        choice = questdlg('You are about to close without saving.','CARMA','Close','Save','Save'); %Ask user to confirm closing without saving
        switch choice
            case 'Close'
                program_reset(handles); %Run PROGRAM_RESET function
                return;
            case 'Save'
                save_rating(handles);
        end
    end
    program_reset(handles); %Run PROGRAM_RESET function
    if success==1
        msgbox('Save successful.');
    else
        msgbox('Save error.');
    end
    
function program_reset(handles)
%PROGRAM_RESET Returns GUI to its default state
    set(handles.report,'string','Open File'); %Update Report window
    set(handles.filename,'string',''); %Clear Filename window
    set(handles.duration,'string',''); %Clear Duration window
    set(handles.playpause,'Enable','off','String','Play'); %Disable Play button
    set(handles.open_file,'enable','on'); %Enable Open File menu option
    set(handles.settings,'enable','on'); %Enable Settings menu option
    set(handles.about,'enable','on'); %Enable About menu option
    set(handles.slider,'Enable','Inactive'); %Disable Slider
    set(handles.slider,'Value',get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2); %Set slider to midpoint value
    drawnow; %Update GUI elements

function make_changes(Settings,handles)
%MAKE_CHANGES Applies configured settings
    axis_min = str2double(Settings.axis_min);
    axis_max = str2double(Settings.axis_max);
    axis_steps = str2double(Settings.axis_steps);
    set(handles.axis_lower,'String',Settings.axis_lower);
    set(handles.axis_upper,'String',Settings.axis_upper);
    set(handles.slider,'SliderStep',[1/(axis_steps-1) 1/(axis_steps-1)]);
    axes(handles.axis_image); %Access slider image axis
    image([colorGradient(Settings.axis_color1,Settings.axis_color2,225,70);...
        colorGradient(Settings.axis_color2,Settings.axis_color3,225,70)]);
    set(handles.slider,'Min',axis_min,'Max',axis_max);
    set(handles.slider,'Value',axis_max-(axis_max-axis_min)/2); %Set slider to midpoint value
    axis ij; hold on; %Configure axis image
    for i = 1:axis_steps-1
        plot([1,5],[450,450]*i/axis_steps,'k-'); %Plot left hash-marks on axis
        plot([65,70],[450,450]*i/axis_steps,'k-'); %Plot right hash-marks on axis
    end
    lin = linspace(axis_min,axis_max,axis_steps);
    for i = 1:length(lin)
        text(37.5,(((450*(i-1))/axis_steps)+((450*i)/axis_steps))/2,sprintf('%.2f',lin(i)),'HorizontalAlignment','center');
    end
    set(gca,'XTick',[],'YTick',[],'XLim',[0,70],'YLim',[0,450]); hold off; %Remove ticks and set limits on axis
