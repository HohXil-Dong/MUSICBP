
clear
close all

address='/home/liuwei/Workflow/BP2/Workshop2019/';            % address of paths that need to be added below
addpath(genpath(strcat(address,'funcLib/')));   % directory of Back-Projection functions
addpath(genpath(strcat(address,'funcLib/formalFunc/')));
%% load stations and event location
% load /home/bb/BP/Experiments/Tohoku_2011/Main/Input/Par0.5_2_10.mat
load data0.mat
    lon0=ret.lon0;
    lat0=ret.lat0;
    dep0=8;

%% set focal mechanism
    strike = 140;
    dip    = 78;
    rake   = -177;
    model=prem('depth',dep0);

%% Calculate
    for j=1:length(ret.lat)
        P = tauptime('mod','prem','dep',dep0,'ph','P,pP','sta',[ret.lat(j) ret.lon(j)],'evt',[lat0, lon0]);
        p_takeoff(j)=rayp2inc(P(1).rayparameter,model.vp,6371-dep0);
        pP_takeoff(j)=180-rayp2inc(P(2).rayparameter,model.vp,6371-dep0);
        azi(j) = azimuth(lat0,lon0,ret.lat(j),ret.lon(j));
    end

     U = RadiationPattern(strike,dip,rake,p_takeoff(:)',azi(:)');
     p_rad(:)=U(:,1)';
     U = RadiationPattern(strike,dip,rake,pP_takeoff(:)',azi(:)');
     pP_rad(:)=U(:,1)';

figure(1);
subplot(2,2,1);
hist(abs(p_rad(:)));
title('P')
subplot(2,2,2)
hist(abs(pP_rad(:)));
title('pP')
% x3=[ret.lat' ret.lon' p_rad' pP_rad' mean(p_rad)' mean(pP_rad)'];

%%
figure
hist(abs(p_rad(:)));
xlim([0 1])
ylabel('number of stations')
xlabel('Radiation pattern (Polarity)')
title('AK to Papua2019')

%%
figure
hist(abs(pP_rad(:)))
h = findobj(gca,'Type','patch');
h.FaceColor = [0 0.5 0.5];
h.EdgeColor = 'w';
hold on
hist(abs(p_rad(:)));
xlim([0 1])
ylabel('number of stations')
xlabel('Radiation pattern (Polarity)')
legend({'pP phase','P phase'},'Location','northwest')
