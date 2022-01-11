function hGui = createDataCaptureUI(s, protocol)
% createDataCaptureUI Create a graphical user interface for data capture.
%   hGui = createDataCaptureUI(s) returns a structure of graphics
%   components handles (hGui) and creates a graphical user interface, by
%   programmatically creating a figure and adding required graphics
%   components for visualization of data acquired from a data acquisition
%   object (s).

global linesSelected scaleFactors

%% Create a figure and configure a callback function (executes on window close)
hGui.Fig = figure;
hGui.Fig.Name = 'Data capture';
hGui.Fig.NumberTitle = 'off';
hGui.Fig.Units = 'Normalized';
hGui.Fig.Position = [0.05,0.1,0.9,0.8];
hGui.Fig.ToolBar = 'None';
hGui.Fig.MenuBar = 'None';
hGui.Fig.Color = 'w';
hGui.Fig.DeleteFcn = {@endDAQ, s};
uiBackgroundColor = hGui.Fig.Color;

%% Channel labels for y-axis and checkboxes
[channelLabels,~] = getChannelLabels;
nChannelsAll = numel(s.Channels);
nChannelsData = nChannelsAll-8; % Final 8 channels are from stim PC

%% Axes for plotting data
betweenGap = 0.04;
axPosY = [0.1,0.3,0.4];

% Create the continuous data plot axes with legend (one line per acquisition channel)
hGui.Axes1 = axes('Units','Normalized','Position',[0.05,axPosY(3),0.9,(1-axPosY(3))]);
hGui.LivePlot = plot(0, zeros(1, nChannelsData));
linesSelected = zeros(1, nChannelsData);
set(hGui.LivePlot,'Selected',0,'ButtonDownFcn',{@lineSelected})
ylabel('Live data (nT)');
% Turn off axes toolbar and data tips for live plot axes
hGui.Axes1.Toolbar.Visible = 'off';
disableDefaultInteractivity(hGui.Axes1);

% Create axes for the stim channel
hGui.Axes2 = axes('Units','Normalized','Position',[0.05,axPosY(2),0.9,(axPosY(3)-axPosY(2)-betweenGap)]);
hGui.StimPlot = plot(0,0);
ylabel('Stim');
hGui.Axes2.Toolbar.Visible = 'off';
disableDefaultInteractivity(hGui.Axes2);

% Create the captured data plot axes (one line per acquisition channel)
hGui.Axes3 = axes('Units','Normalized','Position',[0.05,axPosY(1),0.9,(axPosY(2)-axPosY(1)-betweenGap)]);
hGui.CapturePlot = plot(NaN, NaN(1, nChannelsData));
xlabel('Time (s)');
ylabel('Recorded data (nT)');
hGui.Axes3.Toolbar.Visible = 'off';
disableDefaultInteractivity(hGui.Axes3);

%% Settings from protocol
if ~isempty(protocol)
    name = protocol.Name;
    recordingDuration = num2str(protocol.RecordingDuration);
    plotTimeSpan = num2str(protocol.TimeSpan);
    channelValues = protocol.Channels;
    recordStim = protocol.recordStim;
    scales = protocol.ScaleFactors;
    gaps = 0.02; % hard coded vertical spacing between channels, no option to change in protocol as of yet
else
    % default settings if no protocol selected
    name = 'none';
    recordingDuration = '30';
    plotTimeSpan = 5;
    channelValues = ones(nChannelsData,1);
    recordStim = 1;
    scales = ones(1,nChannelsData);
    gaps = 0.02;
end
sampleRate = num2str(s.Rate);

%% UI components
% Position and dimensions consistent between components
bg = 0.01; % Distance from bottom - buttons
tg = 0.04; % Distance from bottom - text labels
bh = 0.03; % Height - buttons
th = 0.02; % Height - text labels
bw = 0.07; % Width

% Button to stop data acquisition
hGui.DAQButton = uicontrol('style', 'pushbutton', 'string', 'Stop DAQ',...
    'units', 'Normalized', 'position', [0.05,bg,bw,bh]);
hGui.DAQButton.Callback = {@endDAQ, s};


% Checkboxes to display/record selected channels
cw = 0.01;
hGui.boxes = zeros(nChannelsData,1);
for nc = 1:nChannelsData
    chanNo = ceil(nc/2);
    hGui.boxes(nc) = uicontrol('parent',hGui.Fig,'style','checkbox',...
            'BackgroundColor', uiBackgroundColor,...
            'units', 'Normalized',...%'position',[0.96,0.6+nc*th,bw,th],...
            'Value',channelValues(nc));
    if mod(nc,2)==1
        set(hGui.boxes(nc),'position',[0.97,0.6+chanNo*th,cw,th])
    else
        set(hGui.boxes(nc),'position',[0.98,0.6+chanNo*th,cw,th])
    end
