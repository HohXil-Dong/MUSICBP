function suggestion = align_para(path, Band, cutoff, logFile)
%ALIGN_PARA Suggest ts11 and refst values for one manual alignment pass.

if nargin < 4
    logFile = '';
end

filename = strcat(path, 'Input/data', num2str(Band - 1));
load(filename);
[fl, fh, win, range] = alignband(Band);

ret.x = ret.xori;
load ptimes;

[n, ~] = size(ret.x);
[BB, AA] = butter(4, [fl fh] / (ret.sr / 2));
for i = 1:n
    ret.x(i, :) = filter(BB, AA, ret.x(i, :));
end

P_a = [];
ts = [];
siz = size(ret.x);
for i = 1:siz(1)
    rets = ret.x(i, :).';
    pa = aic_pick(rets, 'whole', 'n');
    P_a(i) = pa / 10; %#ok<AGROW>
end

if Band == 1
    for i = 1:size(ret.x, 1)
        ts(i) = P_a(i) - 15; %#ok<AGROW>
        if ts(i) < 0
            ts(i) = 1;
        end
    end
end
if Band == 2
    for i = 1:size(ret.x, 1)
        ts(i) = P_a(i) - 7.5; %#ok<AGROW>
        if ts(i) < 0
            ts(i) = 1;
        end
    end
end
if Band == 3
    for i = 1:size(ret.x, 1)
        ts(i) = P_a(i) - 4; %#ok<AGROW>
        if ts(i) < 0
            ts(i) = 1;
        end
    end
end
if Band == 4
    for i = 1:size(ret.x, 1)
        ts(i) = P_a(i) - 4; %#ok<AGROW>
        if ts(i) < 0
            ts(i) = 1;
        end
    end
end
if Band == 5
    for i = 1:size(ret.x, 1)
        ts(i) = P_a(i) - 5; %#ok<AGROW>
        if ts(i) < 0
            ts(i) = 1;
        end
    end
end

sumCor = [];
usedTs = nan(1, siz(1));
index = 1;

for i = 1:10:siz(1)
    sumCor(i) = 0; %#ok<AGROW>
    align = getcoff();
    align.ts11 = ts(i);
    if align.ts11 > 100 || align.ts11 < 20
        align.ts11 = 60;
    end
    usedTs(i) = align.ts11;
    align.win = win;
    align.lt = 400;
    align.range = range;
    align.refst = i;
    align.cutoff = cutoff;
    rets = getcoff(ret, align);
    for j = 1:siz(1)
        sumCor(i) = sumCor(i) + rets.mxcr1(j);
    end

    if ~isempty(logFile)
        musicbp_log(logFile, ...
            'alignpara band %d candidate refst=%d raw_ts11=%.3f used_ts11=%.3f avg_corr=%.6f', ...
            Band, i, ts(i), align.ts11, sumCor(i) / siz(1));
    end
end

for i = 1:10:siz(1)
    if sumCor(index) < sumCor(i)
        index = i;
    end
end

n_refst = index;
ave_cor = sumCor(index) / siz(1);
ret.cor = ave_cor;

suggestion = struct( ...
    'refst', n_refst, ...
    'raw_ts11', ts(n_refst), ...
    'used_ts11', usedTs(n_refst), ...
    'average_correlation', ave_cor);
end
