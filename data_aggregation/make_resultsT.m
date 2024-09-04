%% run once to make a results table for a new data set, which will be
% populated with open_relevant_info.m
% it is made parallel to the results folder. 
% can contain sz data points
% change RecType to CellType etc
% rename the table and move it to the date result folders

%% smoothed = 0
% path = "C:\Users\Josh Selfe\Documents\Data\Puffing results\results";
% sz = [1 9];
% varTypes = ["string","string","string","string", "double","double", "double", "double", "logical"];
% varNames = ["CellNum","RecNum","RecType","CellType","BaselineF", "MaxMinF","dF","stdDevs", "UsedBGcorrected"];
% results = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
% save (path, 'results');

%% smoothed = 1 (original variables)
path = "C:\Users\Josh Selfe\OneDrive - University of Cape Town\UCT\Masters\Data\testing_reporters_and_channels\aav-ORCHID\non-characterising\results";
sz = [1 15];
varTypes = ["string","string","string","string", "double","double", "double", "double","double", "double","double", "logical","double","double","double"];
varNames = ["CellNum","RecNum","RecType","CellType","BaselineF", "MaxMinF","dF","stdDevs", "SmoothedMaxMinF", "SmoothedDF", "SmoothedStdDevs", "UsedBGcorrected", "SmoothingWindow", "DeltaF_BG", "BGChange"];
results = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
save (path, 'results');

%% smoothed = 2 (when I messed up the 08.22-10.22 data collection)
% path = "C:\Users\Josh Selfe\Documents\Data\Puffing results\results";
% sz = [1 11];
% varTypes = ["string","string","string","string", "double","double", "double", "double","double", "double", "logical"];
% varNames = ["CellNum","RecNum","RecType","CellType","BaselineF", "MaxMinF","dF","stdDevs", "SmoothedMaxMinF", "SmoothedDF", "UsedBGcorrected"];
% results = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
% save (path, 'results');

%% with voltage stuff primarily for holding potentials
% path = "C:\Users\Josh Selfe\OneDrive - University of Cape Town\UCT\Masters\Data\testing_reporters_and_channels\aav-ORCHID\non-charcterising\results";
% sz = [1 17];
% varTypes = ["string","string","string","string", "double","double", "double", "double","double", "double","double", "logical","double","double","double","double","double"];
% varNames = ["CellNum","RecNum","RecType","CellType","BaselineF", "MaxMinF","dF","stdDevs", "SmoothedMaxMinF", "SmoothedDF", "SmoothedStdDevs", "UsedBGcorrected", "SmoothingWindow", "Vhold", "Ihold", "PSP", "dV"];
% results = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
% save (path, 'results');
