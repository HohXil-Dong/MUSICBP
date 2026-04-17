function addfilelist(path)     %add all *.SAC.r files' names to the filelist
musicbp_write_filelist(fullfile(path, 'Data'), '*.SAC*');
end
