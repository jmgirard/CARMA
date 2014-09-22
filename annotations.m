function status = annotations(varargin)
%ANNOTATIONS Code for the Annotations window and functions
% License: https://carma.codeplex.com/license

    % Create and maximize annotation window
    defaultBackground = get(0,'defaultUicontrolBackgroundColor');
    handles.figure_annotations = figure(...
        'Name','CARMA: Annotation Viewer',...
        'NumberTitle','off',...
        'MenuBar','none',...
        'Resize','off',...
        'Color',defaultBackground);
    maximize(handles.figure_annotations);
    pause(0.1);
    %Create menu bar elements
    handles.menu_export = uimenu(handles.figure_annotations,...
        'Parent',handles.figure_annotations,...
        'Label','Export Annotations',...
        'Callback',{@menu_export_Callback,handles});
    handles.menu_reliability = uimenu(handles.figure_annotations,...
        'Parent',handles.figure_annotations,...
        'Label','Compute Reliability',...
        'Enable','off',...
        'Callback',{@menu_reliability_Callback,handles});
    %Create uicontrol elements
    lc = .01; rc = .89;
    handles.axis_annotations = axes('Units','Normalized',...
        'Parent',handles.figure_annotations,...
        'TickLength',[0.05 0],...
        'OuterPosition',[0 0 1 1],...
        'Position',[lc .04 .87 .08]);
    handles.listbox = uicontrol('Style','listbox',...
        'Units','normalized',...
        'FontSize',12,...
        'Position',[rc .185 .10 .795]);
    handles.button_addseries = uicontrol('Style','pushbutton',...
        'Units','normalized',...
        'Position',[rc .145 3/100 3/100],...
        'String','+',...
        'FontSize',16,...
        'TooltipString','Add Annotation File',...
        'Callback',{@button_addseries_Callback,handles});
    handles.button_delseries = uicontrol('Style','pushbutton',...
        'Units','normalized',...
        'Position',[rc+.005+3/100 .145 3/100 3/100],...
        'String','–',...
        'FontSize',16,...
        'TooltipString','Remove Annotation File',...
        'Callback',{@button_delseries_Callback,handles});
    handles.toggle_meanplot = uicontrol('Style','togglebutton',...
        'Units','normalized',...
        'Position',[rc+.01+6/100 .145 3/100 3/100],...
        'String','m',...
        'FontSize',14,...
        'TooltipString','Toggle Mean Plot',...
        'Enable','off',...
        'Callback',{@toggle_meanplot_Callback,handles});
    handles.toggle_playpause = uicontrol('Style','togglebutton',...
        'Parent',handles.figure_annotations,...
        'Units','Normalized',...
        'Position',[rc .02 .10 .10],...
        'String','Play',...
        'FontSize',16.0,...
        'Callback',{@toggle_playpause_Callback,handles});
    % Check for and find Window Media Player (WMP) ActiveX Controller
    axctl = actxcontrollist;
    index = strcmp(axctl(:,1),'Windows Media Player');
    if sum(index)==0, errordlg('Please install Windows Media Player'); quit force; end
    % Invoke and configure WMP ActiveX Controller
    fp = getpixelposition(handles.figure_annotations);
    pause(.25);
    handles.wmp2 = actxcontrol(axctl{index,2},fp([3 4 3 4]).*[lc .14 .87 .815],handles.figure_annotations);
    handles.wmp2.stretchToFit = true;
    handles.wmp2.uiMode = 'none';
    set(handles.wmp2.settings,'autoStart',0);
    % Read data passed to function
    handles.Settings = varargin{find(strcmp(varargin,'Settings'))+1};
    handles.Ratings = varargin{find(strcmp(varargin,'Ratings'))+1};
    handles.AllRatings = handles.Ratings(:,2);
    handles.URL = varargin{find(strcmp(varargin,'URL'))+1};
    handles.dur = varargin{find(strcmp(varargin,'Duration'))+1};
    filename = varargin{find(strcmp(varargin,'Filename'))+1};
    [~,handles.filename,~] = fileparts(filename);
    handles.AllFilenames = {handles.filename};
    % Configure axis_annotations
    axes(handles.axis_annotations);
    handles.CS = get(gca,'ColorOrder');
    % Plot all ratings in axis_annotations
    plot(handles.AllRatings,'o-','LineWidth',2);
    upper = str2double(handles.Settings.axis_min);
    lower = str2double(handles.Settings.axis_max);
    ylim([upper,lower]);
    xlim([0,ceil(handles.dur)+1]);
    set(gca,'YTick',lower+(upper-lower)/2,'YTickLabel',[],'YGrid','on');
    handles.wmp2.URL = handles.URL;
    % Populate list box
    set(handles.listbox,'String',{'<html><u>Annotation Files';sprintf('<html><font color="blue">[01]</font> %s',handles.filename)});
    % Save handles to guidata
    guidata(handles.figure_annotations,handles);
    status = 1;
