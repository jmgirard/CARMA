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
    handles.output = hObject;
    handles.opening = 1;
    axctl = actxcontrollist;
    index = strcmp(axctl(:,1),'Windows Media Player');
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end
    settings_Callback(hObject,[],handles);
    handles.wmp = actxcontrol(axctl{index,2},[10 60 720 480],handles.figure1);
    handles.wmp.stretchToFit = true;
    handles.wmp.uiMode = 'none';
    set(handles.wmp.settings,'autoStart',0);
    handles.opening = 0;
    guidata(hObject, handles);

function varargout = carma_OutputFcn(hObject, ~, handles) 
    varargout{1} = handles.output;

function open_file_Callback(hObject, ~, handles)
    program_reset(handles);
    [video_name,video_path] = uigetfile( ...
        {'*.*','All Files (*.*)'}, 'Select an audio or video file');
    if video_name==0, return; end
    try
        handles.wmp.URL = fullfile(video_path,video_name);
        info = mmfileinfo(fullfile(video_path,video_name));
        handles.dur = info.Duration;
    catch err
        msgbox(err.message,'Error');
        return;
    end
    set(handles.slider,'enable','on');
    set(handles.settings,'enable','on');
    set(handles.report,'string','Press Play');
    set(handles.filename,'string',video_name);
    set(handles.duration,'string',datestr(info.Duration/24/3600,'HH:MM:SS.FFF'));
    set(handles.playpause,'enable','on');
    handles.rating = [];
    guidata(hObject, handles);

function settings_Callback(hObject, ~, handles)
    prompt = inputdlg({'Top Axis Label:','Bottom Axis Label:','Slider Minimum Value:','Slider Maximum Value:','Axis Type (1=Unipolar, 2=Bipolar):','Samples per Second'},'Settings',1);
    if isempty(prompt)
        if handles.opening==1
            choice = questdlg('All options must be specified. Continue?','CARMA','Continue','Close','Continue');
            switch choice
                case 'Continue'
                    settings_Callback(hObject,[],handles);
                case 'Close'
                    quit force;
            end
        else
            return;
        end
    end
    if isempty(prompt{1}) || isempty(prompt{2}) || isempty(prompt{3}) || isempty(prompt{4}) || isempty(prompt{5}) || isempty(prompt{6})
        serror = errordlg('All options must be specified.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{3})>=str2double(prompt{4})
        serror = errordlg('Slider Maximum must be greater than Slider Minimum.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{5})~= 1 && str2double(prompt{5})~=2
        serror = errordlg('Axis Type must be 1 or 2.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{6})<0
        serror = errordlg('Sampling rate must be greater than 0 per second.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{6})>30
        serror = errordlg('Sampling rate must be less than 30 per second.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    set(handles.toplabel,'String',prompt{1});
    set(handles.botlabel,'String',prompt{2});
    set(handles.slider,'Value',str2double(prompt{4})-(str2double(prompt{4})-str2double(prompt{3}))/2,'Min',str2double(prompt{3}),'Max',str2double(prompt{4}));
    if str2double(prompt{5})==2
        image(imread('gradient2_450.png'));
    elseif str2double(prompt{5})==1
        image(imread('gradient1_450.png'));
    end
    h=450; axis ij; hold on;
    plot([1,5],[h/8,h/8],'k-'); plot([65,70],[h/8,h/8],'k-');
    plot([1,5],[h/4,h/4],'k-'); plot([65,70],[h/4,h/4],'k-');
    plot([1,5],[3*h/8,3*h/8],'k-'); plot([65,70],[3*h/8,3*h/8],'k-');
    plot([1,70],[h/2,h/2],'k-');
    plot([1,5],[5*h/8,5*h/8],'k-'); plot([65,70],[5*h/8,5*h/8],'k-');
    plot([1,5],[3*h/4,3*h/4],'k-'); plot([65,70],[3*h/4,3*h/4],'k-');
    plot([1,5],[7*h/8,7*h/8],'k-'); plot([65,70],[7*h/8,7*h/8],'k-');
    set(gca,'XTick',[],'YTick',[],'XLim',[0,70],'YLim',[0,h]);
    hold off;
    set(handles.sample,'String',prompt{6});
    guidata(hObject, handles);

function about_Callback(hObject, ~, handles)
    msgbox(sprintf('Continuous Affect Rating and Media Annotation\nhttp://carma.codeplex.com/\nVersion 1.00 <04-06-2014>'),'About CARMA','help');

function playpause_Callback(hObject, ~, handles)
    if get(hObject,'value')
        set(hObject,'enable','off');
        set(handles.open_file,'enable','off');
        set(handles.settings,'enable','off');
        set(handles.about,'enable','off');
        set(handles.report,'string','Get Ready');
        set(hObject,'string','3'); pause(1);
        set(hObject,'string','2'); pause(1);
        set(hObject,'string','1'); pause(1);
        set(hObject,'string','...');
    end
    handles.wmp.controls.play();
    sample = str2double(get(handles.sample,'string'));
    set(handles.report,'string','Use Slider');
    for i = 1:ceil(handles.dur*sample)
        handles.rating = [handles.rating; get(handles.slider,'value')];
        guidata(hObject, handles);
        pause(1/sample);
    end
    set(handles.report,'string','Processing...');
    save_rating(handles);
    
function save_rating(handles)
    [~,defaultname,~] = fileparts(get(handles.filename,'string'));
    [filename,pathname] = uiputfile({'*.xls; *.xlsx','Excel Spreadsheets (*.xls, *.xlsx)';'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
    if ~isequal(filename,0) && ~isequal(pathname,0)
        rating = handles.rating;
        output = [...
            {sprintf('Filename: %s',get(handles.filename,'string'))};...
            {sprintf('Samples per Second: %s',get(handles.sample,'string'))};...
            {sprintf('Axis Titles: %s to %s',get(handles.botlabel,'string'),get(handles.toplabel,'string'))};...
            {sprintf('Axis Range: %d to %d',get(handles.slider,'min'),get(handles.slider,'max'))};...
            num2cell(rating)];
        [~,message] = xlswrite(fullfile(pathname,filename),output);
        if strcmp(message.identifier,'MATLAB:xlswrite:dlmwrite')
            xlswrite(fullfile(pathname,filename),rating);
        end
    else
        choice = questdlg('You are about to close without saving.','CARMA','Close','Save','Save');
        switch choice
            case 'Exit'
            case 'Save'
                save_rating(handles);
        end
    end
    program_reset(handles);
    
function program_reset(handles)
    smin = get(handles.slider,'Min');
    smax = get(handles.slider,'Max');
    set(handles.report,'string','Open File');
    set(handles.filename,'string','');
    set(handles.duration,'string','');
    set(handles.playpause,'Value',0,'Enable','Inactive','String','Play');
    set(handles.open_file,'enable','on');
    set(handles.settings,'enable','on');
    set(handles.about,'enable','on');
    set(handles.slider,'Value',smax-((smax-smin)/2),'Min',smin,'Max',smax);
    drawnow;
    set(handles.slider,'Enable','Inactive');
