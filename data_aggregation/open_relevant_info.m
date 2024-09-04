%% this class is used to get the puff dF/F and stdDevs from fluoro mat.
%it loads the result table, which stores PSPs for each cell
%it then loadds a fluoro mat for a specified cells and you can look at all
%the traces and choose the best one for saving
%ENTER the date and cell number
clear;
close all;
date = "230610";
smoothed = 1;%note ive added 0s, check down there
setCellType = 1;
volt = 0;
orchid = true;
%if you smoothed post hoc using get smooth dF from fig.m 
fluoro2 = false;

RecType = "long term";
CellType = "IN";

path_results = "C:\Users\Josh Selfe\OneDrive - University of Cape Town\UCT\Masters\Data\testing_reporters_and_channels\aav-ORCHID\non-characterising\results";
path_date = fullfile (path_results, date);

%load result table (where all PSPs are stored, one per cell)
load (fullfile(path_results, 'results.mat'));

%loop through all the cell result folder in a dat result folder
all_sfs = dir(fullfile(path_date,'*')); % list of all subfolders in date folder
cell_sfs = setdiff({all_sfs([all_sfs.isdir]).name},{'.','..'}); % list of subfolders (sfs) not incl . and ..

% user selects cell folders to be excluded form analysis
cell_sfs = exclude (cell_sfs);

%cycle through remaining cell folders in date folder
for f = 1:numel(cell_sfs)

    %to skip if I didnt analyse the cell
    %or to speed up if there is only one dp
    empty = false;
    singular = false;
    cell_num_full = string (cell_sfs(f));
    cell_name = char(cell_sfs (f));
    cell_num = cell_name(1:2);
    cell_num = convertCharsToStrings (cell_num);
    path_cell = fullfile  (path_date, cell_num_full);
    fluoro_mat = date + "_" + cell_num + "_fluoro.mat";
    if fluoro2 == true
        fluoro_mat = date + "_" + cell_num + "_fluoro2.mat";
    end
    patch_mat = date + "_" + cell_num + "_patch.mat";

    %load the fluoro results for the specific cell
    try
        load (fullfile (path_cell, fluoro_mat));
        load (fullfile(path_cell, patch_mat));
    catch
        disp ("NO FLUORO_MAT FOR " + cell_name);
        empty = true;
    end

    if empty == false

        %get the size of the fluorostruct. if it is 1, take the only datapoint as
        %the chosen one
