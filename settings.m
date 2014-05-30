function varargout = settings(varargin)
%SETTINGS Code for the Settings window and functions
% Jeffrey M Girard, 05/2014
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

function settings_OpeningFcn(hObject, eventdata, handles, varargin)
%SETTINGS_OPENINGFCN Executes when settings window is opened
handles.output = hObject;
% Find handle for main CARMA window
mainGuiInput = find(strcmp(varargin,'carma'));
handles.carma = varargin{mainGuiInput+1};
% Load current settings or, if missing, default settings
if exist('settings.mat','file')~=0
    Settings = importdata('settings.mat');
else
    Settings = importdata('default.mat');
    save('settings.mat','Settings');
end
set(handles.axis_lower,'String',Settings.axis_lower);
set(handles.axis_upper,'String',Settings.axis_upper);
set(handles.axis_color1,'BackgroundColor',Settings.axis_color1);
set(handles.axis_color2,'BackgroundColor',Settings.axis_color2);
set(handles.axis_color3,'BackgroundColor',Settings.axis_color3);
set(handles.axis_min,'String',Settings.axis_min);
set(handles.axis_max,'String',Settings.axis_max);
set(handles.axis_steps,'String',Settings.axis_steps);
guidata(hObject,handles);

function varargout = settings_OutputFcn(hObject, eventdata, handles) 
%SETTINGS_OUTPUTFCN Executes when Settings window is closed
varargout{1} = handles.output;

function Settings = get_settings(handles)
%GET_SETTINGS Creates Settings variable from current configuration

% Get current configuration
Settings.axis_lower = get(handles.axis_lower,'string');
Settings.axis_upper = get(handles.axis_upper,'string');
Settings.axis_color1 = get(handles.axis_color1,'BackgroundColor');
Settings.axis_color2 = get(handles.axis_color2,'BackgroundColor');
Settings.axis_color3 = get(handles.axis_color3,'BackgroundColor');
Settings.axis_min = get(handles.axis_min,'string');
Settings.axis_max = get(handles.axis_max,'string');
Settings.axis_steps = get(handles.axis_steps,'string');
% Check for errors in configuration
if isempty(Settings.axis_min) || isempty(Settings.axis_max) || isempty(Settings.axis_steps)
    serror = errordlg('All options must be specified.');
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

function axis_color1_Callback(hObject, eventdata, handles)
%AXIS_COLOR1_CALLBACK Prompts user to select a color
c = uisetcolor('Select the upper color.');
set(hObject,'BackgroundColor',c);

function axis_color2_Callback(hObject, eventdata, handles)
%AXIS_COLOR2_CALLBACK Prompts user to select a color
c = uisetcolor('Select the lower color.');
set(hObject,'BackgroundColor',c);

function axis_color3_Callback(hObject, eventdata, handles)
%AXIS_COLOR3_CALLBACK Prompts user to select a color
c = uisetcolor('Select the lower color.');
set(hObject,'BackgroundColor',c);

function button_cancel_Callback(hObject, eventdata, handles)
%BUTTON_CANCEL_CALLBACK Closes the settings window
close;

function button_default_Callback(hObject, eventdata, handles)
%BUTTON_DEFAULT_CALLBACK Saves current configuration as default
Settings = get_settings(handles);
save('default.mat','Settings');
msgbox('Current settings saved as default.');

function button_apply_Callback(hObject, eventdata, handles)
%BUTTON_APPLY_CALLBACK Applies current configuration to carma window
Settings = get_settings(handles);
save('settings.mat','Settings');
close;