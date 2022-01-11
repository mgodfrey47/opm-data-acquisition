function dataCapture(src, ~, c, hGui)
%dataCapture Process DAQ acquired data when called by ScansAvailable event.
%  dataCapture processes latest acquired data and timestamps from data
%  acquisition object (src), and, based on specified capture parameters from
%  the user interface elements (hGui handles structure), updates UI plots
%  and captures data.

[eventData, eventTimestamps] = read(src, src.ScansAvailableFcnCount, ...
    'OutputFormat', 'Matrix');

% Persistent variables - retain their values between calls to the function.
% -The read data is stored in persistent buffers (dataBuffer and stimBuffer).
% -Since multiple calls to dataCapture will be needed during a data recording,
% a 'recording' condition flag (trigActive) and a corresponding data timestamp
% (trigMoment) are used as persistent variables.
% -capturedChannels stores the channels selected at the time of recording so
% that they won't update during the recording if channels are de/selected.
% -nCaptures stores the number of recordings in a given data acq session so
% variables won't overwrite each other in the workspace.
% -captureData contains the recorded data.
% -nSampPrev tracks the number of previously recorded samples.

global linesSelected scaleFactors

persistent dataBuffer stimBuffer trigActive trigMoment capturedChannels nCaptures captureData nSampPrev

% If dataCapture is running for the first time, initialize persistent vars
if eventTimestamps(1)==0
    dataBuffer = [];          % data buffer
    stimBuffer = [];
    trigActive = false;       % trigger condition flag
    trigMoment = [];          % data timestamp when trigger condition met
end

