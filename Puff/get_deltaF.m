%%take fluoro data, finds the max, finds the baseline region as x
%%images before the max, calculates the average fluorescence over that
%%region, calculates max deltaF/F

% TODO: should change this figure to display time and not images

function [bf, maxF, df, sds, maxFSmooth, dfSmooth, sdsSmooth, bdps, window] = get_deltaF (F, img_ps, img_pe, savedir, num_imgs, exp, time, is0Mg, Mg_light_images)

N = size (F, 2);
x = (1:1:N);
time = time(1:N);
%% testing which window size to use

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
catch
    disp ('could not save SAD figure due to . in filename');
end

% Smooth F trace
%can try a bunch of different ones
%smoothing = input ("Do you want to smooth? 0/1");
smoothing = 1;
if (smoothing == 1)
    good = 0;
    figs = figure;
    %while good == 0
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
        %good = input ("Does it look good? 0/1"); %if you  reinstate the
        %while
    %end %also for while
    try
        close (figs);
    catch
        disp ("Cannot close fig!");
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
% if it is a 0 Mg ORCHID recording, draw lines on at all stimulus points
if is0Mg == true
    light_images_flat = reshape(Mg_light_images,[],1); 
    xline (time (light_images_flat), 'b');
end
%draw puff lines
try
    xline (time(img_ps), 'g');
    xline (time(img_pe), 'g');
catch
    disp ('No puff data available!');
    img_ps = 1;
end
mm = input ("Do you want the max (h) or the min (l) or neither (x)?", 's');

if strcmp (mm, "h")
    mF = max (F); %max or min of F
    mFs = max (Fs);
elseif strcmp (mm, "l")
    mF = min (F);
    mFs = min (Fs);
elseif strcmp (mm, "x")
    mF = 0;
    m_index = 1; %incase there
    sm_index = 1;
end

% if we want neither we still need an index for the line
if ~strcmp (mm, "x")
    m_index = find (F == mF);   %index of the max or min
    m_index = round (m_index); %round it as we will be using it as an index value
    % for smoothed
    sm_index = find (Fs == mFs);   %index of the max or min
    sm_index = round (sm_index);
end
%plot max and see if it is appropriate, if it isn't, user
%selects a wndow over which to select max
figure (ff);
ml = xline (time(m_index), '.m');
sml = xline (time(sm_index), '.b');
hold off;

if ~strcmp (mm, "x")
    answ = input ("Does this min/max look appropriate? 0/1");
else
    answ = 2;
end

if answ == 1 %if max looks correct, set maxF as cut_maxF
    disp ('Min/max is correct');
elseif answ == 0
    disp ('Enter an end for the min/max window (over 100 images)');
    [xm,~] = ginput (1);

    %xm = round (xm, 0); %round for index again
    %xm = find (time == xm); %because it is now in time not images

    %now find index of point. ffs matlab
    distances1 = abs(time - xm);
    [minDistance, indexOfMin1] = min(distances1);

    xm = indexOfMin1;
    m_ind_e = xm;
    if xm >= 100
        m_ind_s = xm - 100;
    elseif xm >= 50 && xm < 100
        m_ind_s = xm - 50;
    elseif xm >= 10 && xm < 50
        m_ind_s = xm - 10;
    end



    if strcmp (mm, "h")
        mF = max (F(m_ind_s:m_ind_e)); %max or min of F
        mFs = max (Fs(m_ind_s:m_ind_e));
    elseif strcmp (mm, "l")
        mF = min (F(m_ind_s:m_ind_e));
        mFs = min (Fs(m_ind_s:m_ind_e));
    end

    m_index = find (F(m_ind_s:m_ind_e) == mF);
    m_index = round (m_index); %round it as we will be using it as an index value
    m_index = m_index + m_ind_s - 1; %correct for the fact we were searching in a subset of F

    sm_index = find (Fs(m_ind_s:m_ind_e) == mFs);
    sm_index = round (sm_index); %round it as we will be using it as an index value
    sm_index = sm_index + m_ind_s - 1;

    figure (ff); %plot new
    hold on;
    delete (ml);
    delete (sml);
    xline (time(m_index), '.m');
    xline (time(sm_index), '.b');
    hold off;
end

%% Baseline
% setting baseline length to the entire baseline, and taking exposure into
% account
% end baseline 50 ms before puff start

% close sad figure now
try
    close (fSAD);
catch
    disp ('Cannot close fig');
end

basegap = ceil(50/exp);

base_ind_e = img_ps - basegap;
if (base_ind_e < 2)
    base_ind_e = 4;
    disp ("couldn't do usual baseline calc");
end
base_ind_s = 2;

figure (ff);
hold on;
fbs = xline (time(base_ind_s), 'k');
fbe = xline (time(base_ind_e), 'k');
hold off;

%if baseline is partly on the peak, you can select a new
%basline

answ2 = input ("Is this a suitable position for baseline? 0/1 (zero is no)");

if answ2 == 0
    %you can iteratively and indefinitely select baselines if you wish ;)
    correct = false;
    blength2 = 60;
    while correct == false
        disp ('Enter a better baseline END');
        [x,~] = ginput (1);

        %x = round (x, 0); %round for index again
        distances2 = abs(time - x);
        [minDistance2, indexOfMin2] = min(distances2);
        x = indexOfMin2;
        base_ind_e = x;
        base_ind_s = x - blength2;

        %add new lines
        figure (ff);
        hold on;
        delete (fbs);
        delete (fbe);
        fbs = xline (time(base_ind_s), 'k');
        fbe = xline (time(base_ind_e), 'k');
        hold off;

        answ3 = input ("Now is this a suitable position for baseline?? 0/1");

        if answ3 == 1
            correct = true;
        else
            blength2 = input ("Enter a desired for baseline in images (default is 40)");
        end
    end
end

%save figure
exp = round (exp);
savedir = savedir + "_" + string (num_imgs) + "x" + string (exp) + "ms.fig";
saveas (ff, savedir);

%calc average baseline. baseline datapoints (bdps)
bdps = F (base_ind_s:base_ind_e);
baselineF = mean (bdps);
baselineSD = std (bdps);


%percentage increase (dF/F)
% we can use baselineF here as we have added avgF to each DP in the main
% class.
%we also get the number of standard deviations the signal is above the
%noise (sds)
change = mF - baselineF;
sds = change/baselineSD;
deltaF = change/baselineF;

changeSmooth = mFs - baselineF;
sdsSmooth = changeSmooth/baselineSD;
deltaFSmooth = changeSmooth/baselineF;

bf = baselineF; maxF = mF; df = deltaF; maxFSmooth = mFs; dfSmooth = deltaFSmooth;
close (ff);


