function ret = seismoAlign(ret, align)
%SEISMOALIGN Align seismograms using cross-correlation around first arrivals.

def = struct( ...
    'win', 9, ...
    'lt', 100, ...
    'ts11', 140, ...
    'range', 10, ...
    'cutoff', 0, ...
    'refst', 1, ...
    'bpbool', 0, ...
    'bp', [0.5 2], ...
    'timeShiftKnown', 0, ...
    'shiftT1bool', false, ...
    'log_file', '', ...
    'band', []);

if ~nargin
    ret = def;
    return;
elseif nargin < 2
    align = def;
end

[nel, ~] = size(ret.x);
x = ret.x;
x0 = ret.x;
sr = ret.sr;
[BB, AA] = butter(4, align.bp / (sr / 2));

logFile = '';
if isfield(align, 'log_file')
    logFile = align.log_file;
end
hasLogger = ~isempty(logFile) && exist('musicbp_log', 'file') == 2;

if align.bpbool == true
    for i = 1:nel
        x(i, :) = filter(BB, AA, x(i, :));
    end
end

win = align.win;
lt = align.lt;
ts11 = align.ts11;
range = align.range;
cutoff = align.cutoff;
refst = align.refst;
timeshift = zeros(1, nel);
t3 = (0:length(x) - 1) / sr;
timeShiftKnown = align.timeShiftKnown;
shiftT1bool = align.shiftT1bool;
B = 1:nel;

if timeShiftKnown(1) ~= 0
    timeshift = timeShiftKnown;
elseif shiftT1bool == true
    timeshift = ret.t1 - 200;
else
    if refst == 0
        xx0 = mean(x(:, ts11 * sr:(ts11 + win) * sr), 1);
        referenceSummary = 'stacked trace';
    else
        xx0 = x(refst, ts11 * sr:(ts11 + win) * sr);
        referenceSummary = sprintf('station %d (%s, lon=%.3f, lat=%.3f)', ...
            refst, strtrim(ret.nm(refst, :)), ret.lon(refst), ret.lat(refst));
    end

    tou = linspace(-range, range, lt);
    xcr = zeros(nel, lt);
    mxcr = zeros(1, nel);

    for i = 1:nel
        for j = 1:lt
            ts22 = ts11 + tou(j);
            tip = linspace(ts22, ts22 + win, win * sr + 1);
            xx = interp1(t3, x(i, :), tip);
            xcr(i, j) = sum(xx0 .* xx) / sqrt(sum(xx0 .^ 2) * sum(xx .^ 2));
        end
    end

    cutCount = 0;
    for i = 1:nel
        mma = max(xcr(i, :));
        if mma < cutoff && ~isnan(cutoff)
            B(i) = 0;
            cutCount = cutCount + 1;
            if hasLogger
                musicbp_log(logFile, ...
                    'align band %s: cut station %d (%s, lon=%.3f, lat=%.3f), max_xcorr=%.6f', ...
                    local_band_label(align), i, strtrim(ret.nm(i, :)), ret.lon(i), ret.lat(i), mma);
            end
        end
        for j = 1:lt
            if abs(xcr(i, j)) == mma
                timeshift(i) = tou(j);
                mxcr(i) = xcr(i, j);
            end
        end
    end

    if hasLogger
        musicbp_log(logFile, ...
            'align band %s: input_stations=%d reference=%s ts11=%.3f cutoff=%.3f cut=%d kept=%d', ...
            local_band_label(align), nel, referenceSummary, ts11, cutoff, cutCount, nel - cutCount);
    end
end

timeshift = timeshift - timeshift(1);
x1 = zeros(nel, length(x0));
for i = 1:nel
    x1(i, :) = specshift(x0(i, :), timeshift(i) * sr);
end

if isfield(ret, 'xori')
    for i = 1:nel
        ret.xori(i, :) = specshift(ret.xori(i, :), timeshift(i) * sr);
    end
end

x0 = x1;
ret.timeshift = ret.timeshift + timeshift;

B = find(B(:) ~= 0);
ret = orderAll(ret, 0, B);
ret.x = x0(B, :);
if exist('mxcr', 'var')
    ret.mxcr1 = mxcr;
end

function bandLabel = local_band_label(alignStruct)
if isfield(alignStruct, 'band') && ~isempty(alignStruct.band)
    bandLabel = num2str(alignStruct.band);
else
    bandLabel = '?';
end
end

end
