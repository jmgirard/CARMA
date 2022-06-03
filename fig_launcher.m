function fig_launcher
%FIG_LAUNCHER Window to launch the other windows
% License: https://github.com/jmgirard/CARMA/blob/master/license.txt

    global version year;
	version = 14.08;
    year = 2022;
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
        'Resize','off', ...
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
        'Callback',@push_review_Callback);
    set(handles.figure_launcher,'Visible','on');
    guidata(handles.figure_launcher,handles);
	addpath('Functions');
    % Check that VLC is installed
    axctl = actxcontrollist;
    index = strcmp(axctl(:,2),'VideoLAN.VLCPlugin.2');
    if sum(index)==0
        choice = questdlg(sprintf('CARMA requires the free, open source VLC Media Player.\nPlease be sure to download the 64-bit Windows version (vlc-xxx-win64.exe).\nPlease be sure to enable the "ActiveX plugin" option.\nOpen download page?'),...
            'CARMA','Yes','No','Yes');
        switch choice
            case 'Yes'
                web('http://download.videolan.org/pub/videolan/vlc/last/win64/','-browser');
        end
    end
    % Get or set default settings
    pExist = ispref('carma');
    if ~pExist
        addpref('carma', ...
            {'labLower','labUpper','axMin','axMax','axSteps','axStart','cmapval','cmapstr','defdir','srateval','sratenum','bsizeval','bsizenum','update'}, ...
            {'Negative Affect','Positive Affect',-100,100,9,0,1,'parula','',2,20,3,1.00,'ask'});
    end
    % Check for updates
    try
        rss = webread('https://github.com/jmgirard/CARMA/releases');
        index = strfind(rss,'CARMA v');
        newest = str2double(rss(index(1)+7:index(1)+11));
        current = version;
        if current < newest
            choice = uigetpref('carma','update', ...
                'New Version', ...
                {'CARMA has detected that an updated version is available.';'Open the download page in your web browser?'}, ...
                {'yes','no';'Yes','No'});
            switch choice
                case 'yes'
                    web('https://github.com/jmgirard/CARMA/releases/','-browser');
                    delete(handles.figure_launcher);
            end
        end
    catch
    end
end

function push_collect_Callback(hObject,~)
    handles = guidata(hObject);
    set(handles.push_collect,'Enable','inactive');
    c = findobj('Type','figure','Name','CARMA: Collect Ratings');
    r = findobj('Type','figure','Name','CARMA: Review Ratings');
    if ~isempty(r)
        msgbox('Only one window can be open at a time. Please close the Review Ratings window before opening the Collect Ratings window.','Error','modal');
        set(handles.push_collect,'Enable','on');
        return;
    end
    if isempty(c)
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
            end
        else
            % If some other problem with the joystick is detected, report it
            errordlg(err.message,'Error');
        end
    else
        uistack(c,'top');
    end
    set(handles.push_collect,'Enable','on');
end

function push_review_Callback(hObject,~)
    handles = guidata(hObject);
    set(handles.push_collect,'Enable','inactive');
    c = findobj('Type','figure','Name','CARMA: Collect Ratings');
    r = findobj('Type','figure','Name','CARMA: Review Ratings');
    if ~isempty(c)
        msgbox('Only one window can be open at a time. Please close the Collect Ratings window before opening the Review Ratings window.','Error','modal');
        set(handles.push_collect,'Enable','on');
        return;
    end
    if isempty(r)
        fig_review();
    else
        uistack(r,'top');
    end
    set(handles.push_collect,'Enable','on');
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