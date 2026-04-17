function musicbp_log(logFile, message, varargin)
%MUSICBP_LOG Append a timestamped line to a text log file.

if nargin < 2 || isempty(logFile) || isempty(message)
    return;
end

logDir = fileparts(logFile);
if ~isempty(logDir) && ~isfolder(logDir)
    mkdir(logDir);
end

fid = fopen(logFile, 'a');
if fid < 0
    warning('musicbp:logOpenFailed', 'Unable to open log file: %s', logFile);
    return;
end

cleanupObj = onCleanup(@() fclose(fid));
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
text = sprintf(message, varargin{:});
fprintf(fid, '[%s] %s\n', timestamp, text);
end
