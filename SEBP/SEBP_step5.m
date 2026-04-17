% SEBP_STEP5
% Apply the same slowness correction derived from aftershocks to the
% mainshock MUSIC BP result.


clear
close all
scriptDir = fileparts(mfilename('fullpath'));
commonDir = fullfile(scriptDir, 'common');
funcLibDir = fullfile(scriptDir, 'funcLib');
addpath(commonDir);
addpath(genpath(funcLibDir));
cfg = musicbp_config('maduo_2021');
profile = cfg.active;
%% PRE-SET
%%% INPUT
mother_loc = profile.mainshock_dir;
ap_ca_loc  = profile.ca_ap_loc_file;
ref = profile.ref_station;

musicbp_require(mother_loc, 'dir', '主震工程目录', '请确认 mainshock 目录存在。');
musicbp_require(profile.ptimesdepth_file, 'file', 'Ptimesdepth.mat', '请确认 SEBP 函数库中的走时表存在。');
musicbp_require(profile.main_bp_file, 'file', '主震 BP 参数文件', '请先运行 SEBP_step1.m。');
musicbp_require(ap_ca_loc, 'file', 'ca_ap_loc.mat', '请先整理余震 BP 视位置并生成 ca_ap_loc.mat。');


%% Main cali

startDir = pwd;

load(profile.main_bp_file)
load(ap_ca_loc);	% Load ca and ap location of afteshocks
n_evt = min([numel(lat_ca), numel(lon_ca), numel(lat_ap), numel(lon_ap)]);
if ~isempty(profile.max_events)
    n_evt = min(n_evt, profile.max_events);
end
lat_ca = lat_ca(1:n_evt);
lon_ca = lon_ca(1:n_evt);
lat_ap = lat_ap(1:n_evt);
lon_ap = lon_ap(1:n_evt);
    
    
  	%% STEP 1: Get slowness error for the mainshock.
        
        lat_sta=ret.lat; lon_sta=ret.lon;               % stations
        
        dep_ca = repmat(ret.dep0, n_evt, 1); % AF catalog depth
        
        lat_c=mean(lat_ap); lon_c=mean(lon_ap); dep_c =ret.dep0;       % geometrical center
        
        dS2Dplus = get_dS_2Dplus(lat_sta,lon_sta,lat_c,lon_c,dep_c,...
                            lat_ca,lon_ca,dep_ca,lat_ap,lon_ap,ref); % IMPORTANT
        ret.dS0 = dS2Dplus.dS0;
        ret.dSx = dS2Dplus.dSx;
        ret.dSy = dS2Dplus.dSy;
        
save(profile.main_bp_calibrated_file, 'ret')

    %% runCali
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    x0=ret.xori;            % wave data
    ret=rmfield(ret,'xori');% remore ret.xori to save RAM
    r=ret.r;                % stations' location
    lon0=ret.lon0;          % hypocenter longitude
    lat0=ret.lat0;          % hypocenter latitude
    dep0=ret.dep0;          % hypocenter depth

    sr=ret.sr;              % sample rate
    parr=ret.parr;          % start time
    begin=ret.begin;        % always 0
    over=ret.end;           % end time
    step=ret.step;          % time step
    ps=ret.ps;              % number of grids for lat
    qs=ret.qs;              % number of grids for lon
    uxRange=ret.latrange;   % lat range
    uyRange=ret.lonrange;   % lon range
    fl=ret.fl;              % frequence low of bandpass
    fh=ret.fh;              % frequence high of bandpass
    win=ret.win;            % window length for BP
    dirname=ret.dirname;    % name of directory that will be created
    Nw=ret.Nw;
    fs=ret.fs;

    [n,~]=size(x0);         % n: number of stations
    ux=linspace(uxRange(1)+lat0,uxRange(2)+lat0,ps); % lat of grid points
    uy=linspace(uyRange(1)+lon0,uyRange(2)+lon0,qs); % lon of grid points
    
    saveDir=fullfile(profile.input_dir, [dirname '_music_Cali2Dplus_Dir']);
    disp(['Directory: ',saveDir])
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    cd(saveDir);
    fileID=fopen('logfile','w');
    
    save('parret','ret');
%% Butter Worth Filter   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [BB,AA]=butter(4,[fl fh]/(sr/2));
    for i=1:n
    
        x0(i,:)=filter(BB,AA,x0(i,:));
    end
    for i=1:n 
        x0(i,:)=x0(i,:)/std(x0(i,parr*ret.sr:(parr+30)*ret.sr));
    end
