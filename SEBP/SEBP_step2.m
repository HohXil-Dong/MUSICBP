% SEBP_STEP2
% Read aftershock SAC data, match stations with the mainshock result, and
% transport mainshock alignment time shifts into each aftershock record.

clear
close all
scriptDir = fileparts(mfilename('fullpath'));
commonDir = fullfile(scriptDir, 'common');
funcLibDir = fullfile(scriptDir, 'funcLib');
addpath(commonDir);
addpath(genpath(funcLibDir));
cfg = musicbp_config('maduo_2021');
profile = cfg.active;

%% INPUT
mother_loc = profile.root_dir;
main_mat   = profile.main_bp_file;
ori      = 60; % please refer to your request on IRIS
display  = 360; % please refer to your request on IRIS
Preshift = false;	% no change! About readBP
plotscale= 1.5;     % plotscale:  scaling of the amplitudes of seismograms

musicbp_require(mother_loc, 'dir', 'SEBP 根目录', '请确认当前脚本位于独立化后的 SEBP 根目录。');
musicbp_require(main_mat, 'file', '主震 BP 参数文件', '请先运行 SEBP_step1.m 生成主震 BP 参数文件。');
musicbp_require(profile.evt_list_file, 'file', 'evtlst.mat', '请先运行 create_ev.m 生成事件列表。');

%% Loop for each aftershock
load(profile.evt_list_file)
[n_evt,~] = size(evtlst_name(:,1)); % n_evt: number of aftershock events
if ~isempty(profile.max_events)
    n_evt = min(n_evt, profile.max_events);
end

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

    musicbp_require(eventDir, 'dir', ['余震目录 ' eventName], '请确认事件目录位于 SEBP 根目录下。');
    musicbp_require(dataDir, 'dir', ['余震 Data 目录 ' eventName], '请把对应余震 SAC 数据放入 Data 目录。');
    if ~isfolder(inputDir)
        mkdir(inputDir);
    end
    if ~isfolder(figDir)
        mkdir(figDir);
    end

    musicbp_write_filelist(dataDir);
    path = [eventDir filesep];
    readteleBP(path,ret_main.lon0,ret_main.lat0,ret_main.sr,ori,display,Preshift,plotscale)
    
    %%%check for data
    %check_data(path,1);
    
    %%% Match stations with mainshock 
    load(fullfile(inputDir, 'data0.mat'))
    [~,i_main,i_aft] = intersect(deblank(string(ret_main.nm)), strtrim(string(ret.nm))); % find same station
    if isempty(i_main)
        error('musicbp:noMatchedStations', '余震 %s 与主震没有匹配台站。', eventName);
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
        for j = 1:length(diff)
            ret.xori(j,:) = specshift(ret.xori(j,:),ret.timeshift(j)*ret.sr);
        end
    
    save(fullfile(inputDir, 'data5.mat'), 'ret')
end
%%% TEST


% tmp1 = (ret.recordtime*3600*24 + ret.timeshift) - (ret.recordtime(1)*3600*24 + ret.timeshift(1));
% tmp2 = (ret_main.recordtime*3600*24 + ret_main.timeshift) - ...
%     (ret_main.recordtime(1)*3600*24 + ret_main.timeshift(1));
% tmp1-tmp2
% x1(i,:)=specshift(x0(i,:),timeshift(i)*sr);

    
