% Comment *****
% 
clear
close all;
address='/home/liuwei/HPSSD/Qinghai/BP/TeleDD_Loc/AU_workshop/';            % address of paths that need to be added below
addpath(genpath(strcat(address,'funcLib/')));   % directory of Back-Projection functions

%% Work to do (do=1, not_do=0)
Initial_flag=0;     % Initialize a project
readBP_flag=0;      % Read seismogram from .SAC files
alignpara_flag=0;   % Get parameters for alignment
alignBP_flag=0;     % Hypocenter alignment
runBPbmfm_flag=0;   % Beamforming Back-projection
runBPmusic_flag=1;  % MUSIC Back-Projection

%% Parameters for read
workPath= '/home/liuwei/HPSSD/Qinghai/BP/TeleDD_Loc/AU_workshop/'; % DON'T FORGET '/' at the end
cd(workPath);

dep=7.607;              % depth
lon0=98.3622588499;     % lontitude
lat0=34.6202641954;     % latitude
Mw=7.4;                 % magenitude
strike1=0;              % strike 1, not used in the code
strike2=0;              % strike 2, not used in the code

sr=10;                  % sample rate
ori=60;                 % how long the data start before P-arrival time (when download data)
display=360;            % time length of waveform showing by plotAll1(ret)
plotscale=1.0;          % plotscale:  scaling of the amplitudes of seismograms


%% Parameters for alignment
Band_for_align=4;       % different freqency choice for alignment times
align(1,:)=[61.5-15,58,0.7];	% 1st align: freq band=[0.1,0.25];windowLength=30;maxShift=5
align(2,:)=[60.3-7.5,48,0.6]; % 2nd align: freq band=[0.25,0.5];windowLength=15;maxShift=0.6
align(3,:)=[59.9-4,39,0.6]; % 3rd align: freq band=[0.5, 1.0];windowLength=8;maxShift=0.1
align(4,:)=[59.9-4,0,0.6];	% 4th align: freq band=[0.5, 1.0];windowLength=8;maxShift=0.1
align(5,:)=[0 ,0, 0.0];	% 5th align: freq band=[1.0, 4.0];windowLength=6;maxShift=0.05
ts11  =align(Band_for_align,1);                % how long the data start before P-arrival time
refst =align(Band_for_align,2);                % the number of reference seismogram, first not zero
cutoff=align(Band_for_align,3);             % threshold of the cross-correlation coefficient


%% Parameeters for setpar/runteleBP
inputband=4;            % number of align_data used for runteleBP
parr=55;                % P arrival time, could be same as tsll
over=35;               % duration of runteleBP
qs=100;                 % longitudinal griding
ps=100;                 % latitudinal griding
latrange=[-0.8 0.8];        % latitudinal range
lonrange=[-1.5 1.5];        % longitudinal range
    %%% Band choice
    Band=4;             % frequency choice for setparBP/runteleBP
                        % for details, look at function 'band_select.m' 
    	% Band=1 [0.05,0.25]; Band=2 [0.25,1.0]; Band=3 [0.5,1]
    	% Band=4 [0.5,2]    ; Band=5 [1,4]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PROCESSING SESSION. NO CHANGE. %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path = [workPath,'/'];
if Initial_flag==1
    fprintf( ' Initialize Project \n')
    initialize_BP(address,workPath,strcat(project,'/'));
end

if readBP_flag==1
	fprintf('Run readBP\n');
    Preshift=false; % no change!
%     addfilelist(path)
    readteleBP(path,lon0,lat0,sr,ori,display,Preshift,plotscale,strike1,strike2,Mw)
    check_data(path,1);   %check the data, remove NaN and Inf in the data0
    
    load 'Input/data0.mat'
    ret.x=ret.xori;
    fl=0.1; fh=2; parr=53; nor_win = 10;
    [BB,AA]=butter(4,[fl fh]/(ret.sr/2));
for i=1:length(ret.lon)
    ret.x(i,:)=filter(BB,AA,ret.xori(i,:));
    ret.x(i,:)=ret.x(i,:)/std(ret.x(i,parr*ret.sr:(parr+nor_win)*ret.sr));
end
    ret.x(:,1:200)=0; ret.x(:,3000:end)=0;
    ret.scale=0.5;
    figure;plotAll1(ret)
end

if alignpara_flag==1
    fprintf( ' Get paramenters for alignment \n')
    align_para(path,Band_for_align,cutoff);
end

if alignBP_flag==1
    fprintf( 'Run alignBP\n');
    align_BP(path,Band_for_align,ts11,refst,cutoff,plotscale)
    
    load(strcat('Input/data',num2str(Band_for_align),'.mat'));
    ret.x=ret.xori;
    fl=0.05; fh=2; parr=40; nor_win = 10;
    [BB,AA]=butter(4,[fl fh]/(ret.sr/2));
    for i=1:length(ret.lon)
        ret.x(i,:)=filter(BB,AA,ret.xori(i,:));
        ret.x(i,:)=ret.x(i,:)/std(ret.x(i,parr*ret.sr:(parr+nor_win)*ret.sr));
    end
    ret.x(:,1:200)=0; ret.x(:,3000:end)=0;
    ret.scale=0.1;
    figure;plotAll1(ret)
end

if runBPbmfm_flag==1
    fprintf( 'Running Beamforming BP\n');
    [BPfile]=setparBP(path,inputband,Band,lon0,lat0,dep,parr,over,ps,qs,lonrange,latrange);
    runteleBPbmfm(path,BPfile);
    posteriorBPbmfm;
    close all;
end

if runBPmusic_flag==1
    fprintf( 'Running MUSIC BP\n');
    [BPfile]=setparBP(path,inputband,Band,lon0,lat0,dep,parr,over,ps,qs,lonrange,latrange);
    runteleBPmusic(path,BPfile);
    posteriorBPmusic;
    close all;
end
