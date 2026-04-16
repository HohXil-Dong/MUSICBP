function addfilelist(path)
%ADDFILELIST Write all SAC file names in path/Data to a filelist.

dataDir = fullfile(path, 'Data');
if ~isfolder(dataDir)
    error('musicbp:addfilelist', 'Missing Data directory: %s', dataDir);
end

entries = dir(fullfile(dataDir, '*.SAC*'));
entries = entries(~[entries.isdir]);
if isempty(entries)
    error('musicbp:addfilelist', 'No SAC files found in %s', dataDir);
end

[~, order] = sort({entries.name});
entries = entries(order);

fid = fopen(fullfile(dataDir, 'filelist'), 'wt');
if fid < 0
    error('musicbp:addfilelist', 'Unable to write filelist in %s', dataDir);
end
cleanupObj = onCleanup(@() fclose(fid));
for i = 1:numel(entries)
    fprintf(fid, '%s\n', entries(i).name);
end
clear cleanupObj
end
