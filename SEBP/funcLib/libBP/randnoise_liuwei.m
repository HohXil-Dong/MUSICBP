function nns=randnoise_liuwei(ns,sr,noise_level,sigp)
n=length(ns(:,1));
for i=1:n
%     nns(i,:)=ns(i,:)+noise_level*max(ns(i,:))*(2*rand(1, length(ns(i,:)))-1);
    nns(i,:)=noise_level*max(sigp(:))*(2*rand(1, length(ns(i,:)))-1);
end
end