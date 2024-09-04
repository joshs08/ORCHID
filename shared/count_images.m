%% this small class will count the number of images in a camera ttl trace
% it will also get the image on which a puff starts and ends
% input a camera trace cut off just after the last image for max efficiency

function  [num_images, imgs, imge] = count_images (camera, puffs, puffe)

dps = size (camera, 1);

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
for i = 1:dps
    if on_img == true && camera (i) < 1        
        on_img = false;
    elseif on_img == false && camera (i) > 1 
        num_imgs = num_imgs + 1;
        on_img = true;
    end
    
    %check if the image is the puff s/e image. 
    %if the puff starts between
    %images, we take the next image as img of puff start, as it is the
    %first image with the puff effect. 
    if i == puffs && on_img == true
        imgs = num_imgs;
    elseif i == puffs && on_img == false
        imgs = num_imgs + 1;
    elseif i == puffe 
       imge = num_imgs; 
    end
end

%incase the entire puff happened in the same low camera TTL! 
% if imge < imgs
%     imge = imgs;
%     lol = input ('entire puff in same img low ttl! weow!pressanykey');
% end
        
num_images = num_imgs;
        
        
        
        