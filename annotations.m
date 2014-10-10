function status = annotations(varargin)
%ANNOTATIONS Code for the Annotations window and functions
% License: https://carma.codeplex.com/license

    % Create and maximize annotation window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_annotations = figure( ...
        'Position',[0 0 0 0], ...
        'Name','CARMA: Annotation Viewer', ...
        'NumberTitle','off', ...
        'ToolBar','none', ...
        'MenuBar','none', ...
        'Color',defaultBackground);
    %Create menu bar elements
    handles.menu_export = uimenu(handles.figure_annotations, ...
        'Parent',handles.figure_annotations, ...
        'Label','Export Mean Ratings', ...
        'Callback',@menu_export_Callback);
    % Maximize and lock window
    pause(.5);
    frame_h = get(handle(gcf),'JavaFrame');
    set(frame_h,'Maximized',1);
    pause(.5);
    set(handles.figure_annotations,'Resize','off');
    %Create uicontrol elements
    lc = .01; rc = .89;
    handles.axis_annotations = axes('Units','Normalized', ...
        'Parent',handles.figure_annotations, ...
        'TickLength',[0.05 0], ...
        'OuterPosition',[0 0 1 1], ...
        'Position',[lc .04 .87 .08]);
    handles.listbox = uicontrol('Style','listbox', ...
        'Units','normalized', ...
        'FontSize',12, ...
        'Position',[rc .485 .10 .50]);
    handles.button_addseries = uicontrol('Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[rc .445 3/100 3/100], ...
        'String','+', ...
        'FontSize',16, ...
        'TooltipString','Add Annotation File', ...
        'Callback',@button_addseries_Callback);
    handles.button_delseries = uicontrol('Style','pushbutton', ...
        'Units','normalized', ...
        'Position',[rc+.005+3/100 .445 3/100 3/100], ...
        'String','–', ...
        'FontSize',16, ...
        'TooltipString','Remove Annotation File', ...
        'Callback',@button_delseries_Callback);
    handles.toggle_meanplot = uicontrol('Style','togglebutton', ...
        'Units','normalized', ...
        'Position',[rc+.01+6/100 .445 3/100 3/100], ...
        'String','m', ...
        'FontSize',14, ...
        'TooltipString','Toggle Mean Plot', ...
        'Enable','off', ...
        'Callback',@toggle_meanplot_Callback);
    pos = getpixelposition(handles.figure_annotations);
    handles.reliability = uitable(...
        'Units','normalized', ...
        'Position',[rc .14 .10 .29], ...
        'ColumnWidth',{pos(3)*.099*.65,pos(3)*.099*.25}, ...
        'ColumnName',[], ...
        'RowName',[], ...
        'Data',[], ...
        'FontSize',10);
    handles.toggle_playpause = uicontrol('Style','togglebutton', ...
        'Parent',handles.figure_annotations, ...
        'Units','Normalized', ...
        'Position',[rc .02 .10 .10], ...
        'String','Play', ...
        'FontSize',16.0, ...
        'Callback',@toggle_playpause_Callback);
    % Check for and find Window Media Player (WMP) ActiveX Controller
    axctl = actxcontrollist;
    index = strcmp(axctl(:,1),'Windows Media Player');
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end
    % Invoke and configure WMP ActiveX Controller
    fp = getpixelposition(handles.figure_annotations);
    pause(.25);
    handles.wmp2 = actxcontrol(axctl{index,2},fp([3 4 3 4]).*[lc .14 .875 .856],handles.figure_annotations);
    handles.wmp2.stretchToFit = true;
    handles.wmp2.uiMode = 'none';
    set(handles.wmp2.settings,'autoStart',0);
    % Read data passed to function
    handles.Settings = varargin{find(strcmp(varargin,'Settings'))+1};
    Ratings = varargin{find(strcmp(varargin,'Ratings'))+1};
    handles.Seconds = Ratings(:,1);
    handles.AllRatings = Ratings(:,2);
    handles.MeanRatings = Ratings(:,2);
    handles.URL = varargin{find(strcmp(varargin,'URL'))+1};
    handles.dur = varargin{find(strcmp(varargin,'Duration'))+1};
    filename = varargin{find(strcmp(varargin,'Filename'))+1};
    [~,handles.filename,~] = fileparts(filename);
    handles.AllFilenames = {handles.filename};
    handles.wmp2.URL = handles.URL;
    % Populate list box
    set(handles.listbox,'String',{'<html><u>Annotation Files';sprintf('<html><font color="%s">[01]</font> %s',rgbconv([0 0.4470 0.7410]),handles.filename)});
    % Populate reliability box
    box = reliability(handles.AllRatings);
    set(handles.reliability,'Data',box);
    % Create timer
	handles.timer2 = timer(...
        'ExecutionMode','fixedRate', ...
        'Period',0.05, ...
        'TimerFcn',{@timer2_Callback,handles});
    % Save handles to guidata
    guidata(handles.figure_annotations,handles);
    update_plots(handles);
    status = 1;
