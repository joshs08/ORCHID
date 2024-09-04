%this small class combines all voltage and camera/i sweeps into one sweep
%(two traces, can be any traces);

function  [newtrace1, newtrace2] = combine_sweeps (t1, t2, numswps)

t1 = downsample (t1, 100);
t2 = downsample (t2, 100);

n = size (t1, 1);

fulln = n * numswps;

newtrace1 = zeros (fulln,1);
newtrace2 = zeros (fulln,1);

%%adding all sweeps onto one 'trace'
for recno=1:numswps
    startdp = (recno-1)*n;
    enddp = recno*n;
    newtrace1(startdp+1:enddp) =t1(:,recno);
    newtrace2(startdp+1:enddp) =t2(:,recno);
end

% ft1 = figure();
% plot (newtrace1);
% axis tight;
% ft2 = figure ();
% plot (newtrace2);
% axis tight;
% 
% t = input ("Save the figures as you desire, squire");
% try
%     close (ft1, ft2);
% catch
%     disp ("close yourself")
% end