%         if fluoro2 == false
%         fluorostruct=fluorostruct.fluorostruct;
%         end
        if fluoro2 == true
        fluorostruct = fluorostruct2;
        end
        sizefs = size (fluorostruct);
        rowsfs = sizefs(2);

        %need to set the baselinedatapoints to [] for display purposes as with the
        %08.22-10.22 data disaster the smoothed data is saved after the
        %baselinedatapoints and scrolling along is annoying.
        for p = 1:rowsfs
            fluorostruct (p).BaselineDatapoints = [];
        end

        %loop through the fluorostruct rows and delete if they have null
        %values
        w = 1;
        while w <= rowsfs & rowsfs > 1

            tfs = fluorostruct(w);
            bl = tfs.BaselineF;
            if bl == 0 | bl == []
                fluorostruct (w) = [];
                rowsfs = rowsfs - 1;
            end
            w = w + 1;
        end


        if rowsfs == 1
            singular = true;
            %tt = input ("Truly singular?")
            disp("this cell had only one data point: " + cell_name);
        end

        %display the fluoro mat in a window
        if singular == false
            tb = struct2table(fluorostruct);
            fig = uifigure;
            fig.Position = [20 100 1300 400];
            uit = uitable(fig,'Data',tb, 'ColumnWidth', 'fit');
            uit.Position = [20 20 1200 200];
        end


        %display the combinedF file
        if orchid == 0
            path_fig = fullfile (path_cell, "combinedF");
        elseif orchid == 1
            path_fig = fullfile (path_cell, "fluorescence_traces");
        end

        sfs = dir(fullfile(path_fig,'*')); % list of all F folders in the combinedF folder
        %(if there are multiple wcp files, there will be multiple combinedF folders

        sfs = setdiff({sfs([sfs.isdir]).name},{'.','..'});
        %loop through combinedF figures
        s = size (sfs, 2);
        for i = 1: s
            path_ff = fullfile (path_fig, sfs (i));
            figs = dir(fullfile(path_ff,'*.fig')); % list of all subfolders in date folder

            for j = 1:size (figs,2)
                try
                    path_f = fullfile (path_ff, figs (j).name );
                    openfig (path_f);
                catch
                    disp ("no figures for this one" + cell_name)
                end
            end
        end

        %fig_num = input ("Which figure do you want? Enter the number it is");
        %trace_num = input ("Which trace do ya want?");
        if singular == false
            fnraw = input ("Which field number/s do you want? In the fluoro mat. Comma delimited.",'s');

            str = regexprep(fnraw,',',' ');
            fn = str2num(str);
        else
            fn = 1;
        end

        %smoothed = input ("is it smoothed boi?0/1");

        %select cell_type
        if setCellType ~= 1
            t = input (("Is it a neuron (n), astro (a), pyramidal (p) or interneuron (i)? Cell: " + cell_name),'s');
            switch t
                case 'n'
                    CellType = "Neuron";
                case 'a'
                    CellType = "Astrocyte";
                case 'p'
                    CellType = "Pyramidal";
                case 'i'
                    CellType = "Interneuron";
                otherwise
                    CellType = "you entered the wrong letter";
            end
        end

        %now loop through the fluorescence traces you chose
        for h = 1:size (fn,2)
            fs = fluorostruct (fn(h));

            RecNum = fs.Recording;
            BaselineF = fs.BaselineF;
            MaxMinF = fs.MaxMinF;
            dF = fs.DeltaFoverF;
            stdDevs = fs.StandardDevs;
            UsedBGcorrected = fs.UsedBGcorrected;

            if smoothed == 1
                sMaxMinF = fs.SmoothedMaxMinF;
                sdF = fs.SmoothedDeltaFoverF;
                sstdDevs = fs.SmoothedStandardDevs;
                swl = fs.SmoothingWindowLength;
                cell = {cell_num_full, RecNum, RecType, CellType, BaselineF, MaxMinF, dF, stdDevs, sMaxMinF, sdF, sstdDevs, UsedBGcorrected, swl};
            elseif smoothed == 0
                %cell = {cell_num_full, RecNum, RecType, CellType, BaselineF, MaxMinF, dF, stdDevs, UsedBGcorrected};
                sMaxMinF = 0;
                sdF = 0;
                sstdDevs = 0;
                swl = 0;
                cell = {cell_num_full, RecNum, RecType, CellType, BaselineF, MaxMinF, dF, stdDevs, sMaxMinF, sdF, sstdDevs, UsedBGcorrected, swl};
            elseif smoothed == 2
                sMaxMinF = fs.maxSmooth;
                sdF = fs.smoothdF;
                cell = {cell_num_full, RecNum, RecType, CellType, BaselineF, MaxMinF, dF, stdDevs, sMaxMinF, sdF, UsedBGcorrected};
            end
            %do voltage things
            if volt == 1
                RecNumChar = convertStringsToChars(RecNum);
                rec_cell = RecNumChar(1:13);
                rec_cell = string (rec_cell);
                if length (RecNumChar) == 16
                    sweep = RecNumChar(15);
                else
                    sweep = RecNumChar(15:16);
                end
                sweep = str2double(sweep);

                %F%$^*$ hate matlab why cant i f#^%&#* search structures
                %more easily
                %indexes = reshape(contains({patchstruct.Recording}, 'rec_cell'), 3);
                %patchstruct(indexes) % will return the structs containing 's2' in Description
                singular2 = false;
                if size (patchstruct,2) == 1
                    singular2 = true;
                end

                if singular2 == false
                    fnraw2 = input ("Which field number/s do you want? In the fluoro mat. Comma delimited.",'s');

                    str2 = regexprep(fnraw2,',',' ');
                    fn2 = str2num(str2);
                else
                    fn2 = 1;
                end

                ps = patchstruct (fn2);
                vmA = ps.Vm;
                iholdA = ps.Ihold;
                pspsA = ps.PSPs;


                vm = vmA(sweep);
                ihold = iholdA(sweep);
                psp = pspsA(sweep);
                dV = psp - vm;

                cell (end+1) = {vm};
                cell (end+1) = {ihold};
                cell (end+1) = {psp};
                cell (end+1) = {dV};
            end%voltage

            disp (cell);
            results = [results; cell];
        end

        path_save = fullfile (path_results, 'results.mat');
        save (path_save, 'results');
        close all;
        try
            close (fig);
        catch
            disp ("nonexistant fig" + cell_name);
        end
    end
end


