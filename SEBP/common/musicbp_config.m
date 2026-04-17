function cfg = musicbp_config(profileName)
%MUSICBP_CONFIG Configuration for the standalone SEBP workflow.

if nargin < 1 || isempty(profileName)
    profileName = 'maduo_2021';
end

profileName = lower(profileName);
if ~strcmp(profileName, 'maduo_2021')
    error('musicbp:unknownProfile', 'Only the maduo_2021 profile is supported in SEBP.');
end

commonDir = fileparts(mfilename('fullpath'));
sebpRoot = fileparts(commonDir);

cfg.root_dir = sebpRoot;
cfg.profile_name = profileName;
cfg.active = local_maduo(sebpRoot, commonDir);
end

function profile = local_maduo(sebpRoot, commonDir)
profile.kind = 'sebp';
profile.description = '2021 Mw 7.4 Maduo standalone SEBP profile';
profile.root_dir = sebpRoot;
profile.common_dir = commonDir;
profile.func_lib_dir = fullfile(sebpRoot, 'funcLib');
profile.mainshock_dir = fullfile(sebpRoot, 'mainshock');
profile.data_dir = fullfile(profile.mainshock_dir, 'Data');
profile.input_dir = fullfile(profile.mainshock_dir, 'Input');
profile.fig_dir = fullfile(profile.mainshock_dir, 'Fig');

profile.read.dep = 7.607;
profile.read.lon0 = 98.3622588499;
profile.read.lat0 = 34.6202641954;
profile.read.Mw = 7.4;
profile.read.strike1 = 0;
profile.read.strike2 = 0;
profile.read.sr = 10;
profile.read.ori = 60;
profile.read.displayLength = 360;
profile.read.plotScale = 1.0;

profile.align.band_for_align = 4;
profile.align.settings = [ ...
    52.9 , 121, 0.7; ...
    60.0 , 41, 0.6; ...
    60.0, 111, 0.6; ...
    60.0, 0, 0.6; ...
    0, 0, 0.0];

profile.bp.inputBand = 4;
profile.bp.parr = 55;
profile.bp.over = 35;
profile.bp.qs = 100;
profile.bp.ps = 100;
profile.bp.latrange = [-0.8 0.8];
profile.bp.lonrange = [-1.5 1.5];
profile.bp.band = 4;
profile.bp.win = 10;
profile.bp.basename = musicbp_bp_basename(profile.bp.band, profile.bp.win);
profile.bp.parameter_file = fullfile(profile.input_dir, [profile.bp.basename '.mat']);
profile.bp.calibrated_parameter_file = fullfile(profile.input_dir, [profile.bp.basename '_cali.mat']);

profile.aftershock.inputBand = 5;
profile.aftershock.band = 4;
profile.aftershock.parr = 45;
profile.aftershock.over = 30;
profile.aftershock.qs = 120;
profile.aftershock.ps = 120;
profile.aftershock.latrange = [-0.8 0.8];
profile.aftershock.lonrange = [-1.5 1.5];
profile.aftershock.win = 10;
profile.aftershock.basename = musicbp_bp_basename(profile.aftershock.band, profile.aftershock.win);

profile.ref_station = 25;
profile.max_events = [];
profile.ca_ap_loc_file = fullfile(sebpRoot, 'ca_ap_loc.mat');
profile.evt_list_file = fullfile(sebpRoot, 'evtlst.mat');
profile.main_bp_file = profile.bp.parameter_file;
profile.main_bp_calibrated_file = profile.bp.calibrated_parameter_file;
profile.ptimesdepth_file = fullfile(profile.func_lib_dir, 'libBP', 'Ptimesdepth.mat');
end
