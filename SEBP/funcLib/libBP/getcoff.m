function ret = getcoff(ret, align)
%GETCOFF Compute cross-correlation coefficients for alignment parameter search.

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
    'shiftT1bool', false);

if ~nargin
    ret = def;
    return;
elseif nargin < 2
    align = def;
end

[nel, ~] = size(ret.x);
x = ret.x;
sr = ret.sr;
[BB, AA] = butter(4, align.bp / (sr / 2));

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
    else
        xx0 = x(refst, ts11 * sr:(ts11 + win) * sr);
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

    for i = 1:nel
        mma = max(xcr(i, :));
        if mma < cutoff && ~isnan(cutoff)
            B(i) = 0;
        end
        for j = 1:lt
            if abs(xcr(i, j)) == mma
                timeshift(i) = tou(j);
                mxcr(i) = xcr(i, j);
            end
        end
    end
end

if exist('mxcr', 'var')
    ret.mxcr1 = mxcr;
end
end
