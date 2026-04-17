function startup_sebp()
%STARTUP_SEBP Add the standalone SEBP folders to the MATLAB path.
% Run this once per MATLAB session before calling musicbp_config or the
% SEBP_step scripts from the SEBP root directory or any other directory.

scriptDir = fileparts(mfilename('fullpath'));
commonDir = fullfile(scriptDir, 'common');
funcLibDir = fullfile(scriptDir, 'funcLib');

if ~isfolder(commonDir)
    error('sebp:startup', 'Missing common directory: %s', commonDir);
end
if ~isfolder(funcLibDir)
    error('sebp:startup', 'Missing funcLib directory: %s', funcLibDir);
end

addpath(commonDir);
addpath(genpath(funcLibDir));
end
