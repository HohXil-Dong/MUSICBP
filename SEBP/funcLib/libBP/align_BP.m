function align_BP(path, Band, ts11, refst, cutoff, plotscale)
%ALIGN_BP Align seismograms for one earthquake event and one frequency band.

filename = strcat(path, 'Input/data', num2str(Band - 1));
load(filename);
[fl, fh, win, range] = alignband(Band);

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
align.log_file = fullfile(path, 'Input', 'SEBP_step1.log');
ret = seismoAlign(ret, align);

ret.scale = plotscale;
ret.lt = 300;
ret.ht = 350;

figure(10 + Band - 1);
plotAll1(ret);
figure(15 + Band - 1);
plotSta(ret);
if refst ~= 0
    hold on;
    plot(lon_ref, lat_ref, 'r.', 'MarkerSize', 20);
end

ret.ts11 = ts11;
ret.refst = refst;

filename = strcat(path, 'Input/data', num2str(Band));
save(filename, 'ret', '-v7.3');

hold off;
end