end

% --- Executes when menu_export is clicked.
function menu_export_Callback(~,~,handles)
    handles = guidata(handles.figure_annotations);
    % Load data to be exported
    Settings = handles.Settings;
    axis_min = str2double(Settings.axis_min);
    axis_max = str2double(Settings.axis_max);
    axis_steps = str2double(Settings.axis_steps);
    [~,defaultname,~] = fileparts(handles.URL);
    if size(handles.AllRatings,2)>1
        % If multiple files are imported, create a master file
        [dim1,dim2] = size(handles.AllRatings);
        output = [{'Filename','Lower Label','Upper Label','Minimum Value','Midpoint Value','Maximum Value','Number of Steps','Second'},{'Mean'};...
            cellstr(repmat(handles.URL,dim1,1)),...
            cellstr(repmat(Settings.axis_lower,dim1,1)),...
            cellstr(repmat(Settings.axis_upper,dim1,1)),...
            num2cell(repmat(axis_min,dim1,1)),...
            num2cell(repmat(axis_max-(axis_max-axis_min)/2,dim1,1)),...
            num2cell(repmat(axis_max,dim1,1)),...            
            num2cell(repmat(axis_steps,dim1,1)),...
            num2cell((1:dim1)'),...
            num2cell(handles.MeanRatings)];
        for i = 1:dim2
            output = [output,[handles.AllFilenames(i);num2cell(handles.AllRatings(:,i))]];
        end
        defaultname = sprintf('%s_Mean',defaultname);
    else
        % If only one file is imported, recreate it
        sz = size(handles.AllRatings,1);
        output = [...
            {'Filename','Lower Label','Upper Label','Minimum Value','Midpoint Value','Maximum Value','Number of Steps','Second','Rating'};...
            cellstr(repmat(handles.URL,sz,1)),...
            cellstr(repmat(Settings.axis_lower,sz,1)),...
            cellstr(repmat(Settings.axis_upper,sz,1)),...
            num2cell(repmat(axis_min,sz,1)),...
            num2cell(repmat(axis_max-(axis_max-axis_min)/2,sz,1)),...
            num2cell(repmat(axis_max,sz,1)),...            
            num2cell(repmat(axis_steps,sz,1)),...
            num2cell((1:sz)'),...
            num2cell(handles.AllRatings)];
    end
    %Prompt user for output filepath
    [filename,pathname] = uiputfile({'*.xlsx','Excel 2007 Spreadsheet (*.xlsx)';...
        '*.xls','Excel 2003 Spreadsheet (*.xls)';...
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

% --- Executes when menu_reliability is clicked.
function menu_reliability_Callback(~,~,handles)
    handles = guidata(handles.figure_annotations);
    % Calculate single and average ICCs
    Data = handles.AllRatings;
    [ICC31,ICC3k,alpha] = reliability(Data);
    % Create figure to display results
    f = figure('Position',[0 0 300 100],...
        'MenuBar','none',...
        'Name','Reliability Report',...
        'NumberTitle','off',...
        'Resize','off');
    labels = {'Number of Raters';'Single ICC (3,1)';'Average ICC (3,k)';'Cronbach Alpha'};
    numbers = {size(Data,2);ICC31;ICC3k;alpha};
    uitable('Parent',f,...
        'Position',[10 10 280 80],...
        'ColumnWidth',{139},...
        'ColumnName',[],...
        'RowName',[],...
        'Data',[labels,numbers]);
    movegui(f,'center');
end

% --- Executes when button_addseries is clicked.
function button_addseries_Callback(~,~,handles)
    handles = guidata(handles.figure_annotations);
    % Prompt user for import file.
    [filename,pathname] = uigetfile({'*.xls; *.xlsx; *.csv','CARMA Export Formats (*.xls, *.xlsx, *.csv)'},'Open Annotations');
    if filename==0, return; end
    data = importdata(fullfile(pathname,filename));
    % Check that the import file matches the multimedia file
    if floor(handles.dur) ~= size(data.data,1)
        msgbox('Annotation file must be the same duration as multimedia file.','Error','Error');
        return;
    else
        % Read data from the import file
        Settings.axis_lower = data.textdata{2,2};
        Settings.axis_upper = data.textdata{2,3};
        Settings.axis_min = num2str(data.data(1,1));
        Settings.axis_max = num2str(data.data(1,3));
        Settings.axis_steps = num2str(data.data(1,4));
        % Check that the import file matches previous import files
        if ~strcmpi(handles.Settings.axis_lower,Settings.axis_lower)...
                || ~strcmpi(handles.Settings.axis_upper,Settings.axis_upper)...
                || ~strcmp(handles.Settings.axis_min,Settings.axis_min)...
                || ~strcmp(handles.Settings.axis_max,Settings.axis_max)...
                || ~strcmp(handles.Settings.axis_steps,Settings.axis_steps)
            msgbox('These files were collected using different CARMA settings and are not compatible.');
            return;
        end
        % Append the new file to the stored data
        handles.AllRatings = [handles.AllRatings, data.data(:,6)];
        [~,fn,~] = fileparts(filename);
        handles.AllFilenames = [handles.AllFilenames;fn];
        % Update mean series
        handles.MeanRatings = mean(handles.AllRatings,2);
        % Plot all the imported annotations and update legend
        axes(handles.axis_annotations);
        if size(handles.AllRatings,2)>7
            CS = varycolor(size(handles.AllRatings,2));
        else
            CS = handles.CS;
        end
        set(handles.axis_annotations,'NextPlot','replacechildren','ColorOrder',CS);
        plot(handles.AllRatings,'o-','LineWidth',2);
        ylim([str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)]);
        xlim([0,ceil(handles.dur)+1]);
        % Update list box
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(i,:)),i,handles.AllFilenames{i})];
        end
        set(handles.listbox,'String',rows);
    end
    set(handles.menu_reliability,'Enable','on');
    set(handles.toggle_meanplot,'Enable','on');
    guidata(handles.figure_annotations,handles);
