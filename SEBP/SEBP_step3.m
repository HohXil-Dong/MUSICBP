% SEBP_STEP3
% Run MUSIC BP for each aftershock using the matched station/time-shifted
% data produced by SEBP_step2.


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

%%
musicbp_require(mother_loc, 'dir', 'SEBP 根目录', '请确认当前脚本位于独立化后的 SEBP 根目录。');
musicbp_require(profile.ptimesdepth_file, 'file', 'Ptimesdepth.mat', '请确认 SEBP 函数库中的走时表存在。');
musicbp_require(profile.evt_list_file, 'file', 'evtlst.mat', '请先运行 create_ev.m 生成事件列表。');
load(profile.evt_list_file); % load event list
[n_evt,~] = size(evtlst_char);
if ~isempty(profile.max_events)
    n_evt = min(n_evt, profile.max_events);
end

%% Loop for all events
% for j=1:2
startDir = pwd;
for j = 1 : n_evt
    
    eventName = strtrim(evtlst_name(j,:));
    path = [fullfile(mother_loc, eventName) filesep];
    musicbp_require(fullfile(path, 'Input', 'data5.mat'), 'file', ...
        ['余震 data5.mat ' eventName], '请先运行 SEBP_step2.m。');

    [BPfile]=setparBP(path,profile.aftershock.inputBand,profile.aftershock.band, ...
        profile.read.lon0,profile.read.lat0,profile.read.dep, ...
        profile.aftershock.parr,profile.aftershock.over, ...
        profile.aftershock.ps,profile.aftershock.qs, ...
        profile.aftershock.lonrange,profile.aftershock.latrange);
    runteleBPmusic(path,BPfile)
    posteriorBPmusic;
    close all;
    cd(startDir);
end