%% Use 1D-ref model to build up time table for grid points
    Ptimesdepth=load('Ptimesdepth.mat');    % load 1D ref-model
    rr=Ptimesdepth.dis;     % distance of 1D model
    dd=Ptimesdepth.dep;     % Depth of 1D model
    tt=Ptimesdepth.Ptt;     % travel times for [rr,dd]

    tlib=zeros(n,ps,qs);    % Initialize the time table
    
   
    for p=1:ps              % Grid point [q,p]
        for q=1:qs          % Grid point [q,p]
            
            lon_cnt=lon_c; % center for this grid
            lat_cnt=lat_c; % center for this grid
            
            dx=111.195*(lat_cnt-ux(p));
            dy=111.195*(lon_cnt-uy(q))*cosd((lat_cnt+ux(p))/2);
            
            sd=phtime2d(lat0,lon0,dep0,ux(p),uy(q),dep0,r(:,2),r(:,1),rr,dd,tt)'...
                        -(ret.dS0 + ret.dSx*dx + ret.dSy*dy); % IMPORTANT;
                    
            tlib(:,p,q)=sd-mean(sd); % tlib is the time table we want
        end
    end
    clear sd
    
%% Generate power field of the source area (Pm) then pick peaks of each sec 
 	
for tl=parr+begin:step:parr+over          %for each second
    
    
    th=tl+win;                            %in time window
    display(['t=' num2str(tl-parr-begin) 's']); %show the time


    Pm=zeros(ps,qs);                      %initialize the power space
    Pw=zeros(ps,qs);                      %initialize the power space

    S=cmtmall(x0(:,tl*sr:th*sr-1),Nw);    %S is a n*n autocorrelation matrix, contain the waveform information received by stations
    s=linspace(0,sr-sr/((th-tl)*sr),(th-tl)*sr);%length(s)=win*sr, s is used for the loop
    fli=round(interp1(s,1:length(s),fl)); %the serial number for low limit frequency
    fhi=round(interp1(s,1:length(s),fh)); %the serial number for high limit frequency
%%  for every frequency in the range of fl to fh
    for i=fli:fs:fhi

        s(i)                              %transfer the serial number back to the frequency
        Pm1=zeros(ps,qs);                 %Pm1 is the part of Pm in this frequency
        Pw1=zeros(ps,qs);                 %Pw1 is the part of Pw in this frequency
        clear Uv A Un a wi;
        Rxx=zeros(n,n);
        for j=1:n
            for k=1:n
                Rxx(j,k)=S(i,j,k);        %get the autocorrelation matrix
            end
        end
        [Uv,A]=eig(Rxx);                  %get the eigenvectors
        As=zeros(n,n);
        un=zeros(n,n);
        us=zeros(n,n);
        M=rank(Rxx);
        
        
        
        un(:,1:n-M)=Uv(:,1:n-M);          %un is the useful signal
        
        Un=un*un';
        for p=1:ps
            
            for q=1:qs
                
                a=exp(-1i*2*pi*s(i)*tlib(:,p,q));% a is a n*1 vector
                Pm1(p,q)=((a'*a)/(a'*Un*a));     
                Pw1(p,q)=((a'*Rxx*a)/(a'*a));
            end
        end
        
        Pm=Pm+Pm1;    %sum the Pm1 of in the frequency band 
        Pw=Pw+Pw1;    %sum the Pw1 of in the frequency band 
        
    end
 %%%%%%%%  Pick power peak for the power field at tl(s) %%%%%%%%%%%%
           tmp1=peakfit2d(real(Pm));
            bux=interp1(1:length(ux),ux,tmp1(1));       % lat of peak at time tl
            buy=interp1(1:length(uy),uy,tmp1(2));       % lon of peak at time tl
            maxp=interp2(1:ps,1:qs,Pm',tmp1(1),tmp1(2),'linear',0);% power of peak
            
             tmp2=peakfit2d(real(Pw));
            bux2=interp1(1:length(ux),ux,tmp2(1));      % lat of peak at time tl
            buy2=interp1(1:length(uy),uy,tmp2(2));      % lon of peak at time tl
            maxp2=interp2(1:ps,1:qs,Pw',tmp2(1),tmp2(2),'linear',0);% power of peak
            
            disp(['bm bux ' num2str(tmp2(1)) ' buy ' num2str(tmp2(2)) ' max ' num2str(maxp2)]);

         fprintf(fileID,'%f %f %f %f %f %f %f\n',tl,bux,buy,maxp,bux2,buy2,maxp2);

        save ([  num2str(tl-parr-begin) 'smat'],'Pm','Pw');

end

save('parret','ret');

    % END of current loop
posteriorBPmusic
cd(startDir)
