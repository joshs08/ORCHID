% This script takes fluoro data, finds the max, finds the baseline region as x
% images before the max, calculates the average fluorescence over that
% region, calculates max deltaF/F

% TODO: should change this figure to display time and not images

function [bf, maxF, df, sds, maxFSmooth, dfSmooth, sdsSmooth, bdps, window] = get_deltaF_ORCHID (F, ni, pl, savedir, num_imgs, exp, time, faster)

N = size (F, 1);
x = (1:1:N);
time = time(1:N);
% testing which window size to use for smoothing

windowSizes = 3 : 1 : 20;
for k = 1 : length(windowSizes)
    smoothedSignal = smoothdata(F, 'movmean', windowSizes(k));
    sad(k) = sum(abs(smoothedSignal - F));
end
d = diff (sad);
fSAD = figure;
subplot (2,1,1);
plot(windowSizes, sad, 'b*-', 'LineWidth', 2);
grid on;
xlabel('Window Size', 'FontSize', 20);
ylabel('SAD', 'FontSize', 20);
windowSizes = windowSizes (2:end);
subplot (2,1,2);
plot (windowSizes, d);

savedirSAD = savedir + "_SAD";
try
    saveas (fSAD, savedirSAD);
    close (fSAD);
catch
    disp ('could not save or close SAD figure due to . in filename');
end

% Smooth F trace
%can try a bunch of different ones
if faster == false
    dywts = input("Press 1 to smooth the trace (else 0)");
else
    dywts = 1;
end
if (dywts == 1)
    good = 0;
    figs = figure;
    while good == 0
        %window = input ("enter window length in images:");
        window = 7;
        %n = input("movmean, movmedian, gaussian, sgolay");
        n = 'movmean';
        Fs = smoothdata(F, n, window);
        figure (figs);
        plot (time, F, 'r');
        hold on
        plot (time, Fs, 'k', 'LineWidth', 2);
        xlabel ("time (ms)");
        axis tight;
        hold off
        if faster == false
            good = input ("Press 1 to continue or 0 to smooth again");
        else
            good = 1;
        end
    end
    try
        close (figs);
    catch
        disp ("Cannot close fig");
    end
else
    Fs = ones (1, size(x,2));
end


ff = figure;
plot (time, F, 'r');
hold  on
plot (time, Fs, 'k', 'LineWidth', 2);
xlabel ("time (ms)");
axis tight;
%draw puff lines
ba = 2;
bb = ni - 2;
sa = ni+2;
sb = ni+pl;
try
    xline (time(ni+1), '--b');
    xline (time(ni+pl+1), '--b');
    xline (time(ba), 'r');
    xline (time(bb), 'r');
    xline (time(sa), 'g');
    xline (time(sb), 'g');
catch
    disp ('No puff data available');
    img_ps = 1;
end

%%
baselineF = mean (F(ba:bb));
mF = mean (F(sa:sb));


%save figure
exp = round (exp);
savedir = savedir + "_" + string (num_imgs) + "x" + string (exp) + "ms.fig";
saveas (ff, savedir);

if faster == false
    disp ("Red lines: where baseline measurement was taken between. Blue lines: blue light on and off. Green lines: where the dF measurement was taken between.");
    temp = input ("View data. Press any key and ENTER.");
end
%percentage increase (dF/F)
% we can use baselineF here as we have added avgF to each DP in the main
% class.
%we also get the number of standard deviations the signal is above the
%noise (sds)
change = mF - baselineF;
deltaF = change/baselineF;

%disp ("DeltaF: " + deltaF + ". Baseline: " + baselineF + ". Change: " + change)
%ttt = input ("Abalysis output. Press any key and enter.");

bf = baselineF; maxF = mF; df = deltaF; maxFSmooth = 0; dfSmooth = 0; sdsSmooth = 0; sds=0; bdps = 0;
close (ff);