end

% ===============================================================================

function menu_export_Callback(hObject,~)
    handles = guidata(hObject);
    % Load data to be exported
    Settings = handles.Settings;
    axis_min = str2double(Settings.axis_min);
    axis_max = str2double(Settings.axis_max);
    axis_steps = str2double(Settings.axis_steps);
    [~,defaultname,ext] = fileparts(handles.URL);
    % If multiple files are imported, create a master file
    output = [ ...
        {'Time of Rating'},{datestr(now)}; ...
        {'Multimedia File'},{sprintf('%s%s',defaultname,ext)}; ...
        {'Lower Label'},{Settings.axis_lower}; ...
        {'Upper Label'},{Settings.axis_upper}; ...
        {'Minimum Value'},{axis_min}; ...
        {'Maximum Value'},{axis_max}; ...
        {'Number of Steps'},{axis_steps}; ...
        {'Second'},{'Rating'}; ...
        {'%%%%%%'},{'%%%%%%'}; ...
        num2cell([handles.Seconds,handles.MeanRatings])];
    defaultname = sprintf('%s_Mean',defaultname);
    %Prompt user for output filepath
    [filename,pathname] = uiputfile({'*.xlsx','Excel 2007 Spreadsheet (*.xlsx)'; ...
        '*.xls','Excel 2003 Spreadsheet (*.xls)'; ...
        '*.csv','Comma-Separated Values (*.csv)'},'Save as',defaultname);
    if isequal(filename,0), return; end
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
        h = msgbox('Export successful.');
        waitfor(h);
    else
        h = msgbox('Export error.');
        waitfor(h);
    end
end

% ===============================================================================

function button_addseries_Callback(hObject,~)
    handles = guidata(hObject);
    % Prompt user for import file.
    [filename,pathname] = uigetfile({'*.xls; *.xlsx; *.csv','CARMA Export Formats (*.xls, *.xlsx, *.csv)'},'Open Annotations');
    if filename==0, return; end
    [~,~,data] = xlsread(fullfile(pathname,filename));
    % Check that the import file matches the multimedia file
    if floor(handles.dur) ~= data{end,1}
        msgbox('Annotation file must be the same duration as multimedia file.','Error','Error');
        return;
    end
    if size(handles.AllRatings,1) ~= size(data,1)-9
        msgbox('Annotation file must have the same sampling rate as the other annotation files.','Error','Error');
        return;
    else
        % Read data from the import file
        Settings.axis_lower = data{3,2};
        Settings.axis_upper = data{4,2};
        Settings.axis_min = num2str(data{5,2});
        Settings.axis_max = num2str(data{6,2});
        Settings.axis_steps = num2str(data{7,2});
        Ratings = cell2mat(data(10:end,:));
        % Check that the import file matches previous import files
        if ~strcmpi(handles.Settings.axis_lower,Settings.axis_lower) ...
                || ~strcmpi(handles.Settings.axis_upper,Settings.axis_upper) ...
                || ~strcmp(handles.Settings.axis_min,Settings.axis_min) ...
                || ~strcmp(handles.Settings.axis_max,Settings.axis_max) ...
                || ~strcmp(handles.Settings.axis_steps,Settings.axis_steps)
            msgbox('These files were collected using different CARMA settings and are not compatible.');
            return;
        end
        % Append the new file to the stored data
        handles.AllRatings = [handles.AllRatings,Ratings(:,2)];
        [~,fn,~] = fileparts(filename);
        handles.AllFilenames = [handles.AllFilenames;fn];
        % Update mean series
        handles.MeanRatings = mean(handles.AllRatings,2);
        % Plot all the imported annotations
        guidata(handles.figure_annotations,handles);
        update_plots(handles);
        % Update list box
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(handles.CS(colorindex,:)),i,handles.AllFilenames{i})];
        end
        set(handles.listbox,'String',rows);
        % Update reliability box
        box = reliability(handles.AllRatings);
        set(handles.reliability,'Data',box);
    end
    set(handles.toggle_meanplot,'Enable','on');
    guidata(handles.figure_annotations,handles);
end

% ===============================================================================

