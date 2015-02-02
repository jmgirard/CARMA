function fig_configure
%FIG_CONFIGURE Window for the configuration of settings
%   License: https://carma.codeplex.com/license

    global settings;
    % Create and maximize annotation window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_configure = figure( ...
        'Name','CARMA: Configure', ...
        'Units','pixels', ...
        'Position',[0 0 550 350], ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Visible','off', ...
        'Color',defaultBackground);
    movegui(handles.figure_configure,'center');
    c1 = .02; w = c1+.92*2/3; c2 = c1*2+w;
    handles.panel_slider = uipanel( ...
        'Parent',handles.figure_configure, ...
        'Units','Normalized', ...
        'Position',[c1 .40 w .55]);
    handles.panel_scale = uipanel( ...
        'Parent',handles.figure_configure, ...
        'Units','Normalized', ...
        'Position',[c2 .40 1-c2-c1 .55]);
    handles.panel_sampling = uipanel( ...
        'Parent',handles.figure_configure, ...
        'Position',[c1 .25 c1*2+.92 .1]);
    handles.push_submit = uicontrol(...
        'Parent',handles.figure_configure, ...
        'Units','Normalized', ...
        'Position',[c1*3+.92*2/3 .05 .92/3 .15], ...
        'String','Apply Current Settings', ...
        'Callback',@push_submit_Callback);
    % Create uicontrol elements in panel_slider
    nr = 5; %number of rows
    nc = 2; %number of columns
    sh = .015; %horizontal spacing
    sv = .05; %vertical spacing
    w = (1-sh*(nc+1))/nc;
    h = (1-sv*(nr+1))/nr;
    c1 = sh; c2 = c1+w+sh;
    r5 = sv; r4 = r5+h+sv; r3 = r4+h+sv; r2 = r3+h+sv; r1 = r2+h+sv;
    % Text label and control for text_axis_min
    uicontrol(handles.panel_slider, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1 r1 w h], ...
        'String','Axis Upper Label', ...
        'HorizontalAlign','left');
    handles.text_axis_upper = uicontrol(handles.panel_slider, ...
        'Style','edit', ...
        'Units','normalized', ...
        'Position',[c2 r1 w h], ...
        'BackgroundColor',[1 1 1], ...
        'String',settings.axis_upper);
    % Text label and control for text_axis_max
    uicontrol(handles.panel_slider, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1 r2 w h], ...
        'String','Axis Maximum Value', ...
        'HorizontalAlign','left');
    handles.text_axis_max = uicontrol(handles.panel_slider, ...
        'Style','edit', ...
        'Units','normalized', ...
        'Position',[c2 r2 w h], ...
        'BackgroundColor',[1 1 1], ...
        'String',num2str(settings.axis_max));
    % Text label and control for text_axis_steps
    uicontrol(handles.panel_slider, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1 r3 w h], ...
        'String','Number of Steps', ...
        'HorizontalAlign','left');
    handles.text_axis_steps = uicontrol(handles.panel_slider, ...
        'Style','edit', ...
        'Units','normalized', ...
        'Position',[c2 r3 w h], ...
        'BackgroundColor',[1 1 1], ...
        'String',num2str(settings.axis_steps));
    % Text label and control for text_axis_min
    uicontrol(handles.panel_slider, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1 r4 w h], ...
        'String','Axis Minimum Value', ...
        'HorizontalAlign','left');
    handles.text_axis_min = uicontrol(handles.panel_slider, ...
        'Style','edit', ...
        'Units','normalized', ...
        'Position',[c2 r4 w h], ...
        'BackgroundColor',[1 1 1], ...
        'String',num2str(settings.axis_min));
    % Text label and control for text_axis_lower
    uicontrol(handles.panel_slider, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1 r5 w h], ...
        'String','Axis Lower Label', ...
        'HorizontalAlign','left');
    handles.text_axis_lower = uicontrol(handles.panel_slider, ...
        'Style','edit', ...
        'Units','normalized', ...
        'Position',[c2 r5 w h], ...
        'BackgroundColor',[1 1 1], ...
        'String',settings.axis_lower);
    % Create color gradient buttons
    uicontrol(handles.panel_scale, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1*2 r1 1-c1*4 h], ...
        'String','Color Gradient', ...
        'HorizontalAlign','center');
    handles.button_axis_color1 = uicontrol(handles.panel_scale, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[c1*2 r2 1-c1*4 h], ...
        'String','Upper Color', ...
        'BackgroundColor',settings.axis_color1, ...
        'Callback',@button_axis_color_Callback);
    handles.button_axis_color2 = uicontrol(handles.panel_scale, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[c1*2 r3 1-c1*4 h], ...
        'String','Middle Color', ...
        'BackgroundColor',settings.axis_color2, ...
        'Callback',@button_axis_color_Callback);
    handles.button_axis_color3 = uicontrol(handles.panel_scale, ...
        'Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[c1*2 r4 1-c1*4 h], ...
        'String','Lower Color', ...
        'BackgroundColor',settings.axis_color3, ...
        'Callback',@button_axis_color_Callback);
    % Create sampling controls
    uicontrol(handles.panel_sampling, ...
        'Style','text', ...
        'Units','normalized', ...
        'Position',[c1 -.2 1/3 1], ...
        'String','Samples per Second', ...
        'HorizontalAlign','left');
    handles.bgroup_samples = uibuttongroup(handles.panel_sampling, ...
        'Units','normalized', ...
        'Position',[c1+1/3 0 2/3-c1 1], ...
        'BorderType','none', ...
        'Visible','off');
    handles.sample_1per4 = uicontrol(handles.bgroup_samples, ...
        'Style','radiobutton', ...
        'Units','normalized', ...
        'Position',[.02 0 1/5 1], ...
        'String','0.25', ...
        'HandleVisibility','off');
    handles.sample_1per2 = uicontrol(handles.bgroup_samples, ...
        'Style','radiobutton', ...
        'Units','normalized', ...
        'Position',[.02+1/5 0 1/5 1], ...
        'String','0.50', ...
        'HandleVisibility','off');
    handles.sample_1per1 = uicontrol(handles.bgroup_samples, ...
        'Style','radiobutton', ...
        'Units','normalized', ...
        'Position',[.02+2/5 0 1/5 1], ...
        'String','1.00', ...
        'HandleVisibility','off');
    handles.sample_2per1 = uicontrol(handles.bgroup_samples, ...
        'Style','radiobutton', ...
        'Units','normalized', ...
        'Position',[.02+3/5 0 1/5 1], ...
        'String','2.00', ...
        'HandleVisibility','off');
    handles.sample_4per1 = uicontrol(handles.bgroup_samples, ...
        'Style','radiobutton', ...
        'Units','normalized', ...
        'Position',[.02+4/5 0 1/5 1], ...
        'String','4.00', ...
        'HandleVisibility','off');
    set(handles.bgroup_samples,'Visible','on');
    set(handles.figure_configure,'Visible','on');
    switch settings.sps
        case 0.25
            set(handles.bgroup_samples,'SelectedObject',handles.sample_1per4);
        case 0.50
            set(handles.bgroup_samples,'SelectedObject',handles.sample_1per2);
        case 1.00
            set(handles.bgroup_samples,'SelectedObject',handles.sample_1per1);
        case 2.00
            set(handles.bgroup_samples,'SelectedObject',handles.sample_2per1);
        case 4.00
            set(handles.bgroup_samples,'SelectedObject',handles.sample_4per1);
    end
    % Save handles to guidata
    guidata(handles.figure_configure,handles);
