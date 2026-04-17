function musicbp_require(target, targetType, label, hint, logFile)
%MUSICBP_REQUIRE Assert that a file or directory exists.

if nargin < 3 || isempty(label)
    label = targetType;
end
if nargin < 4
    hint = '';
end
if nargin < 5
    logFile = '';
end

switch lower(targetType)
    case 'file'
        exists = isfile(target);
    case {'dir', 'folder'}
        exists = isfolder(target);
    otherwise
        error('musicbp:invalidTargetType', 'Unsupported target type: %s', targetType);
end

if exists
    return;
end

message = sprintf('Missing %s: %s', label, target);
if ~isempty(hint)
    message = sprintf('%s\n%s', message, hint);
end
musicbp_log(logFile, 'ERROR', '%s', message);
error('musicbp:missingTarget', '%s', message);
end
