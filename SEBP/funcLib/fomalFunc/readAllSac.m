function ret = readAllSac(dir, myOpr)
%READALLSAC Read SAC files in a directory and return waveform metadata.

def = struct( ...
    'FileList', 'filelist', ...
    'lat0', 0, ...
    'lon0', 0, ...
    'bpbool', false, ...
    'bp', [0.5 2], ...
    'snrFilterbool', false, ...
    'ori', 140, ...
    'snrFilter', [0.05 0.5 2 -20 -10 5 10], ...
    'distanceFilterbool', false, ...
    'distanceFilter', [26 28.5], ...
    'orderDistancebool', false, ...
    'sr', 20, ...
    'alignbool', false, ...
    'nrt', 0, ...
    'resample', 0, ...
    'dec', 0, ...
    'timesegment', [0 0], ...
    'filelistdir', '', ...
    'log_file', '', ...
    'align', seismoAlign());

if ~nargin
    ret = def;
    return;
elseif nargin < 2
    Opr = def;
elseif nargin < 3
    Opr = myOpr;
else
    error('too many parameters');
end

FileList = Opr.FileList;
lat0 = Opr.lat0;
lon0 = Opr.lon0;
logFile = '';
if isfield(Opr, 'log_file')
    logFile = Opr.log_file;
end
hasLogger = ~isempty(logFile) && exist('musicbp_log', 'file') == 2;

if strcmp(Opr.filelistdir, '') == 1
    filelistdir = dir;
else
    filelistdir = Opr.filelistdir;
end

fid = fopen([filelistdir FileList]);
if fid < 0
    error('musicbp:missingFileList', 'Unable to open file list: %s', [filelistdir FileList]);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

count = 1;
r = zeros(1, 2);
nm = zeros(1, 8);
rdis = zeros(1, 1);
az = zeros(1, 1);
time = zeros(1, 1);
x = zeros(1, 1);
t1 = zeros(1, 1);

if Opr.resample ~= 0
    Opr.sr = Opr.sr * Opr.resample;
end

while ~feof(fid)
    [B, A] = butter(4, Opr.snrFilter(2:3) / (Opr.sr / 2));
    [BB, AA] = butter(4, Opr.bp / (Opr.sr / 2));

    dataname = strtrim(fgetl(fid));
    if isempty(dataname)
        continue;
    end
    if hasLogger
        musicbp_log(logFile, 'readAllSac: reading file %s', dataname);
    end

    [Ztime, Zdata, ZSAChdr] = fget_sac([dir dataname]);
    Ztime = [ZSAChdr.times.b:ZSAChdr.times.delta:(ZSAChdr.data.trcLen - 1) * ZSAChdr.times.delta + ZSAChdr.times.b]';

    rx = ZSAChdr.station.stlo;
    ry = ZSAChdr.station.stla;
    original_sr = 1 / ZSAChdr.times.delta;
    et = ZSAChdr.event;

    recordtime0 = datenum(et.nzyear, 1, 1, et.nzhour, et.nzmin, ...
        et.nzsec + et.nzmsec / 1000) + et.nzjday;
    if Opr.timesegment(1) ~= Opr.timesegment(2)
        time_int = Opr.timesegment(1):1 / original_sr / 3600 / 24:Opr.timesegment(2);
        time_ori = recordtime0 + Ztime / 3600 / 24;
        ZZdata = interp1(time_ori, Zdata, time_int);
        ZZtime = interp1(time_ori, Ztime, time_int);
        clear Ztime Zdata;
        Ztime = ZZtime;
        Zdata = ZZdata;
    end

    dep0 = et.evdp;
    decimationFactor = round(original_sr / Opr.sr);
    if hasLogger
        musicbp_log(logFile, ...
            'readAllSac: station %s lon=%.3f lat=%.3f original_sr=%.3f target_sr=%.3f decimation=%d samples=%d', ...
            strtrim(ZSAChdr.station.kstnm), rx, ry, original_sr, Opr.sr, decimationFactor, length(Zdata));
    end

    Zdata = decimate(Zdata, decimationFactor);
    Ztime = decimate(Ztime, decimationFactor);
    Zdata = Zdata - mean(Zdata);

    if Opr.resample ~= 0
        Zdata = interp(Zdata, Opr.resample);
        Ztime = interp(Ztime, Opr.resample);
    end

    if Opr.snrFilterbool == true
        z0data = filter(B, A, Zdata);
        snrValue = std(z0data((Opr.ori + Opr.snrFilter(4)) * Opr.sr:(Opr.ori + Opr.snrFilter(5)) * Opr.sr)) / ...
            std(z0data((Opr.ori + Opr.snrFilter(6)) * Opr.sr:(Opr.ori + Opr.snrFilter(7)) * Opr.sr));
        if snrValue >= Opr.snrFilter(1)
            if hasLogger
                musicbp_log(logFile, 'readAllSac: skipped %s due to snr filter (value=%.6f)', dataname, snrValue);
            end
            continue;
        end
    end

    if Opr.distanceFilterbool == true
        stationDistance = distance11(ry, rx, lat0, lon0, 1) * 180 / pi;
        if stationDistance > Opr.distanceFilter(2) || stationDistance < Opr.distanceFilter(1)
            if hasLogger
                musicbp_log(logFile, ...
                    'readAllSac: skipped %s due to distance filter (distance=%.3f deg)', ...
                    dataname, stationDistance);
            end
            continue;
        end
    end

    x(count, 1:length(Zdata)) = Zdata;
    time(count, 1:length(Zdata)) = Ztime(1:length(Zdata));
    r(count, 1) = rx;
    r(count, 2) = ry;
    t1(count) = Ztime(1);
    et = ZSAChdr.event;
    recordtime(count) = datenum(et.nzyear, 1, 1, et.nzhour, et.nzmin, ...
        et.nzsec + et.nzmsec / 1000) + et.nzjday;
    name = ZSAChdr.station.kstnm;
    nm(count, 1:8) = name(1:8);
    rdis(count) = distance11(ry, rx, lat0, lon0, 1) * 180 / pi;
    [~, az(count)] = vdist(ry, rx, lat0, lon0);
    lat(count) = ZSAChdr.station.stla;
    lon(count) = ZSAChdr.station.stlo;
    count = count + 1;
