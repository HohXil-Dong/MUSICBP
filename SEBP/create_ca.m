% CREATE_CA
% Maintain the aftershock apparent/catalog locations used by SEBP_step4
% and SEBP_step5. This file should stay in the SEBP root directory.

scriptDir = fileparts(mfilename('fullpath'));

lat_ap=[34.44;34.42;34.65];
lat_ca=[34.49;34.43;34.70];
lon_ap=[99.05;99.30;98.09];
lon_ca=[98.91;99.14;98.03];
lat_cali=[];
lon_cali=[];

save(fullfile(scriptDir, 'ca_ap_loc.mat'), 'lat_ca', 'lat_ap', 'lon_ca', 'lon_ap', 'lat_cali', 'lon_cali')
