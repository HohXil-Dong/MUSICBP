% SEBP_STEP3
% Run MUSIC BP for each aftershock using the matched station/time-shifted
% data produced by SEBP_step2.


clear;
close all;
scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, 'common'));
[cfg, profile, logFile] = musicbp_step_setup(mfilename('fullpath'), mfilename, 'maduo_2021'); %#ok<ASGLU>
%% INPUT
mother_loc = profile.aftershock_root_dir;

%%
musicbp_require(mother_loc, 'dir', 'aftershock root directory', ...
    'Please confirm that aftershock event directories are located under SEBP/aftershock.', logFile);
musicbp_require(profile.ptimesdepth_file, 'file', 'Ptimesdepth.mat', ...
    'Please confirm that the travel-time table exists in the SEBP function library.', logFile);
musicbp_require(profile.evt_list_file, 'file', 'evtlst.mat', ...
    'Please run create_ev.m first to generate the aftershock event list.', logFile);
musicbp_log(logFile, 'INFO', ...
    'config: aftershock inputBand=%d band=%d win=%.3f parr=%.3f over=%.3f', ...
    profile.aftershock.inputBand, profile.aftershock.band, profile.aftershock.win, ...
    profile.aftershock.parr, profile.aftershock.over);
load(profile.evt_list_file); % load event list
[n_evt,~] = size(evtlst_char);
if ~isempty(profile.max_events)
    n_evt = min(n_evt, profile.max_events);
end

%% Loop for all events
% for j=1:2
startDir = pwd;
fprintf('step3: processing %d aftershocks.\n', n_evt);
musicbp_log(logFile, 'INFO', 'processing %d aftershocks', n_evt);
for j = 1 : n_evt

    eventName = strtrim(evtlst_name(j,:));
    path = [fullfile(mother_loc, eventName) filesep];
    fprintf('step3: running MUSIC BP for %s (%d/%d).\n', eventName, j, n_evt);
    musicbp_log(logFile, 'INFO', 'event %s start (%d/%d)', eventName, j, n_evt);
    musicbp_require(fullfile(path, 'Input', 'data5.mat'), 'file', ...
        ['aftershock data5.mat ' eventName], 'Please run SEBP_step2.m first.', logFile);

    BPfile = setparBP(path, profile.aftershock.inputBand, profile.aftershock.band, ...
        profile.read.lon0, profile.read.lat0, profile.read.dep, ...
        profile.aftershock.parr, profile.aftershock.over, ...
        profile.aftershock.ps, profile.aftershock.qs, ...
        profile.aftershock.lonrange, profile.aftershock.latrange, profile.aftershock.win);
    musicbp_log(logFile, 'INFO', 'event %s parameter file: %s', eventName, BPfile);
    bpInfo = load(BPfile, 'ret');
    outputDir = fullfile(path, 'Input', [bpInfo.ret.dirname '_MUSIC_Dir']);
    runteleBPmusic(path, BPfile, logFile);
    musicbp_require(fullfile(outputDir, 'parret.mat'), 'file', ...
        ['aftershock parret.mat ' eventName], 'MUSIC BP did not generate a complete output set.', logFile);
    cd(outputDir);
    posteriorBPmusic;
    musicbp_log(logFile, 'INFO', 'event %s finished', eventName);
    cd(startDir);
end

fprintf('step3: finished.\n');
musicbp_log(logFile, 'INFO', 'step3 session end');
