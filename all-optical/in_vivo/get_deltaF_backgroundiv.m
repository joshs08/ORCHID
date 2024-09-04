%% this function open the BG figures for a specific cell we are analysing and subtracts the smoothed BG from the 
%BG trace, and then takes the images we took the signal and baseline values
%during for getdeltaF, and getsdeltaF for the BG too

function [deltaF_BG, change] = get_deltaF_backgroundiv (path, rec_num, fn, imgs_Fiv, imgs_BGiv)

path_save = fullfile (path, "BGC", rec_num, fn + "_dFBG.fig");
path_fbg = fullfile (path, "BGC", rec_num, fn + "_figbg.fig");
path_fbgs = fullfile (path, "BGC", rec_num, fn + "_figbgs.fig");

[xbg, Fbg] = get_fig_data (path_fbg);
[xbgs, Fbgs] = get_fig_data (path_fbgs);

%zero the smoothed trace
Fbgs = Fbgs - min (Fbgs);

%subtract the smoothed BG from the raw BG to get it noice and flat 
F = Fbg - Fbgs;

%plot this as well as the points we'd take deltaF from
figdf = figure();
plot (xbg, F);
axis tight;
hold on;
xline (xbg(imgs_Fiv (1,1)), 'g');
xline (xbg(imgs_Fiv (2,1)), 'r');
xline (xbg(imgs_BGiv (:,1)), 'k');
hold off;

t = input ("does this look suitable?");

saveas (figdf, path_save);

meanF = mean (F(imgs_Fiv (1,1):imgs_Fiv (2,1)));
baselineF = mean (F(imgs_BGiv (1,1):imgs_BGiv (2,1)));

change = (meanF - baselineF);
deltaF_BG = change/baselineF;

try
    close (figdf);
catch
    disp ("unable to close a figure");
end


