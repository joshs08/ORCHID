%% this small class will count the number of images in a camera ttl trace
%% it will also get the image on which a puff starts and ends
%input a camera trace cut off just after the last image for max efficiency

function  [num_imgs, steps] = count_images_get_vSteps (camera, voltage, numswps)

dps = size (camera, 1);
sdv = std (voltage (1:(dps/100))); %stddev of voltage, first 1% of values
mv = mean(voltage (1:(dps/100))); %mean of first 1% voltage values

%this will store the start and end images of the vsteps
steps = zeros (2, numswps);

%check if we start on a high or low TTL
if camera (1) > 1
    num_imgs = 1;
    on_img = true;
else
    num_imgs = 0;
    on_img = false;
end

% loop through all datapoints in 'camera', and count the high TTL pulses
% (images)
stepno = 1; %filling up step array with vsteps
onstep = false; %check whether we are on a vstep
positive = true;

for i = 1:dps
    if on_img == true && camera (i) < 1
        on_img = false;
    elseif on_img == false && camera (i) > 1
        num_imgs = num_imgs + 1;
        on_img = true;
    end

    %get the images of V steps. If voltage trace is above or below the
    %threshold
    if (voltage (i) > mv+(5*sdv) || voltage (i) < mv-(5*sdv)) && onstep == false
        onstep = true;
        if on_img == false %we record the images that capture atleast some of the v change
            steps (1, stepno) = num_imgs+1;
        else
            steps (1, stepno) = num_imgs;
        end
        %annoyingly, check if it is a +ve or -ve step for the elseif
        if voltage (i) > mv+(5*sdv)
            positive = true;
        elseif voltage (i) < mv-(5*sdv)
            positive = false;
        end
    elseif ((positive == true && (voltage (i) < mv+(5*sdv))) || (positive == false && (voltage (i) > mv-(5*sdv)))) && onstep == true
        onstep = false;
        if on_img == false
            steps (2, stepno) = num_imgs-1;
        else
            steps (2, stepno) = num_imgs;
        end
        stepno = stepno + 1;
    end
end

%now i want to populate the last element of the steps array, reserved
%for the 0 mV step

%divide into 2 arrays for ease
stepstarts = steps (1,:);
stepends = steps (2,:);
%the way diff works, the value of stepstartdiff that is larger than the
%mean will have the index of the last stepstart before the 0 mV gap.
% only one should be above the mean
stepstartdiff = diff (stepstarts(:,1:7)); %1:7 else the last 0 in index 8 throws a large -ve diff
stependdiff = diff (stepends(:,1:7));
for j = 1:size (stepstartdiff, 2)
    if stepstartdiff (j) > mean (stepstartdiff)
        avgstartgap = round(mean (stepstartdiff(1:3)),0); %there are at least 3 v steps before the 0 mv
        avgendgap = round (mean (stependdiff(1:3)),0);
        steps (1, numswps) = stepstarts (j) + avgstartgap; %populate last value in array
        steps (2, numswps) = stepends (j) + avgendgap;
    end
end




