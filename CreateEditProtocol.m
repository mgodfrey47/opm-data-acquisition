function protocol = CreateEditProtocol(nChannels)

protocol = [];
pGui = SetProtocol;
uiwait(pGui.fig)


function pGui = SetProtocol
% Protocols will contain following acquisition parameters:
% - Name of protocol
% - Length of recording (s)
% - Time span seen in live data plot (s)
% - Sample rate (Hz)
% - Desired channels
% - Desired stim channel
% - Amplitude scale factors

%% Create figure
pGui.fig = figure;
pGui.fig.Units = 'Normalized';
pGui.fig.Position = [0.35,0.3,0.3,0.4];
pGui.fig.Color = 'w';
pGui.fig.ToolBar = 'none';
pGui.fig.MenuBar = 'none';
pGui.fig.Name = 'Study protocol';
pGui.fig.NumberTitle = 'off';

% Background image
pGui.ha = axes('units','normalized','position',[0 0 1 1]);
uistack(pGui.ha,'bottom');
I=imread('background_image.jpg');
hi = imagesc(I);
set(pGui.ha,'handlevisibility','off','visible','off')

%% UIcontrol components
% uicontrol dimensions
h = 0.05;
w = 0.25;
lg = 0.05; % Gap from left side of figure

% Select protocol filename / create new one
pbg = 0.9;
pGui.p = uicontrol('Style','edit','String','','FontSize',8,...
    'Units','Normalized','Position',[lg,pbg-h,2*w,h]);
pGui.pText = uicontrol('Style','Text','String','Protocol:','FontSize',10,...
    'Units','Normalized','Position',[lg,pbg,w/2,h]);
pGui.pNew = uicontrol('Style','pushbutton','String','Create new','FontSize',10,...
    'Units','Normalized','Position',[lg+w/2,pbg,0.75*w,h],'BackgroundColor','w',...
    'Callback',@NewProtocolFilename);
pGui.pEdit = uicontrol('Style','pushbutton','String','Edit existing','FontSize',10,...
    'Units','Normalized','Position',[lg+1.25*w,pbg,0.75*w,h],'BackgroundColor','w',...
    'Callback',@EditProtocolFilename);

% Recording duration
rbg = 0.7;
pGui.rd = uicontrol('Style','edit','String','30','FontSize',10,...
    'Units','Normalized','Position',[lg+w,rbg,w,h]);
pGui.rdText = uicontrol('Style','Text','String','Recording duration (s):','FontSize',10,...
    'Units','Normalized','Position',[lg,rbg,w,h]);

% Live plot time span
tbg = 0.6;
pGui.ts = uicontrol('Style','edit','String','5','FontSize',10,...
    'Units','Normalized','Position',[lg+w,tbg,w,h]);
pGui.tsText = uicontrol('Style','Text','String','Live plot time span (s):','FontSize',10,...
    'Units','Normalized','Position',[lg,tbg,w,h]);

% Sample rate
fbg = 0.5;
pGui.f = uicontrol('Style','edit','String','2000','FontSize',10,...
    'Units','Normalized','Position',[lg+w,fbg,w,h]);
pGui.fText = uicontrol('Style','Text','String','Sample rate (Hz):','FontSize',10,...
    'Units','Normalized','Position',[lg,fbg,w,h]);

% Stim channel checkbox
tcbg = 0.3;
pGui.sc = uicontrol('Style','checkbox','String','Show stim channel',...
        'FontSize',10,'HorizontalAlignment','left',...
        'Units','Normalized','Position',[lg+w,tcbg,w,h]);

% Channel selection
cw = 0.98;
clgo = 0.6;
cwo = 0.35;
pGui.cp = uipanel('FontSize',12,'Units','Normalized','Position',[clgo,0.15,cwo,0.75],...
    'BackgroundColor','w');
pGui.cTitle = uicontrol('Style','Text','String','Channels',...
    'FontSize',10,'Units','Normalized','Position',[clgo,0.9,cwo,h]);
pGui.cSelect = uicontrol('Style','pushbutton','String','Select all','FontSize',10,...
    'Units','Normalized','Position',[clgo,0.05,cwo/2,h],'BackgroundColor','w',...
    'Callback',@SelectAllChannels);
pGui.cClear = uicontrol('Style','pushbutton','String','Clear all','FontSize',10,...
    'Units','Normalized','Position',[clgo+cwo/2,0.05,cwo/2,h],'BackgroundColor','w',...
    'Callback',@ClearAllChannels);
pGui.cSelectY = uicontrol('Style','pushbutton','String','Select all Y','FontSize',10,...
    'Units','Normalized','Position',[clgo,0.1,cwo/2,h],'BackgroundColor','w',...
    'Callback',@SelectAllY);
pGui.cSelectZ = uicontrol('Style','pushbutton','String','Select all Z','FontSize',10,...
    'Units','Normalized','Position',[clgo+cwo/2,0.1,cwo/2,h],'BackgroundColor','w',...
    'Callback',@SelectAllZ);

% Channel checkboxes
ylg = 0.3;
zlg = 0.6;
[channelLabels,~] = getChannelLabels;
pGui.c = zeros(nChannels,1);
for nc = 1:nChannels
    chanNo = ceil(nc/2);
    pGui.c(nc) = uicontrol('Parent',pGui.cp,'Style','checkbox',...
        'Value',1,'BackgroundColor','w','Units','Normalized');
    if mod(nc,2)==1
        set(pGui.c(nc),'position',[ylg,0.95-0.05*chanNo,cw,h])
    else
        set(pGui.c(nc),'position',[zlg,0.95-0.05*chanNo,cw,h])
    end
