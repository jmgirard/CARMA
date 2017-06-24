function fig_launcher
%FIG_LAUNCHER Window to launch the other windows
% License: https://github.com/jmgirard/CARMA/blob/master/license.txt

    global version;
	version = 14.00;
    % Create and center main window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_launcher = figure( ...
        'Units','pixels', ...
        'Position',[0 0 600 350], ...
        'Name','CARMA: Continuous Affect Rating and Media Annotation', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'NumberTitle','off', ...
        'Visible','off', ...
        'Color',defaultBackground);
    movegui(handles.figure_launcher,'center');
    % Create UI elements
    handles.axis_title = axes(handles.figure_launcher,...
        'Units','normalized', ...
        'Position',[0.05 0.60 0.90 0.30], ...
        'Color',[0.2 0.2 0.2],...
        'Box','on','XTick',[],'YTick',[],...
        'ButtonDownFcn',@website);
    xlim([-1 1]); ylim([-1 1]);
    text(0,0,sprintf('CARMA v%.2f',version),'Color',[1 1 1],'FontSize',42,...
        'FontName','cambria','HorizontalAlignment','center',...
        'ButtonDownFcn',@website);
    handles.push_collect = uicontrol(handles.figure_launcher, ...
		'Style','pushbutton', ...
        'Units','Normalized', ...
        'Position',[0.05 0.10 0.425 0.40], ...
        'String','Collect Ratings', ...
        'FontSize',18, ...
        'Callback',@push_collect_Callback);
    handles.push_review = uicontrol(handles.figure_launcher, ...
		'Style','pushbutton', ...
        'Units','Normalized', ...
        'Position',[0.525 0.10 0.425 0.40], ...
        'String','Review Ratings', ...
        'FontSize',18, ...
        'Callback','fig_review()');
    set(handles.figure_launcher,'Visible','on');
    guidata(handles.figure_launcher,handles);
	addpath('Functions');
    % Check that VLC is installed
    axctl = actxcontrollist;
    index = strcmp(axctl(:,2),'VideoLAN.VLCPlugin.2');
    if sum(index)==0
        choice = questdlg(sprintf('CARMA requires the free, open source VLC Media Player.\nPlease be sure to download the 64-bit Windows version.\nPlease be sure to enable the "ActiveX plugin" option.\nOpen download page?'),...
            'CARMA','Yes','No','Yes');
        switch choice
            case 'Yes'
                web('http://www.videolan.org/vlc/download-windows.html','-browser');
        end
    end
    % Check for updates
    try
        rss = urlread('https://github.com/jmgirard/CARMA/releases');
        index = strfind(rss,'CARMA v');
        newest = str2double(rss(index(1)+7:index(1)+10));
        current = version;
        if current < newest
            choice = questdlg(sprintf('CARMA has detected that an update is available.\nOpen download page?'),...
                'CARMA','Yes','No','Yes');
            switch choice
                case 'Yes'
                    web('https://github.com/jmgirard/CARMA/releases/','-browser');
                    delete(handles.figure_launcher);
            end
        end
    catch
    end
end

function push_collect_Callback(~,~)
    err.message = 'Joystick connected.';
    try
        vrjoystick(1);
    catch err
    end
    if strcmp(err.message,'Joystick is not connected.')
        % If no joystick is detected, default to the mouse version
        fig_collect_mouse();
    elseif strcmp(err.message,'Joystick connected.')
        % If a joystick is detected, ask to use mouse or joystick
        choice = questdlg('Which input device would you like to use?','CARMA','Mouse','Joystick','Joystick');
        switch choice
            case 'Mouse'
                fig_collect_mouse();
            case 'Joystick'
                fig_collect_vrjoy();
            otherwise
                return;
        end
    else
        % If some other problem with the joystick is detected, report it
        errordlg(err.message,'Error');
    end
end

function website(~,~)
    choice = questdlg('Open CARMA website in browser?','CARMA','Yes','No','Yes');
    switch choice
        case 'Yes'
            web('http://carma.jmgirard.com/','-browser');
        otherwise
            return;
    end
end