end

% ===============================================================================

function button_axis_color_Callback(hObject,~)
    % Prompt the user to select a color and recolor the button
    c = uisetcolor('Select a color.');
    set(hObject,'BackgroundColor',c);
end

% ===============================================================================

function Settings = get_settings(handles)
    handles = guidata(handles.figure_settings);
    % Get current configuration from GUI elements
    Settings.axis_lower = get(handles.text_axis_lower,'string');
    Settings.axis_upper = get(handles.text_axis_upper,'string');
    Settings.axis_color1 = get(handles.button_axis_color1,'BackgroundColor');
    Settings.axis_color2 = get(handles.button_axis_color2,'BackgroundColor');
    Settings.axis_color3 = get(handles.button_axis_color3,'BackgroundColor');
    Settings.axis_min = get(handles.text_axis_min,'string');
    Settings.axis_max = get(handles.text_axis_max,'string');
    Settings.axis_steps = get(handles.text_axis_steps,'string');
    Settings.sps = get(get(handles.bgroup_samples,'SelectedObject'),'string');

end

% ===============================================================================

function push_submit_Callback(hObject,~)
    handles = guidata(hObject);
    global settings;
    axis_steps = str2double(get(handles.text_axis_steps,'string'));
    % Check for errors in configuration
    if isempty(get(handles.text_axis_min,'string')) || isempty(get(handles.text_axis_max,'string')) || isempty(get(handles.text_axis_max,'string'))
        serror = errordlg('All numerical options must be specified.');
        uiwait(serror); return;
    end
    if str2double(get(handles.text_axis_min,'string')) >= str2double(get(handles.text_axis_max,'string'))
        serror = errordlg('Maximum Value must be greater than Minimum Value.');
        uiwait(serror); return;
    end
    if isnan(axis_steps) || axis_steps<=1 || ceil(axis_steps)~=floor(axis_steps)
        serror = errordlg('Number of Axis Steps must be a positive integer greater than 1.');
        uiwait(serror); return;
    end
    % Update global settings variable
    settings.axis_lower = get(handles.text_axis_lower,'String');
    settings.axis_upper = get(handles.text_axis_upper,'String');
    settings.axis_color1 = get(handles.button_axis_color1,'BackgroundColor');
    settings.axis_color2 = get(handles.button_axis_color2,'BackgroundColor');
    settings.axis_color3 = get(handles.button_axis_color3,'BackgroundColor');
    settings.axis_min = str2double(get(handles.text_axis_min,'String'));
    settings.axis_max = str2double(get(handles.text_axis_max,'String'));
    settings.axis_steps = str2double(get(handles.text_axis_steps,'String'));
    settings.sps = str2double(get(get(handles.bgroup_samples,'SelectedObject'),'string'));
    delete(gcf);
    return;
end