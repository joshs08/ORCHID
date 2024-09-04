% take fluoro data, finds the max, finds the baseline region as x
% images before the max, calculates the average fluorescence over that
% region, calculates max deltaF/F

% TODO: should change this figure to display time and not images

function [bf, maxF, df, sds, maxFSmooth, dfSmooth, sdsSmooth, bdps, window, imgs_F, imgs_BG] = get_deltaF_in_vivo (F, light_imgs, savedir, num_imgs, exp, time)

%signal start gap (number of images we wait for stable blue v change
sagap = 2;
sbgap = 0;
%instantiate
imgs_F = [1;2];
imgs_BG = [1;2];

N = size (F, 2);
time = time(1:N);
window = 0; %for if we were smoothing, but we ain't! 


ff = figure;
plot (time, F, 'r');
xlabel ("time (ms)");
axis tight;

%draw puff lines
try
    xline (time(light_imgs (1,:)), 'g');
    xline (time(light_imgs (2,:)), 'r');
catc
    disp ('No data available for images when blue light was on/off');
end

tr = input ("do you want to take a reading? 0/1"); %take reading
if tr == 1
    mmgood = 0; %min or max is good?
    iteration = 0;
    while mmgood == 0
        disp ('Enter an end for the reading window. Click between the light on and off please');
        [xm,~] = ginput (1);

        %xm = round (xm, 0); %round for index again
        %xm = find (time == xm); %because it is now in time not images

        %now find index of point. ffs matlab
        distances1 = abs(time - xm);
        [minDistance, indexOfMin1] = min(distances1);

        xm = indexOfMin1;

        %find the light start and ends closest to this point
        found = false;
        for z = 1:size (light_imgs, 2)
            if light_imgs (2, z) > xm && found == false
                found = true;
                ls = light_imgs (1, z);
                le = light_imgs (2, z);
            end
        end

        if iteration > 0
            sagap = input ("Enter a better start gap (default 2 images): ");
            sbgap = input ("Enter a better end gap (default 0 images): ");
        end
        slength = le-sbgap-ls-sagap; %the length of the signal we average over
        meanF = mean (F(ls+sagap:le-sbgap));

        figure (ff); %plot new
        hold on;
        mml = xline (time(ls+sagap), '.b');
        smml = xline (time(le-sbgap), '.b');
        hold off;
        mmgood = input ("View epoch. Press 1 to continue or 0 to change epoch.");
        iteration = iteration + 1;
    end
    %output the images we take the mean over, for BG deltaF calc
    imgs_F = [ls+sagap; le-sbgap];
elseif tr == 0
    disp ("no reading required");
end


%% Baseline
% setting baseline length to the entire baseline, and taking exposure into
% account
% end baseline 50 ms before puff start


if tr == 1
    answ2=0;
    if answ2 == 0
        %you can iteratively and indefinitely select baselines if you wish ;)
        correct = false;
        while correct == false
            disp ('Enter a better baseline END');
            [x,~] = ginput (1);

            %x = round (x, 0); %round for index again
            distances2 = abs(time - x);
            [minDistance2, indexOfMin2] = min(distances2);
            x = indexOfMin2;
            base_ind_e = x;
            base_ind_s = x - slength;

            %add new lines
            figure (ff);
            hold on;
            try
                delete (fbs);
                delete (fbe);
            catch
                disp ("first iteration");
            end
            fbs = xline (time(base_ind_s), 'k');
            fbe = xline (time(base_ind_e), 'k');
            hold off;

            answ3 = input ("View baseline. 1 to continue or 0 to change");

            if answ3 == 1
                correct = true;
            else
                slength = input ("Enter a desired length for baseline in images: ");
            end
        end
    end
    %output the images we take the mean baselineover, for BG deltaF calc
    imgs_BG = [base_ind_s; base_ind_e];
end

%save figure
exp = round (exp);
savedir = savedir + "_" + string (num_imgs) + "x" + string (exp) + "ms.fig";
saveas (ff, savedir);
if tr == 1
    %calc average baseline. baseline datapoints (bdps)
    bdps = F (base_ind_s:base_ind_e);
    baselineF = mean (bdps);
    baselineSD = std (bdps);


    %percentage increase (dF/F)
    % we can use baselineF here as we have added avgF to each DP in the main
    % class.
    %we also get the number of standard deviations the signal is above the
    %noise (sds)
    change = meanF - baselineF;
    sds = change/baselineSD;
    deltaF = change/baselineF;

    changeSmooth = 0;
    sdsSmooth = 0;
    dfSmooth = 0;

    bf = baselineF; maxF = meanF; df = deltaF; maxFSmooth = 0;
else
    bf = 0;
    maxF = 0;
    df = 0;
    sds= 0;
    maxFSmooth= 0;
    dfSmooth= 0;
    sdsSmooth= 0;
    bdps= 0;
end
close (ff);


