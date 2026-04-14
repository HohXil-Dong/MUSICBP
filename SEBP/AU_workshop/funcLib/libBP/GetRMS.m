clear
close all

%calculate rms
lat_DD=[18.45,18.39,18.49,18.48];
lon_DD=[-73.56,-73.56,-73.75,-73.73];

lat_BP=[18.46,18.4,18.47,18.5];
lon_BP=[-73.55,-73.54,-73.71,-73.71];

lat_cali=[18.44,18.41,18.5,18.52];
lon_cali=[-73.59,-73.6,-73.74,-73.72];

dist_before=[];
dist_cali=[];
for i=1:length(lat_BP)
    dist_before(i)=distance22(lat_DD(i),lon_DD(i),lat_BP(i),lon_BP(i));
    dist_cali(i)=distance22(lat_DD(i),lon_DD(i),lat_cali(i),lon_cali(i));
end

dist_before=dist_before*111.195;
dist_cali=dist_cali*111.195;
R1=rms(dist_before)
R2=rms(dist_cali)