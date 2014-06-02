function varargout = annotations(varargin)
%FIGURE_ANNOTATIONS Code for the figure_annotations window and functions
% License: https://carma.codeplex.com/license

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotations_OpeningFcn, ...
                   'gui_OutputFcn',  @annotations_OutputFcn, ...
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

% --- Executes just before figure_annotations is made visible.
function annotations_OpeningFcn(hObject, eventdata, handles, varargin)
    % Initialize GUI data
    handles.output = hObject;
    movegui(gcf,'center');
    guidata(hObject, handles);
    % Write input variables to GUI data
    handles.Settings = varargin{find(strcmp(varargin,'Settings'))+1};
    handles.Ratings = varargin{find(strcmp(varargin,'Ratings'))+1};
    handles.URL = varargin{find(strcmp(varargin,'URL'))+1};
    handles.duration = varargin{find(strcmp(varargin,'Duration'))+1};
    % Check for and find Window Media Player (WMP) ActiveX Controller
    axctl = actxcontrollist;
    index = strcmp(axctl(:,1),'Windows Media Player');
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end
    % Invoke and configure WMP
    handles.wmp2 = actxcontrol(axctl{index,2},[10 110 720 480],handles.figure_annotations);
    handles.wmp2.stretchToFit = true;
    handles.wmp2.uiMode = 'none';
    set(handles.wmp2.settings,'autoStart',0);
    handles.wmp2.URL = handles.URL;
    % Plot all ratings in axis_annotations
    axes(handles.axis_annotations);
    plot(handles.Ratings(:,2),'LineWidth',2);
    ylim([str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)]);
    xlim([0,ceil(handles.duration)+1]);
    guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = annotations_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

% --- Executes on button press in toggle_playpause.
function toggle_playpause_Callback(hObject, eventdata, handles)
    if get(hObject,'Value')
        % If toggle is set to play, send play() command to WMP
        handles.wmp2.controls.play();
        while ~strcmp(handles.wmp2.playState,'wmppsPlaying'), pause(0.01); end
        % Update GUI elements
        set(hObject,'String','Pause');
        axes(handles.axis_annotations);
        % While playing, plot current ratings in axis_annotations
        while strcmp(handles.wmp2.playState,'wmppsPlaying') && get(hObject,'Value')
            pause(0.1);
            ts = handles.wmp2.controls.currentPosition;
            plot(handles.axis_annotations,[ts,ts],[str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)],'k','LineWidth',1); hold on;
            plot(handles.axis_annotations,handles.Ratings(:,2),'b','LineWidth',2); hold off;
            xlim([ts-5,ts+5]);
            drawnow;
        end
        if get(hObject,'Value')
            % When done, send stop() command to WMP
            handles.wmp2.controls.stop();
            set(hObject,'String','Play');
            % Plot all ratings in axis_annotations
            axes(handles.axis_annotations);
            plot(handles.Ratings(:,2),'LineWidth',2);
            ylim([str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)]);
            xlim([0,ceil(handles.duration)+1]);
        end
    else
        % If toggle is set to pause, send pause() command to WMP
        handles.wmp2.controls.pause();
        set(hObject,'String','Play');
    end
    guidata(hObject, handles);

% --- Executes on button press in button_export.
function button_export_Callback(hObject, eventdata, handles)
    % Prompt user for export filepath
    axis_min = str2double(handles.Settings.axis_min);
    axis_max = str2double(handles.Settings.axis_max);
    axis_steps = str2double(handles.Settings.axis_steps);
    [~,defaultname,~] = fileparts(handles.URL);
    [filename,pathname] = uiputfile({'*.xls; *.xlsx','Excel Spreadsheets (*.xls, *.xlsx)';...
        '*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
    if ~isequal(filename,0) && ~isequal(pathname,0)
        % Add metadata to mean ratings and timestamps
        output = [...
            {'Filename','Lower Label','Upper Label','Minimum Value','Midpoint Value','Maximum Value','Number of Steps','Second','Rating'};...
            cellstr(repmat(handles.URL,size(handles.Ratings,1),1)),...
            cellstr(repmat(handles.Settings.axis_lower,size(handles.Ratings,1),1)),...
            cellstr(repmat(handles.Settings.axis_upper,size(handles.Ratings,1),1)),...
            num2cell(repmat(axis_min,size(handles.Ratings,1),1)),...
            num2cell(repmat(axis_max-(axis_max-axis_min)/2,size(handles.Ratings,1),1)),...
            num2cell(repmat(axis_max,size(handles.Ratings,1),1)),...            
            num2cell(repmat(axis_steps,size(handles.Ratings,1),1)),...
            num2cell(handles.Ratings)];
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
            msgbox('Export successful.');
        else
            msgbox('Export error.');
        end
    end
