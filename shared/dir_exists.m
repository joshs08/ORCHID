%% checks if a folder exists, and if not it makes it
function [] = dir_exists (path);

if ~exist(path, 'dir')
    mkdir(path)
else
    %a = input ("Cell result directory exists. Contents will be overwritten." ...
    %+ "Do you wish to rename the existent folder? 0/1");
    a = 0;
    if a == 1
       old_path = path + "_old";
       movefile (path, old_path);
       mkdir (path);
    end
    
end