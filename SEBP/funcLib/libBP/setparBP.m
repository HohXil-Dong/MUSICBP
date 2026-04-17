function filename = setparBP(path, inputband, Band, lon0, lat0, dep, parr, over, ps, qs, lonrange, latrange)
% setparBP set parameters for runteleBP/runteleBPmusic/runteleBPmusicCali
%   
%   explaination of the inputs:
%   	path:     	the working address of current project or event, 
%                       e.g. /home/USER/BackProjection/Mexico2017.
%    	Band:           
%     	ts11:     	P arrival time since the straight one (records)
%                       i.e. how long the data start before P-arrival time
%     	refst:   	
%       cutoff:     
%       plotscale:  scaling of the amplitudes of seismograms
%   

%   Copyright 2013-2017 Han Bao & Lingsen Meng's group, UCLA.


fileinput = strcat(path, 'Input/data', num2str(inputband));

load(fileinput);
ret.lon0 = lon0;
ret.lat0 = lat0;
ret.dep0 = dep;
ret.parr = parr;
ret.begin = 0;
ret.end = over;
ret.step = 1;
ret.ps = ps;
ret.qs = qs;
ret.lonrange = lonrange;
ret.latrange = latrange;
% frequency
[fl, fh] = band_select(Band);
ret.fl = fl;
ret.fh = fh;
ret.fs = 2;
ret.win = 10;
% fl 0.5 fh 2 win 10
ret.dirname = strcat('Par', num2str(fl), '_', num2str(fh), '_', num2str(ret.win));
ret.Nw = 0.5;
filename = strcat(path, 'Input/', ret.dirname, '.mat');
save(filename, 'ret', '-v7.3');
end
