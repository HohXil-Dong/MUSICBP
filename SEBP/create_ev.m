% CREATE_EV
% Maintain the aftershock event list for the standalone SEBP workflow.
% Event directories should be located directly under the SEBP root.

scriptDir = fileparts(mfilename('fullpath'));

evtlst_char=['af04_M51';'af06_M52';'af08_M52'];
evtlst_name=['af04_M51';'af06_M52';'af08_M52'];

save(fullfile(scriptDir, 'evtlst.mat'), 'evtlst_char', 'evtlst_name')