end

% --- Executes when button_delseries is clicked.
function button_delseries_Callback(~,~,handles)
    handles = guidata(handles.figure_annotations);
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
    axes(handles.axis_annotations);
    if size(handles.AllRatings,2)>7
        CS = varycolor(size(handles.AllRatings,2));
    else
        CS = handles.CS;
    end
    set(handles.axis_annotations,'NextPlot','replacechildren','ColorOrder',CS);
    plot(handles.AllRatings,'o-','LineWidth',2);
    ylim([str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)]);
    xlim([0,ceil(handles.dur)+1]);
    % Update list box
    set(handles.listbox,'Value',1);
    rows = {'<html><u>Annotation Files'};
    for i = 1:size(handles.AllRatings,2)
        rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(i,:)),i,handles.AllFilenames{i})];
    end
    set(handles.listbox,'String',rows);
    % Turn off multiplot options if only one plot is left
    if size(handles.AllRatings,2)<2
        set(handles.menu_reliability,'Enable','off');
        set(handles.toggle_meanplot,'Enable','off','Value',0);
        toggle_meanplot_Callback(handles.toggle_meanplot,[],handles);
    end
    % Update guidata with handles
    guidata(handles.figure_annotations,handles);
end

% --- Executes on button press in toggle_meanplot.
function toggle_meanplot_Callback(hObject,~,handles)
    handles = guidata(handles.figure_annotations);
    if get(hObject,'Value')==get(hObject,'Max')
        % Plot annotations in light blue
        plot(handles.AllRatings,'LineWidth',2,'Color',[.5 .5 1]); hold on;
        ylim([str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)]);
        xlim([0,ceil(handles.dur)+1]);
        % Update list box
        set(handles.listbox,'Value',1);
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv([.5 .5 1]),i,handles.AllFilenames{i})];
        end
        rows = [cellstr(rows);'<html><font color="red">[M]</font> Mean Plot'];
        set(handles.listbox,'String',rows);
        % Plot mean series in red
        plot(handles.MeanRatings,'ro-','LineWidth',2); hold off;
    elseif get(hObject,'Value')==get(hObject,'Min')
        % Plot old series with colors
        axes(handles.axis_annotations);
        if size(handles.AllRatings,2)>7
            CS = varycolor(size(handles.AllRatings,2));
        else
            CS = handles.CS;
        end
        set(handles.axis_annotations,'NextPlot','replacechildren','ColorOrder',CS);
        plot(handles.AllRatings,'o-','LineWidth',2);
        ylim([str2double(handles.Settings.axis_min),str2double(handles.Settings.axis_max)]);
        xlim([0,ceil(handles.dur)+1]);
        % Update list box
        set(handles.listbox,'Value',1);
        rows = {'<html><u>Annotation Files'};
        for i = 1:size(handles.AllRatings,2)
            rows = [cellstr(rows);sprintf('<html><font color="%s">[%02d]</font> %s',rgbconv(CS(i,:)),i,handles.AllFilenames{i})];
        end
        set(handles.listbox,'String',rows);
        drawnow();
    end
    guidata(hObject, handles);
