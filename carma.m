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
    if handles.opening==1
        defaults = {'very negative','very positive','1','9','9','2','1','1'};
        prompt = inputdlg({'Axis Lower Label:','Axis Upper Label:','Axis Minimum Value:','Axis Maximum Value:','Number of Axis Steps:','Image (1=Unipolar, 2=Bipolar, 3=Custom):','Samples per Second:','Break Rating into Segments:'},'Settings',1,defaults);
    else
        defaults = {...
            get(handles.botlabel,'String'),...
            get(handles.toplabel,'String'),...
            num2str(get(handles.slider,'Min')),...
        	num2str(get(handles.slider,'Max')),...
            get(handles.steps,'String'),...
        	get(handles.axisimage,'String'),...
            get(handles.sample,'String'),...
            get(handles.segments,'String')};
        prompt = inputdlg({'Axis Lower Label:','Axis Upper Label:','Axis Minimum Value:','Axis Maximum Value:','Number of Axis Steps:','Image (1=Unipolar, 2=Bipolar, 3=Custom):','Samples per Second:','Break Video into Segments:'},'Settings',1,defaults);
    end
    if isempty(prompt)
        if handles.opening==1
            choice = questdlg('All options must be specified. Continue?','CARMA','Continue','Exit','Continue');
            switch choice
                case 'Continue'
                    settings_Callback(hObject,[],handles);
                case 'Exit'
                    quit;
            end
        else
            return;
        end
    end
    if isempty(prompt{1}) || isempty(prompt{2}) || isempty(prompt{3}) || isempty(prompt{4}) || isempty(prompt{5}) || isempty(prompt{6}) || isempty(prompt{7}) || isempty(prompt{8})
        serror = errordlg('All options must be specified.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{3})>=str2double(prompt{4})
        serror = errordlg('Axis Maximum must be greater than Axis Minimum.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if isnan(str2double(prompt{5})) || str2double(prompt{5})<=1 || ceil(str2double(prompt{5}))~=floor(str2double(prompt{5}))
        serror = errordlg('Number of Axis Steps must be a positive integer greater than 1.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{6})~= 1 && str2double(prompt{6})~=2 && str2double(prompt{6})~=3
        serror = errordlg('Image must be 1, 2, or 3.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if isnan(str2double(prompt{7}))
        serror = errordlg('Samples per Second must be numerical.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{7})<=0
        serror = errordlg('Samples per Second must be greater than 0.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if str2double(prompt{7})>30
        serror = errordlg('Samples per Second must be less than 30.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    if isnan(str2double(prompt{8})) || str2double(prompt{8})<=0 || ceil(str2double(prompt{8}))~=floor(str2double(prompt{8}))
        serror = errordlg('Number of Segments must be a positive integer.');
        uiwait(serror); settings_Callback(hObject,[],handles);
        return;
    end
    set(handles.botlabel,'String',prompt{1});
    set(handles.toplabel,'String',prompt{2});
    set(handles.steps,'String',prompt{5});
    set(handles.axisimage,'String',prompt{6});
    set(handles.sample,'String',prompt{7});
    set(handles.segments,'String',prompt{8});
    steps = str2double(prompt{5});
    set(handles.slider,...
        'Min',str2double(prompt{3}),...
        'Max',str2double(prompt{4}),...
        'SliderStep',[1/(steps-1) 1/(steps-1)]);
    axes(handles.gaxis);
    if str2double(prompt{6})==1
        image(imread('gradient1_450.png'));
        set(handles.slider,'Value',str2double(prompt{3}));
    elseif str2double(prompt{6})==2
        image(imread('gradient2_450.png'));
        set(handles.slider,'Value',str2double(prompt{4})-(str2double(prompt{4})-str2double(prompt{3}))/2);
    elseif str2double(prompt{6})==3
        set(handles.slider,'Value',str2double(prompt{3}));
        [imfile,impath] = uigetfile(...
            {'*.bmp;*.gif;*.hdf;*.jpg;*.jpeg;*.pcx;*.png;*.tif;*.tiff;*.xwd','Image Files (*.bmp;*.gif;*.hdf;*.jpg;*.jpeg;*.pcx;*.png;*.tif;*.tiff;*.xwd)'},...
            'Select a custom gradient image (450x70 px):');
        if ~isequal(imfile,0)
            cgradient = imread(fullfile(impath,imfile));
            cgradient = imresize(cgradient,[450 70]);
            image(cgradient);
        else
            image(imread('gradient1_450.png'));
        end
    end
    axis ij; hold on;
    for i = 1:steps-1
        plot([1,5],[450,450]*i/steps,'k-');
        plot([65,70],[450,450]*i/steps,'k-');
    end
    set(gca,'XTick',[],'YTick',[],'XLim',[0,70],'YLim',[0,450]);
    hold off;
    guidata(hObject, handles);

function about_Callback(hObject, ~, handles)
    msgbox(sprintf('Continuous Affect Rating and Media Annotation\nhttp://carma.codeplex.com/\nVersion 2.00 <05-05-2014>\nGNU General Public License v3'),'About CARMA','help');

function playpause_Callback(hObject, ~, handles)
    set(hObject,'enable','off');
    set(handles.open_file,'enable','off');
    set(handles.settings,'enable','off');
    set(handles.about,'enable','off');
    segments = str2double(get(handles.segments,'string'));
    sample = str2double(get(handles.sample,'string'));
    seconds = handles.dur/segments;
    for i = 1:segments
        set(handles.report,'string','Get Ready');
        set(hObject,'string','3'); pause(1);
        set(hObject,'string','2'); pause(1);
        set(hObject,'string','1'); pause(1);
        set(hObject,'string','...');
        set(handles.report,'string','Use Slider');
        temp_ratings = zeros(ceil(seconds*sample),1);
        handles.wmp.controls.play();
        for j = 1:ceil(seconds*sample)
            temp_ratings(j) = get(handles.slider,'value');
            pause(1/sample);
        end
        handles.wmp.controls.pause();
        handles.rating = [handles.rating; temp_ratings];
        guidata(hObject, handles);
        if i ~= segments
            resume = msgbox(sprintf('End of rating segment #%02d/%02d\nClick OK when ready to resume.',i,segments),'CARMA');
            uiwait(resume);
        end
    end
    set(handles.report,'string','Processing...');
    guidata(hObject, handles);
    save_rating(handles);
    handles.wmp.controls.stop();
    
function save_rating(handles)
    [~,defaultname,~] = fileparts(get(handles.filename,'string'));
    [filename,pathname] = uiputfile({'*.xls; *.xlsx','Excel Spreadsheets (*.xls, *.xlsx)';'*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
    if ~isequal(filename,0) && ~isequal(pathname,0)
        rating = handles.rating;
        output = [...
            {sprintf('Filename: %s',get(handles.filename,'string'))};...
            {sprintf('Axis Labels: %s to %s',get(handles.botlabel,'string'),get(handles.toplabel,'string'))};...
            {sprintf('Axis Range: %d to %d',get(handles.slider,'min'),get(handles.slider,'max'))};...
            {sprintf('Axis Image: %s',get(handles.axisimage,'string'))};...
            {sprintf('Number of Axis Steps: %s',get(handles.steps,'string'))};...
            {sprintf('Samples per Second: %s',get(handles.sample,'string'))};...
            num2cell(rating)];
        [~,~,ext] = fileparts(filename);
        if strcmpi(ext,'.XLS') || strcmpi(ext,'.XLSX')
            [~,message] = xlswrite(fullfile(pathname,filename),output);
            if strcmp(message.identifier,'MATLAB:xlswrite:dlmwrite')
                serror = errordlg('Exporting to .XLS/.XLSX requires Microsoft Excel to be installed. CARMA will now export to .CSV instead.');
                uiwait(serror);
                csvwrite(fullfile(pathname,filename),rating);
            end
        elseif strcmpi(ext,'.CSV')
            csvwrite(fullfile(pathname,filename),rating);
        end
    else
        choice = questdlg('You are about to close without saving.','CARMA','Close','Save','Save');
        switch choice
            case 'Close'
            case 'Save'
                save_rating(handles);
        end
    end
    program_reset(handles);
    
function program_reset(handles)
    set(handles.report,'string','Open File');
    set(handles.filename,'string','');
    set(handles.duration,'string','');
    set(handles.playpause,'Enable','off','String','Play');
    set(handles.open_file,'enable','on');
    set(handles.settings,'enable','on');
    set(handles.about,'enable','on');
    set(handles.slider,'Enable','Inactive');
    if strcmp(get(handles.axisimage,'string'),'2')
        set(handles.slider,'Value',get(handles.slider,'Max')-(get(handles.slider,'Max')-get(handles.slider,'Min'))/2);
    else
        set(handles.slider,'Value',get(handles.slider,'Min'));
    end
    drawnow;
