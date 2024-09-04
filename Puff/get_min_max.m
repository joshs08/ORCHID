%% this class will give you the option to select the min or max of a
%(usually puffing wcp) trace, or both, in which case it will plot
%each sequentially and ask if you want min or max

function [psp] = get_min_max (output, time, numswps, bs)

correct = false;
psp = zeros (numswps, 1);
last = size(output, 1);

timeint = time(end)/size(time,2);
while correct == false
    hlb = input('Do you want to take the max (h), min (l), both (b) or neither (x)? If trace is not flat say (b)', 's');
    if strcmp (hlb, 'h')
        psp = max (output(bs:last, :));
        correct = true;
    elseif strcmp (hlb, 'l')
        psp = min (output (bs:last, :));
        correct = true;
    elseif strcmp (hlb, 'x')
        psp = 0;
        correct = true; 
    elseif strcmp (hlb, 'b')
        correct = true;
        for g = 1:numswps
            figt = figure;
            plot (time, output (:,g));
            axis tight;
                 
            disp ('Enter an end for the min/max window (over 250 ms)');
            [xm,~] = ginput (1);
            m_ind_e = round (xm/timeint);
            m_ind_s = round ((xm - 250)/timeint);
            figure (figt);
            xline (time(m_ind_s), '--r');
            xline (time(m_ind_e), '--r');
            hlb = input('Do you want to take the max (h), the min (l), neither (x)?', 's');
            if strcmp (hlb, 'h')
                psp (g) = max (output (m_ind_s:m_ind_e,g));
                close (figt);
            elseif strcmp (hlb, 'l')
                psp (g) = min (output (m_ind_s:m_ind_e,g));
                close (figt);
            elseif strcmp (hlb, 'x')
                psp (g) = 0;
                close (figt);
            end
        end
    else
        correct = false;
        disp ('try again please');
    end
end