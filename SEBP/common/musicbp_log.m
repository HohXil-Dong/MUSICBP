function musicbp_log(logFile, varargin)
%MUSICBP_LOG Append a timestamped line to a text log file.

if nargin < 2 || isempty(logFile)
    return;
end

if nargin >= 3 && local_is_level(varargin{1})
    level = upper(char(varargin{1}));
    message = varargin{2};
    args = varargin(3:end);
else
    level = 'INFO';
    message = varargin{1};
    args = varargin(2:end);
end

if isempty(message)
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
text = sprintf(message, args{:});
fprintf(fid, '[%s] [%s] %s\n', timestamp, level, text);
end

function tf = local_is_level(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    tf = false;
    return;
end

tf = any(strcmpi(char(value), {'INFO', 'WARN', 'ERROR'}));
end
