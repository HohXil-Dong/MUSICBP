function [cfg, profile, logFile, scriptDir] = musicbp_step_setup(scriptPath, stepName, profileName)
%MUSICBP_STEP_SETUP Initialize paths, configuration, and the step log.

if nargin < 3 || isempty(profileName)
    profileName = 'maduo_2021';
end

scriptDir = fileparts(scriptPath);
commonDir = fullfile(scriptDir, 'common');
funcLibDir = fullfile(scriptDir, 'funcLib');

if ~isfolder(commonDir)
    error('musicbp:missingCommonDir', 'Missing common directory: %s', commonDir);
end
if ~isfolder(funcLibDir)
    error('musicbp:missingFuncLibDir', 'Missing funcLib directory: %s', funcLibDir);
end

addpath(scriptDir);
addpath(commonDir);
addpath(genpath(funcLibDir));

cfg = musicbp_config(profileName);
profile = cfg.active;

logFile = fullfile(scriptDir, [stepName '.log']);
fid = fopen(logFile, 'wt');
if fid < 0
    error('musicbp:logResetFailed', 'Unable to reset log file: %s', logFile);
end
fclose(fid);

musicbp_log(logFile, 'INFO', '============================================================');
musicbp_log(logFile, 'INFO', '%s session start', stepName);
musicbp_log(logFile, 'INFO', 'profile=%s root=%s', cfg.profile_name, profile.root_dir);
end