end

nel = count - 1;
timeshift = zeros(1, nel);
recordtimesec = (recordtime - recordtime(1)) * 24 * 3600;

ret = struct( ...
    'r', r, ...
    'nm', char(nm), ...
    'lat', lat, ...
    'lon', lon, ...
    'lat0', lat0, ...
    'lon0', lon0, ...
    'dep0', dep0, ...
    'rdis', rdis, ...
    'az', az, ...
    'time', time, ...
    'recordtime', recordtime, ...
    'recordtimesec', recordtimesec, ...
    'timeshift', timeshift, ...
    't1', t1, ...
    'x', x, ...
    'sr', Opr.sr, ...
    'ori', Opr.ori, ...
    'opr', Opr);

if hasLogger
    musicbp_log(logFile, 'readAllSac: accepted %d traces from %s', nel, dir);
end

if Opr.nrt ~= 0
    for i = 1:nel
        ret.x(i, :) = sign(ret.x(i, :)) .* (abs(ret.x(i, :))) .^ (1 / Opr.nrt);
    end
end

if Opr.orderDistancebool == true
    ret = orderDistance(ret);
end

if Opr.alignbool == true
    ret = seismoAlign(ret, Opr.align);
end

if Opr.bpbool == true
    for i = 1:nel
        ret.x(i, :) = filter(BB, AA, ret.x(i, :));
    end
    if Opr.alignbool == true
        for i = 1:nel
            ret.x1(i, :) = filter(BB, AA, ret.x1(i, :));
        end
    end
end

if Opr.dec ~= 0
    x = ret.x;
    x1 = ret.x1;
    clear ret.x ret.x1;
    for i = 1:nel
        xx(i, :) = decimate(x(i, :), Opr.dec); %#ok<AGROW>
        xx1(i, :) = decimate(x1(i, :), Opr.dec); %#ok<AGROW>
    end
    ret.x = xx;
    ret.x1 = xx1;
    Opr.sr = Opr.sr / Opr.dec;
    ret.sr = Opr.sr;
end
end
