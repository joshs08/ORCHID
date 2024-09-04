%% this takes one F trace that covers multiple wcp sweeps (number given in numswps)
% and overlays them onto one figure
% it is designed to work with F response to V/I step protocol
% path is the path to save the overlayed figure (to 'Overlay' folder)

function  [] = overlay_ftrace_100Hz (ydata, numswps, path_save, rec_num, usedBGCForBoth, twentyfiveHz)

%bA is the first baseline, i.e. the start of the nicely BG corretcetd trace
bAlength = input ("How many images do you want to get the baseline over? x-value/10");

%how long after one step do you want to take a mean over before you start
%looking for sweep end
if twentyfiveHz == 1
    gap = 15; %is 90 for 10 ms exposure, 100 Hz, 15 for 25 Hz
else
    gap = 90;
end
startbA = 1; %ususally 1, the point at which mean and std begin being taken

bA = mean (ydata (startbA:startbA+bAlength)); %mean of baseline
bAsd = std  (ydata (startbA:startbA+bAlength));

bueno = false;
repeats = -1; %if you're really struggling and do the cycle many times
while (bueno == false)
    repeats = repeats +1;

    if repeats > 3
        startbA = input ('add a new start for the baseline period. choose low SD');
        bA = mean (ydata (startbA:startbA+bAlength));
        bAsd = std  (ydata (startbA:startbA+bAlength));
    end

    stddevs = input("Enter no. of standard devs for signal detection i.e. 3-5");
    %we use stddevs number of std deviatiosn to test if it is baseline or
    %signal

    thresh = [bA + stddevs*bAsd; bA- stddevs*bAsd];
    length = size (ydata,2);

    %store the start and end of each signal ie voltage step
    %column 1 is start, column 2 is end
    stepArr = zeros (numswps,2);

    %loop through array and determine the start and end of each signal
    peak = false;
    %1 for peaks, 0 for troughs. Assume starts with peaks... set to 0 if it
    %starts with troughs
    peaktrough = 1;
    stepno = 1;
    %number of images you wait, after finding signal start, before looking
    %for signal end. for the smaller signals

    until = 0;
    for i = 1:length-gap-1 %stop one gap from end of ydata
        %while on baseline, looking for signal (peak or trough) start
        if peak == false
            meanlevel = mean(ydata (i:i+gap));
            %if t1 (i) > thresh (1) && t1 (i+1) > thresh (1) && t1(i+2) > thresh (1)
            if ydata (i) > thresh (1) && meanlevel > thresh (1)
                %look only for signal ends now
                peak = true;
                %add image number to array
                stepArr (stepno,1) = i;
                %on a peak
                peaktrough = 1;
                %don't look for signal end until i >= until
                until = i + gap;
                %elseif t1 (i) < thresh (2) && t1 (i+1) < thresh (2) && t1(i+2) < thresh (2)
            elseif ydata (i) < thresh (2) && meanlevel < thresh (2)
                peak = true;
                stepArr (stepno,1) = i;
                peaktrough = 0;
                until = i + gap;
            end
        end

        %while on peak/trough, looking for baseline
        if peak == true
            meanlevel = mean(ydata (i:i+gap));
            %if i >= until && peaktrough == 1 && t1 (i) < thresh (1) && t1 (i+1) < thresh (1) && t1(i+2) < thresh (1)
            if i >= until && peaktrough == 1 && ydata (i) < thresh (1) && meanlevel < thresh (1)
                peak = false;
                stepArr (stepno,2) = i;
                stepno = stepno+1;
                %elseif i >= until && peaktrough == 0 && t1 (i) > thresh (2) && t1 (i+1) > thresh (2) && t1(i+2) > thresh (2)
            elseif i >= until && peaktrough == 0 && ydata (i) > thresh (2) && meanlevel > thresh (2)
                peak = false;
                stepArr (stepno,2) = i;
                stepno = stepno+1;
            end
        end
    end

    figt = figure ();
    x = 1:1:length;
    plot (x, ydata);
    hold on;
    xline (startbA, 'g');
    xline (startbA+bAlength, 'g');

    for k = 1:numswps
        xline (stepArr (k,1));
        xline (stepArr (k,2));
    end
    if input ("Looks suitable?0/1") == 1
        bueno = true;
        temp = input ("Is saved, view and PAK");

        if usedBGCForBoth == 2
            path_save_file = fullfile (path_save, rec_num + "_peakselection_BG2.fig");
        else
            path_save_file = fullfile (path_save, rec_num + "_peakselection.fig");
        end
        saveas (figt, path_save_file);
        close (figt);
    end
    try
        close (figt);
    catch
        disp('a figure could not be closed');
    end
end

disp (stepArr);
%signal length good? is 100 for voltron, 25 for ORCHID
if twentyfiveHz == 1 
    slt = 25;
else
    slt = 100;
end
if input ("Does a signal length of " + slt + " look good? 0/1") == 1
    sl = slt;
else
    sl = input ("Enter better signal length");
end

stepArr = stepArr';
%array to store gap lengths (from one signal start to the next
stepstarts = stepArr (1,:);
stepends = stepArr (2,:);
%the way diff works, the value of stepstartdiff that is larger than the
%mean will have the index of the last stepstart before the 0 mV gap.
% only one should be above the mean
stepstartdiff = diff (stepstarts(:,1:7)); %1:7 else the last 0 in index 8 throws a large -ve diff
stependdiff = diff (stepends(:,1:7));
for j = 1:size (stepstartdiff, 2)
    if stepstartdiff (j) > mean (stepstartdiff)
        avgstartgap = round(mean (stepstartdiff(1:3)),0); %there are at least 3 v steps before the 0 mv
        avgendgap = round (mean (stependdiff(1:3)),0);
        stepArr (1, numswps) = stepstarts (j) + avgstartgap; %populate last value in array
        stepArr (2, numswps) = stepends (j) + avgendgap;
    end
end

%how much of each baseline do you want on either side of each step
bll = round (0.2 * avgstartgap,0);

%the length of each fluorescent 'signal' ie the length, with baseline on
%each side, of each v step in images
fl = round ((sl + (bll*2)),0);
%an array to save all the v steps
fArr = zeros (numswps, fl);

%populate fArr, using only the start of each signal
for m = 1:numswps
    fs = stepArr (1,m) - (bll);
    fe = fs + fl;
    f = ydata (fs:fe-1);
    fArr (m, :) = f;
end

figf = figure;
x2 = 1:fl;
plot (x2, fArr);
axis tight;
temp = input ("view and PAK");

if usedBGCForBoth == 2
    path_save_file = fullfile (path_save, rec_num + "_overlay_BG2.fig");
else
    path_save_file = fullfile (path_save, rec_num + "_overlay.fig");
end
saveas (figf, path_save_file);

close (figf);

if input ("Do you wish to get dF/Fs? 0/1") == 1
    get_deltaF_vsteps(path_save_file, path_save, rec_num, bll, sl, usedBGCForBoth, twentyfiveHz);
end


