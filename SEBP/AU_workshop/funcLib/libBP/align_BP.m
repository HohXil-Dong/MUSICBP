function align_BP(path,Band,ts11,refst,cutoff,plotscale)
% align_BP align seismograms  
%   align_BP(path,Band,ts11,refst,cutoff,plotscale) used after function 
%   'readteleBP' to align seismograms for one earthquake event
%   
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

%   Copyright 2013-2019 Han Bao & Lingsen Meng's group, UCLA.

filename=strcat(path,'Input/data',num2str(Band-1))
load(filename);
[fl fh win range]=alignband(Band);

% !!check for data!!
%check_data(path,Band);

ret.x=ret.xori;
load ptimes;
if refst~=0
    lat_ref=ret.r(refst,2);
    lon_ref=ret.r(refst,1);
end
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[n m]=size(ret.x);

[BB,AA]=butter(4,[fl fh]/(ret.sr/2));
for i=1:n
    ret.x(i,:)=filter(BB,AA,ret.x(i,:));
end


%% autommatically set the parameters
% 
% %step1 set the ts11 for each station
% %use the AIC method
% P_a=[];
% ts=[];
% siz=size(ret.x);
% for i=1:1:siz(1)
%     rets=ret.x(i,:).';
%     [pa]=aic_pick(rets,'whole','n');
%     P_a(i)=pa/10;
% end
% if Band==1
%     for i=1:1:size(ret.x)
%         ts(i)=P_a(i)-15;
%         if ts(i)<0
%             ts(i)=1;
%         end
%     end
% end
% if Band==2
%     for i=1:1:size(ret.x)
%         ts(i)=P_a(i)-7.5;
%         if ts(i)<0
%            ts(i)=1;
%         end
%     end
% end
% if Band==3
%     for i=1:1:size(ret.x)
%         ts(i)=P_a(i)-4;
%         if ts(i)<0
%            ts(i)=1;
%         end
%     end
% end
% if Band==4
%     for i=1:1:size(ret.x)
%         ts(i)=P_a(i)-4;
%         if ts(i)<0
%            ts(i)=1;
%         end
%     end
% end
% if Band==5
%     for i=1:1:size(ret.x)
%         ts(i)=P_a(i)-5;
%     end
%     if ts(i)<0
%         ts(i)=1;
%     end
% end
% 
% %step2: set the refst
% refst=0;
% sum=[];
% rets=struct();
% %step=floor(siz(1)/10);   %we choose one station from step stations as candidate of reference station
% index=1;
% 
% for i=1:1:siz(1)
%     sum(i)=0;
%     refst=i;
%     align=getcoff();
%     align.ts11=ts(i);% aligned time start from straight one
%     align.win=win;
%     align.lt=400;%no change
%     align.range=range; % upper limitation
%     align.refst=refst;% first not zero, anyone is ok
%     align.cutoff=cutoff;
%     rets=getcoff(ret,align);
%     for j=1:1:siz(1)
%         sum(i)=sum(i)+rets.mxcr1(j);
%     end
%     rets=struct();
% end
% 
% for i=1:1:siz(1)
%     if sum(index)<sum(i)
%         index=i;
%     end
% end
% n_refst=index;
% ave_cor=sum(index)/siz(1);
% ret.cor=ave_cor;     %record average cross-correlation
%%


align=seismoAlign();
align.ts11=ts11;% aligned time start from straight one
align.win=win;
align.lt=400;%no change
align.range=range; % upper limitation
align.refst=refst;% first not zero, anyone is ok
align.cutoff=cutoff;
ret=seismoAlign(ret,align);%!!!!!!!important!!!!

ret.scale=plotscale;%no change
ret.lt=300;% no change
ret.ht=350;%no change  above 3 lines for plotting

figure(10+Band-1);
plotAll1(ret);
figure(15+Band-1);
plotSta(ret);
if refst~=0
    hold on
    plot( lon_ref, lat_ref, 'r.','MarkerSize',20);
end

ret.ts11=ts11;    %reocrd tsll and reference station
ret.refst=refst;

filename=strcat(path,'Input/data',num2str(Band))
save(filename,'ret','-v7.3');

hold off

%fprintf('the value of referrence station is %d, and the value of ts11 is %f\n',n_refst,ts(n_refst));  %to get the refst and ts11 for running BPbmfm
end