end

% --- Executes on button press in toggle_playpause.
function toggle_playpause_Callback(hObject,~,handles)
    handles = guidata(handles.figure_annotations);
    if get(hObject,'Value')
        % If toggle is set to play, send play() command to WMP
        handles.wmp2.controls.play();
        while ~strcmp(handles.wmp2.playState,'wmppsPlaying'), pause(0.01); end
        % Update GUI elements
        set(hObject,'String','Pause');
        set(handles.menu_export,'Enable','off');
        set(handles.menu_reliability,'Enable','off');
        axes(handles.axis_annotations);
        % While playing, plot current ratings in axis_annotations
        set(gca,'NextPlot','add');
        while strcmp(handles.wmp2.playState,'wmppsPlaying') && get(hObject,'Value')
            pause(0.1);
            ts = handles.wmp2.controls.currentPosition;
            if exist('p','var')~=0, delete(p); end
            p = plot([ts,ts],[100,-100],'k');
            drawnow();
        end
        if get(hObject,'Value')
            % When done, send stop() command to WMP
            handles.wmp2.controls.stop();
            set(hObject,'String','Play');
            set(handles.menu_export,'Enable','on');
            set(handles.menu_reliability,'Enable','on');
        end
    else
        % If toggle is set to pause, send pause() command to WMP
        handles.wmp2.controls.pause();
        set(hObject,'String','Play');
        set(handles.menu_export,'Enable','on');
        set(handles.menu_reliability,'Enable','on');
    end
    guidata(hObject, handles);
end