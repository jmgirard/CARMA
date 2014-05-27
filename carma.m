function varargout = carma(varargin)
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
    handles.opening = 1; %Turn opening flag on (for use in SETTINGS_CALLBACK)
    axctl = actxcontrollist; %Find ActiveX Controllers
    index = strcmp(axctl(:,1),'Windows Media Player'); %Find WMP ActiveX Controller
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end %Quit if not found
    settings_Callback(hObject,[],handles); %Run SETTINGS_CALLBACK
    handles.wmp = actxcontrol(axctl{index,2},[10 60 720 480],handles.figure1); %Create WMP window
    handles.wmp.stretchToFit = true; %Configure WMP Settings
    handles.wmp.uiMode = 'none'; %Configure WMP Settings
    set(handles.wmp.settings,'autoStart',0); %Configure WMP Settings
    handles.opening = 0; %Turn opening flag off (for use in SETTINGS_CALLBACK)
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
    handles.rating = []; %Initialize rating vector
    guidata(hObject, handles); %Update GUI data

function settings_Callback(hObject, ~, handles)
%SETTINGS_CALLBACK Runs when selecting the Settings menu option
    if handles.opening==1 %If called from CARMA_OPENINGFNC...
        if exist('default.mat','file')~=0 
            prompt = importdata('default.mat'); %Try to load default settings from default.mat
        else
            prompt = {'very negative','very positive','1','9','9','2','1','1'}; %If failed, use these
        end
    else %If called from the Settings button...
        defaults = {... %Load default options from current settings
            get(handles.botlabel,'String'),...
            get(handles.toplabel,'String'),...
            num2str(get(handles.slider,'Min')),...
        	num2str(get(handles.slider,'Max')),...
            get(handles.steps,'String'),...
        	get(handles.axisimage,'String'),...
            get(handles.sample,'String'),...
            get(handles.segments,'String')};
        prompt = inputdlg(... %Prompt user to change or accept settings
            {'Axis Lower Label:',...
            'Axis Upper Label:',...
            'Axis Minimum Value:',...
            'Axis Maximum Value:',...
            'Number of Axis Steps:',...
            'Image (1=Unipolar, 2=Bipolar, 3=Custom):',...
            'Samples per Second:',...
            'Break Video into Segments:'},...
            'Settings',1,defaults);
    end
    if isempty(prompt), return; end %Cancel function if prompt is exited
    if isempty(prompt{1}) || isempty(prompt{2}) || isempty(prompt{3}) || isempty(prompt{4}) || isempty(prompt{5}) || isempty(prompt{6}) || isempty(prompt{7}) || isempty(prompt{8})
        %Cancel function if any options are empty
        serror = errordlg('All options must be specified.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{3})>=str2double(prompt{4})
        %Cancel function if axis minimum is greater than or equal to axis maximum
        serror = errordlg('Axis Maximum must be greater than Axis Minimum.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if isnan(str2double(prompt{5})) || str2double(prompt{5})<=1 || ceil(str2double(prompt{5}))~=floor(str2double(prompt{5}))
        %Cancel function if number of axis steps is not a positive integer greater than 1
        serror = errordlg('Number of Axis Steps must be a positive integer greater than 1.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{6})~= 1 && str2double(prompt{6})~=2 && str2double(prompt{6})~=3
        %Cancel function if image value is not 1, 2, or 3
        serror = errordlg('Image must be 1, 2, or 3.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if isnan(str2double(prompt{7}))
        %Cancel function if samples per second is not a number
        serror = errordlg('Samples per Second must be numerical.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{7})<=0
        %Cancel function if samples per second is less than or equal to 0
        serror = errordlg('Samples per Second must be greater than 0.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{7})>30
        %Cancel function if samples per second is greater than 30
        serror = errordlg('Samples per Second must be less than 30.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if isnan(str2double(prompt{8})) || str2double(prompt{8})<=0 || ceil(str2double(prompt{8}))~=floor(str2double(prompt{8}))
        %Cancel function if number of segments is not a positive integer
        serror = errordlg('Number of Segments must be a positive integer.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    set(handles.botlabel,'String',prompt{1}); %Set axis lower label
    set(handles.toplabel,'String',prompt{2}); %Set axis upper label
    set(handles.steps,'String',prompt{5}); %Save number of steps to a hidden field
    set(handles.axisimage,'String',prompt{6});  %Save axis image to a hidden field
    set(handles.sample,'String',prompt{7});  %Save sampling rate to a field
    set(handles.segments,'String',prompt{8});  %Save number of segments to a hidden field
    steps = str2double(prompt{5}); %Convert number of steps to a number
    set(handles.slider,...
        'Min',str2double(prompt{3}),... %Set slider minimum value
        'Max',str2double(prompt{4}),... %Set slider maximum value
        'SliderStep',[1/(steps-1) 1/(steps-1)]); %Set number of steps
    axes(handles.gaxis); %Access slider image axis
    if str2double(prompt{6})==1 
        image(imread('gradient1_450.png')); %If axis image 1, display gradient1_450
        set(handles.slider,'Value',str2double(prompt{3})); %Set slider to minimum value
    elseif str2double(prompt{6})==2
        image(imread('gradient2_450.png')); %If axis image 2, display gradient2_450
        set(handles.slider,'Value',str2double(prompt{4})-(str2double(prompt{4})-str2double(prompt{3}))/2); %Set slider to midpoint value
    elseif str2double(prompt{6})==3
        set(handles.slider,'Value',str2double(prompt{3})); %If axis image 3, set slider to minimum value
        [imfile,impath] = uigetfile(... %Prompt user for a custom image
            {'*.bmp;*.gif;*.hdf;*.jpg;*.jpeg;*.pcx;*.png;*.tif;*.tiff;*.xwd','Image Files (*.bmp;*.gif;*.hdf;*.jpg;*.jpeg;*.pcx;*.png;*.tif;*.tiff;*.xwd)'},...
            'Select a custom gradient image (450x70 px):');
        if ~isequal(imfile,0)
            cgradient = imread(fullfile(impath,imfile)); %Load custom image
            cgradient = imresize(cgradient,[450 70]); %Resize custom image
            image(cgradient); %Display custom image
        else
            image(imread('gradient1_450.png')); %If no file, display gadient1_450
        end
    end
    axis ij; hold on; %Configure axis image
    for i = 1:steps-1
        plot([1,5],[450,450]*i/steps,'k-'); %Plot left hash-marks on axis
        plot([65,70],[450,450]*i/steps,'k-'); %Plot right hash-marks on axis
    end
    set(gca,'XTick',[],'YTick',[],'XLim',[0,70],'YLim',[0,450]); hold off; %Remove ticks and set limits on axis
    guidata(hObject, handles); %Update GUI data
    if handles.opening == 0
        savedefault = questdlg('Save these settings as the default settings?', ...
            'Save Settings?','Yes','No','Cancel','Yes'); %Prompt user to save settings as default
        switch savedefault
            case 'Yes'
                save('default.mat','prompt'); %Save settings to default.mat
            case 'No'
            case 'Cancel'
                return; %Cancel function if cancel is selected
        end
    end

function about_Callback(hObject, ~, handles)
%ABOUT_CALLBACK Runs when selecting About menu option
    line1 = 'Continuous Affect Rating and Media Annotation';
    line2 = 'http://carma.codeplex.com/';
    line3 = 'Version 2.01 <05-27-2014>';
    line4 = 'GNU General Public License v3';
    msgbox(sprintf('%s\n%s\n%s\n%s',line1,line2,line3,line4),'About CARMA','help'); %Display CARMA information

function playpause_Callback(hObject, ~, handles)
%PLAYPAUSE_CALLBACK Runs when selecting the Play button
    set(hObject,'enable','off'); %Disable the Play button
    set(handles.open_file,'enable','off'); %Disable the Open File menu option
    set(handles.settings,'enable','off'); %Disable the Settings menu option
    set(handles.about,'enable','off'); %Disable the About menu option
    segments = str2double(get(handles.segments,'string')); %Get number of segments
    sample = str2double(get(handles.sample,'string')); %Get sampling rate
    seconds = handles.dur/segments; %Calculate number of seconds per segment
    for i = 1:segments %Loop through each segment
        set(handles.report,'string','Get Ready'); %Update Report window
        set(hObject,'string','3'); pause(1); %Countdown on Play button
        set(hObject,'string','2'); pause(1); %Countdown on Play button
        set(hObject,'string','1'); pause(1); %Countdown on Play button
        set(hObject,'string','...'); %Update Play button
        set(handles.report,'string','Use Slider'); %Update Report window
        temp_ratings = zeros(ceil(seconds*sample),1); %Preallocate temporary ratings vector
        handles.wmp.controls.play(); %Send play command to WMP ActiveX Controller
        for j = 1:ceil(seconds*sample) %Loop through each sampling in current segment
            temp_ratings(j) = get(handles.slider,'value'); %Write current slider value to temporary ratings vector
            pause(1/sample); %Wait a length of time according to sampling rate
        end
        handles.wmp.controls.pause(); %Send pause command to WMP ActiveX Controller
        handles.rating = [handles.rating; temp_ratings]; %Add temporary ratings vector to overall ratings vector
        guidata(hObject, handles); %Update GUI data
        if i ~= segments  %If not the final segment, wait for user to resume rating
            resume = msgbox(sprintf('End of rating segment #%02d/%02d\nClick OK when ready to resume.',i,segments),'CARMA');
            uiwait(resume);
        end
    end
    set(handles.report,'string','Processing...'); %Update Report window
    guidata(hObject, handles); %Update GUI data
    save_rating(handles); %Run SAVE_RATING function
    handles.wmp.controls.stop(); %Send stop command to WMP ActiveX Controller
    
function save_rating(handles)
%SAVE_RATING Runs at the completion of rating
    [~,defaultname,~] = fileparts(get(handles.filename,'string')); %Get multimedia file name without path or extensions
    [filename,pathname] = uiputfile({'*.xls; *.xlsx','Excel Spreadsheets (*.xls, *.xlsx)';'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname); %Prompt user for save path
    if ~isequal(filename,0) && ~isequal(pathname,0)
        rating = handles.rating; %Get ratings vector
        output = [... %Add metadata to ratings vector
            {sprintf('Filename: %s',get(handles.filename,'string'))};...
            {sprintf('Axis Labels: %s to %s',get(handles.botlabel,'string'),get(handles.toplabel,'string'))};...
            {sprintf('Axis Range: %d to %d',get(handles.slider,'min'),get(handles.slider,'max'))};...
            {sprintf('Axis Image: %s',get(handles.axisimage,'string'))};...
            {sprintf('Number of Axis Steps: %s',get(handles.steps,'string'))};...
            {sprintf('Samples per Second: %s',get(handles.sample,'string'))};...
            num2cell(rating)];
        [~,~,ext] = fileparts(filename);
        if strcmpi(ext,'.XLS') || strcmpi(ext,'.XLSX')
            [~,message] = xlswrite(fullfile(pathname,filename),output); %Write output to Excel spreadsheet
            if strcmp(message.identifier,'MATLAB:xlswrite:dlmwrite')
                serror = errordlg('Exporting to .XLS/.XLSX requires Microsoft Excel to be installed. CARMA will now export to .CSV instead.');
                uiwait(serror);
                csvwrite(fullfile(pathname,filename),rating); %If no Excel, write output to CSV instead
            end
        elseif strcmpi(ext,'.CSV')
            csvwrite(fullfile(pathname,filename),rating); %Write output to CSV
        end
    else
        choice = questdlg('You are about to close without saving.','CARMA','Close','Save','Save'); %Ask user to confirm closing without saving
        switch choice
            case 'Close'
            case 'Save'
                save_rating(handles);
        end
    end
    program_reset(handles); %Run PROGRAM_RESET function
    
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
    if strcmp(get(handles.axisimage,'string'),'2')
        set(handles.slider,'Value',get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2); %If axis image 2, set slider to midpoint value
    else
        set(handles.slider,'Value',get(handles.slider,'Min')); %Otherwise, set slider to minimum value
    end
    drawnow; %Update GUI elements