end

% Text labels for checkboxes with channel number and Y/Z
pGui.txtChan = zeros(chanNo,1);
for nch = 1:chanNo
    pGui.txtChan(nc) = uicontrol('Parent',pGui.cp, 'Style', 'text', 'String', channelLabels{nch}, ...
    'units', 'Normalized','Position', [0.1,0.95-0.05*nch,0.2,h],'BackgroundColor', 'w');
end
pGui.txtYChan = uicontrol('Parent',pGui.cp, 'Style', 'text', 'String', 'Y', 'FontSize',10,'HorizontalAlignment','left',...
    'units', 'Normalized','Position', [ylg,0.95,0.2,h],'BackgroundColor', 'w');
pGui.txtZChan = uicontrol('Parent',pGui.cp, 'Style', 'text', 'String', 'Z', 'FontSize',10,'HorizontalAlignment','left',...
    'units', 'Normalized','Position', [zlg,0.95,0.2,h],'BackgroundColor', 'w');

% Text fields for editing amplitude scale factors for displaying live data
pGui.amp = zeros(nChannels,1);
for nc = 1:nChannels
    chanNo = ceil(nc/2);
    pGui.amp(nc) = uicontrol('Parent',pGui.cp,'Style','edit','String','1',...
        'Units','Normalized');
    if mod(nc,2)==1
        set(pGui.amp(nc),'position',[ylg+0.1,0.95-0.05*chanNo,0.1,h])
    else
        set(pGui.amp(nc),'position',[zlg+0.1,0.95-0.05*chanNo,0.1,h])
    end
end
pGui.txtAmpY = uicontrol('Parent',pGui.cp, 'Style', 'text', 'String', 'gain', 'FontSize',7,'HorizontalAlignment','left',...
    'units', 'Normalized','Position', [ylg+0.1,0.95,0.2,h*0.8],'BackgroundColor', 'w');
pGui.txtAmpZ = uicontrol('Parent',pGui.cp, 'Style', 'text', 'String', 'gain', 'FontSize',7,'HorizontalAlignment','left',...
    'units', 'Normalized','Position', [zlg+0.1,0.95,0.2,h*0.8],'BackgroundColor', 'w');

% Save protocol
sbg = 0.1;
pGui.sButton = uicontrol('Style','pushbutton','String','Save and close','FontSize',10,...
    'Units','Normalized','Position',[lg,sbg,w,h],'BackgroundColor','w',...
    'Callback',@SaveProtocol);

%% Callbacks
function NewProtocolFilename(src,event)
    filter = 'D:\Protocols\*.mat';
    [file,path] = uiputfile(filter);
    pGui.p.String = [path,file];
end
function EditProtocolFilename(src,event)
    filter = 'D:\Protocols\*.mat';
    [file,path] = uigetfile(filter);
    pGui.p.String = [path,file];
    
    if exist(pGui.p.String,'file')
        op = load(pGui.p.String);
        pGui.rd.String = num2str(op.protocol.RecordingDuration);
        pGui.ts.String = num2str(op.protocol.TimeSpan);
        pGui.f.String = num2str(op.protocol.SampleRate);
        for ne = 1:nChannels
            set(pGui.c(ne),'Value',op.protocol.Channels(ne));
            set(pGui.amp(ne),'String',num2str(op.protocol.ScaleFactors(ne)));
        end
        pGui.sc.Value = op.protocol.recordStim;
%         pGui.tcp.Value = op.protocol.TriggerChannels.ProPixx;
%         pGui.tco.Value = op.protocol.TriggerChannels.Other;
    end
end

function SelectAllChannels(src,event)
    for ncs = 1:nChannels
        set(pGui.c(ncs),'Value',1);
    end
end
function SelectAllY(src,event)
    for ncs = 1:2:nChannels-1
        set(pGui.c(ncs),'Value',1);
    end
end
function SelectAllZ(src,event)
    for ncs = 2:2:nChannels
        set(pGui.c(ncs),'Value',1);
    end
end
function ClearAllChannels(src,event)
    for ncs = 1:nChannels
        set(pGui.c(ncs),'Value',0);
    end
end

function SaveProtocol(src,event)
    [~,name,ext] = fileparts(pGui.p.String);
    if exist(pGui.p.String,'file')
        answer = questdlg([name,ext,' already exists. Overwrite?'],'Save?','Yes','Cancel','Cancel');
    else
        answer = 'Yes';
    end
    
    if strcmp(answer,'Yes')
        protocol = [];
        protocol.Name = name;
        protocol.RecordingDuration = str2double(pGui.rd.String);
        protocol.TimeSpan = str2double(pGui.ts.String);
        protocol.SampleRate = str2double(pGui.f.String);
        protocol.Channels = zeros(nChannels,1);
        protocol.ScaleFactors = zeros(1,nChannels);
        for n = 1:nChannels
            protocol.Channels(n) = get(pGui.c(n),'Value');
            protocol.ScaleFactors(n) = str2double(get(pGui.amp(n),'String'));
        end
%         protocol.TriggerChannels.ProPixx = get(pGui.tcp,'Value');
%         protocol.TriggerChannels.Other = get(pGui.tco,'Value');
        protocol.recordStim = get(pGui.sc,'Value');
        
        
        % Save protocol to file and close figure
        save(pGui.p.String,'protocol','-v7.3')
        close(pGui.fig)
    end
end

end

end