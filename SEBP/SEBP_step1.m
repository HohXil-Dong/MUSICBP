% SEBP_STEP1
% Mainshock preprocessing and back-projection for the standalone SEBP flow.
% It operates on SEBP/mainshock/Data and writes outputs to
% SEBP/mainshock/Input.

clear;
close all;

scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, 'common'));
[cfg, profile, logFile] = musicbp_step_setup(mfilename('fullpath'), mfilename, 'maduo_2021'); %#ok<ASGLU>

musicbp_require(profile.func_lib_dir, 'dir', 'SEBP function library', ...
    'Please confirm that the funcLib directory is complete.', logFile);

%% Work to do (do=1, not_do=0)
Initial_flag = 0;      % Initialize a project
readBP_flag = 0;       % Read seismogram from .SAC files
alignpara_flag = 0;    % Get parameters for alignment
alignBP_flag = 0;      % Hypocenter alignment
runBPbmfm_flag = 0;    % Beamforming Back-projection
runBPmusic_flag = 1;   % MUSIC Back-Projection

%% Parameters for read
workPath = profile.root_dir;
project = 'mainshock';

dep = profile.read.dep;
lon0 = profile.read.lon0;
lat0 = profile.read.lat0;
Mw = profile.read.Mw;
strike1 = profile.read.strike1;
strike2 = profile.read.strike2;

sr = profile.read.sr;
ori = profile.read.ori;
displayLength = profile.read.displayLength;
plotscale = profile.read.plotScale;

%% Parameters for alignment
% Keep the original manual workflow:
% 1. Set Band_for_align manually.
% 2. Run alignpara_flag=1 to inspect the suggested ts11/refst.
% 3. Update the align array manually if needed.
% 4. Run alignBP_flag=1 for the selected band only.
Band_for_align = profile.align.band_for_align;
align = profile.align.settings;
ts11 = align(Band_for_align, 1);
refst = align(Band_for_align, 2);
cutoff = align(Band_for_align, 3);

%% Parameters for setpar/runteleBP
inputband = profile.bp.inputBand;
parr = profile.bp.parr;
over = profile.bp.over;
qs = profile.bp.qs;
ps = profile.bp.ps;
latrange = profile.bp.latrange;
lonrange = profile.bp.lonrange;
Band = profile.bp.band;

%% Logging
musicbp_log(logFile, ...
    'flags: Initial=%d readBP=%d alignpara=%d align=%d bmfm=%d music=%d', ...
    Initial_flag, readBP_flag, alignpara_flag, alignBP_flag, ...
    runBPbmfm_flag, runBPmusic_flag);
musicbp_log(logFile, ...
    'config: band_for_align=%d ts11=%.3f refst=%d cutoff=%.3f inputband=%d bp_band=%d', ...
    Band_for_align, ts11, refst, cutoff, inputband, Band);

path = [profile.mainshock_dir filesep];
stepStartDir = pwd;

if ~isfolder(profile.mainshock_dir)
    mkdir(profile.mainshock_dir);
    musicbp_log(logFile, 'INFO', 'created mainshock directory: %s', profile.mainshock_dir);
end
if ~isfolder(profile.input_dir)
    mkdir(profile.input_dir);
    musicbp_log(logFile, 'INFO', 'created input directory: %s', profile.input_dir);
end
if ~isfolder(profile.fig_dir)
    mkdir(profile.fig_dir);
    musicbp_log(logFile, 'INFO', 'created figure directory: %s', profile.fig_dir);
end

if Initial_flag == 1
    fprintf('step1: initializing mainshock project directories.\n');
    musicbp_log(logFile, 'INFO', 'initializing project directories under %s', profile.mainshock_dir);
    initialize_BP(profile.root_dir, workPath, project);
end

