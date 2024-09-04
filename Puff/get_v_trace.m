% this script displays the voltage trace from the .wcp file from a patched cell
% it cuts the trace off at imaging end
% gets the min/max PSP of each wcp trace
% counts the images
% applies a gaussian filter to data
% returns the counted images, image puff starts on, image puff ends on, Vm,
% i_hold and the PSPs for each trace
% it saves a figure with the voltage traces, and the filtered and
% unfiltered traces

% notes: for a 4 trace wcp file (V, I, puff, camera)
%check current is fine

function  [counted_TTLs, img_ps, img_pe, vm, i_hold, psp, quality, type, endt, light_images] = get_v_trace (path_data, path_results, date, cell_num, wcp_file, patchData, setRecType, recType, is0Mg, npulses) %

%wcp_path = string(fullfile (path_folders, 'data', date, cell_num, wcp_file));
wcp_path = string(fullfile (path_data, wcp_file));
out = import_wcp(wcp_path, 'debug');

voltage = out.S{1};
current = out.S{2};
puff = out.S{3};
camera = out.S{4};
time = out.T; %gives the wrong time:(

%% fix V, I and t
numswps = size(voltage,2);
% convert to mV and pA
voltage = voltage*10e3;
current = current*10e2;

% time does not import correctly, if it is a 3250 ms recording (test_puff),
% time (end) = 83.9552. If it is a 5000 ms recording (6x_puffs and
% 1x_puff), time(end) = 19.1898
t_end = time(end);

if abs(t_end - 83.9552) < 0.001 * t_end
    swp_length = 3250;
    short = true;
elseif abs(t_end - 19.1898) < 0.001 * t_end
    swp_length = 5000;
    short = false;
elseif abs(t_end - 2194.8288) < 0.001 * t_end
    swp_length = 7000;
    short = false;
else
    swp_length = input ('Sweep length unexpected. Please enter sweep length in ms:');
    short = true;
end

%fixing time
nt = size (time,2);
timeint = swp_length/nt; %interval between two timepoints
time = timeint*(1:nt);

%% cutting off traces after last camera TTL
% get the index just after the last image for each sweep
endc_arr = zeros(numswps,1);
for j = 1:numswps
    camswp = camera(:,j);
    endc_arr (j)= get_camera_end (camswp);
end

% check that all sweeps have idential endc. if not, something is wrong! or one trace was a dud
% if they are identical, we can assume the camera trace of one is identical
% for all, and we can take an endc of any trace
if (all(diff(endc_arr) == 0)) == 0
    endc_trace = input ('the traces do not have the same camera frame data. Enter a trace with correct camera frame data:');
    endc = endc_arr (endc_trace);
else
    endc = endc_arr (1);
end

% we now take one camera trace for all sweeps
if numswps > 1
    camera (:, 2:end) = [];
end

% cut all necessary traces off here
voltage (endc+1:end, :) = [];
camera (endc+1:end, :) = [];
time = time (1:endc);
endt = time (end);
N = size (voltage, 1); %number of elements after cutting off once camera stopped

%% getting the images the puff occurs during, counting image TTLs
% get the puff start index and puff end index for each sweep

puffs_arr = zeros(numswps,1);
puffe_arr = zeros (numswps,1);
for k = 1:numswps
    puffswp = puff(:,k);
    try
        [puffs_arr(k), puffe_arr(k)] = get_puff_indexes (puffswp);
    catch
        disp ("One of the traces did not return puff indices");
    end
end

% check that all sweeps have idential puffs and puffe. if not, one trace was a dud
% if they are identical, we can assume the puff trace of one is identical
% for all, and we can calculate one puffs img and one puffe img
if ((all(diff(puffs_arr) == 0)) == 0) || ((all(diff(puffe_arr) == 0)) == 0)
    puff_trace = input ('the traces do not have the same puff start/end. Enter a trace with a correct puff TTL:');
    puffs = puffs_arr (puff_trace);
    puffe = puffe_arr (puff_trace);
else
    puffs = puffs_arr (1);
    puffe = puffe_arr (1);
end

%count the number of imaging TTLs, and get the images the puff started and
%ended on
[counted_TTLs, img_ps, img_pe] = count_images (camera, puffs, puffe);

%% if it is a 0 Mg ORCHID recording, get the light pulses
if is0Mg == true
    [light_images] = getLightPulsesORCHID0Mg (puff, camera, npulses);
else
    light_images = 0;
end
%% smooth the data
if patchData == 1
    s = input ("Do you wish to apply gaussian filter? 1/0");
else
    s = 0;
end
if s == 1
    g = 0;
    gauss = 1500;
    while g == 0
        voutput = smoothdata(voltage, 'gaussian' , gauss);
        ioutput = smoothdata(current, 'gaussian' , gauss);
        %plot
        rsv = figure ();
        plot(time,voltage,time,voutput);legend('Raw','Smoothed');
        
        g = input ("View data. 1 to continue or 0 to smooth again");
        if g == 0
            a2 = input ("Select new gaussian? 1/0");
            if a2 == 1
                gauss = input ("Gaussian = " + gauss + ". Enter new gaussian: ");
            else
                voutput = voltage;
                ioutput = current;
            end
        end
        close (rsv);
    end
else
    voutput = voltage;
    ioutput = current;
end


%% get Vm and iHold
vm = zeros (numswps, 1);
i_hold = zeros (numswps, 1);

% if short == false
%     bl = 500;
%     %this give a 500 ms baseline between 400 and 900 ms
%     bet = 900;
%     bst = bet - bl; %baseline start time
% else
%     bl = 150;
%     %this gives a 150 ms baseline between
%     bet = 200;
%     bst = bet - bl;
% end

bei = puffs - round(50/timeint); %end baseline 50 ms before puff start, same as imaging data 
bsi = 1;


%bsi = round(bst/timeint); %baseline start and end, as determined once obbservationally
%bei = round(bet/timeint);

%%
tf  = figure ();
%this is the only time this is plotted
plot (time, voutput);
hold on;

if patchData == 1
    patch = input ("Do you want to further analyse the patch data i.e., get dV? 1/0");
else
    patch = 0;
end

if (patch == 1)
    
    vbsl = xline (time(bsi), '--r'); %voltage baseline start line
    vbel = xline (time(bei), '--r');
    hold off;
    
    %if baseline is partly on the peak, you can select a new
    %basline
    
    answ2 = input ("Is this a suitable position for baseline? 0/1 (zero is no)");
    
    %you can iteratively and indefinitely select baselines if you wish ;)
    while answ2 == 0
        figure (tf);
        delete (vbsl);
        delete (vbel);
        bl = input("Enter a basline length in ms (usually 950 ms):");
        disp ('Enter a better baseline END');
        [x,~] = ginput (1);
        
        x = round (x, 0); %round for index again
        
        bei = round (x/timeint); %baseline end index
        bsi = round ((x - bl)/timeint);
        figure (tf);
        delete (vbsl);
        delete (vbel);
        hold on;
        vbsl =  xline (time(bsi), '--r');
        vbel =  xline (time(bei), '--r');
        hold off;
        
        answ2 = input ("Now is this a suitable position for baseline? 0/1");
    end
    
    try
        close (tf);
    catch
        disp ("Could not close a figure.");
    end
    %% get vm and ihold
    
    for j = 1:numswps
        vm (j) = mean (voutput (bsi:bei, j));
        i_hold (j) = mean (ioutput (bsi:bei, j));
    end
