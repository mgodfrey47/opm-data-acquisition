function DataAcquisition
% DataAcquisition launches a user interface for live DAQ data
% visualization and interactive data capture
%
% Parameters for plotting and recording data can be set using editable text 
% fields in UI and/or using study protocol. Option to load/create protocol
% will appear on running this script. If no protocol is selected, data will
% be acquired with a default sample rate of 2kHz.

clear dataCapture

% Configure data acquisition object and add input channels
d = daqlist;
d = d(1,:);
s = daq('ni');
ch = addinput(s, d{1,2}, 0:31, 'Voltage');

% Set acquisition configuration for each channel
for nc = 1:32
    ch(nc).TerminalConfig = 'SingleEnded';
    ch(nc).Range = [-10 10];
end

% Get channel labels
nChannels = numel(s.Channels);
[~,capture.channelLabels] = getChannelLabels;

% Option to choose study protocol
answer = questdlg('Would you like to use a study protocol?','Protocol',...
    'Create/edit','Load','No','No');
switch answer
    case 'Create/edit'
        protocol = CreateEditProtocol(nChannels-8); % 8 last channels are from stim PC
        
    case 'Load'
        filter = 'D:\Protocols\*.mat';
        [file,path] = uigetfile(filter);
        protocolFilename = [path,file];
        if exist(protocolFilename,'file')
            op = load(protocolFilename);
            protocol = op.protocol;
            clear op
        end
        
    case 'No'
        protocol = [];
end

% Set acquisition rate, in scans/second
if isempty(protocol) || ~isfield(protocol,'SampleRate') || protocol.SampleRate<=0
    s.Rate = 2000;
    warning('Default sample rate set to 2000Hz')
else
    s.Rate = protocol.SampleRate;
end

% Protocol name extracted to use later for filename
if ~isempty(protocol)
    capture.protocolName = protocol.Name;
else
    capture.protocolName = '';
end

% Determine the timespan corresponding to the block of samples supplied
% to the ScansAvailable event callback function.
callbackTimeSpan = double(s.ScansAvailableFcnCount)/s.Rate;
capture.callbackTimeSpan = callbackTimeSpan;

% Display graphical user interface
hGui = createDataCaptureUI(s, protocol);

% Configure a ScansAvailableFcn callback function
% The specified data capture parameters and the handles to the UI graphics
% elements are passed as additional arguments to the callback function.
s.ScansAvailableFcn = @(src,event) dataCapture(src, event, capture, hGui);

% Configure a ErrorOccurredFcn callback function for acquisition error
% events which might occur during background acquisition
s.ErrorOccurredFcn = @(src,event) disp(getReport(event.Error));

% Start continuous background data acquisition
start(s, 'continuous')

% warning off % REMOVE IF YOU WANT TO SEE WARNINGS

% Wait until data acquisition object is stopped from the UI
while s.Running
    pause(0.5)
end

% Disconnect from hardware
delete(s)
end