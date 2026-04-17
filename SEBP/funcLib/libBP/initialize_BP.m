function initialize_BP(root_address, workPath, project)
%INITIALIZE_BP Create a project directory with the expected subfolders.

% root_address is kept for backward compatibility with old callers.
if nargin < 3
    error('musicbp:initializeBP', 'initialize_BP requires workPath and project.');
end

project = regexprep(project, '[\\/]+$', '');
projectDir = fullfile(workPath, project);

if ~isfolder(projectDir)
    mkdir(projectDir);
end

subdirs = {'Input', 'Data', 'Fig'};
for k = 1:3
    targetDir = fullfile(projectDir, subdirs{k});
    if ~isfolder(targetDir)
        mkdir(targetDir);
    end
end
end
