function readteleBP(path, lon0, lat0, sr, ori, displayLength, Preshift, plotscale, strike1, strike2, Mw)
%READTELEBP Read .SAC files for one earthquake event.

opr = readAllSac();
opr.bpbool = false;
opr.lon0 = lon0;
opr.lat0 = lat0;
opr.bp = [0.01 2];
opr.snrFilterbool = false;
opr.snrFilter = [0.1 0.1 2 -20 -10 100 130];
opr.sr = sr;
opr.ori = ori;
opr.log_file = fullfile(path, 'Input', 'SEBP_step1.log');

datalog = strcat(path, 'Data/');
ret = readAllSac(datalog, opr);
ret.xori = ret.x;

load ptimes;
[n, m] = size(ret.x);
musicbp_log(opr.log_file, 'readteleBP: loaded %d traces with %d samples', n, m);

figure(1);
plotSta(ret);

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

musicbp_log(opr.log_file, ...
    'readteleBP: kept %d stations after distance filter and sorting', size(ret.xori, 1));

figure(10);
plotAll1(ret);

filename = strcat(path, 'Input/data0');
save(filename, 'ret', '-v7.3');
musicbp_log(opr.log_file, 'readteleBP: saved %s.mat', filename);
end