if readBP_flag == 1
    fprintf('step1: reading mainshock SAC data.\n');
    musicbp_log(logFile, 'INFO', 'reading mainshock SAC data from %s', profile.data_dir);

    Preshift = false;
    musicbp_prepare_data_dir(profile.data_dir, logFile);

    readteleBP(path, lon0, lat0, sr, ori, displayLength, Preshift, plotscale, ...
        strike1, strike2, Mw, logFile);
    check_data(path, 1);

    data0 = load(fullfile(profile.input_dir, 'data0.mat'), 'ret');
    ret = data0.ret;
    readStationCount = size(ret.xori, 1);
    fprintf('step1: readBP kept %d stations after distance filtering.\n', readStationCount);
    musicbp_log(logFile, 'INFO', 'data0.mat created with %d stations', readStationCount);

    ret.x = ret.xori;
    fl = 0.1;
    fh = 2;
    parrPlot = 53;
    nor_win = 10;
    [BB, AA] = butter(4, [fl fh] / (ret.sr / 2));
    for i = 1:length(ret.lon)
        ret.x(i, :) = filter(BB, AA, ret.xori(i, :));
        ret.x(i, :) = ret.x(i, :) / std(ret.x(i, parrPlot * ret.sr:(parrPlot + nor_win) * ret.sr));
    end
    ret.x(:, 1:200) = 0;
    ret.x(:, 3000:end) = 0;
    ret.scale = 0.5;
    hReadPreview = figure('Name', 'mainshock - data0 read preview', 'NumberTitle', 'off');
    plotAll1(ret);
    figure(hReadPreview);
    drawnow;
    pause(0.05);
    drawnow;
    print(hReadPreview, fullfile(profile.fig_dir, 'data0_read_preview.png'), '-dpng', '-r200');
    figure(hReadPreview);
    drawnow;
    pause(0.05);
    drawnow;
end

if alignpara_flag == 1
    fprintf('step1: estimating alignment parameters for band %d.\n', Band_for_align);

    if Band_for_align == 1
        requiredInput = fullfile(profile.input_dir, 'data0.mat');
        requiredLabel = 'data0.mat';
        requiredHint = 'Please run readBP_flag first to generate mainshock data.';
    else
        requiredInput = fullfile(profile.input_dir, sprintf('data%d.mat', Band_for_align - 1));
        requiredLabel = sprintf('data%d.mat', Band_for_align - 1);
        requiredHint = 'Please finish the previous manual alignment pass first.';
    end

    musicbp_require(requiredInput, 'file', requiredLabel, requiredHint, logFile);
    musicbp_log(logFile, ...
        'alignpara band %d using %s with manual ts11=%.3f refst=%d cutoff=%.3f', ...
        Band_for_align, requiredLabel, ts11, refst, cutoff);

    suggestion = align_para(path, Band_for_align, cutoff, logFile);
    if ~isempty(suggestion)
        fprintf('step1: suggested refst=%d, ts11=%.3f (evaluated ts11=%.3f).\n', ...
            suggestion.refst, suggestion.raw_ts11, suggestion.used_ts11);
        musicbp_log(logFile, ...
            'alignpara recommendation band %d: refst=%d raw_ts11=%.3f used_ts11=%.3f avg_corr=%.6f', ...
            Band_for_align, suggestion.refst, suggestion.raw_ts11, ...
            suggestion.used_ts11, suggestion.average_correlation);
    end
end

if alignBP_flag == 1
    fprintf('step1: running alignment for band %d.\n', Band_for_align);

    if Band_for_align == 1
        requiredInput = fullfile(profile.input_dir, 'data0.mat');
        requiredLabel = 'data0.mat';
        requiredHint = 'Please run readBP_flag first to generate mainshock data.';
    else
        requiredInput = fullfile(profile.input_dir, sprintf('data%d.mat', Band_for_align - 1));
        requiredLabel = sprintf('data%d.mat', Band_for_align - 1);
        requiredHint = 'Please finish the previous manual alignment pass first.';
    end

    musicbp_require(requiredInput, 'file', requiredLabel, requiredHint, logFile);
    inputData = load(requiredInput, 'ret');
    inputRet = inputData.ret;
    inputStations = size(inputRet.xori, 1);

    if refst > 0
        refName = strtrim(inputRet.nm(refst, :));
        refLon = inputRet.lon(refst);
        refLat = inputRet.lat(refst);
        refSummary = sprintf('station %d (%s, lon=%.3f, lat=%.3f)', ...
            refst, refName, refLon, refLat);
    else
        refSummary = 'stacked trace';
    end

    musicbp_log(logFile, ...
        'align band %d using %s: input_stations=%d ts11=%.3f refst=%d cutoff=%.3f reference=%s', ...
        Band_for_align, requiredLabel, inputStations, ts11, refst, cutoff, refSummary);

    align_BP(path, Band_for_align, ts11, refst, cutoff, plotscale, logFile);

    outputData = load(fullfile(profile.input_dir, sprintf('data%d.mat', Band_for_align)), 'ret');
    ret = outputData.ret;
    outputStations = size(ret.xori, 1);
    fprintf('step1: align band %d kept %d/%d stations after cutoff %.2f.\n', ...
        Band_for_align, outputStations, inputStations, cutoff);
    musicbp_log(logFile, ...
        'alignment finished for band %d: stations kept %d/%d', ...
        Band_for_align, outputStations, inputStations);

    ret.x = ret.xori;
    fl = 0.05;
    fh = 2;
    parrPlot = 40;
    nor_win = 10;
    [BB, AA] = butter(4, [fl fh] / (ret.sr / 2));
    for i = 1:length(ret.lon)
        ret.x(i, :) = filter(BB, AA, ret.xori(i, :));
        ret.x(i, :) = ret.x(i, :) / std(ret.x(i, parrPlot * ret.sr:(parrPlot + nor_win) * ret.sr));
    end
    ret.x(:, 1:200) = 0;
    ret.x(:, 3000:end) = 0;
    ret.scale = 0.1;
    hAlignPreview = figure( ...
        'Name', sprintf('mainshock - data%d align preview', Band_for_align), ...
        'NumberTitle', 'off');
    plotAll1(ret);
    figure(hAlignPreview);
    drawnow;
    pause(0.05);
    drawnow;
    print(hAlignPreview, ...
        fullfile(profile.fig_dir, sprintf('data%d_align_preview.png', Band_for_align)), ...
        '-dpng', '-r200');
    figure(hAlignPreview);
    drawnow;
    pause(0.05);
    drawnow;
