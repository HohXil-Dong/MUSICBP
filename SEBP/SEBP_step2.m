% SEBP_STEP2
% Read aftershock SAC data, match stations with the mainshock result, and
% transport mainshock alignment time shifts into each aftershock record.

clear;
close all;
scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, 'common'));
[cfg, profile, logFile] = musicbp_step_setup(mfilename('fullpath'), mfilename, 'maduo_2021'); %#ok<ASGLU>

%% INPUT
mother_loc = profile.aftershock_root_dir;
main_mat = profile.main_bp_file;
ori = profile.aftershock.read.ori;
displayLength = profile.aftershock.read.displayLength;
Preshift = false;
plotscale = profile.aftershock.read.plotScale;

musicbp_require(mother_loc, 'dir', 'aftershock root directory', ...
    'Please confirm that aftershock event directories are located under SEBP/aftershock.', logFile);
musicbp_require(main_mat, 'file', 'mainshock BP parameter file', ...
    'Please run SEBP_step1.m first to generate the mainshock BP parameter file.', logFile);
musicbp_require(profile.evt_list_file, 'file', 'evtlst.mat', ...
    'Please run create_ev.m first to generate the aftershock event list.', logFile);
musicbp_log(logFile, 'INFO', ...
    'config: ori=%.3f display=%.3f plotScale=%.3f main_bp=%s', ...
    ori, displayLength, plotscale, main_mat);

%% Loop for each aftershock
load(profile.evt_list_file);
[n_evt,~] = size(evtlst_name(:,1)); % n_evt: number of aftershock events
if ~isempty(profile.max_events)
    n_evt = min(n_evt, profile.max_events);
end

fprintf('step2: processing %d aftershocks.\n', n_evt);
musicbp_log(logFile, 'INFO', 'processing %d aftershocks', n_evt);

for i = 1 : n_evt
   %%% Load mainshock .mat file
    load(main_mat);
    ret_main = ret;

   %%% readBP for aftershock events
    eventName = strtrim(evtlst_name(i,:));
    eventDir = fullfile(mother_loc, eventName);
    inputDir = fullfile(eventDir, 'Input');
    dataDir = fullfile(eventDir, 'Data');
    figDir = fullfile(eventDir, 'Fig');

    fprintf('step2: matching %s (%d/%d).\n', eventName, i, n_evt);
    musicbp_log(logFile, 'INFO', 'event %s start (%d/%d)', eventName, i, n_evt);
    musicbp_require(eventDir, 'dir', ['aftershock directory ' eventName], ...
        'Please confirm that the event directory is located under SEBP/aftershock.', logFile);
    musicbp_prepare_data_dir(dataDir, logFile);
    if ~isfolder(inputDir)
        mkdir(inputDir);
    end
    if ~isfolder(figDir)
        mkdir(figDir);
    end

    path = [eventDir filesep];
    readteleBP(path, ret_main.lon0, ret_main.lat0, ret_main.sr, ori, displayLength, ...
        Preshift, plotscale, [], [], [], logFile);

    %%%check for data
    %check_data(path,1);

    %%% Match stations with mainshock
    load(fullfile(inputDir, 'data0.mat'));
    readStationCount = size(ret.xori, 1);
    fprintf('step2: %s readBP kept %d stations after distance filtering.\n', ...
        eventName, readStationCount);
    [~,i_main,i_aft] = intersect(deblank(string(ret_main.nm)), strtrim(string(ret.nm))); % find same station
    if isempty(i_main)
        musicbp_log(logFile, 'ERROR', 'event %s has no matched stations with the mainshock', eventName);
        error('musicbp:noMatchedStations', 'Aftershock %s has no matched stations with the mainshock.', eventName);
    end
        %%%% Since the 'recordtime' of different event downloaded from IRIS
        %%%% might be different, we also need to correct this difference,
        %%%% by transit this error into aftershock's 'timeshift'
        ret = orderAll(ret,0,i_aft);
        ret_main = orderAll(ret_main,0,i_main);
        rctime_diff_sec      = 3600*24*(ret.recordtime      - ret.recordtime(1));
        rctime_main_diff_sec = 3600*24*(ret_main.recordtime - ret_main.recordtime(1));
        diff = rctime_main_diff_sec - rctime_diff_sec;
        ret.timeshift = ret_main.timeshift + diff;
        matchedStationCount = numel(i_main);
        for j = 1:length(diff)
            ret.xori(j,:) = specshift(ret.xori(j,:),ret.timeshift(j)*ret.sr);
        end

    save(fullfile(inputDir, 'data5.mat'), 'ret');
    fprintf('step2: %s matched %d stations with the mainshock.\n', eventName, matchedStationCount);
    musicbp_log(logFile, 'INFO', ...
        'event %s matched %d stations and saved %s', ...
        eventName, matchedStationCount, fullfile(inputDir, 'data5.mat'));
end

fprintf('step2: finished.\n');
musicbp_log(logFile, 'INFO', 'step2 session end');
%%% TEST


% tmp1 = (ret.recordtime*3600*24 + ret.timeshift) - (ret.recordtime(1)*3600*24 + ret.timeshift(1));
% tmp2 = (ret_main.recordtime*3600*24 + ret_main.timeshift) - ...
%     (ret_main.recordtime(1)*3600*24 + ret_main.timeshift(1));
% tmp1-tmp2
% x1(i,:)=specshift(x0(i,:),timeshift(i)*sr);
