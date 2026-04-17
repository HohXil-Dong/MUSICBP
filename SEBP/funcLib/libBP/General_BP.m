% Comment *****
%
clear
close all;
address='/home/liuwei/Workflow/BP2/Workshop2019/';            % address of paths that need to be added below
addpath(genpath(strcat(address,'funcLib/')));   % directory of Back-Projection functions

%% Work to do (do=1, not_do=0)
Initial_flag=1;     % Initialize a project
readBP_flag=10;      % Read seismogram from .SAC files
alignpara_flag=10;   % Get parameters for alignment
alignBP_flag=10;     % Hypocenter alignment
runBPbmfm_flag=10;   % Beamforming Back-projection
runBPmusic_flag=10;  % MUSIC Back-Projection

%% Parameters for read
workPath= '/home/liuwei/Workflow/BP2/Workshop2019/practice/2020/'; % DON'T FORGET '/' at the end
project = '2020event2_Alaska';% name of the project, e.g. Tohoku_2011
num_eve=2;                %mark the number of event, start from 0
% lon0=169.35;           % lontitude
% lat0=54.16;            % latitude
% dep=30.5;               % depth
% Mw=7.7;                 % magenitude
% strike1=50              % strike 1
% strike2=300              % strike 2
cd(workPath);
fid = fopen('eventformat.txt','r');      %the file contain basic information about events
C = textscan(fid,'%f %f %f %f %f %f %f');
fclose(fid);
dep=C{1,2}(num_eve+1);               % depth
lon0=C{1,4}(num_eve+1);           % lontitude
lat0=C{1,3}(num_eve+1);            % latitude
Mw=C{1,5}(num_eve+1);                 % magenitude
strike1=C{1,6}(num_eve+1);          %strike1
strike2=C{1,7}(num_eve+1);          %strike2

sr=10;                  % sample rate
ori=60;                 % how long the data start before P-arrival time (when download data)
display=360;            % time length of waveform showing by plotAll1(ret)
plotscale=1.5;          % plotscale:  scaling of the amplitudes of seismograms


%% Parameters for alignment
Band_for_align=1;       % different freqency choice for alignment times
align(1,:)=[54,40,0.7];	% 1st align: freq band=[0.1,0.25];windowLength=30;maxShift=5
align(2,:)=[61,40,0.6]; % 2nd align: freq band=[0.25,0.5];windowLength=15;maxShift=0.6
align(3,:)=[64,40,0.6]; % 3rd align: freq band=[0.5, 1.0];windowLength=8;maxShift=0.1
align(4,:)=[64,0, 0.6];	% 4th align: freq band=[0.5, 1.0];windowLength=8;maxShift=0.1
align(5,:)=[0 ,0, 0.0];	% 5th align: freq band=[1.0, 4.0];windowLength=6;maxShift=0.05
ts11  =align(Band_for_align,1);                % how long the data start before P-arrival time
refst =align(Band_for_align,2);                % the number of reference seismogram, first not zero
cutoff=align(Band_for_align,3);             % threshold of the cross-correlation coefficient


%% Parameeters for setpar/runteleBP
inputband=2;            % number of align_data used for runteleBP
parr=60;                % P arrival time, could be same as tsll
over=40;               % duration of runteleBP
qs=120;                 % longitudinal griding
ps=120;                 % latitudinal griding
latrange=[-3 3];        % latitudinal range
lonrange=[-3 3];        % longitudinal range
    %%% Band choice
    Band=4;             % frequency choice for setparBP/runteleBP
                        % for details, look at function 'band_select.m'
    	% Band=1 [0.05,0.25]; Band=2 [0.25,1.0]; Band=3 [0.5,1]
    	% Band=4 [0.5,2]    ; Band=5 [1,4]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PROCESSING SESSION. NO CHANGE. %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path = [workPath,project,'/'];
if Initial_flag==1
    fprintf( ' Initialize Project \n')
    initialize_BP(address,workPath,strcat(project,'/'));
end
if readBP_flag==1
    fprintf('Run readBP\n');
    Preshift=false; % no change!
    addfilelist(path)
    readteleBP(path,lon0,lat0,sr,ori,display,Preshift,plotscale,strike1,strike2,Mw)
    check_data(path,1);   %check the data, remove NaN and Inf in the data0
end
if alignpara_flag==1
    fprintf( ' Get paramenters for alignment \n')
    align_para(path,Band_for_align,cutoff);
end
if alignBP_flag==1
    fprintf( 'Run alignBP\n');
    align_BP(path,Band_for_align,ts11,refst,cutoff,plotscale)
end
if runBPbmfm_flag==1
    fprintf( 'Running Beamforming BP\n');
    [BPfile]=setparBP(path,inputband,Band,lon0,lat0,dep,parr,over,ps,qs,lonrange,latrange);
    runteleBPbmfm(path,BPfile);
end
if runBPmusic_flag==1
    fprintf( 'Running MUSIC BP\n');
    [BPfile]=setparBP(path,inputband,Band,lon0,lat0,dep,parr,over,ps,qs,lonrange,latrange);
    runteleBPmusic(path,BPfile);
end