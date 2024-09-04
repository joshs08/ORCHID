% this class will show a user a dialog to exclude files from a list
% usage e.g., cell_sfs = exclude (cell_sfs);

function [output] = exclude (files)

[indx2,~] = listdlg('PromptString','Select files to be excluded',...
    'ListString',files);

% remove selected files from list of wcp files
s2 = size (indx2);
s2 = s2(2);
for i = 1:s2
    files{1, indx2(i)} = [];
end

output = files(~cellfun('isempty',files));
