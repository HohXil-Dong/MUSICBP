function addfilelist(path)
%ADDFILELIST Rebuild the SAC filelist in the event Data directory.

musicbp_prepare_data_dir(fullfile(path, 'Data'), '', '*.SAC*');
end
