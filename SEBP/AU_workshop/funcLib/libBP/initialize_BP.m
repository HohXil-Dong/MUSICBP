function initialize(root_address,workPath,project)


cd (workPath)
mkdir(project)
cd (project)
mkdir Input
mkdir Data
mkdir Fig

command = ['cp ',root_address,'funcLib/libBP/General_BP.m ./'];
system(command);
cd Data
command = ['cp ',root_address,'funcLib/libBP/addfilelist.m ./'];
system(command);
end
