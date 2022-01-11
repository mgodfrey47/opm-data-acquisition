function ArrangePlotPositions(hGui,keepStim,plotRecorded)

if keepStim==1 && plotRecorded==1
    hGui.Axes1.Position = [0.05,0.4,0.9,(1-0.4)];
    hGui.Axes2.Position = [0.05,0.3,0.9,0.06];
    hGui.Axes2.Visible = 'on';
    hGui.Axes3.Visible = 'on';
    
elseif keepStim==0 && plotRecorded==1
    hGui.Axes1.Position = [0.05,0.3,0.9,(1-0.3)];
    hGui.Axes2.Visible = 'off';
    hGui.Axes3.Visible = 'on';
    
elseif keepStim==1 && plotRecorded==0
    hGui.Axes1.Position = [0.05,0.2,0.9,(1-0.2)];
    hGui.Axes2.Position = [0.05,0.1,0.9,0.06];
    hGui.Axes2.Visible = 'on';
    hGui.Axes3.Visible = 'off';
else
    hGui.Axes1.Position = [0.05,0.1,0.9,(1-0.1)];
    hGui.Axes2.Visible = 'off';
    hGui.Axes3.Visible = 'off';
end


