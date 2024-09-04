%% this class takes a 0 Mg ORCHID recording and gets all the images that light pulses appear on

function [light_images] = getLightPulsesORCHID0Mg (puff, camera, npulses)

numdps = size (puff, 1);
light_images = zeros (npulses, 2);

on_stim = false;
light_num = 1;

for i = 1:numdps

    if puff(i) > 1 && on_stim == false
        on_stim = true;
        lights = i;
    end
    if puff (i) < 1 && on_stim == true
        on_stim = false;
        lighte = i;
        [num_images, imgs, imge] = count_images (camera, lights, lighte);
        light_images (light_num, :) = [imgs imge];
        light_num = light_num+1;
    end
end