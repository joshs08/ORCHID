
%% this function takes a recording folder rec_folder, and reads in any .ome.tif files
% it then asks the user to select ROI and background, performs a background subtraction
% and returns the fluorescence change for each image. It requires input of boolean
% new_cell, which if true will get the user to draw a new ROI. it returns
% the exposure time from the info file as well as the number of images

function  [C, F, B, num_images, exp] = get_fluoro_changes (path_data, path_results, cell_num, imaging_folder, new_cell, isCharacterisation, lightError, light_imgs, isORCHID, haslfp) %

% C = corrected; F = fluorescence; B = background
% get the path to the actual .ome.tif
%rec_file = fullfile (path_folder, 'data', date, cell_num, imaging_folder, 'MMStack_Default.ome.tif');
%rec_deets = fullfile (path_folder, 'data', date, cell_num, imaging_folder, 'MMStack_Default_metadata.txt'); %the path to the micromanager metadata file
bgc = 0;
%if isCharacterisation == true
%bgc = input ("Do you want to use the ImageJ background corrected stack? 0/1");
%end
if bgc == 0
    stackname = 'MMStack_Default.ome.tif';
elseif bgc == 1
    stackname = 'MMStack_Default_BGR.tif';
end

rec_file = fullfile (path_data, imaging_folder, stackname);
%the path to the micromanager metadata file
rec_deets = fullfile (path_data, imaging_folder, 'MMStack_Default_metadata.txt');

%path for saving ROIs
roi_name = cell_num + "_roi.mat";
%path_roi = fullfile (path_folder, 'results', date, cell_num, 'ROIs');
path_roi = fullfile (path_results, 'ROIs');
%comment out as it will create a ROIs folder
dir_exists (path_roi);
path_roi = fullfile (path_roi, roi_name);

num_images = size(imfinfo(rec_file),1);

%for plotting
x = (1:1:num_images);

%% get the exposure time
% get the lines of interest (51-63)
fdetails = fopen(rec_deets,'r');
numLines = 63;
details = cell(numLines,1);
for d = 1:numLines
    details(d) = {fgetl(fdetails)};
end
fclose(fdetails);

% exposure is stored in cell 57
exposure = char(details(57));
indxs = strfind (exposure, ':');
indxe = strfind (exposure, ',');
exposure = str2double(convertCharsToStrings(exposure (indxs+2:indxe-1)));
exp = exposure;


%% read in images and create image stacks
%read in the first image to populate the image array with zero
testimage = imread(rec_file,1);
height = size(testimage,1);
width = size(testimage,2);
clear testimage;

%create a zero-filled image stack
img_stack = zeros(height,width,num_images);

%Loop through the images and build the image stack
disp ('reading in images');
for i = 1:num_images
    img_stack(:,:,i) = imread(rec_file,i);
end
disp ('images successfully read in');
if lightError == true
    if  input ('Cut off trace after x images? ie light error 0/1') == 1
        cut = input ('after how many images?');
        img_stack = img_stack (:,:,1:cut);
        num_images = cut;
        x = (1:1:num_images);
    end
end

%% test. to scroll through image stack. never use this, more commented out below if you wanna reinstate
if (haslfp == true)
fscroll = figure();
imtool3D(img_stack, [0 0 1 1], fscroll);
end
%% create mean images and select the ROIs
mean_img = mean(img_stack,3);%mean image
mean_img = mat2gray(mean_img);


%% draw background and neuronal polygons for the images (using the mean images)
fm = figure();
imshow (mean_img);

% if it is a new cell, ask the user to draw new ROIs. If it is
% not a new cell, display the ROI from the cell's previous
% recording and ask if it is suitable

if new_cell == false

    %load the ROI variable from roi.mat
    figure (fm)
    hold on
    load (path_roi, 'n_x', 'n_y', 'bg_x', 'bg_y');

    title ('Do these ROIs look suitable? 0/1 (zero is no)');

    psN = polyshape(n_x,n_y);
    pgN = plot(psN);
    psBG = polyshape (bg_x,bg_y);
    pgBG = plot (psBG);
    hold off

    % temp fluoro display, for repeating getting better ROIS
    fluoro_temp = zeros (1,num_images);
    % cycle through the stack
    for t = 1:num_images
        img = img_stack (:,:,t);
        fluoro_temp (t) = mean (img(poly2mask(n_x, n_y, height, width)));
        fluoro_temp_bg (t) = mean (img(poly2mask(bg_x, bg_y, height, width)));
    end
    ft = figure();
    plot (x, fluoro_temp);
    if isORCHID == true %adds lines for when the light goes on and off
        hold on
        xline (light_imgs (1,:), 'g');
        xline (light_imgs (2,:), 'r');
        hold off
    end
    axis tight
    ftbp = figure();
    plot (x, fluoro_temp_bg);
    if isORCHID == true %adds lines for when the light goes on and off
        hold on
        xline (light_imgs (1,:), 'g');
        xline (light_imgs (2,:), 'r');
        hold off
    end
    axis tight
    % end of fluoro_temp

    answ = input ('Do these ROIs and fluoro trace look suitable? 0/1 (zero is no)');

    if answ == 1
        disp ('Using the previous ROIs');
        try
            close ([ft ftbp]);
        catch
            disp ("Could not close fluoro trace figure.");
        end

    elseif answ == 0
        while answ == 0

            figure(fm);

            title('Draw better N ROI)');
            disp('Draw a better neuron ROI polygon');
            N_poly = drawpolygon('LineWidth', 0.1); %get coords of a specific ROI

            % split into the x and y coordinates of each polygon
            n_xy = N_poly.Position;
            n_x = n_xy(:, 1);
            n_y = n_xy(:, 2);

            % temp fluoro display, for repeating getting better ROIS
            fluoro_temp = zeros (1,num_images);
            % cycle through the stack
            for t = 1:num_images
                img = img_stack (:,:,t);
                fluoro_temp (t) = mean (img(poly2mask(n_x, n_y, height, width)));
            end

            try
                close (ft);
            catch
                disp ("Could not close fluoro trace figure.");
            end

            ft = figure();
            plot (x, fluoro_temp);
            axis tight
            % end of fluoro_temp

            g = input ("Does it look alright? 1/0");
            close (ft);
            if g == 1
                answ = 1;
            end
        end
        answbg = 0;
        while answbg == 0
            figure (fm);
            title('Draw better BG ROI)');
            disp('Draw a better background polygon');
            bg_poly = drawpolygon('LineWidth', 0.1);

            bg_xy = bg_poly.Position;
            bg_x = bg_xy(:, 1);
            bg_y = bg_xy(:, 2);

            % temp fluoro display, for repeating getting better ROIS
            fluoro_temp_bg = zeros (1,num_images);
            % cycle through the stack
            for t = 1:num_images
                img = img_stack (:,:,t);
                fluoro_temp_bg (t) = mean (img(poly2mask(bg_x, bg_y, height, width)));
            end

            try
                close (ft);
            catch
                disp ("Could not close fluoro trace figure.");
            end

            ft = figure();
            plot (x, fluoro_temp_bg);
            axis tight
            % end of fluoro_temp

            g = input ("Does it look alright? 1/0");
            close (ft);
            if g == 1
                answbg = 1;
            end
        end

        save (path_roi, 'n_x', 'n_y', 'bg_x', 'bg_y');

    end
