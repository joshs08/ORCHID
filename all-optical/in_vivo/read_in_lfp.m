% to read in an lfp trace from during an in vivo ORCHID experiment
% in the form of an xlsx file. 
% it saves a figure of the trace 

function [lfp, lfptime] = read_in_lfp (path_lfp, path_results, date, cell_num, trace_num, cf)


fn = date + "_" + cell_num + "_" + cf;
xlname = fn + "_LFP.xlsx";
path_lfpfile = fullfile (path_lfp, xlname);
path_results_lfp = fullfile (path_results, 'LFP', fn);

t = readtable (path_lfpfile);
lfptime = table2array(t (:,1));
lfp = table2array(t(:, 4));
c = table2array(t(:, 3));

%lfp_raw_tt = array2timetable(lfp_raw,'RowTimes',time);

call = find (c > 2); %find all indices when camera is on
con = call(1); %time when camera first goes on
coff = call (end); %time  when camera first goes off

%conind = find (c == con); %index camera goes on
%coffind = find (c == coff);

lfp = lfp (con:coff, :); %cut it to imaging only
c = c (con:coff, :);
lfptime = lfptime (con:coff, :);
lfptime = lfptime - lfptime (1,1); %we want it starting from 0 not the number of minutes in a day lol

% lfp_raw_filt = lfp;
% l = lfptime (end) - lfptime (1);
% sampint = numel (lfptime)/l;
% % fpass = [1; 140]; %bandpass
% % lfp_raw_filt = bandpass(lfp_raw_filt,fpass, fs); %sampled at 10k/s
% 
% %x = 1:(numimgs/numel(lfp)):numimgs;
% 
% %sampint = max(lfp(:,1))/length(lfp); %sampling interval (s)
% Fsampling = 1/sampint;
% F1cutoff = 1; %in Hz
% F2cutoff = 140;
% Pole = 1;
% F1norm = F1cutoff/(Fsampling/2);
% F2norm = F2cutoff/(Fsampling/2);
% [b1,a1] = butter(1,[F1norm F2norm],'bandpass');
% BaseTrace = filtfilt(b1,a1,lfp(:,1)); %filtfilt does zero phase digital filtering ie no delay!
% 
% 
% %attempt 2
% filteredlfp = bandpass(lfp,[1 140],10000);
% 
% Fs = 10000;
% T = 1/Fs;
% L = numel (lfp);
% t = (0:L-1)*T;
% Y = fft(filteredlfp);
% P2 = abs(Y/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2*P1(2:end-1);
% f = Fs*(0:(L/2))/L;
% plot(f,P1) 

figlfp = figure();
%subplot (2,1,1);
plot (lfptime, lfp);
axis tight;
%subplot (2,1,2);
%plot (x, lfp);
%hold on
%xline (light_imgs (1,:), 'g');
%xline (light_imgs (2,:), 'r');
%hold off
dir_exists (path_results_lfp);
fp = fullfile (path_results_lfp, fn + "_LFP.fig");
saveas(figlfp, fp);
% try
%     close (figlfp);
% catch
%     disp ("cannot close lfp fig");
% end


%temp = input ("View data");

path_results = 'D:\Joshua\data\aav_ORCHID_in_vivo\LFP\230518\Mouse2';
path_lfp = "D:\Joshua\data\aav_ORCHID_in_vivo\LFP\230518\Mouse2";
date = "230518";
cell_num = "06";
trace_num = "001";
cf = "001(1)";
light_imgs = 0;




