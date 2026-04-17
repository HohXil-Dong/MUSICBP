% SEBP_STEP5
% Apply the same slowness correction derived from aftershocks to the
% mainshock MUSIC BP result.

clear;
close all;

scriptDir = fileparts(mfilename('fullpath'));
addpath(fullfile(scriptDir, 'common'));
[cfg, profile, logFile] = musicbp_step_setup(mfilename('fullpath'), mfilename, 'maduo_2021'); %#ok<ASGLU>

%% PRE-SET
%%% INPUT
mother_loc = profile.mainshock_dir;
ap_ca_loc = profile.ca_ap_loc_file;
ref = profile.ref_station;

musicbp_require(mother_loc, 'dir', 'mainshock working directory', 'Please confirm that the mainshock directory exists.', logFile);
musicbp_require(profile.ptimesdepth_file, 'file', 'Ptimesdepth.mat', ...
    'Please confirm that the travel-time table exists in the SEBP function library.', logFile);
musicbp_require(profile.main_bp_file, 'file', 'mainshock BP parameter file', ...
    'Please run SEBP_step1.m first.', logFile);
musicbp_require(ap_ca_loc, 'file', 'ca_ap_loc.mat', ...
    'Please prepare the aftershock apparent/catalog locations and generate ca_ap_loc.mat first.', logFile);

%% Main cali
startDir = pwd;

load(profile.main_bp_file);
load(ap_ca_loc); % Load ca and ap location of aftershocks.
n_evt = min([numel(lat_ca), numel(lon_ca), numel(lat_ap), numel(lon_ap)]);
if ~isempty(profile.max_events)
    n_evt = min(n_evt, profile.max_events);
end
lat_ca = lat_ca(1:n_evt);
lon_ca = lon_ca(1:n_evt);
lat_ap = lat_ap(1:n_evt);
lon_ap = lon_ap(1:n_evt);
musicbp_log(logFile, 'INFO', ...
    'config: main basename=%s ref_station=%d aftershock_count=%d', ...
    profile.bp.basename, ref, n_evt);
fprintf('step5: calibrating mainshock using %d aftershocks.\n', n_evt);

%% STEP 1: Get slowness error for the mainshock.
lat_sta = ret.lat;
lon_sta = ret.lon;
dep_ca = repmat(ret.dep0, n_evt, 1); % AF catalog depth
lat_c = mean(lat_ap);
lon_c = mean(lon_ap);
dep_c = ret.dep0; % geometrical center

dS2Dplus = get_dS_2Dplus(lat_sta, lon_sta, lat_c, lon_c, dep_c, ...
    lat_ca, lon_ca, dep_ca, lat_ap, lon_ap, ref); % IMPORTANT
ret.dS0 = dS2Dplus.dS0;
ret.dSx = dS2Dplus.dSx;
ret.dSy = dS2Dplus.dSy;
musicbp_log(logFile, 'INFO', ...
    'mainshock slowness correction dS0=%.6f dSx=%.6f dSy=%.6f', ...
    ret.dS0, ret.dSx, ret.dSy);

save(profile.main_bp_calibrated_file, 'ret');

%% runCali
x0 = ret.xori;              % wave data
ret = rmfield(ret, 'xori'); % remove ret.xori to save RAM
r = ret.r;                  % stations' location
lon0 = ret.lon0;            % hypocenter longitude
lat0 = ret.lat0;            % hypocenter latitude
dep0 = ret.dep0;            % hypocenter depth

sr = ret.sr;                % sample rate
parr = ret.parr;            % start time
begin = ret.begin;          % always 0
over = ret.end;             % end time
step = ret.step;            % time step
ps = ret.ps;                % number of grids for lat
qs = ret.qs;                % number of grids for lon
uxRange = ret.latrange;     % lat range
uyRange = ret.lonrange;     % lon range
fl = ret.fl;                % frequency low of bandpass
fh = ret.fh;                % frequency high of bandpass
win = ret.win;              % window length for BP
dirname = ret.dirname;      % name of directory that will be created
Nw = ret.Nw;
fs = ret.fs;

[n, ~] = size(x0);
ux = linspace(uxRange(1) + lat0, uxRange(2) + lat0, ps);
uy = linspace(uyRange(1) + lon0, uyRange(2) + lon0, qs);

