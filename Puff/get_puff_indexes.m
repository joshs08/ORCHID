%% this short class takes a puff trace and gets the index of puff start and puff end
% we separate the puff at the value of 0.1 

function  [puffs, puffe] = get_puff_indexes (puff)

dps = size (puff, 1);
puff_started = false;
puff_found = false;
i = 1;

while ((i <= dps) && (puff_found == false))
   if puff_started == false && puff (i) > 0.1
       puff_started = true;
       puffs = i;
   elseif puff_started == true && puff (i) < 0.1
       puffe = i - 1; % the puff was still happening at the previous datapoint
       puff_found = true;
   end
   i = i + 1;
end