% Checks whether GUI is open
if ishghandle(hGui.Fig)
    
    % Get buffer size from text field
    sampleRate = src.Rate;
    timeSpan = str2double(hGui.timeSpan.String); % in seconds
    plotTimeSpan =  str2double(hGui.plotTimeSpan.String); % in seconds
    bufferTimeSpan = max([plotTimeSpan, c.callbackTimeSpan*3]);
    bufferSize =  round(bufferTimeSpan * sampleRate);
    
    % Time, data and stim channels
    timeChan = 1;
    stimChans = [21,20, 23,22, 29,28, 31,30]; % J6 J7 J14 J15 on adaptor board
    dataChans=1:33;
    dataChans([timeChan,stimChans])=[];
    
    % Store continuous acquisition timestamps and data in persistent FIFO
    % buffer dataBuffer
    eventData = eventData/2.7; % convert from voltage to nanotesla
    latestData = [eventTimestamps, eventData];
    dataBuffer = [dataBuffer; latestData(:,[timeChan,dataChans])];
    
    % Discard previous samples that no longer need to be displayed on live plot
    numSamplesToDiscard = size(dataBuffer,1) - bufferSize;
    if (numSamplesToDiscard > 0)
        dataBuffer(1:numSamplesToDiscard, :) = [];
    end
    
    % Protocol name for saving data later
    protocolName = c.protocolName;
    
    %% Update continuous data plot
    % Plot latest plotTimeSpan seconds of data in dataBuffer
    samplesToPlot = min([round(plotTimeSpan * sampleRate), size(dataBuffer,1)]);
    firstPoint = size(dataBuffer, 1) - samplesToPlot + 1;
    
    % Update x-axis limits
    xlim(hGui.Axes1, [dataBuffer(firstPoint,1), dataBuffer(end,1)]);
    
    % See which channels to display from checkboxes
    channelsToKeep = cell2mat(get(hGui.boxes,'Value'));
    
    % Extract data to plot
    yData = dataBuffer(firstPoint:end, logical([0;channelsToKeep]));
    mY = mean(yData);
    
    % Scale amplitude of data automatically or based on amplitude scale factors
    if hGui.scaleButton.Value==1
        % Auto-scaling
        sY = std(yData);
        stackGaps = [0,cumsum(2*sY(1:end-1)+2*sY(2:end))];
        yData = yData+kron(stackGaps-mY,ones(samplesToPlot,1));
    else
        % Manual scaling with buttons
        % scaleFactors is a global variable initially created in createDataCaptureUI
        stackGaps = (0:sum(channelsToKeep)-1)*str2double(hGui.gaps.String);
        yData = yData.*repmat(scaleFactors(channelsToKeep==1),size(yData,1),1);
        yData = yData+kron(stackGaps-scaleFactors(channelsToKeep==1).*mY,ones(samplesToPlot,1));
    end
    
    % Channels labelled on y axis
    hGui.Axes1.YTick = stackGaps;
    channelLabelsYZ = c.channelLabels;
    hGui.Axes1.YTickLabel = channelLabelsYZ(channelsToKeep==1);
    
    % Unselect non-visible channels
    % linesSelected is a global variable initially created in createDataCaptureUI
    linesSelected(~channelsToKeep) = 0;
    
    % Define colormap so colour for each channel can be kept consistent
    cmap = colormap('lines');
    
    % Live plot has one line for each acquisition channel. Channels are only
    % displayed if corresponding channel checkbox is ticked
    z = 1;
    for ii = 1:numel(hGui.LivePlot)
        if channelsToKeep(ii)==1
            set(hGui.LivePlot(ii), 'XData', dataBuffer(firstPoint:end, 1), ...
                'YData', yData(:,z),'Color',cmap(ii,:),'LineStyle','-')
            if linesSelected(ii)==1
                hGui.LivePlot(ii).Color = [1,0,0];
            end
            z = z+1;
        else
            set(hGui.LivePlot(ii),'LineStyle','none')
        end
    end
    
    %% Stim channel
    % Convert from binary to decimal
    stimBin = latestData(:,stimChans)>0.5; % convert to 1s and 0s
    pow2 = 2.^(0:7);
    stimDec = sum(stimBin.*kron(pow2,ones(size(stimBin,1),1)),2);
    
    % Append to previous stim data (same process as for dataBuffer)
    stimBuffer = [stimBuffer; [latestData(:,timeChan),stimDec]];
    if (numSamplesToDiscard > 0)
        stimBuffer(1:numSamplesToDiscard, :) = [];
    end
    
  
    
    %% Arranging plots
    % Display stim channel if box is ticked
    keepStim = get(hGui.stimBox,'Value');
    if keepStim==1
        xlim(hGui.Axes2, [stimBuffer(firstPoint,1), stimBuffer(end,1)]);
        set(hGui.StimPlot, 'XData', stimBuffer(firstPoint:end, 1), ...
            'YData', stimBuffer(firstPoint:end, 2),...
            'Color','k','LineStyle','-')
    else
        set(hGui.StimPlot,'LineStyle','none')
    end
    
    % Display recorded data plot if box is ticked, hide if not
    plotRecorded = get(hGui.recBox,'Value');
    if plotRecorded==0
        set(hGui.CapturePlot,'LineStyle','none')
    end
    ArrangePlotPositions(hGui,keepStim,plotRecorded);
    
    %% Recording
    % After enough data is acquired for a complete capture, as specified by the
    % capture timespan, extract the captured data from the data buffer and save
    % it to a base workspace variable.
    
    % Get capture toggle button value (1 or 0) from UI
    captureRequested = hGui.CaptureButton.Value;
    
    % Check whether data capture has been aborted
    abortRequested = hGui.AbortButton.Value;
    
    
    if captureRequested && (~trigActive)
        % State: "Looking for trigger event"
        
        % Update UI status
        hGui.StatusText.String = 'Preparing';
        trigActive = hGui.CaptureButton.Value;
        trigMoment = latestData(1,1);
    end
    
    if captureRequested && trigActive && (((latestData(1,1)-trigMoment) >= timeSpan) || abortRequested)
        % State: "Acquired enough data for a complete capture"
        % Ends data capture if either
        %     - the required recording duration time has elapsed
        %     - or the recording has been aborted
        
        % Reset trigger flag, to allow for a new triggered data capture
        trigActive = false;
        
        % Update recorded data plot (one line for each acquisition channel)
        set(hGui.recBox,'Value',1);
        ArrangePlotPositions(hGui,keepStim,get(hGui.recBox,'Value'));
        z = 1;
        for ii = 1:numel(hGui.CapturePlot)
            if channelsToKeep(ii)==1
                z = z+1;
                set(hGui.CapturePlot(ii), 'XData', captureData(:, 1), ...
                    'YData', captureData(:, z),...
                    'Color',cmap(ii,:),'LineStyle','-')
            else
                set(hGui.CapturePlot(ii),'LineStyle','none')
            end
        end
        
        % Update UI to show that recording has ended
        hGui.CaptureButton.Value = 0;
        hGui.StatusText.String = '';
        set(hGui.AbortButton,'Value',0)
        
        % Save captured data to a base workspace variable
        % Get the variable name from UI text input
        % Variable name in format 'variableNameN' if multiple recordings are taken
        if isempty(nCaptures)
            varName = hGui.VarName.String;
            nCaptures = 1;
        else
            varName = [hGui.VarName.String,num2str(nCaptures)];
            nCaptures = nCaptures+1;
        end
        
        % Create header file with acquisition parameters
        hdr = [];
        hdr.Protocol = protocolName;
        hdr.SampleRate = sampleRate;
        hdr.Channels = channelLabelsYZ(capturedChannels==1);
        
        % Use assignin function to save the captured data to a base workspace variable
        assignin('base', varName, captureData);
        assignin('base', 'hdr', hdr);
        
        % Option to save data to file, opens dialogue box
        answer = questdlg('Save dataset?','Save','Yes','No','Yes');
        switch answer
            case 'Yes'
                % Automatically generates filename in the format:
                % DataDirectory/Date_Protocol_ParticipantID_DatasetID.mat
                % where DatasetID is an integer that increases with each
                % repeated scan. 
                
                todaysDate = datestr(now,'yyyymmdd');
                
                dataDir = ['D:\Data\',todaysDate,'\'];
                if ~exist(dataDir,'dir')
                    mkdir(dataDir)
                end
                
                subID = hGui.subID.String;
                filePrefix = sprintf('%s%s_%s_%s',dataDir,todaysDate,protocolName,subID);
                nFiles = length(dir([filePrefix,'*']));
                defaultFilename = sprintf('%s_%02d',filePrefix,nFiles+1);
                
                % Opens file explorer so filename can be overwritten.
                [filename,path]=uiputfile([defaultFilename,'.mat']);
                
                % Saves data and header using variable names captureData and hdr
                save([path,filename],'captureData','hdr','-v7.3');
                
            case 'No'
                disp('WARNING: Data not saved to file - manually save from workspace if needed')
        end
        
        % Reset selected channels
        capturedChannels = [];
        captureData = [];
        
        
    elseif captureRequested && trigActive && ((latestData(1,1)-trigMoment) < timeSpan)
        % State: "Capturing data"
        % Not enough data recorded to cover capture timespan during this callback execution
        
        % Update text field to give progress of recording
        timeSoFar = floor(latestData(1,1)-trigMoment);
        hGui.StatusText.String = sprintf('Recording: %i/%ss',timeSoFar,num2str(timeSpan));
        
        % At start of recording, set channels to record as those that were selected at time of recording
        if isempty(capturedChannels)
            capturedChannels = channelsToKeep==1;
        end
        
        % Preallocate recorded data array
        nSampTot = round(timeSpan*sampleRate);
        if isempty(captureData)
            captureData = zeros(nSampTot,sum(capturedChannels)+2);
            nSampPrev = 0;
        end
        
        % Store latest data in recorded data array
        % Doesn't take whole data segment if recording timespan ends mid-segment
        chans = [timeChan,dataChans(capturedChannels)];
        nSamp = min([size(latestData,1),nSampTot-nSampPrev]);
        captureData(nSampPrev+1:nSampPrev+nSamp,1:length(chans)) = latestData(1:nSamp,chans);
        
        % Append stim channel as final column
        stimStart = size(stimBuffer,1)-size(latestData,1)+1;
        captureData(nSampPrev+1:nSampPrev+nSamp,end) = stimBuffer(stimStart:stimStart+nSamp-1,2);
        
        % Update number of recorded samples
        nSampPrev = nSampPrev+nSamp;
        
        
    elseif ~captureRequested
        % State: "Capture not requested"
        % Capture toggle button is not pressed, set trigger flag and update UI
        trigActive = false;
        hGui.StatusText.String = 'Not recording';
    end
    
    drawnow
    
end

end