saveDir = fullfile(profile.input_dir, [dirname '_music_Cali2Dplus_Dir']);
if ~isfolder(saveDir)
    mkdir(saveDir);
end
musicbp_log(logFile, 'INFO', 'mainshock calibrated output directory: %s', saveDir);
cd(saveDir);
fileID = fopen('logfile', 'w');

save('parret', 'ret');

%% Butter Worth Filter
[BB, AA] = butter(4, [fl fh] / (sr / 2));
for i = 1:n
    x0(i, :) = filter(BB, AA, x0(i, :));
end
for i = 1:n
    x0(i, :) = x0(i, :) / std(x0(i, parr * ret.sr:(parr + 30) * ret.sr));
end

%% Use 1D-ref model to build up time table for grid points
Ptimesdepth = load(profile.ptimesdepth_file);
rr = Ptimesdepth.dis;
dd = Ptimesdepth.dep;
tt = Ptimesdepth.Ptt;

tlib = zeros(n, ps, qs);
for p = 1:ps
    for q = 1:qs
        lon_cnt = lon_c;
        lat_cnt = lat_c;
        dx = 111.195 * (lat_cnt - ux(p));
        dy = 111.195 * (lon_cnt - uy(q)) * cosd((lat_cnt + ux(p)) / 2);

        sd = phtime2d(lat0, lon0, dep0, ux(p), uy(q), dep0, r(:, 2), r(:, 1), rr, dd, tt)' ...
            - (ret.dS0 + ret.dSx * dx + ret.dSy * dy); % IMPORTANT
        tlib(:, p, q) = sd - mean(sd);
    end
end
clear sd;

%% Generate power field of the source area (Pm) then pick peaks of each sec
for tl = parr + begin:step:parr + over
    th = tl + win;

    Pm = zeros(ps, qs);
    Pw = zeros(ps, qs);

    S = cmtmall(x0(:, tl * sr:th * sr - 1), Nw);
    s = linspace(0, sr - sr / ((th - tl) * sr), (th - tl) * sr);
    fli = round(interp1(s, 1:length(s), fl));
    fhi = round(interp1(s, 1:length(s), fh));

    %%  for every frequency in the range of fl to fh
    for i = fli:fs:fhi
        s(i); % transfer the serial number back to the frequency
        Pm1 = zeros(ps, qs);
        Pw1 = zeros(ps, qs);
        clear Uv A Un a wi;
        Rxx = zeros(n, n);
        for k = 1:n
            for m = 1:n
                Rxx(k, m) = S(i, k, m);
            end
        end
        [Uv, A] = eig(Rxx); %#ok<ASGLU>
        As = zeros(n, n); %#ok<NASGU>
        un = zeros(n, n);
        us = zeros(n, n); %#ok<NASGU>
        M = rank(Rxx);

        un(:, 1:n - M) = Uv(:, 1:n - M);
        Un = un * un';
        for p = 1:ps
            for q = 1:qs
                a = exp(-1i * 2 * pi * s(i) * tlib(:, p, q));
                Pm1(p, q) = ((a' * a) / (a' * Un * a));
                Pw1(p, q) = ((a' * Rxx * a) / (a' * a));
            end
        end

        Pm = Pm + Pm1;
        Pw = Pw + Pw1;
    end

    %%%%%%%%  Pick power peak for the power field at tl(s) %%%%%%%%%%%%
    tmp1 = peakfit2d(real(Pm));
    bux = interp1(1:length(ux), ux, tmp1(1));
    buy = interp1(1:length(uy), uy, tmp1(2));
    maxp = interp2(1:ps, 1:qs, Pm', tmp1(1), tmp1(2), 'linear', 0);

    tmp2 = peakfit2d(real(Pw));
    bux2 = interp1(1:length(ux), ux, tmp2(1));
    buy2 = interp1(1:length(uy), uy, tmp2(2));
    maxp2 = interp2(1:ps, 1:qs, Pw', tmp2(1), tmp2(2), 'linear', 0);

    fprintf(fileID, '%f %f %f %f %f %f %f\n', tl, bux, buy, maxp, bux2, buy2, maxp2);
    save([num2str(tl - parr - begin) 'smat'], 'Pm', 'Pw');
end

fclose(fileID);
save('parret', 'ret');

posteriorBPmusic;
cd(startDir);
fprintf('step5: finished.\n');
musicbp_log(logFile, 'INFO', 'step5 session end');
