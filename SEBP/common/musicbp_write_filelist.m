function filelistPath = musicbp_write_filelist(dataDir, pattern)
%MUSICBP_WRITE_FILELIST Write a SAC filelist into the data directory.

if nargin < 2 || isempty(pattern)
    pattern = '*.SAC*';
end

musicbp_require(dataDir, 'dir', '数据目录', '请先确认项目 Data 目录已存在。');

entries = dir(fullfile(dataDir, pattern));
entries = entries(~[entries.isdir]);
if isempty(entries)
    error('musicbp:noSacFiles', '在 %s 中未找到匹配 %s 的 SAC 文件。', dataDir, pattern);
end

[~, order] = sort({entries.name});
entries = entries(order);

filelistPath = fullfile(dataDir, 'filelist');
fid = fopen(filelistPath, 'wt');
if fid < 0
    error('musicbp:filelistOpenFailed', '无法写入 filelist: %s', filelistPath);
end

cleanupObj = onCleanup(@() fclose(fid));
for i = 1:numel(entries)
    fprintf(fid, '%s\n', entries(i).name);
end

clear cleanupObj
end