end


% either if new_cell was input as true or if the ROIs of the previous cell
% could not be found
if new_cell == true
    good = false;
    while good == false
        figure (fm);
        title('Mean image (draw N then BG ROI)');
        disp('Draw your neuron ROI polygon');
        N_poly = drawpolygon('LineWidth', 0.1); %get coords of a specific ROI

        % get the x and y coordinates of the neuronal polygon
        n_xy = N_poly.Position;
        n_x = n_xy(:, 1);
        n_y = n_xy(:, 2);

        %temp fluoro display, for repeating getting better ROIS
        fluoro_temp = zeros (1,num_images);
        % cycle through the stack
        for t = 1:num_images
            img = img_stack (:,:,t);
            fluoro_temp (t) = mean (img(poly2mask(n_x, n_y, height, width)));
        end
        ft = figure();
        plot (x, fluoro_temp);
        axis tight
        figure (ft);
        g = input ("Does it look alright? 1/0");
        try
            close (ft);
        catch
            disp ("Not able to close a figure. Don't stress.");
        end
        if g == 1
            good = true;
        end
    end %end of while good == false

    %now draw BG polygon
    goodbg = false;
    %we want to redraw backgrounds until there is no neuropil contamination
    %if necessary
    while goodbg == false
        figure (fm);
        disp('Draw your background polygon');
        bg_poly = drawpolygon('LineWidth', 0.1);

        % get the x and y coordinates of the bg polygon
        bg_xy = bg_poly.Position;
        bg_x = bg_xy(:, 1);
        bg_y = bg_xy(:, 2);


        fluorobg_temp = zeros (1,num_images);
        % cycle through the stack
        for t = 1:num_images
            img = img_stack (:,:,t);
            fluorobg_temp (t) = mean (img(poly2mask(bg_x, bg_y, height, width)));
        end
        ft = figure();
        plot (x, fluorobg_temp);
        axis tight
        figure (ft);
        gbg = input ("Does it look alright? 1/0");
        close (ft)
        if gbg == 1
            goodbg = true;
        end
    end

    %save the x and y coords in roi.mat
    save (path_roi, 'n_x', 'n_y', 'bg_x', 'bg_y');
end

try
    if haslfp == true
        close (fm, fscroll);
    end
    close (fm);
catch
    disp ("Could not close stack figure or fscroll.");
end


%% calculate the fluorescence in each image in the stack
fluorescence = zeros (1,num_images);
corrected = zeros (1,num_images);
background = zeros (1,num_images);
% cycle through the stack
for m = 1:num_images
    img = img_stack (:,:,m);

    % create a binary image (1s within polgon, 0s without)
    binary_N = poly2mask(n_x, n_y, height, width);

    % calculate the sum of pixel values, the number of pixels,
    % and the mean pixel value

    %the number of pixels within Neuron roi
    pixels = sum(binary_N(:));
    %the sum of the pixel values of the particular image, where the binary image is 1
    intDen = sum (img(binary_N));
    %calculating the mean pixel value in one step. The above
    %three lines can be used to get the mean_img too, and are
    %only done as a sanity check
    mean_sanity = intDen/pixels;
    mean_fluoro = mean (img(poly2mask(n_x, n_y, height, width)));
    mean_bg = mean (img(poly2mask(bg_x,bg_y,height, width)));

    %the area of each ROI, used to calculate

    % sanity check that mean is calculating correctly
    if (mean_fluoro ~= (mean_sanity))
        error ('mean and intDen/noOfPixels are not equal');
    end

    % calculate the corrected total cell fluorescence
    % CTCF = Integrated Density – (Area of selected cell X
    % Mean fluorescence of background readings)
    background (m) = mean_bg;
    fluorescence (m) = mean_fluoro;
    corrected (m) = (intDen - (mean_bg*pixels))/pixels;
end
C = corrected;
F = fluorescence;
B = background;
