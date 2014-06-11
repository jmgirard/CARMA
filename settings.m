function varargout = settings(varargin)
%SETTINGS Code for the Settings window and functions
% License: https://carma.codeplex.com/license

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @settings_OpeningFcn, ...
                   'gui_OutputFcn',  @settings_OutputFcn, ...
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

% --- Executes just before figure_settings is made visible.
function settings_OpeningFcn(hObject, eventdata, handles, varargin)
    % Initialize GUI Data
    handles.output = hObject;
    movegui(gcf,'center');
    guidata(hObject,handles);
    % Find handle for main CARMA window
    mainGuiInput = find(strcmp(varargin,'carma'));
    handles.carma = varargin{mainGuiInput+1};
    % Load current settings or, if missing, default settings
    if exist(fullfile(ctfroot,'settings.mat'),'file')~=0
        Settings = importdata(fullfile(ctfroot,'settings.mat'));
    else
        Settings = importdata(fullfile(ctfroot,'default.mat'));
        save(fullfile(ctfroot,'settings.mat'),'Settings');
    end
    % Populate settings options with appropriate text/colors
    set(handles.text_axis_lower,'String',Settings.axis_lower);
    set(handles.text_axis_upper,'String',Settings.axis_upper);
    set(handles.button_axis_color1,'BackgroundColor',Settings.axis_color1);
    set(handles.button_axis_color2,'BackgroundColor',Settings.axis_color2);
    set(handles.button_axis_color3,'BackgroundColor',Settings.axis_color3);
    set(handles.text_axis_min,'String',Settings.axis_min);
    set(handles.text_axis_max,'String',Settings.axis_max);
    set(handles.text_axis_steps,'String',Settings.axis_steps);
    guidata(hObject,handles);

% --- Outputs from this function are returned to the command line.
function varargout = settings_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;

% --- Called from multiple other functions.
function Settings = get_settings(handles)
    % Get current configuration from GUI elements
    Settings.axis_lower = get(handles.text_axis_lower,'string');
    Settings.axis_upper = get(handles.text_axis_upper,'string');
    Settings.axis_color1 = get(handles.button_axis_color1,'BackgroundColor');
    Settings.axis_color2 = get(handles.button_axis_color2,'BackgroundColor');
    Settings.axis_color3 = get(handles.button_axis_color3,'BackgroundColor');
    Settings.axis_min = get(handles.text_axis_min,'string');
    Settings.axis_max = get(handles.text_axis_max,'string');
    Settings.axis_steps = get(handles.text_axis_steps,'string');
    % Check for errors in configuration
    if isempty(Settings.axis_min) || isempty(Settings.axis_max) || isempty(Settings.axis_steps)
        serror = errordlg('All numerical options must be specified.');
        uiwait(serror); return;
    end
    if str2double(Settings.axis_min) >= str2double(Settings.axis_max)
        serror = errordlg('Maximum Value must be greater than Minimum Value.');
        uiwait(serror); return;
    end
    steps = str2double(Settings.axis_steps);
    if isnan(steps) || steps <= 1 || ceil(steps) ~= floor(steps)
        serror = errordlg('Number of Axis Steps must be a positive integer greater than 1.');
        uiwait(serror); return;
    end

% --- Executes on button press in button_axis_color1.
function button_axis_color1_Callback(hObject, eventdata, handles)
    % Prompt the user to select a color and recolor the button
    c = uisetcolor('Select the upper color.');
    set(hObject,'BackgroundColor',c);

% --- Executes on button press in button_axis_color2.
function button_axis_color2_Callback(hObject, eventdata, handles)
    % Prompt the user to select a color and recolor the button
    c = uisetcolor('Select the lower color.');
    set(hObject,'BackgroundColor',c);

% --- Executes on button press in button_axis_color3.
function button_axis_color3_Callback(hObject, eventdata, handles)
    % Prompt the user to select a color and recolor the button
    c = uisetcolor('Select the lower color.');
    set(hObject,'BackgroundColor',c);

% --- Executes on button press in button_load_defaults.
function button_load_defaults_Callback(hObject, eventdata, handles)
    % Load Default Settings
    Settings = importdata(fullfile(ctfroot,'default.mat'));
    % Populate settings options with appropriate text/colors
    set(handles.text_axis_lower,'String',Settings.axis_lower);
    set(handles.text_axis_upper,'String',Settings.axis_upper);
    set(handles.button_axis_color1,'BackgroundColor',Settings.axis_color1);
    set(handles.button_axis_color2,'BackgroundColor',Settings.axis_color2);
    set(handles.button_axis_color3,'BackgroundColor',Settings.axis_color3);
    set(handles.text_axis_min,'String',Settings.axis_min);
    set(handles.text_axis_max,'String',Settings.axis_max);
    set(handles.text_axis_steps,'String',Settings.axis_steps);
    guidata(hObject,handles);

% --- Executes on button press in button_save_default.
function button_save_default_Callback(hObject, eventdata, handles)
    % Save the current configuration as default settings
    Settings = get_settings(handles);
    save(fullfile(ctfroot,'default.mat'),'Settings');
    msgbox('Current settings saved as default.');

% --- Executes on button press in button_apply_changes.
function button_apply_changes_Callback(hObject, eventdata, handles)
    % Save the current configuration as current and close Settings window
    Settings = get_settings(handles);
    save(fullfile(ctfroot,'settings.mat'),'Settings');
    close;