function button_delseries_Callback(hObject,~)
    handles = guidata(hObject);
    % Get currently selected item
    index = get(handles.listbox,'Value')-1;
    % Cancel if the first row is selected
    if index == 0, msgbox('You cannot delete the first row.'); return; end
    % Cancel if only one row remains
    if size(handles.AllRatings,2)<2, msgbox('At least one file must remain.'); return; end
    % Remove the selected item from program
    handles.AllRatings(:,index) = [];
    handles.AllFilenames(index) = [];
    % Update mean series
    handles.MeanRatings = mean(handles.AllRatings,2);
    % Update plot and listbox
    guidata(handles.figure_annotations,handles);
    update_plots(handles);
    % Update list box
    set(handles.listbox,'Value',1);
    rows = {'<html><u>Annotation Files'};
    for i = 1:size(handles.AllRatings,2)
        colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
        rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(handles.CS(colorindex,:)),i,handles.AllFilenames{i})];
    end
    set(handles.listbox,'String',rows);
    % Update reliability box
    box = reliability(handles.AllRatings);
    set(handles.reliability,'Data',box);
    % Turn off multiplot options if only one plot is left
    if size(handles.AllRatings,2)<2
        set(handles.toggle_meanplot,'Enable','off','Value',0);
        toggle_meanplot_Callback(handles.toggle_meanplot,[]);
    end
    % Update guidata with handles
    guidata(handles.figure_annotations,handles);
end

% ===============================================================================

function toggle_meanplot_Callback(hObject,~)
    handles = guidata(hObject);
    update_plots(handles);
    if get(hObject,'Value')==get(hObject,'Max');
        % Update list box
        set(handles.listbox,'Value',1);
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv([.8 .8 .8]),i,handles.AllFilenames{i})];
        end
        rows = [cellstr(rows);'<html><font color="red">[M]</font> Mean Plot'];
        set(handles.listbox,'String',rows);
    else
        % Plot old series with colors
        axes(handles.axis_annotations);
        % Update list box
        set(handles.listbox,'Value',1);
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            colorindex = mod(i,7); if colorindex==0, colorindex = 7; end
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(handles.CS(colorindex,:)),i,handles.AllFilenames{i})];
        end
        set(handles.listbox,'String',rows);
        drawnow();
    end
    guidata(hObject,handles);
end

% ===============================================================================

function toggle_playpause_Callback(hObject,~)
    handles = guidata(hObject);
    if get(hObject,'Value')==get(hObject,'Max')
        % Send play() command to WMP and start timer
        handles.wmp2.controls.play();
        start(handles.timer2);
        set(hObject,'String','Pause');
        set(handles.menu_export,'Enable','off');
    else
        % Send pause() command to WMP and stop timer
        handles.wmp2.controls.pause();
        stop(handles.timer2);
        set(hObject,'String','Resume','Value',0);
        set(handles.menu_export,'Enable','on');
    end
    guidata(hObject,handles);
end

% ===============================================================================

function timer2_Callback(~,~,handles)
    handles = guidata(handles.figure_annotations);
    if strcmp(handles.wmp2.playState,'wmppsPlaying')
        % While playing, update annotations plot
        ts = handles.wmp2.controls.currentPosition;
        update_plots(handles);
        hold on;
        plot(handles.axis_annotations,[ts,ts],[100,-100],'k');
        hold off;
        drawnow();
    elseif strcmp(handles.wmp2.playState,'wmppsStopped')
        % When done, send stop() command to WMP
        handles.wmp2.controls.stop();
        stop(handles.timer2);
        update_plots(handles);
        set(handles.toggle_playpause,'String','Play','Value',0);
        set(handles.menu_export,'Enable','on');
    else
        % When transitioning, wait and return
        return;
    end
end

% ===============================================================================

function update_plots(handles)
    handles = guidata(handles.figure_annotations);
    if get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Min')
        % Plot each series of ratings with its own color
        axes(handles.axis_annotations); cla;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2);
        upper = str2double(handles.Settings.axis_min);
        lower = str2double(handles.Settings.axis_max);
        ylim([upper,lower]);
        xlim([0,ceil(handles.dur)+1]);
        set(gca,'YTick',lower+(upper-lower)/2,'YTickLabel',[],'YGrid','on');
        handles.CS = get(gca,'ColorOrder');
    elseif get(handles.toggle_meanplot,'Value')==get(handles.toggle_meanplot,'Max')
        % Plot each series of ratings in blue and the mean series in red
        axes(handles.axis_annotations); cla;
        hold on;
        plot(handles.Seconds,handles.AllRatings,'-','LineWidth',2,'Color',[.8 .8 .8]);
        plot(handles.Seconds,handles.MeanRatings,'-','LineWidth',2,'Color',[1 0 0]);
        upper = str2double(handles.Settings.axis_min);
        lower = str2double(handles.Settings.axis_max);
        ylim([upper,lower]);
        xlim([0,ceil(handles.dur)+1]);
        set(gca,'YTick',lower+(upper-lower)/2,'YTickLabel',[],'YGrid','on');
        hold off;
    end
    guidata(handles.figure_annotations,handles);
end