end

if runBPbmfm_flag == 1
    fprintf('step1: running beamforming BP.\n');
    musicbp_require(profile.ptimesdepth_file, 'file', 'Ptimesdepth.mat', ...
        'Please confirm that the travel-time table exists in SEBP/funcLib/libBP.', logFile);
    musicbp_require(fullfile(profile.input_dir, sprintf('data%d.mat', inputband)), ...
        'file', sprintf('data%d.mat', inputband), ...
        'Please finish the mainshock alignment step first.', logFile);

    BPfile = setparBP(path, inputband, Band, lon0, lat0, dep, parr, over, ps, qs, lonrange, latrange, ...
        profile.bp.win);
    bpInfo = load(BPfile, 'ret');
    outputDir = fullfile(profile.input_dir, [bpInfo.ret.dirname '_bmfm_Dir']);
    musicbp_log(logFile, 'running beamforming BP with parameter file %s', BPfile);
    musicbp_log(logFile, 'beamforming output directory: %s', outputDir);

    runteleBPbmfm(path, BPfile, logFile);
    musicbp_require(fullfile(outputDir, 'parret.mat'), 'file', 'beamforming parret.mat', ...
        'Beamforming BP did not produce the expected output directory contents.', logFile);
    cd(outputDir);
    posteriorBPbmfm;
    cd(stepStartDir);
    musicbp_log(logFile, 'beamforming BP finished for %s', bpInfo.ret.dirname);
end

if runBPmusic_flag == 1
    fprintf('step1: running MUSIC BP.\n');
    musicbp_require(profile.ptimesdepth_file, 'file', 'Ptimesdepth.mat', ...
        'Please confirm that the travel-time table exists in SEBP/funcLib/libBP.', logFile);
    musicbp_require(fullfile(profile.input_dir, sprintf('data%d.mat', inputband)), ...
        'file', sprintf('data%d.mat', inputband), ...
        'Please finish the mainshock alignment step first.', logFile);

    BPfile = setparBP(path, inputband, Band, lon0, lat0, dep, parr, over, ps, qs, lonrange, latrange, ...
        profile.bp.win);
    bpInfo = load(BPfile, 'ret');
    outputDir = fullfile(profile.input_dir, [bpInfo.ret.dirname '_MUSIC_Dir']);
    musicbp_log(logFile, 'running MUSIC BP with parameter file %s', BPfile);
    musicbp_log(logFile, 'MUSIC output directory: %s', outputDir);

    runteleBPmusic(path, BPfile, logFile);
    musicbp_require(fullfile(outputDir, 'parret.mat'), 'file', 'MUSIC parret.mat', ...
        'MUSIC BP did not produce the expected output directory contents.', logFile);
    cd(outputDir);
    posteriorBPmusic;
    cd(stepStartDir);
    musicbp_log(logFile, 'MUSIC BP finished for %s', bpInfo.ret.dirname);
end

fprintf('step1: finished.\n');
musicbp_log(logFile, 'INFO', 'step1 session end');
