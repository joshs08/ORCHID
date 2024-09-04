% this script displays the voltage trace from the .wcp file from a patched cell
% it only imports the first two (V and I) traces (along with camera)
% applies a gaussian filter to data
% returns dummy data for all the required variables that are not relevant (img_ps, img_pe (image
% puff starts and ends on) etc. 
% it saves a figure with the voltage traces, and the filtered and
% unfiltered traces

%NB: it calculates image number and images upon which V steps begin and end

% notes: for a 2 trace wcp file (V, I)

% NB - endt is taken as the sweep length, which is set by me. this is
% wrong, and has been changed in the other two get_v_trace scripts by
% cutting them off when the imaging TTLs end - not done here as imaging
% continues over many sweeps

function  [counted_TTLs, img_ps, img_pe, vm, i_hold, psp, quality, rtype, endt, steps] =...
    get_v_trace_v_and_i_only (path_data, path_results, date, cell_num, wcp_file,...
    setVorI, VorI, setSweepLength, swp_length) 

%for the other code we need output
counted_TTLs = ones (20, 1);
img_ps = 1:20:1;
img_pe = 1:20:1;
vm = ones (20,1);
i_hold = ones (20,1);
psp = ones (20,1);
quality = strings (20,1);
rtype = strings (20,1);

wcp_path = string(fullfile (path_data, wcp_file));
out = import_wcp(wcp_path, 'debug');

trace1 = out.S{1};
trace2 = out.S{2};
camera = out.S{4};
time = out.T; %gives the wrong time:(

%% fix V, I and t
% if it is a current clamp recording, and displays V in S{1}, set voltage
% as trace1, else set current as trace1
if setVorI == false
    vi = input ("First trace displays V, or does not (and displays I) 1/0");
else
    vi = VorI;
end
if (vi == 1)
    %if 1, the first trace is voltage, correct it as V is corrected
    trace1 = trace1*10e3;
    trace2 = trace2*10e3;
else
    %if 0, the trace 1 is I, correct it as I is corrected
    trace1 = trace1*10e3;
    trace2 = trace2*10e3;
end

numswps = size(trace1,2);

% time does not import correctly, if it is a 3250 ms recording (test_puff),
% time (end) = 83.9552. If it is a 5000 ms recording (6x_puffs and
% 1x_puff), time(end) = 19.1898
t_end = time(end);

if abs(t_end - 83.9552) < 0.001 * t_end
    swp_length = 3250;
elseif abs(t_end - 19.1898) < 0.001 * t_end
    swp_length = 5000;
elseif setSweepLength == false
    swp_length = input ('Sweep length unexpected. Please enter sweep length in ms:');
end

%fixing time
nt = size (time,2);
timeint = swp_length/nt; %interval between two timepoints
time = timeint*(1:nt);
endt = time (end); 

%% smooth the data
%s = input ("Do you wish to apply gaussian filter? 1/0");
disp ('gaussian deactivated');
s = 0;
if s == 1
    g = 0;
    gauss = 1500;
    trace2 = 1;
    while g == 0
        output1 = smoothdata(trace1, 'gaussian' , gauss);
        output2 = smoothdata(trace2, 'gaussian' , gauss);
        %plot
        rsv = figure ();
        plot(time,trace1,time,output1);legend('Raw','Smoothed');
        
        g = input ("View data. 1 to continue or 0 to smooth again");
        if g == 0
            a2 = input ("Select new gaussian? 1/0");
            if a2 == 1
                gauss = input ("Gaussian = " + gauss + ". Enter new gaussian: ");
            else
                output1 = trace1;
                output2 = trace2;
            end
        end
        close (rsv);
    end
else
    output1 = trace1;
    output2 = trace2;
end

%% plot the (potentially filtered) data:
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
plot(time, output1);

if vi ==1
    ylabel ('Voltage (mV)');
    
else
    ylabel ('Current (pA)');
end
xlabel ('Time (ms)');
legend (lbl);
axis tight

%save figure
saveas (figs, save_dir + '.fig');
close (figs);

%if input ("Do you want to combine sweeps? 0/1") == 1
 [trace2combined, cameracombined] = combine_sweeps (trace2, camera, numswps);
 %call count images and get the images upon which the steps start and end
 [counted_TTLs, steps] = count_images_get_vSteps (cameracombined, trace2combined, numswps);
%end


