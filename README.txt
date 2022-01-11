MATLAB scripts for OPM MEG data acquisition through NI-9205 DAQ unit.

To start data acquisition, first ensure DAQ unit is connected to the OPMs
and to the PC, and then run DataAcquisition.m

Live data from each channel should appear in the top axes. Change the time
span of data shown using the left-most text field at the bottom of the figure,
and select the desired channels using the checkboxes to the right of the live
data plot.

If recording data, change the participant ID and the desired variable name
using the text fields in the bottom right. Record using the 'Capture' button.
Change the duration of the recording using the neighbouring text field.

When recording is complete, there will be an option to save the data. A
filename will be automatically generated based on the current date and the
participant ID.