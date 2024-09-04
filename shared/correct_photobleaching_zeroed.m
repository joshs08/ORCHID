% this class fits an exponential curve to fluoro data and subtracts the curve,
% this corrects for photobleaching/trends

function [corrected, uncorrected] = correct_photobleaching_zeroed (data, zeroed, savedir, timef)

N = size (zeroed, 2);
%N=size (zeroed,1);
n = (1:1:N);
g = false;
uncorrected = false;

while g == false
    fc = figure();
    plot (n, zeroed);
    axis tight;
    p1 = polyfit (n, zeroed, 9);
    p2 = polyfit(n,zeroed,10); %originally 10
    l1 = polyval (p1, n); %line 1
    l2 = polyval (p2, n); % line 2
    hold on;
    h1 = plot (n, l1,'r--'); %handle 1
    h2 = plot (n, l2, 'g--'); %handle 2
    
    disp ("We will now fit a 9th (red) or 10th (green) order polynomial to the trace to perform detrending.");
    d = input ("Which polynomial fits best: n = (1 (r) or 2 (g) or 0 (draw your own/none)?");
    %     if d ~= 0
    %         q = input ("Shift this polynomial up/down? ");
    %     end
    q = 0;
    
    if d == 1
        delete (h2);
        lf = l1; %line final
        if q == 1
            [~, sy] = ginput (1);
            delete (h1);
            a = lf (1);
            diff = a - sy;
            lf = lf - diff;
            plot (n, lf,'m--');
        end
    elseif d == 2
        delete (h1);
        lf = l2;
        if q == 1
            [~, sy] = ginput (1);
            delete (h2);
            a = lf (1);
            diff = a - sy;
            lf = lf - diff;
            plot (n, lf,'m--');
            axis tight;
        end
    elseif d == 0
        delete (h1);
        delete (h2);
        yline = input ("Add two points for y = mx + c? Otherwise none 1/0");
        if yline == 1
            g = 0;
            while g == 0
                [x, y] = ginput (2);
                p3 = polyfit (x,y,1);
                l3 = polyval (p3, n);
                h3 = plot (n, l3,'g--');
                g = input ("View data. 1 to continue or 0 to retry");
                if g == 0
                    delete (h3);
                end
            end
            lf = l3;
        else
            lf = 0;
            uncorrected = true;
        end
    else
        disp ("wrong number");
    end
    hold off;
    
    %lf = lf';
    datac = data - lf;
    ff = figure();
    try
        plot (timef, datac);
    catch
        disp ('Something unexpected with image numbers occurred');
        plot (n, datac);
    end
    
    axis tight;
    
    c = input ("View data. 1 to continue or 0 to retry");
    if c == 1
        g = true;
        saveas (fc, savedir + "_bleach.fig");
        close (fc, ff);
        corrected = datac;
    else
        g = false;
        close (fc, ff);
    end
end



