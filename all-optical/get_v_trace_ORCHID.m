%% this script displays the voltage trace from the .wcp file from a patched cell
% It imports the first five (V and I and light TTL and camera and blue arduino TTL) channels
% Applies a gaussian filter to data
% Returns dummy data for ALL the returned (and thus required) variables (img_ps, img_pe (image
% puff starts and ends on) etc. This is necessary as these variables are
% not used for ORCHID analysis. 
% It saves a figure with the voltage traces, and the filtered and
% unfiltered traces

% notes: for a 5 channel wcp file (V, I, lightTTL and camera)

function  [counted_TTLs, img_ps, img_pe, vm, i_hold, psp, quality, rtype, light_imgs, endt]...
    = get_v_trace_ORCHID (path_data, path_results, date, cell_num, wcp_file, npulses,...
    setVorI, VorI, setSweepLength, swp_length) 

% for subsequent code we need output. Dummy data
img_ps = 1:20:1;
img_pe = 1:20:1;
vm = ones (20,1);
i_hold = ones (20,1);
psp = ones (20,1);
quality = strings (20,1);
rtype = strings (20,1);

% read in wcp
wcp_path = string(fullfile (path_data, wcp_file));
out = import_wcp(wcp_path, 'debug');

trace1 = out.S{1};
trace2 = out.S{2};
lightTTL = out.S{3};
camera = out.S{4};
blue = out.S{5};
time = out.T; %gives the wrong time:(

si = 10; ei = 11; %dummy data, should be puff indices
counted_TTLs = count_images (camera, si, ei);

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
elseif abs (t_end - 599938560) < 0.001 * t_end
    swp_length = 6000;
elseif abs (t_end - 1.0999e+09) < 0.001*t_end
    swp_length = 11000;
else
    if setSweepLength == false
    swp_length = input ('Sweep length unexpected. Please enter sweep length in ms:');
    end
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
    endc_trace = input ('the traces do not have the same endc. Enter a trace with correct endc:');
    endc = endc_arr (endc_trace);
else
    endc = endc_arr (1);
    endc_trace = 1;
end

% we now take one camera trace for all sweeps
if numswps > 1
    %camera (:, 2:end) = [];
    camera = camera (:, endc_trace);
end

% cut all necessary traces off here
cutt1 = trace1;
cutt1 (endc+1:end, :) = [];
%trace2 (endc+1:end, :) = [];
time = time (1:endc);
camera = camera (1:endc);
endt = time (end);
N = size (cutt1, 1); %number of elements after cutting off once camera stopped

%% find the light TTL start and ends. Assumes npulses light TTLs
st = 1; %index to start at
single = lightTTL (:, endc_trace);
e = size (single, 1); %index to end at
foundAll = false;
high = false;
pulse = 1;
ttls = zeros (2, npulses);

while ((st <= e) && (foundAll == false))
    if high == false && single(st) > 1
        ttls (1, pulse) = st;
        high = true;
    elseif high == true && single(st) < 1
        ttls (2, pulse) = st - 1;
        high = false;
        pulse = pulse + 1;
    end
    
    if pulse == npulses+1
        foundAll = true;
    end
    st = st + 1;
end

%% call count_images to get the image of the TTL start and end
% call it npulses times, once for each lightTTL
num_images = zeros (1, npulses);
light_imgs = zeros (2, npulses);

for j = 1:npulses
    starti = ttls (1, j);
    endi = ttls (2, j);
    [ni ,is , ie] = count_images (camera, starti, endi);
    light_imgs (1,j) = is;
    light_imgs (2,j) = ie;
    num_images (1,j) = ni; %not sure why this is needed
end

%% average the voltage trace for each sweep
fmean = figure();
for u = 1:numswps
    clear vpulse;
    pl_arr = zeros (1,npulses); %pulse lengths
    for k = 1:npulses
        pl_arr (1, k) = ttls (2,k) - ttls (1,k);
    end
    
    if all(pl_arr == pl_arr(1,1))
        pl = pl_arr (1,1);
    else
        pl = min (pl_arr (1,:));
        %         cf = zeros (1, npulses); %correction factor
        %         for t = 2:npulses
        %             %apply a correction of usually 1 data point to traces that have
        %             %a pulse length slightly longer/shorter
        %            cf (t) = pl_arr - pl;
        %         end
    end
    
    % number of indices before and after pulse
    ni = floor((N - (npulses*pl))/(npulses*2));
    %ni = pl-1;
    %ni = floor(pl/2);
    vpulse = zeros (pl + 2*ni, npulses);
    
    for y = 1:npulses
        vs = ttls (1, y) - ni;
%          if vs <= 0
%              vs = 1;
%          end
        ve = ttls (1, y) + pl + ni;
        vpulse (:, y) = trace1 (vs:ve-1, u);
    end
    tp = time (1:pl+(2*ni)); %time for the light pulse
    vmean = mean (vpulse, 2);
    
    hold on;
    plot (tp, vmean);
    axis tight;
    
end
lbl = (1:1:numswps);
lbl = string (lbl);
legend (lbl);
xline (tp(ni), '--b', 'HandleVisibility','off');
xline (tp(ni + pl), '--b', 'HandleVisibility','off');
hold off;

%get wcp rec num (ie 003) for figure names
length = strlength (wcp_file);
c = strfind(wcp_file, '_');
wcp_file_num = extractBetween(wcp_file, c + 1, length-4);

%get title for figures
title = date + '_' + cell_num + '_' + wcp_file_num;

%the name for the mean fiure
meantitle = title + '_mean';
set(fmean, 'Name', meantitle)

%% plot the data
%name for all data figure
figs = figure ('Name', title);

%get name to save file under and directory to save it in
save_dir = fullfile(path_results, 'voltage_traces');

% check dir existence and if not in existence, create it
dir_exists (save_dir);
save_dir_all = fullfile (save_dir, title);
save_dir_mean = fullfile (save_dir, meantitle);

% plot
%colour for traces
newcolors = {'#A2142F','#D95319','#EDB120','#77AC30','#4DBEEE','#7E2F8E'}; %ROYGBIV
colororder(newcolors);

% label for traces
lbl = (1:1:numswps);
lbl = string (lbl);

%plot voltage sweeps
plot(time, cutt1);

if vi ==1
    ylabel ('Voltage (mV)');
else
    ylabel ('Current (pA)');
end

xlabel ('Time (ms)');
legend (lbl);
axis tight

%save figure
saveas (fmean, save_dir_mean + '.fig');
saveas (figs, save_dir_all + '.fig');
close (figs, fmean);

