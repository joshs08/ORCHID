%% The parent script for analysis of ORCHID imaging and electrophysiology data

% Data input:
% For ORCHID imaging: typically a uManager tiff stack (.ome.tif) and
%   a .wcp file where the TTL pulses used to trigger the blue light were
%       recorded
%   Additional: a uManager metadata file containing imaging parameters,
% For electrophysiology: a .wcp file containing the V/I clamp recording OR
%       a .xlsx file of a LFP recording
%   Additional: a cell_info.txt where information pertaining to the recording was recorded
% For recordings in which there was activation of endogenous GABAARs by GABA puff:
%   identical to ORCHID imaging, with the .wcp file recording the puff TTL
% 
% What the script does:
%   Reads in the ephys data, plotting the V/I clamp or LFP recording if there is
%   one
%   Read in images, create a mean image, allow user to select a cell ROI and then a background (BG) ROI
%   Plot the F trace for both of these ROIs
%   You can then select whether to subtract the BG or not .
% script will take raw imaging files of fluoro changes after puffing, it will:
% subtract backgroung, correct for bleaching, display the trace.
% It will then display the relevant patch trace, filtered and cut

% Data and results structure:
%   Data: path\date\cell number\image stack folder
%   date: e.g., 240225, contains all cell folders (e.g., 01-08)
%   cell number: e.g., 01. This folder contains all .wcp files (e.g., 240225_001.wcp) and all
%       image stack folders (e.g., 001(1), 001(2) for that cell. Where 001
%       relates to the .wcp file number and the number in brackets is the sweep
%       number.
%   image stack folder: e.g., 001(1). Contains the .ome.tif stacks and the
%       metadata file from uManager acquisition.
%   results: a folder reesults is created in the path given, with date and
%       cell folders created in that

% apologies if any idiosyncrartic comments or text lines have snuck through. I was keeping myself entertained. 

%% set analysis parameters
% NB! If you have been using open_relevant_info.m, "clear all" before running this again!

% the date folder your imaging data is in
date = "230323";
% path to data, one up from date folder
path_data = 'D:\Joshua\data\aav_ORCHID';
%path_data = 'D:\Joshua\data\aav-Voltron2\mouse\puffing_data';
% direct path to folder with all LFP .xlsx files. Ignore if no LFP
path_lfp = "D:\Joshua\data\aav_ORCHID_in_vivo\LFP\230609";
%path to folder one up from results. 
path_folders = ...
   'C:\Users\Josh Selfe\OneDrive - University of Cape Town\UCT\Masters\Data\testing_reporters_and_channels\aav-ORCHID\review';

% variables to remove iterations of user input
setClear = 1; % to clear previous structures. It is always 1. 0 if you want additional user input each time.
patchData = 1; % set to 1 if you want to analyse the patch data, besides the light pulses or puff (ie, if cell was patched)
setRecType = 1; % if 1: pre-set to set the type of recording, use if all recordings are the same. Otherwise 0: you will be asked for the type of each recording.
recType = 'SLE'; % the pre-set recording type (if setRecType = 1)
new_BGC = true; % if you want to implement the smoothed background correction (BGC) (where background trace is smoothed before being subtracted).
faster = false; % if you want to disregard a bunch of checks and inputs
askaboutBGC = false; % ask the question for using BGC, or not, or doing an iteration of each. If false, BGC is default.

% one of these must be true and the other two false. Unless it is a 0 Mg
% ORCIHD rec, then have puff and 0Mg as true
isORCHID = false;
is0Mg = true; % for ORCHID 0 Mg recordings. have isORCHID as false, isPuff as true and is0Mg as true and it will work 
isPuff = true;
isCharacterisation = false;
is0MgBaseline = true; % this is always false unless you are doing a 0 Mg baseline (13 x repeated stim) recording, in which case isPuff, is0Mg, and this are true
bursting = false; %true with puff and 0Mg
mixed_trace = false; %for bursting, if it wasn't a cleanly timed recording ie 5 pulses in middle
% additional inputs
twentyfiveHz = true; % set to true if it is ORCHID, or false if it is 100 Hz Voltron
in_vivo = false; % self-explanatory. 
haslfp = false; % implemented after the above. Not all in vivo recs have lfp recs

%for ORHCID and characterisation recordings
setVorI = true; % make false if some cells were patched and others weren't
VorI = 1; % 1 for current clamp; 0 for vclamp, unpatched
vStepswps = 5; % for patch-clamp characterisation recordings (typicall V or I steps), how many vstep sweeps are there? Typically 8
lightError = false; % set as true if you turned the light off before the end of image acquisition
baselineLengthForAvgF = 80; % the number of images that baseline is taken over. This is fine for puff and for v steps,
%   but likely not fine for ORCHID! it is the number of images baseline is
%   taken over to add to once BGC has taken place

setSweepLength = true; % the length in ms of a single sweep in the .wcp recording. If false, the user will be asked to input a sweep length for every cell.
sweepLength = 65000; % ms,
% 2000 for i steps
% 3000 ms for V steps
% 25000 ms for ORCHID 
% 65000 ms for ORCHID 0 MG
% 7000 ms for puffing

%for ORCHID recordings:
setLightPulses = true; % make false if number is different for different recordings. always true in modern times
npulses = 13;

%% begin analysis
%% folder handling:
% we need to display all of the subfolders in the date folder and ask the
%user to select any to be excluded!
path_data = fullfile(path_data, date);
all_sfs = dir(fullfile(path_data,'*')); % list of all subfolders in date folder
cell_sfs = setdiff({all_sfs([all_sfs.isdir]).name},{'.','..'}); % list of subfolders (sfs) not incl . and ..

% user selects cell folders to be excluded from analysis
cell_sfs = exclude (cell_sfs);

% cycle through remaining cell folders in date folder
for f = 1:numel(cell_sfs)
    % new cell boolean for get_fluoro_changes
    new_cell = true;
    c = setClear;
    if c == 1
        clear ('fluorostruct', 'patchstruct');
    end

    % path to current cell subfolders
    cell_num = string(cell_sfs (f));
    %this path_data and the next 4 occurences (in the next 20ish lines)
    %could be renamed path_data_cell...
    path_data = fullfile (path_data, cell_num);
    % path_cell = path_cell{1};

    % the data specific to one cell/one patch (many wcps).
    try
        vars = get_txt_vars (path_data);
    catch
        disp ("No cell_info.txt.");
        vars = "Na";
    end
    path_results = fullfile (path_folders, 'results', date, cell_num);
    dir_exists (path_results);
    path_vars = fullfile (path_results, date + "_" + cell_num + "_vars.mat");
    save (path_vars, 'vars');

    %path to all the files in the first subfolder
    all_cell_files = dir(fullfile (path_data, '*'));

    imaging_folders = setdiff({all_cell_files([all_cell_files.isdir]).name},{'.','..'});

    wcp_files_struct = dir(fullfile (path_data, '*.wcp'));
    wcp_files = {wcp_files_struct.name};

    %% analysis of wcp files
    % user selects wcp files to be excluded form analysis
    wcp_files = exclude (wcp_files);

    % loop through the wcp files and plot for each of them
    nw = numel(wcp_files); %num wcp files
    clear ('TTLs', 'puffs');
    % TTLs is a useless variable as I just use num_images always
    %TTLs = cell (nw, 2);
    puffs = cell (nw, 3);
    for w = 1:nw %loop through files in subfolder
        wcp_file = string(wcp_files (w));
        wcp_file_path = string(fullfile(path_data, wcp_files(w))); %path to first wcp file

        %get the wcp rec_num
        wis = strfind (wcp_file, "_"); %wcp index start
        wie = strfind (wcp_file, "w");
        trace_num = char (wcp_file);
        trace_num = trace_num(wis+1:wie-2);
        trace_num = string (trace_num);
        wcp_name = date + "_" + cell_num + "_" + trace_num;

        %call get_v_trace for different experimental paradigms
        if (isORCHID == true)
            if setLightPulses == false
                npulses = input ("In this ORCHID recording, how many light pulses were there? (hint: 3 or 5)");
            else
                npulses = npulses;
            end
            [counted_TTLs, img_ps, img_pe, vm, i_hold, psp, quality, rtype, light_imgs, endt] =...
                get_v_trace_ORCHID (path_data, path_results, date, cell_num, wcp_file, npulses,...
                setVorI, VorI, setSweepLength, sweepLength);
        elseif (isPuff == true)
            [counted_TTLs, img_ps, img_pe, vm, i_hold, psp, quality, rtype, endt, Mg_light_images] = get_v_trace (path_data, path_results, date, cell_num, wcp_file, patchData, setRecType, recType, is0Mg, npulses, bursting, mixed_trace);
            if Mg_light_images (1,1) < 20
                Mg_light_images = [26 50; 151 175; 276 300; 401 425; 526 550; 651 675; 776 800; 901 925; 1026 1050; 1151 1175; 1276 1300; 1401 1425; 1526 1550];
            end
            light_imgs = [0; 0]; %these are for the ORCHID light pulses, set to 0 if not ORCHID
        elseif (isCharacterisation == true)
            [counted_TTLs, img_ps, img_pe, vm, i_hold, psp, quality, rtype, endt, steps] =...
                get_v_trace_v_and_i_only (path_data, path_results, date, cell_num, wcp_file,...
                setVorI, VorI, setSweepLength, sweepLength);
            light_imgs = [0; 0];
        end

        % save all the wcp data for the *cell*
        patchstruct (w)= struct ('Recording', wcp_name,...
            'Type', rtype,...
            'Quality', quality,...
            'Vm', vm,...
            'Ihold', i_hold,...
            'PSPs', psp);

        %TTLs (w, :) = {wcp_name, counted_TTLs};
        puffs (w, :) = {wcp_name, img_ps, img_pe};

    end

    path_patch = fullfile (path_results, date + "_" + cell_num + "_patch.mat");
    save (path_patch, 'patchstruct');



    %% analysis of imaging data 
    nif = numel (imaging_folders);%number of imaging folders
    sa = 1; %start at

    % loop through the imaging folders, grouped by the wcp trace they are
    % from
    while sa <= nif
        tn = string(imaging_folders (sa)); %trace number
        %do this for the cases of 005.5(1)
        if contains (tn, "(")
            li = strfind (tn, "("); %last index (we want the number before this
            tn = char (tn);
            tn = tn(1:li-1);
            tn = string (tn);
        end

        tni1 = find(contains (imaging_folders, tn)); %indices for that trace number
        if ~contains (tn, '.')
            tni2 = find (~contains(imaging_folders, '.')); %we don't want ie 001.3 as that is a new wcp trace
            tni = intersect (tni1, tni2);
        else
            tni = tni1;
        end
        cfs = imaging_folders (tni); %current folders


        a = input ("Do you wish to analyse the " + tn + " folders? 0/1");

        %this loop will cycle through the tracenum (wcp) grouped imaging folders
        if a == 1
            %exclude any folders
            cfs = exclude (cfs);
            %try to open the figure with the  voltage traces
            try
                rec_num = date + "_" + cell_num + "_" + tn;
                fig_name = rec_num + ".fig";
                fig_path = fullfile (path_results, 'voltage_traces', fig_name);
                fv = open (fig_path);
            catch
                disp ("no voltage trace figure could be found");
            end

            % this loop will cycle through the individual folders of that tn
            numcfs =numel (cfs);
            clear sweeps;
            for c = 1:numcfs
                cf = cfs (c);

                if contains (cf, "(")
                    sis = cell2mat(strfind (cf, "(")); %sweep index start
                    sie = cell2mat(strfind (cf, ")"));
                    sweep = char (cf);
                    sweep = sweep(sis+1:sie-1);
                    sweep = string (sweep);
                    sweep = "(" + sweep + ")";
                else
                    sweep = "";
                end
                sweeps (c) = sweep;
            end

            % create a new combined fluoresence trace figure
            if contains (cf, "(")
                ffn = rec_num + sweeps(1) + "-" + sweeps(end);
            else
                ffn = rec_num;
            end
            cff = figure ('Name', ffn);
            cff2 = figure ('Name', ffn + "_BG2");

            for b = 1: numcfs
                cf = cfs (b);
                disp ("Now analysing " + cf);

                %%visualise BG changes
                % these are not being used currently. save_ORCHID_sweeps
                % was only useful for alternating blue and orange sweeps.
                % could reimplement the bg_increase_visualisation in
                % future
                %                 if isORCHID == 1
                %                     if (input ("Do you wish to visualise the BG difference? 0/1")) == 1
                %                         bg_increase_visualisation (path_data, cf, pulse_imgs, path_results, date, cell_num, wcp_file);
                %                     end
                %                     if (input ("Do you want to do separate sweep BG removal? 0/1")) ==1
                %                        save_ORCHID_sweeps(path_data, path_results, cf, pulse_imgs);
                %                     end
                %                 end

                if haslfp == true
                    [lfp, lfptime] = read_in_lfp (path_lfp, path_results, date, cell_num, trace_num, cf);
                else
                    lfp = zeros (1, 480);
                    lfptime = 1:480;
                end

                [corrected, fluoro, bg, num_images, exposure] = get_fluoro_changes (path_data, path_results, cell_num, cf, new_cell, isCharacterisation, lightError, light_imgs, isORCHID, in_vivo);

                % plot corrected, uncorrected and background
                % x_numimages is the x axis variable for plots, from 1 to
                % the number of images in the img stack
                % x_time is the x axis variable for plots, but from 1 to
                % the sweep length in the number of counted TTLs (it has to
                % be based on number of counted TTLs, else it will be the
                % length of one sweep, with more than one sweep's worth of
                % images
                % why not just use num_images?? 
                ccx_numimages = 1:1:num_images;
                x_time = linspace (0, endt, num_images);
                tPerImg = endt/num_images;

                % added after for the new smoothe BG correction
                meanbg = 0;%set incase it is false
                if new_BGC == true
                    %one value to be subtracted from baselineF and min/maxF
                    meanbg = mean(bg);
                    %number of values smoothing occurs over
                    span = 100;
                    gd = 0; %is it good yet?
                    fbgs = figure();
                    while gd == 0
                        bg_smoothed = smooth (bg, span);
                        plot (x_time, bg_smoothed);
                        gd = input ("Does the smoothing of the background look suitable? 0/1");
                        if gd == 0
                            span = input ("Enter new span (default is 100):");
                        end
                    end

                    bg_smoothed = bg_smoothed';
                    corrected = fluoro-bg_smoothed;
                end

                if isCharacterisation == true
                    %vStepswps = input  ("For time display: does the imaging recording run over multiple sweeps; how many? 1 if 1");
                    endttot = endt*vStepswps;
                    x_time = linspace (0, endttot, num_images);
                end

                figc = figure();
                % try and plot each with the time on the x axis, but if the
                % TTLs ran over just plot it with x_num_images
                try    
                    plot (x_time, corrected);
%                     if haslfp == true   
%                         subplot (2,1,1);
%                         plot (x_time, corrected);
%                         axis tight;
%                         subplot (2,1,2);
%                         plot (lfptime, lfp)
%                     else
%                         plot (x_time, corrected);
%                     end
                catch
                    disp ('Something unexpected with image numbers occurred');
                    plot (x_numimages, corrected);
                end
                legend ('Corrected');
                axis tight;

                figf = figure ();
                try
                    plot (x_time, fluoro);
%                     if haslfp == true
%                         subplot (2,1,1);
%                         plot (x_time, fluoro);
%                         axis tight;
%                         subplot (2,1,2);
%                         plot (lfptime, lfp);
%                     else
%                         plot (x_time, fluoro);
%                     end
                catch
                    disp ('Something unexpected with image numbers occurred');
                    plot (x_numimages, fluoro);
                end
                axis tight;
                legend ('Uncorrected fluoro');

                figbg = figure ();
                try
                    plot (x_time, bg);
                catch
                    disp ('Something unexpected with image numbers occurred');
                    plot (x_numimages, bg);
                end
                axis tight;
                legend ('Background');
                if askaboutBGC == false
                    useBGCForBoth = 1;
                else
                    useBGCForBoth = input ("Do you want to use background corrected F (1), not use BGC F (0), or do an iteration of each (2)? 1/0/2");
                end
                %now saving all BGC figures
                BG_dir = fullfile (path_results, 'BGC', rec_num);
                dir_exists (BG_dir);
                BG_dir = fullfile (BG_dir, rec_num + sweeps(b));
                saveas (figf, BG_dir+'_figf.fig'); %non-background corrected F
                saveas (figc, BG_dir+'_figc.fig'); %background corrected F
                saveas (figbg, BG_dir+'_figbg.fig');%the figure showing the unsmoothed BG F
                try
                    saveas (fbgs, BG_dir+'_figbgs.fig'); %the figure showing the smoothed background F (no signal here)
                    close (fbgs);
                catch
                    disp ("not using new BGC");
                end
                close (figf, figc, figbg);
                if useBGCForBoth == 1
                    fluoro = corrected;
                    usedBGcorrected = true;
                elseif useBGCForBoth == 0
                    usedBGcorrected = false;
                elseif useBGCForBoth == 2
                    fluoro2 = corrected;%now we will have fluoro and fluoro2
                    usedBGcorrected = true;
                end
                try
                    avgF = mean (fluoro(1:baselineLengthForAvgF));%80 is fine for 10 ms puffing and for v steps
                    if useBGCForBoth == 2
                        avgF2 = mean (fluoro2(1:baselineLengthForAvgF));
                    end
                catch
                    af = input( "Enter the number of images over which the average F (for baseline re-correction) is taken (<80): ");
                    avgF = mean (fluoro (1:af));
                    if useBGCForBoth == 2
                        avgF2 = mean (fluoro2(1:af));
                    end
                end
                % compare num_images to counted_TTLs, throw error if not identical
                %                 tfrn = cellfun(@(p)isequal(p,rec_num),TTLs); %TTL find rec_num
                %                 [trnr,~] = find(tfrn); %TTL rec_num row and column
                %                 ttlnum = cell2mat(TTLs (trnr, 2));
                %
                %                 try
                %                     if ~isequal (num_images, ttlnum)
                %                         error = input ("Counted image TTLs ("+ttlnum+") does not match number of images ("+num_images+") for " + rec_num + ". Enter correct num:");
                %                     end
                %                 catch
                %                     error = num_images;
                %                 end

                %get the row of the puff start and end for this trace/rec num
                pfrn = cellfun(@(x)isequal(x,rec_num),puffs);
                [prnr,~] = find(pfrn);

                %directory to save the bleaching correction figures
                bleach_dir = fullfile (path_results, 'baseline_correction', rec_num);
                fluoro_dir = fullfile (path_results, 'fluorescence_traces', rec_num);
                fluoro_dir2 = fullfile (path_results, 'fluorescence_traces2', rec_num);%for when anaylsing ORCHID with both BGC and no BGC
                combined_dir = fullfile (path_results, 'combinedF', rec_num);
                mean_dir = fullfile (path_results, 'meanF', rec_num);
                mean_dir2 = fullfile (path_results, 'meanF2', rec_num);%for when anaylsing ORCHID with both BGC and no BGC
                dir_exists (bleach_dir);
                dir_exists (fluoro_dir);
                dir_exists (fluoro_dir2);
                if isORCHID == 1 %only create mean directory if it is an ORCHID recording
                    dir_exists (mean_dir);
                    dir_exists (mean_dir2);
                end
                bleach_dir = fullfile (bleach_dir, rec_num + sweeps(b));
                fluoro_dir = fullfile (fluoro_dir, rec_num + sweeps(b));
                fluoro_dir2 = fullfile (fluoro_dir2, rec_num + sweeps(b));
                mean_dir = fullfile (mean_dir, rec_num + sweeps(b));
                mean_dir2 = fullfile (mean_dir2, rec_num + sweeps(b));
                % correct for bleaching
                if faster == false
                    z = input ("Do you want to zero the signal? 1/0");
                elseif faster == true && in_vivo == false
                    z = 1;
                elseif faster == true && in_vivo == true
                    z = 0;
                end

                if (z == 1)
                    zero_out = zero_signal (fluoro, num_images, light_imgs, isORCHID, faster);
                    if useBGCForBoth == 2
                        zero_out2 = zero_signal (fluoro2, num_images, light_imgs, isORCHID, faster);
                    end
                else
                    zero_out = fluoro;
                    if useBGCForBoth == 2
                        zero_out2 = fluoro2;
                    end
                end
                [corrected_fluoro, uncorrected] = correct_photobleaching_zeroed (fluoro, zero_out, bleach_dir, x_time);
                if useBGCForBoth == 2
                    disp ('now doing the BG corrected version')
                    [corrected_fluoro2, uncorrected2] = correct_photobleaching_zeroed (fluoro2, zero_out2, bleach_dir, x_time);
                end
                %once we have background corrected and photobleaching
                %corrected, we add the average F taken before this was done
                %to each data point (this is to make dF/F accurate). If
                %uncorrected is true, we didn't do any bleaching correction
                if uncorrected == false
                    corrected_fluoro = corrected_fluoro + avgF;
                    if useBGCForBoth == 2
                        corrected_fluoro2 = corrected_fluoro2 + avgF2;
                    end

                end

                if isORCHID == 1
                    tpi = endt/counted_TTLs; %time per image. this is correct as endt is the time the last TTL ends
                    [fmean, ni, pl] = average_ORCHID_1swp (corrected_fluoro, light_imgs, mean_dir, num_images, npulses, tpi, faster);
                    if useBGCForBoth == 2
                        [fmean2, ni2, pl2] = average_ORCHID_1swp (corrected_fluoro2, light_imgs, mean_dir2, num_images, npulses, tpi);
                    end
                end

                % get the img puff start and img puff end
                imgps = cell2mat(puffs (prnr, 2));
                imgpe = cell2mat(puffs (prnr, 3));

                % get deta F
                if faster == false
                    gdf = input ("Get deltaF? 1/0. 0 if characterising");
                else
                    gdf = 1;
                end

                if (gdf == 1)
                    %this now calculates deltaF using avgF, and the PSP
                    %height
                    if isORCHID == 1 && in_vivo == 0
                        [baselineF, maxF, deltaF, sds, maxFs, deltaFs, sdsSmooth, bdps, window_length] = get_deltaF_ORCHID (fmean, ni, pl, fluoro_dir, num_images, exposure, x_time, faster);
                        if useBGCForBoth == 2
                            [baselineF2, maxF2, deltaF2, sds2, maxFs2, deltaFs2, sdsSmooth2, bdps2, window_length2] = get_deltaF_ORCHID (fmean2, ni2, pl2, fluoro_dir2, num_images, exposure, x_time, faster);
                        end
                    elseif isORCHID == 0 && in_vivo == 0 && is0MgBaseline == 0
                        [baselineF, maxF, deltaF, sds, maxFs, deltaFs, sdsSmooth, bdps, window_length] = get_deltaF (corrected_fluoro, imgps, imgpe, fluoro_dir, num_images, exposure, x_time, is0Mg, Mg_light_images);
                        if useBGCForBoth == 2 %we currently can't get deltaFs for both BGC and no-BG, even if we selected analysing both. would change here
                            [baselineF2, maxF2, deltaF2, sds2, maxFs2, deltaFs2, sdsSmooth2, bdps2, window_length2] = get_deltaF (corrected_fluoro2, imgps, imgpe, fluoro_dir, num_images, exposure, x_time);
                        end
                    elseif isORCHID == 0 && in_vivo == 0 && is0MgBaseline == 1
                        [baselineF, maxF, deltaF, sds, maxFs, deltaFs, sdsSmooth, bdps, window_length] = get_deltaF_0Mg_baseline (corrected_fluoro, imgps, imgpe, fluoro_dir, num_images, exposure, x_time, is0Mg, Mg_light_images);
                    elseif isORCHID == 1 && in_vivo == 1 %haslfp is used as proxy for invivo
                        [baselineF, maxF, deltaF, sds, maxFs, deltaFs, sdsSmooth, bdps, window_length, imgs_Fiv, imgs_BGiv] = get_deltaF_in_vivo (corrected_fluoro, light_imgs, fluoro_dir, num_images, exposure, x_time);
                    end
                else
                    baselineF = 0; baselineF2 = 0;
                    maxF = 0; maxF2 = 0;
                    deltaF = 0; deltaF2 = 0;
                    sds = 0;sds2 = 0;
                    bdps = 0; bdps2 = 0;
                    maxFs = 0; maxFs2 = 0;
                    deltaFs = 0; deltaFs2 = 0;
                    sdsSmooth = 0; sdsSmooth2 = 0;
                    window_length = 0; window_length2 = 0;
                end

                % save the combined figure
                x_numimages = 1:1:num_images;
                figure (cff);
                hold on
                try
%                     if haslfp == true
%                         subplot (2,1,1);
%                         hold on;
%                         plot (x_time, corrected_fluoro);
%                         axis tight;
%                         xlabel ('time (ms)');
%                         hold off;
%                         if ORCHID == true %adds lines for when the light goes on and off. used to be if ORCHID is true
%                             hold on
%                             xline (x_time(light_imgs (1,:)), 'g');
%                             xline (x_time(light_imgs (2,:)), 'r');
%                             hold off
%                         end
%                         subplot (2,1,2);
%                         hold on;
%                         plot (lfptime, lfp);
%                         axis tight;
%                         xlabel ('time (s)');
%                         hold off;
%                     else
                        plot (x_time, corrected_fluoro);
                        xlabel ('time (ms)');
                        if isORCHID == true %adds lines for when the light goes on and off
                            hold on
                            xline (x_time(light_imgs (1,:)), 'g');
                            xline (x_time(light_imgs (2,:)), 'r');
                            hold off
                        end
%                     end
                catch
                    disp ('Something unexpected with image numbers occurred');
                    plot (x_numimages, corrected_fluoro);
                    xlabel ('num_images');

                    if isORCHID == true %adds lines for when the light goes on and off
                        hold on
                        xline (x_time(light_imgs (1,:)), 'g');
                        xline (x_time(light_imgs (2,:)), 'r');
                        hold off
                    end
                end

                legend (sweeps);
                axis tight;
                hold off;

                %now repeat above for BG corrected if we are doing both
                if useBGCForBoth == 2
                    %cff2 = figure ('Name', ffn);
                    figure (cff2);
                    hold on
                    try
                        plot (x_time, corrected_fluoro2);
                        xlabel ('time (ms)');

                        if isORCHID == true %adds lines for when the light goes on and off
                            hold on
                            xline (light_imgs (1,:), 'g');
                            xline (light_imgs (2,:), 'r');
                            hold off
                        end
                    catch
                        disp ('Something unexpected with image numbers occurred');
                        plot (x_numimages, corrected_fluoro2);
                        xlabel ('num_images');

                        if isORCHID == true %adds lines for when the light goes on and off
                            hold on
                            xline (light_imgs (1,:), 'g');
                            xline (light_imgs (2,:), 'r');
                            hold off
                        end
                    end

                    legend (sweeps);
                    axis tight;
                    hold off;
                end
                
                %now plot a nice figure of both LFP and fluoro with light
                %lines 
                deltaF_BG = 0;
                dFBG_change = 0;
                if in_vivo == true
                    figlfp = figure();
                    subplot (2,1,1);
                    plot (lfptime, lfp);
                    xlabel ('time (s)');
                    axis tight;
                    subplot (2,1,2);
                    plot (x_time, corrected_fluoro);
                    axis tight;
                    xlabel ('time (ms)');
                    hold on
                    xline (x_time(light_imgs (1,:)), 'g');
                    xline (x_time(light_imgs (2,:)), 'r');
                    hold off

                    wjefb = input ("Does it look alright?");
                    fn = date + "_" + cell_num + "_" + cf;
                    path_results_lfp = fullfile (path_results, 'LFP', fn);
                    dir_exists (path_results_lfp);
                    fp = fullfile (path_results_lfp, fn + "_LFP+F.fig");
                    saveas (figlfp, fp);

                    %now run the this to get the deltaF of the BG at the
                    %same time poinnts as you got it for the F trace
                    [deltaF_BG, dFBG_change] = get_deltaF_backgroundiv (path_results, rec_num, fn, imgs_Fiv, imgs_BGiv);

                    try
                        close (figlfp);
                    catch
                        disp ("Unable to close a figure.");
                    end
                end
                % save the data
                % sa is the folder number we start at for each group
                % grouped by wcp recording number (ie 003). b loops through
                % this group (1: number in group)
                if useBGCForBoth == 2
                    fluorostruct (sa - 1 + b) = struct ('Recording', rec_num + sweeps (b),...
                        'BaselineF', baselineF,...
                        'MaxMinF', maxF,...
                        'DeltaFoverF', deltaF,...
                        'StandardDevs', sds,...
                        'UsedBGcorrected', usedBGcorrected,...
                        'BaselineDatapoints', bdps,...
                        'SmoothedMaxMinF', maxFs,...
                        'SmoothedDeltaFoverF', deltaFs,...
                        'SmoothedStandardDevs', sdsSmooth,...
                        'SmoothingWindowLength', window_length,...
                        'MeanBackground', meanbg,...
                        'BaselineF2', baselineF2,...
                        'MaxMinF2', maxF2,...
                        'DeltaFoverF2', deltaF2,...
                        'StandardDevs2', sds2,...
                        'BaselineDatapoints2', bdps2,...
                        'SmoothedMaxMinF2', maxFs2,...
                        'SmoothedDeltaFoverF2', deltaFs2,...
                        'SmoothedStandardDevs2', sdsSmooth2,...
                        'SmoothingWindowLength2', window_length2);
                else
                    fluorostruct (sa - 1 + b) = struct ('Recording', rec_num + sweeps (b),...
                        'BaselineF', baselineF,...
                        'MaxMinF', maxF,...
                        'DeltaFoverF', deltaF,...
                        'StandardDevs', sds,...
                        'UsedBGcorrected', usedBGcorrected,...
                        'BaselineDatapoints', bdps,...
                        'SmoothedMaxMinF', maxFs,...
                        'SmoothedDeltaFoverF', deltaFs,...
                        'SmoothedStandardDevs', sdsSmooth,...
                        'SmoothingWindowLength', window_length,...
                        'DeltaF_BG', deltaF_BG,...
                        'BGChange', dFBG_change,...
                        'MeanBackground', meanbg);
                end
                new_cell = false;
            end % end of loop cycling through the imaging foldersof specific trace
            dir_exists (combined_dir);
            combined_dir1 = fullfile (combined_dir, ffn + ".fig");
            saveas (cff, combined_dir1);

            if useBGCForBoth == 2
                combined_dir2 = fullfile (combined_dir, ffn + "_BGC.fig");
                saveas (cff2, combined_dir2);
            end

            % to overlay characterisation traces and get dF/Fs
            if isCharacterisation == true
                if input ("Do you wish to overlay the traces? 0/1") == 1
                    %don't call get_fig_data as it requires a path
                    dataObjs = findobj(cff,'-property','YData');
                    ydata = dataObjs(1).YData;
                    %path to Overlayed folder in cell results
                    overlay_dir = fullfile (path_results, "Overlayed");
                    dir_exists (overlay_dir);
                    %call overlay_ftrace, which calls get_deltaF_vsteps
                    % pass bg into overlay_ftrace as aa, as before both
                    % figs were being saved as BG2 as aa was == 2 in both
                    % calls
                    bgcUsed = 1;

                    overlay_ftrace_100Hz(ydata, vStepswps, overlay_dir, rec_num, bgcUsed, twentyfiveHz)

                    if useBGCForBoth == 2
                        dataObjs2 = findobj(cff2,'-property','YData');
                        ydata2 = dataObjs2(1).YData;
                        bgcUsed = 2;
                        overlay_ftrace_100Hz(ydata2, vStepswps, overlay_dir, rec_num, bgcUsed, twentyfiveHz)
                    end

                end
            end
            
            %closing this here because it is nice to see during analysis 
            if haslfp == true
                try
                    close (figlfp);
                catch
                    disp ("cannot close lfp fig");
                end
            end

            try
                close (fv, cff);
                close (cff2);
            catch
                disp ("Could not close voltage or combined figure.");
            end
        end % end of if (we want to analyse the 001 imaging folders)
        sa = tni (end) + 1; %next loop we start at the imaging folder after the last index
    end
    path_fluoro = fullfile (path_results, date + "_" + cell_num + "_fluoro.mat");
    save (path_fluoro, 'fluorostruct');
end

