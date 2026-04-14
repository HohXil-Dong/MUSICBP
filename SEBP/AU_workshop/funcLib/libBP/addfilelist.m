function addfilelist(path)     %add all *.SAC.r files' names to the filelist

cd(path)
d=dir('Data/*.SAC.r')
i=size(d)
filelist=strings(0,1)

for j=3:1:i(1)
    
    filelist=[filelist;d(j).name]

end

fid = fopen('filelist','wt');
fprintf(fid,'%s\n',filelist); 
fclose(fid);

copyfile('filelist', 'Data');
end
