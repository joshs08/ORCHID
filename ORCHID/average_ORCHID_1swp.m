%% this script averages the three fluorescence traces for npulses light pulses
% takes in the BG corrected fluoro trace (from get_fluoro_changes),
% and the pulse image starts and ends (from get_v_trace_ORCHID),
% and averages the light responses

% NB - if the trace has a . extension (ie 004.2) it won't save. add code to remove this dot

function [fmean, ni, pl] = average_ORCHID_1swp (fluoro, pulse_imgs, save_dir, num_images, npulses, tpi, faster)

indall = strfind(save_dir,'\');
indlast = indall(end);
str2 = extractAfter (save_dir, indlast);
str1 = extractBefore (save_dir, indlast);

str2 = strrep(str2,'.','_');

save_dir = fullfile (str1, str2);

pl = zeros (1,npulses); %pulse lengths
for k = 1:npulses
    pl (1, k) = pulse_imgs (2,k) - pulse_imgs (1,k);
end

if all(pl == pl(1,1))
    pl = pl (1,1);
else
    disp (pl);
    %pl = input ("Pulse lengths different. enter preferred pulse length in images");
    pl = max (pl);
end

%there was an issue where some pulses were 1 image longer than others. I
%knew of this but didn't realise it was elading to those light pulses not
%being added to fpulse for averaging. Now I will set pulse end to pulse
%start + pl
for z = 1:npulses
    pulse_imgs (2,z) = pulse_imgs (1, z) + pl;
end
ni = 30;
%number of images before and after each pulse. this should give
fseArr = zeros (2,npulses); %an array to store the start and end of fluoro we will average

for i = 1:npulses
    fs = pulse_imgs (1, i) - ni; %fluoro start
    fe = pulse_imgs (2, i) + ni;
    fseArr (1, i) = fs;
    fseArr (2, i) = fe;
   % try
    fpulse (:, i) = fluoro (fs:fe);
    %catch
      %  disp ("Images needed are more than available for getting mean fluoro");
   % end
end

%new code added to plot for sanity
figavg = figure();
plot (fluoro);
hold on;
xline (fseArr (1, :), 'g');
xline (fseArr(2, :), 'r');
hold off;
axis tight;
figoverlay = figure();
plot (fpulse);
if faster == false
    temp = input('looks suitable? not able to change it either way unfortunately');
end
save_dir_avg = save_dir + "_avg";
save_dir_overlay = save_dir + "_overlay";
saveas (figavg, save_dir_avg);
saveas (figoverlay, save_dir_overlay);
try
    close (figavg);
    close (figoverlay);
catch
    disp ('figure could not be closed');
end
%end of new code 

fmean = mean (fpulse, 2);
mean_imgs = size (fmean, 1);
maxt = mean_imgs*tpi;
time = linspace (0, maxt, mean_imgs);
time = time';

figm = figure();
plot (time, fmean);
xlabel ("time (ms)");
hold on;
xline(time(ni+1),'--b');
xline (time(ni+pl+1), '--b');
hold off;
axis tight;
saveas (figm, save_dir);

try
    close (figm);
catch
    disp("could not close mean ORCHID fig");
end