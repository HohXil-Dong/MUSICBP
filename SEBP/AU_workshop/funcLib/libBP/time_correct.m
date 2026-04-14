% USAGE: after download, rdseed all events, and remove instrument response 
%        in mother_loc, this script will:
%           1. automatically read all .SAC files for each event.
%           2. correct recordtime (same as bbeu001)
%           3. match stations with MAINSHOCK.
%           4. transport 'timeshift' to matched stations.
%           5. Generate data_matched.mat with matched stations and
%           timeshift(mainshock alignment)
% INPUT: 1. mother_loc: Mother directory of all events
%        2. main_mat: .mat file of the Mainshock
%        3. ori:      for aftershock, how many sec before P-arrival
%        4. display:  for aftershock, how many sec of signal in total (before_P + after_P)

clear
close all

%% INPUT
ori        = 60; % please refer to bbeu004 where you send request to IRIS
display    = 360; % please refer to bbeu004 where you send request to IRIS
Preshift   = false;	% no change! About readBP
plotscale  = 1;     % plotscale:  scaling of the amplitudes of seismograms
dep0   = 20;
%% Some preparation
 % get event origin time
        origin_time= datenum('2004-06-28 09:49:47');

%% Time correction
    load('Input/data0.mat')

      % Delete stations with hypocenter dist larger than 90
        iin=find(ret.rdis<91);   
        ret=orderAll(ret,0,iin);

      % Calculate travel time
        load Ptimesdepth.mat
        travel_time = interp2(dis,dep,Ptt,ret.rdis,dep0,'linear',0);

        correct_recordtime = origin_time + (travel_time-ori)/3600/24;
        
        %% Local time correction
        % Need to correct ret.recordtime first 
        % based just on Japan local time difference: UTC+0900.
        ret.recordtime = ret.recordtime - 9.0/24;
        
        %% time correction based on P-arrival removal
        time_correction = correct_recordtime - (ret.recordtime-1); 
        time_correction = time_correction*3600*24; % from datenum to seconds
      % Now it's time to shift the seismogram with respect to time_correction
        for j = 1:length(ret.lon) 
            ret.xori(j,:) = specshift(ret.xori(j,:),time_correction(j)*ret.sr);
            ret.x(j,:)    = specshift(ret.x(j,:),   time_correction(j)*ret.sr);
        end
%         ret.xori = ret.xori(:,1:sr*(ori+display));
      % Also we need to correct ret.recordtime and recordtimesec
        ret.recordtime = correct_recordtime;
        ret.recordtimesec = (ret.recordtime - ret.recordtime(1)) * 24 * 3600;
    
    % Save ret
      save Input/data0 ret
      plotAll1(ret)
    
