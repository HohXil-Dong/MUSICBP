% The Multiple Signal Classification (MUSIC) technique
%is a high-resolution technique designed
%to resolve closely spaced simultaneous sources.
%MUSIC enables back-projection imaging (BP)
%with superior resolution than the standard Beamforming techinque.
%MUSICBP is a tutorial code in Matlab
%that images the spatial-temporal evolution of high-frequency radiators
%(as a proxy of rupture front) for large earthquakes.
% You can modify simulation parameters in parts of the code
% that have comments starting as: "**** Set here ..."
% September 3, 2019
% Lingsen Meng (meng@epss.ucla.edu) and Han Bao (hbrandon@ucla.edu)
clear
close all;
scriptDir = fileparts(mfilename('fullpath'));
addpath(scriptDir);
%% *** Set here the processing steps to perform (positive=1, negtive=0)****
Initial_flag=0;     % Initializing a new project
readBP_flag=0;      % Reading seismogram from .SAC files
alignBP_flag=0;     % Hypocenter alignment
runBPbmfm_flag=0;   % Beamforming Back-projection
runBPmusic_flag=1;  % MUSIC Back-Projection

%% *** Set here the parameters to initialize the project and read the SAC files***
project = 'Tohoku_2011'; % name of the project
lon0=142.373;          % hypocenter longitude
lat0=38.297;          % hypocenter latitude
dep=20.0;           % hypocenter depth
Mw=9.0;                % magnitude
sr=10;                % sampling rate in Hz
ori=60;             % length of seismograms before P-arrival
displayLength=360;  % length of waveforms to be displayed
plotScale=1.5;      % amplitude scaling factor of seismograms

%% *** Set here the Parameters for Hypocenter alignment ***
bandChoice=4;       % Choice of the alignment frequency band.
align = [ ...
    54, 55, 0.80; ...
    61, 55, 0.80; ...
    64, 55, 0.80; ...
    64, 0, 0.80];
ts  = align(bandChoice,1); % start of the alignment window
refSta = align(bandChoice,2); % No. of the reference seismogram, set to zero for the stacked seismogram
cutoff= align(bandChoice,3); % cutoff threshold of the cross-correlation coefficient


%% *** Set here the Parameters for back-projection runner ***
inputBand=4;        % number of aligned seismograms used as input
parr=61;            % P-wave arrival time
duration=150;       % earthquake duration
qs=120;             % number of grids in latitude
ps=120;             % number of grids in longitude
latrange=[-3.0 3.0];% latitude length of the imaging domain
lonrange=[-3.0 3.0];% longitude length of the imaging domain
Band=4;             % frequency band for the back-projection
% Band=1 [0.10,0.25](Hz); Band=2 [0.25,1.0]; Band=3 [0.5,1]; Band=4 [0.5,2]; Band=5 [1,4]

%% *** NO CHANGE BELOW THIS LINE ***
workPath = scriptDir;
projectDir = fullfile(scriptDir, project);
inputDir = fullfile(projectDir, 'Input');
dataDir = fullfile(projectDir, 'Data');
path = [projectDir filesep];
if Initial_flag==1
    fprintf( ' Initializing... \n')
    initialize_BP(scriptDir, workPath, project);
end
if readBP_flag==1
    fprintf('Reading seismograms\n');
    Preshift=false; % no change!
    if ~isfolder(inputDir)
        mkdir(inputDir);
    end
    require_path(dataDir, 'dir', 'project Data directory', 'Initialize the project and place SAC files in Data first.');
    addfilelist(path);
    readteleBP(path,lon0,lat0,sr,ori,displayLength,Preshift,plotScale)
end
if alignBP_flag==1
    fprintf( 'Aligning Seismograms\n');
    require_path(fullfile(inputDir, 'data0.mat'), 'file', 'raw data file', 'Run the readBP step first to generate data0.mat.');
    check_data(path,1);
    align_BP(path,bandChoice,ts,refSta,cutoff,plotScale)
end
if runBPbmfm_flag==1
    fprintf( 'Running Beamforming back-projection\n');
    require_path(fullfile(inputDir, ['data' num2str(inputBand) '.mat']), 'file', ...
        sprintf('data%d.mat', inputBand), 'Complete the alignment step for the selected band first.');
    [BPfile]=setparBP(path,inputBand,Band,lon0,lat0,dep,parr,duration,ps,qs,lonrange,latrange);
    runteleBPbmfm(path,BPfile);
    summaryBPbeamforming
end
if runBPmusic_flag==1
    fprintf( 'Running MUSIC back-projection\n');
    require_path(fullfile(inputDir, ['data' num2str(inputBand) '.mat']), 'file', ...
        sprintf('data%d.mat', inputBand), 'Complete the alignment step for the selected band first.');
    [BPfile]=setparBP(path,inputBand,Band,lon0,lat0,dep,parr,duration,ps,qs,lonrange,latrange);
    runteleBPmusic(path,BPfile);
    summaryBPmusic
end

function require_path(target, targetType, label, hint)
if nargin < 3 || isempty(label)
    label = targetType;
end
if nargin < 4
    hint = '';
end
switch lower(targetType)
    case 'file'
        exists = isfile(target);
    case {'dir', 'folder'}
        exists = isfolder(target);
    otherwise
        error('musicbp:invalidTargetType', 'Unsupported target type: %s', targetType);
end
if exists
    return;
end
message = sprintf('Missing %s: %s', label, target);
if ~isempty(hint)
    message = sprintf('%s\n%s', message, hint);
end
error('musicbp:missingTarget', '%s', message);
end
