% this small class finds the idex of when the camera trace ends.
% this index can be used to cut off voltage/current/puff traces (as well
% as the camera trace itself) at this point, as we have no need for data
% that was not imaged 

function  [camera_end] = get_camera_end (camera)

%finding when the camera ends
y = size (camera,1);
found = false;
camera_end = 1;
while y > 1 && found == false
    if camera(y) > 1
        camera_end = y + 1;
        found= true;
    end
    y=y-1;
end

if (camera_end > size(camera,1))
    disp ('the trace ends on a high img ttl');
    camera_end = camera_end - 1;
end