end
% Text labels for checkboxes with channel number and Y/Z
hGui.txtChan = zeros(chanNo,1);
for nch = 1:chanNo
    hGui.txtChan(nc) = uicontrol('Style', 'text', 'String', channelLabels{nch}, ...
    'units', 'Normalized','Position', [0.955,0.6+nch*th,0.015,th],'BackgroundColor', uiBackgroundColor);
end
hGui.txtYChan = uicontrol('Style', 'text', 'String', 'Y', ...
    'units', 'Normalized','Position', [0.97,0.6+(chanNo+1)*th,cw,th],'BackgroundColor', uiBackgroundColor);
hGui.txtZChan = uicontrol('Style', 'text', 'String', 'Z', ...
    'units', 'Normalized','Position', [0.98,0.6+(chanNo+1)*th,cw,th],'BackgroundColor', uiBackgroundColor);


% Buttons for amplitude scaling
r = 0.96;
% Button to turn autoscaling on/off
hGui.scaleButton = uicontrol('style', 'togglebutton', 'string', 'Auto-scale',...
    'units', 'Normalized', 'position', [r,0.5,bw/2,bh]);

% Buttons for changing amplitude if autoscaling is off
hGui.txtScale = uicontrol('style', 'text', 'string', 'Amplitude',...
    'units', 'Normalized', 'position', [r,0.5-bh,bw/2,th],...
    'HorizontalAlignment', 'left', 'BackgroundColor', uiBackgroundColor);
hGui.scaleUpButton = uicontrol('style', 'pushbutton', 'string', '+',...
    'units', 'Normalized', 'position', [r+bw/4,0.5-(th+bh),bw/4,th]);
hGui.scaleDownButton = uicontrol('style', 'pushbutton', 'string', '-',...
    'units', 'Normalized', 'position', [r,0.5-(th+bh),bw/4,th]);
hGui.scaleUpButton.Callback = @scaleUp;
hGui.scaleDownButton.Callback = @scaleDown;
scaleFactors = scales;

% Editable text field for the gap between channels
gh = 0.42;
hGui.gaps = uicontrol('style', 'edit', 'string', num2str(gaps),...
    'units', 'Normalized', 'position', [r,gh-th,bw/2,th]);
hGui.txtGaps = uicontrol('style', 'text', 'string', 'Spacing',...
    'units', 'Normalized', 'position', [r,gh,bw/2,th],...
    'HorizontalAlignment', 'left', 'BackgroundColor', uiBackgroundColor);


% Checkbox for dislaying/recording stim channel
hGui.stimBox = uicontrol('parent',hGui.Fig,'style','checkbox',...
            'BackgroundColor', uiBackgroundColor,...
            'units', 'Normalized','position',[0.985,0.3,cw,th],...
            'Value',recordStim);
hGui.txtStimBox = uicontrol('Style', 'text', 'String', 'Plot stim', ...
    'units', 'Normalized','Position', [0.955,0.3,2.5*cw,th],'BackgroundColor', uiBackgroundColor);

% Checkbox for dislaying recorded data plot
hGui.recBox = uicontrol('parent',hGui.Fig,'style','checkbox',...
            'BackgroundColor', uiBackgroundColor,...
            'units', 'Normalized','position',[0.985,0.22,cw,th],...
            'Value',0);
hGui.txtRecBox = uicontrol('Style', 'text', 'String', 'Plot recorded', ...
    'units', 'Normalized','Position', [0.955,0.22+0.018,4*cw,th],'BackgroundColor', uiBackgroundColor);
hGui.txtRecBox = uicontrol('Style', 'text', 'String', 'data', ...
    'units', 'Normalized','Position', [0.955,0.22,1.5*cw,th],'BackgroundColor', uiBackgroundColor);

% Text fields showing sample rate and study protocol (non-editable)
p = 0.15;
hGui.txtProtocol = uicontrol('Style', 'text', 'String', ['PROTOCOL: ',name], ...
    'units', 'Normalized','Position', [p,bg+th,2*bw,th], ...
    'HorizontalAlignment', 'left','BackgroundColor', uiBackgroundColor);
hGui.txtProtocol = uicontrol('Style', 'text', 'String', ['SAMPLE RATE: ',sampleRate,'Hz'], ...
    'units', 'Normalized','Position', [p,bg,2*bw,th], ...
    'HorizontalAlignment', 'left','BackgroundColor', uiBackgroundColor);