else %end of if we want to analyse patch data further
    vm = ones (numswps, 1);
    i_hold = ones (numswps, 1);
    
    try
        close (tf);
    catch
        disp ("Could not close a figure");
    end
    
end
%% plot the filtered data so user can select minmax for the PSPs:
%get wcp rec num (ie 003)
length = strlength (wcp_file);
c = strfind(wcp_file, '_');
wcp_file_num = extractBetween(wcp_file, c + 1, length-4);

%get title for figure
title = date + '_' + cell_num + '_' + wcp_file_num;
figs = figure ('Name', title);

%get name to save file under and directory to save it in
save_dir = fullfile(path_results, 'voltage_traces');

% check dir existence and if not in existence, create it
dir_exists (save_dir);
save_dir = fullfile (save_dir, title);

% plot
%colour for traces
newcolors = {'#A2142F','#D95319','#EDB120','#77AC30','#4DBEEE','#7E2F8E'}; %ROYGBIV
colororder(newcolors);

% label for traces
lbl = (1:1:numswps);
lbl = string (lbl);

%plot voltage and lines where baseline was taken, without showing in legend
plot(time, voutput);
ylabel ('Voltage (mV)');
xlabel ('Time (ms)');
legend (lbl);
axis tight
hold on;
if (patch == 1)
    xline(time(bsi),'--b', 'HandleVisibility','off');
    xline(time(bei), '--b', 'HandleVisibility','off');
end
xline (time(puffs), '--g', 'HandleVisibility','off');
xline (time(puffe), '--g', 'HandleVisibility','off');

hold off;

%save figure
saveas (figs, save_dir + '.fig');

%% get recording quality and type

if setRecType == 1
    type = recType;
else
    typearr = ["Baseline puffs", "Single patch puff", "6 repeats", "Some different potentials", "Many different potentials",...
        "High Cl-","VU", "Other"];
    [indx4,~] = listdlg('PromptString','Recording type: ',...
        'ListString',typearr, 'SelectionMode','single');
    type = typearr (indx4);
end

% qualarr = ["Great", "Good", "Average", "S#!t"];
% [indx3,~] = listdlg('PromptString','Recording quality: ',...
%     'ListString',qualarr, 'SelectionMode','single');
% quality = qualarr (indx3);
quality = 'Undetermined';


%% get the mix/max PSP
if patch == 1
    psp = get_min_max (voutput, time, numswps, bsi);
else
    psp = ones (numswps, 1);
end
close (figs);

