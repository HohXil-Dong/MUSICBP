function filelistPath = musicbp_prepare_data_dir(dataDir, logFile, pattern)
%MUSICBP_PREPARE_DATA_DIR Validate a data directory and rebuild filelist.

if nargin < 2
    logFile = '';
end
if nargin < 3 || isempty(pattern)
    pattern = '*.SAC*';
end

if ~isfolder(dataDir)
    musicbp_log(logFile, 'ERROR', 'Missing data directory: %s', dataDir);
    error('musicbp:missingDataDir', 'Missing data directory: %s', dataDir);
end

entries = dir(fullfile(dataDir, pattern));
entries = entries(~[entries.isdir]);
if isempty(entries)
    musicbp_log(logFile, 'ERROR', 'No SAC files matching %s under %s', pattern, dataDir);
    error('musicbp:noSacFiles', 'No SAC files matching %s under %s', pattern, dataDir);
end

[~, order] = sort({entries.name});
entries = entries(order);

filelistPath = fullfile(dataDir, 'filelist');
fid = fopen(filelistPath, 'wt');
if fid < 0
    musicbp_log(logFile, 'ERROR', 'Unable to write filelist: %s', filelistPath);
    error('musicbp:filelistOpenFailed', 'Unable to write filelist: %s', filelistPath);
end

cleanupObj = onCleanup(@() fclose(fid));
for i = 1:numel(entries)
    fprintf(fid, '%s\n', entries(i).name);
end

musicbp_log(logFile, 'INFO', ...
    'Prepared data directory %s with %d SAC files -> %s', ...
    dataDir, numel(entries), filelistPath);
end