% Text field to set time span shown in live plot in seconds
hGui.plotTimeSpan = uicontrol('style', 'edit', 'string', plotTimeSpan,...
    'units', 'Normalized', 'position', [0.3,bg,bw,bh]);
% Label for the duration field
hGui.txtPlotTimeSpan = uicontrol('Style', 'text', 'String', 'Live plot time span (s):', ...
    'units', 'Normalized','Position', [0.3,tg,bw,th], ...
    'HorizontalAlignment', 'center','BackgroundColor', uiBackgroundColor);


% Button for starting data capture
cb = 0.45;
hGui.CaptureButton = uicontrol('style', 'togglebutton', 'string', 'Record',...
    'units', 'Normalized', 'position', [cb,bg,bw,bh]);
hGui.CaptureButton.Callback = {@startCapture, hGui};

% Text field to set length of recording in seconds
hGui.timeSpan = uicontrol('style', 'edit', 'string', recordingDuration,...
    'units', 'Normalized', 'position', [cb+bw,bg,bw,bh]);
% Label for the duration field
hGui.txtTimeSpan = uicontrol('Style', 'text', 'String', 'Recording duration (s):', ...
    'units', 'Normalized','Position', [cb+bw,tg,bw,th], ...
    'HorizontalAlignment', 'center','BackgroundColor', uiBackgroundColor);

% Status text field to indicate whether recording data or not
hGui.StatusText = uicontrol('style', 'text', 'string', '',...
    'units', 'Normalized', 'position', [cb+2*bw,bg,2*bw,bh],...
    'HorizontalAlignment', 'left', 'BackgroundColor', uiBackgroundColor);

% Button for aborting data capture
hGui.AbortButton = uicontrol('style', 'togglebutton', 'string', 'Abort',...
    'units', 'Normalized', 'position', [cb+3*bw,bg,bw,bh]);
% hGui.AbortButton.Callback = {@abort, hGui};


% Editable text field for participant ID
hGui.subID = uicontrol('style', 'edit', 'string', 'ddmmyy-xxx',...
    'units', 'Normalized', 'position', [0.8,bg,bw,bh]);
% Label for the variable name text field
hGui.txtSubID = uicontrol('Style', 'text', 'String', 'Participant ID:', ...
    'units', 'Normalized','Position', [0.8,tg,bw,th], ...
    'HorizontalAlignment', 'center','BackgroundColor', uiBackgroundColor);


% Editable text field for the captured data variable name
hGui.VarName = uicontrol('style', 'edit', 'string', 'recordedData',...
    'units', 'Normalized', 'position', [0.9,bg,bw,bh]);
% Label for the variable name text field
hGui.txtVarName = uicontrol('Style', 'text', 'String', 'Variable name:', ...
    'units', 'Normalized','Position', [0.9,tg,bw,th], ...
    'HorizontalAlignment', 'center','BackgroundColor', uiBackgroundColor);


% Callback function tracks which lines have been selected
function lineSelected(lineH,~)
    channelInd = find(lineH==hGui.LivePlot);
    if linesSelected(channelInd)==1
        linesSelected(channelInd) = 0;
    else
        linesSelected(channelInd) = 1;
    end
end

%% Callback functions for buttons which increase/decrease amplitude scaling.
% Scale factor changes by 1 if it is already larger than 1, or changes by
% 0.1 if between 0.1 and 1
function scaleUp(~,~)
    m = scaleFactors<=0.99;
    b = scaleFactors>0.99;
    if sum(linesSelected)==0
        scaleFactors(m) = scaleFactors(m)+0.1;
        scaleFactors(b) = scaleFactors(b)+1;
    else
        scaleFactors(m & linesSelected==1) = scaleFactors(m & linesSelected==1)+0.1;
        scaleFactors(b & linesSelected==1) = scaleFactors(b & linesSelected==1)+1;
    end
end
function scaleDown(~,~)
    m = scaleFactors<=1.1 & scaleFactors>=0.11;
    b = scaleFactors>1.1;
    if sum(linesSelected)==0
        scaleFactors(m) = scaleFactors(m)-0.1;
        scaleFactors(b) = scaleFactors(b)-1;
    else
        scaleFactors(m & linesSelected==1) = scaleFactors(m & linesSelected==1)-0.1;
        scaleFactors(b & linesSelected==1) = scaleFactors(b & linesSelected==1)-1;
    end
end
        
end

function startCapture(obj, ~, hGui)
if obj.Value
    % If button is pressed clear data capture plot
    for ii = 1:numel(hGui.CapturePlot)
        set(hGui.CapturePlot(ii), 'XData', NaN, 'YData', NaN);
    end
end
end

function endDAQ(~, ~, s)
if isvalid(s)
    if s.Running
        stop(s);
    end
end
end