mkdir('./portland_state_with_GT/');

% read a bunch of images
imgs_path = './portland_state/';
imgs_file = dir([imgs_path, '*.jpg']);
labl_files= dir([imgs_path, '*.labl']);

obj_name = 'dog-walker';
%{
imgs_path = './new_image/';
imgs_file = dir([imgs_path, '*.jpg']);
labl_files = dlmread(['./new_image/gt_', obj_name, '.txt']);
%}
ground_truth_array = zeros(length(imgs_file), 4);


for img_index = 1 : length(imgs_file)
    
    % read each image
    single_image = imread([imgs_path, imgs_file(img_index).name]);
    
    full_path = ['./portland_state/', labl_files(img_index).name];
    
    % get the bounding box for specific object
    outputs = prasings(full_path, obj_name);
    
    % convert the format of ground truth to the same format as proposals results
    ground_truth = [outputs(:,1), outputs(:,2), outputs(:,1) + outputs(:,3), outputs(:,2) + outputs(:,4)];
    
    
    % get image's size
    [height, width, n_channel] = size(single_image);
    %{
    % resizing the image size depending on original size
    if ( height >= 1600 || width >= 1600 )
        % original * 0.25
        new_img = imresize(single_image, 0.25);
        ground_truth = round(ground_truth * 0.25);
    elseif ( (height >= 1200 || width >= 1200) && (height < 1600 || width < 1600) )
        % original * 0.35
        new_img = imresize(single_image, 0.35);
        ground_truth = round(ground_truth * 0.35);
    elseif ( (height >= 550 || width >= 550) && (height < 1200 || width < 1200) )
        % original * 0.7
        new_img = imresize(single_image, 0.7);
        ground_truth = round(ground_truth * 0.7);
    elseif ( height < 550 || width < 550)
        % original * 0.9
        new_img = imresize(single_image, 0.9);
        ground_truth = round(ground_truth * 0.9);
    end
    %}
    
    % plot the ground truth on the image and save new images as jpg files
    %output =  [labl_files(img_index, 1), labl_files(img_index, 2), labl_files(img_index, 3) - labl_files(img_index, 1), labl_files(img_index, 4) - labl_files(img_index, 2)];   
    %output = labl_files(img_index, :);
    imshow(single_image, 'Border', 'tight');
    %hold on
    rectangle('Position',outputs, 'EdgeColor', 'y','LineWidth', 2);
    %rectangle('Position', [proposals(min_ind,1), proposals(min_ind,2), proposals(min_ind,3) - proposals(min_ind,1), proposals(min_ind,4) - proposals(min_ind,2)],'EdgeColor', 'g','LineWidth', 2);
    f = getframe(gca);
    im = frame2im(f);
    
    
    imwrite(im, ['./portland_state_with_GT/', imgs_file(img_index).name]);
    
    % save ground truth
    %ground_truth_array(img_index, :) = ground_truth;
    
end

% save ground truth as mat file
%dlmwrite(['./new_image/gt_', obj_name, '.txt'],ground_truth_array );







