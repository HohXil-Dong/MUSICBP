function [signal,noise]=stacksignal(datal,sd,sr)
n=length(sd);
for i=1:n
data(i,:)=specshift(datal(i,:),sr*sd(i));
end
signal=mean(data(:,:),1);
noise=data-ones(n,1)*signal;
end