function align_BP(path, Band, ts11, refst, cutoff, plotscale, logFile)
%ALIGN_BP Align seismograms for one earthquake event and one frequency band.

if nargin < 7
    logFile = '';
end

filename = strcat(path, 'Input/data', num2str(Band - 1));
load(filename);
[fl, fh, win, range] = alignband(Band, true);
figDir = fullfile(path, 'Fig');
if ~isfolder(figDir)
    mkdir(figDir);
end
eventDir = regexprep(path, [filesep '$'], '');
[~, eventName] = fileparts(eventDir);
dataStem = sprintf('data%d', Band);
waveformFile = fullfile(figDir, sprintf('%s_align_waveforms.png', dataStem));
stationFile = fullfile(figDir, sprintf('%s_align_stations.png', dataStem));

ret.x = ret.xori;
load ptimes;
if refst ~= 0
    lat_ref = ret.r(refst, 2);
    lon_ref = ret.r(refst, 1);
end

[n, ~] = size(ret.x);
[BB, AA] = butter(4, [fl fh] / (ret.sr / 2));
for i = 1:n
    ret.x(i, :) = filter(BB, AA, ret.x(i, :));
end

align = seismoAlign();
align.ts11 = ts11;
align.win = win;
align.lt = 400;
align.range = range;
align.refst = refst;
align.cutoff = cutoff;
align.band = Band;
align.log_file = logFile;
ret = seismoAlign(ret, align);

ret.scale = plotscale;
ret.lt = 300;
ret.ht = 350;

waveFig = figure( ...
    'Name', sprintf('%s - %s aligned waveforms', eventName, dataStem), ...
    'NumberTitle', 'off');
plotAll1(ret);
figure(waveFig);
drawnow;
pause(0.05);
drawnow;
print(waveFig, waveformFile, '-dpng', '-r200');
figure(waveFig);
drawnow;
pause(0.05);
drawnow;

stationFig = figure( ...
    'Name', sprintf('%s - %s aligned stations', eventName, dataStem), ...
    'NumberTitle', 'off');
plotSta(ret);
if refst ~= 0
    hold on;
    plot(lon_ref, lat_ref, 'r.', 'MarkerSize', 20);
end
figure(stationFig);
drawnow;
pause(0.05);
drawnow;
print(stationFig, stationFile, '-dpng', '-r200');
figure(stationFig);
drawnow;
pause(0.05);
drawnow;

ret.ts11 = ts11;
ret.refst = refst;

filename = strcat(path, 'Input/data', num2str(Band));
save(filename, 'ret', '-v7.3');
musicbp_log(logFile, 'align_BP: saved figures to %s and %s', waveformFile, stationFile);
end
