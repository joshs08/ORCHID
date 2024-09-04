% this funciton takes an input signal and num_images, plots them, 
% gets the user to select the points between light onset and light offset, and then
% replaces the trace between these points straight line. this improves curve fitting
% for detrending correction. fit the curve to this output and then subtract
% the curve from the original trace.

function [output] = zero_signal (data, num_images, light_ttls, isORCHID, faster)
good = false; 
n = 0; %counts number of zeroings for ORCHID 5 pulses
ti = 0; %user input to do more zeroings if 1
while good == false

    figf = figure ();
    x = 1:1:num_images;
    plot (x, data);
    hold on;
    if isORCHID == true
        xline (light_ttls (1, :), 'g');
        xline (light_ttls(2,:), 'r');
    end
    axis tight;
    figf.WindowState = 'maximized';

    disp ("We will now iteratively select points on the F trace exactly between the light on and light off points, with the aim of performing suitable detrending");
    disp ("We will do it once for each light pulse (5 times typically)");
    disp ('Select two points on lines denotating light on (green) and off (red), between which you want to draw a straight line');
    [x1, y1] = ginput (1);
    [x2, y2] = ginput (1);

    x1 = round (x1, 0); %changing the points selected into indices
    x2 = round (x2, 0);

    data (x1) = y1;
    data (x2) = y2;

    p1 = data (x1);
    p2 = data (x2);% the points between which we plot the lines

    p = polyfit ([x1, x2],[p1, p2],1); %fitting a first degree polynomial to the points (ie a straight line)
    n2 = x1:1:x2;
    l = polyval (p, n2); %evaluate polynomial p and points n2, and returns corresponding y points

    data (x1:x2) = l;

    f = figure();
    plot (x, data);
    n = n+1;
    if isORCHID == false
        ti = input ("View output. 1/0. 0 to zero more segments");
    elseif isORCHID == true && faster == true &&  n >= 5
        ti = input ("View output. 1/0. 0 to zero more segments");
    elseif isORCHID == true && faster == false
        ti = input ("View output. 1/0. 0 to zero more segments");
    end
    if (ti == 1)
        good = true;
    end
    close (figf);
    close(f);
end

output = data;
