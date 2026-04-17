%% this code is used to plot GMT figure with HFdots

load parret.mat;

%% load parameter from parret.mat (ret)  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lon0=ret.lon0;          % lon of mainshock
lat0=ret.lat0;          % lat of mainshock
sr=ret.sr;              % sample rate
parr=ret.parr;          % P-arrival time
tend=ret.end-ret.begin; % duration of movie
step=ret.step;          % time step
ps=ret.ps;              % number of lat grids
qs=ret.qs;              % number of lon grids
uxRange=ret.latrange;   % range of latitude
uyRange=ret.lonrange;   % range of longitude
dur=ret.end;            % duration of rupture

%% set GMT parameters
system('gmt gmtset MAP_FRAME_TYPE plain');
system('gmt gmtset FONT_LABEL 10p,Helvetica FONT_ANNOT_PRIMARY Helvetica');
system('gmt gmtset FONT_ANNOT_PRIMARY 10p,Helvetica');
system('gmt gmtset PS_MEDIA A2');
system('gmt gmtset FORMAT_GEO_MAP ddd.x');

minx=lon0+uyRange(1);
maxx=lon0+uyRange(2);
miny=lat0+uxRange(1);
maxy=lat0+uxRange(2);
ProjectionScale=5;

RVALUE=string(minx)+'/'+maxx+'/'+miny+'/'+maxy;
JVALUE="m"+ProjectionScale+"c";

GrdimageDate="/home/liuwei/HPSSD/Supershear/Rupture_speed2/Functionlib/topo15.grd";

BathData="region.nc";
BathDataGradient="region_gradient.nc";

%% make the topography data
system('gmt grdcut '+GrdimageDate+' -R'+RVALUE+' -Gregion.nc');
system('gmt grdgradient '+BathData+' -A0/270 -Nt -Gregion_gradient.nc');

%% make the cpt for topo and rupture time
system('makecpt -Crelief -T-6000/6000/500 > BathColor.cpt');
system('makecpt -Cjet -T0/'+string(dur)+'/1 > Main.cpt');

%% Plot the map
system('gmt grdimage '+BathData+' -I'+BathDataGradient'+' -R -J'+JVALUE+' -Ba0.5f0.5/a0.5f0.5NseW -K -CBathColor.cpt > output.ps');
system('gmt pscoast -R -J -Di -W1.0p,black,-- -O -K >> output.ps');
% plot the epicenter
system('echo '+string(lon0)+' '+string(lat0)+' | gmt psxy -J -R -V -Sa0.6c -Gyellow -W1.0p -O -K >> output.ps');
% plot the rupture
awkcmd="awk '{print $3,$2,$1,$4*0.6}' HFdots ";
system(awkcmd + '| gmt psxy -J  -R -P -Sd -W0.6p -CMain.cpt -O -K -V >> output.ps');
% end of the plot
system('gmt psxy -R -J -O -T >> output.ps');
% convert to pdf and png
system('gmt psconvert -Tf -A output.ps');
system('gmt psconvert -Tg -A output.ps');
