function readteleBP(path, lon0, lat0, sr, ori, displayLength, Preshift, plotscale, strike1, strike2, Mw, logFile)
%READTELEBP Read .SAC files for one earthquake event.

if nargin < 12
    logFile = '';
end

opr = readAllSac();
opr.bpbool = false;
opr.lon0 = lon0;
opr.lat0 = lat0;
opr.bp = [0.01 2];
opr.snrFilterbool = false;
opr.snrFilter = [0.1 0.1 2 -20 -10 100 130];
opr.sr = sr;
opr.ori = ori;
opr.log_file = logFile;

datalog = strcat(path, 'Data/');
ret = readAllSac(datalog, opr);
ret.xori = ret.x;
figDir = fullfile(path, 'Fig');
if ~isfolder(figDir)
    mkdir(figDir);
end
eventDir = regexprep(path, [filesep '$'], '');
[~, eventName] = fileparts(eventDir);
dataStem = 'data0';
stationMapFile = fullfile(figDir, [dataStem '_station_map.png']);
waveformFile = fullfile(figDir, [dataStem '_waveform_overview.png']);

load ptimes;
[n, m] = size(ret.x);
musicbp_log(opr.log_file, 'readteleBP: loaded %d traces with %d samples', n, m);

stationFig = figure( ...
    'Name', sprintf('%s - %s station map', eventName, dataStem), ...
    'NumberTitle', 'off');
plotSta(ret);
figure(stationFig);
drawnow;
pause(0.05);
drawnow;
print(stationFig, stationMapFile, '-dpng', '-r200');
figure(stationFig);
drawnow;
pause(0.05);
drawnow;

load ptimes;
if Preshift == true
    shift = interp1(rr, tt, ret.rdis);
    for i = 1:n
        ret.x(i, :) = specshift(ret.x(i, :), ret.sr * (shift(i) - shift(1)));
    end
end

ret.xori = ret.x;
fl = 0.1;
fh = 0.5;
[BB, AA] = butter(4, [fl fh] / (ret.sr / 2));
for i = 1:n
    ret.x(i, :) = filter(BB, AA, ret.x(i, :));
end

ret.x = ret.x(:, 1:displayLength * ret.sr);
for i = 1:n
    ret.x(i, :) = ret.x(i, :) / std(ret.x(i, 10 * ret.sr:displayLength * ret.sr));
    ret.xori(i, :) = ret.xori(i, :) / std(ret.xori(i, 10 * ret.sr:displayLength * ret.sr));
end

ret.scale = plotscale;
ret.lt = 300;
ret.ht = 350;

I = find(ret.rdis < 93 & ret.rdis > 30);
ret = orderAll(ret, 0, I);

[~, I] = sort(ret.rdis);
ret = orderAll(ret, 0, I);
keptStationCount = size(ret.xori, 1);

musicbp_log(opr.log_file, ...
    'readteleBP: kept %d/%d stations after distance filter and sorting', keptStationCount, n);

waveFig = figure( ...
    'Name', sprintf('%s - %s waveform overview', eventName, dataStem), ...
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

filename = strcat(path, 'Input/data0');
save(filename, 'ret', '-v7.3');
musicbp_log(opr.log_file, 'readteleBP: saved %s.mat', filename);
musicbp_log(opr.log_file, 'readteleBP: saved figures to %s and %s', stationMapFile, waveformFile);
end
