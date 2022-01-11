function [channelLabels,channelLabelsYZ] = getChannelLabels
% [channelLabels,channelLabelsYZ] = getChannelLabels
% Creates cell arrays of channel labels.
% channelLabels just contains the sensor labels.
% channelLabelsYZ contains all channel labels, with two channels from each 
% sensor labelled with the Y and Z components.

% Just sensor labels
channelLabels = {
    'NV';
    'NW';
    '10N';
    '10O';
    'FW';
    'FX';
    'FY';
    'GO';
    '10P';
    '10Q';
    'PW';
    'PX'};

nChannels = length(channelLabels)*2;

% Labels including Y and Z
channelLabelsYZ = cell(nChannels,1);
for nc = 1:nChannels
    chanNo = ceil(nc/2);
    if mod(nc,2)==1
        channelLabelsYZ{nc} = sprintf('%s Y',channelLabels{chanNo});
    else
        channelLabelsYZ{nc} = sprintf('%s Z',channelLabels{chanNo});
    end
end

