function nns=randnoise(ns,sr)
n=length(ns(:,1));
stm=1/sr; %sampling time
sigleng=length(ns(1,:));
NFFT=sigleng;
ns_f=fft(ns,NFFT,2);
ns_f=fftshift(ns_f,2);
xf=stm/2*linspace(-1,1,NFFT);
xfM=ones(n,1)*xf;
%%%
rphi=rand([n,NFFT/2])*2*pi;
randphi=[rphi rphi(:,NFFT/2:-1:1)];
%%%
ns_f=ns_f.*exp(1i*randphi);
ns_f=fftshift(ns_f,2);
nns=real(ifft(ns_f,NFFT,2));
end