function run_RP_5(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number, nMinimumWindows)
% setting window number array
number_window_array = round(linspace(nMinimumWindows, nMaximumWindows, interval_number));

% setting parameters
configParams = LoadConfigFile(configFile);
%detected_result = zeros(length(number_window_array), 5);
detection_portland_leash = zeros(length(number_window_array), 5, length(image_files));


% initialize image structure
image_struct_array = struct('image', []);
% read images into image structure array
for imgs_index = 1 : length(image_files)
    % read each image
    image_struct_array(imgs_index).image = imread([file_path, image_files(imgs_index).name]);
end

% deal with label file
ground_truth_array = zeros(length(image_files), 4);
if strcmp(file_path , './new_image/') == 0
         
    for img_index = 1 : length(image_files)
             
        % read label file
        full_path = [file_path, labl_files(img_index).name];
             
        % parse the lable file
        output = prasing(full_path, object_name);
             
        % convert the format of ground truth to the same format as proposals results
        ground_truth_array(img_index, :) = [output(:,1), output(:,2), output(:,1) + output(:,3), output(:,2) + output(:,4)];
         
    end % check each label file 
                    
    %ground_truth_array(small_index).coordinates = temp;
         
elseif strcmp(file_path , './new_image/') == 1
         
    ground_truth_array = dlmread(['./new_image/gt_', object_name, '.txt']);
    %ground_truth = labl_files(file_index, :); 
    %ground_truth_array(small_index).coordinates = labl_files;
end


% create proposals structure
proposal_structure_array = struct('proposal',[]);
% create cell array to store a bunch of proposals
proposal_cell = cell([1, length(image_files)]);

% for each requested window number
for window_index = 1 : length(number_window_array)
    
    % setting new requested window number
    configParams.approxFinalNBoxes = number_window_array(window_index);
    
    % setting parallel pool
    parpool(12);

    % repeat loop, repeat RP method five times
    for repeat_index = 1 : 5
        
        % setting random seed
        configParams.rSeedForRun = repeat_index;
        
        % compute detected numbere, go through each testing image by
        % parallel computing
        parfor file_index = 1 : length(image_files)
            % run randomized prim's algorithm
            proposal_cell{file_index} = RP(image_struct_array(file_index).image, configParams);
        end % go through each testing image
        
        proposal_structure_array(repeat_index).proposal = proposal_cell;
        
    end % end repeat loop
    
    % find proper window and record detection result
    for repeating_index = 1 : 5
        % image loop
        for imgs_index = 1 : length(image_files)
            
            % get a proper window and compute IoU value
            ratio_result = find_window_compute_IOU(proposal_structure_array(repeating_index).proposal{1, imgs_index}, ground_truth_array(imgs_index, :));
             
            % compute IOU
            %ratio_result = compute_IOU_function(ground_truth_array(imgs_index, :), detected_window);
            
            if (ratio_result >= 0.5)
                %temp_array(1, repeat_index) = temp_array(1, repeat_index) + 1;
                detection_portland_leash(window_index, repeating_index, imgs_index) = 1;
            end
             
        end % end image loop
        
    end % end repeating loop
    
    % shut down parallel pool
    p = gcp;
    delete(p);
    
end % window loop

% save detection information
save('result_portland_leash','detection_portland_leash');

%delete variables
clear proposal_structure_array;
clear proposal_cell;
clear image_struct_array;
clear ground_truth_array;


% find a proper window from a bunch of windows
function IOU_ratio = find_window_compute_IOU(proposals, ground_truth)

% compute the difference between ground truth position and proposals position
rec_difference = zeros(1, length(proposals(:,1)));

for rectangle_index = 1 : length(proposals(:,1))
    %rec_difference(1, rectangle_index) = norm(proposals(rectangle_index,:) - ground_truth);
    rec_difference(1, rectangle_index) = abs(proposals(rectangle_index,1) - ground_truth(:,1)) ... 
    + abs(proposals(rectangle_index,2) - ground_truth(:,2)) + abs(proposals(rectangle_index,3) - ground_truth(:,3)) ...
    + abs(proposals(rectangle_index,4) - ground_truth(:,4));
end

% find the closest rectangle from proposals    
%min_value = min(rec_difference);
min_ind = find(rec_difference == min(rec_difference));
        
if (length(min_ind) > 1)
    min_ind = datasample(min_ind, 1);
end

clear rec_difference;

proper_window = proposals(min_ind,:);

% compute IoU value
%format is [xmin ymin xmax ymax] for two inputs
c_xmin = max(ground_truth(1),proper_window(1));
c_xmax = min(ground_truth(3),proper_window(3));
c_ymin = max(ground_truth(2),proper_window(2));
c_ymax = min(ground_truth(4),proper_window(4));

% compute intersection area
if ((c_xmin > c_xmax) || (c_ymin > c_ymax))
    %areaBB = 0;
    IOU_ratio= 0;
else
    %areaBB = (c_xmax - c_xmin + 1) * (c_ymax - c_ymin + 1);
    IOU_ratio = ( (c_xmax - c_xmin + 1) * (c_ymax - c_ymin + 1) ) / ( (ground_truth(3) - ground_truth(1) + 1) * ( ground_truth(4) - ground_truth(2) + 1) );
end


% parsing function
function object_position = prasing(full_path, object_name)
    
% read one label file
%file_ID = fopen('dog-walking92.labl');
file_ID = fopen(full_path);
string_line = fgetl(file_ID);
fclose(file_ID);

num_part = textscan(string_line, '%f', 'Delimiter', '|');
%number_length = length(num_part{1});

input_file = textscan(string_line, '%s', 'Delimiter', '|');
labl_file = input_file{1};

% convert cell array to ordinary number array
number_array = zeros(1, length(num_part{1}) - 3);
for number_index = 4 : length(num_part{1})
    number_array(number_index - 3) = str2double(labl_file{number_index});
end

% convert cell array to ordinary string array
string_array = cell(1, (length(labl_file) - length(num_part{1})));
count_index = 1;
for string_index = (length(num_part{1}) + 1) : length(labl_file)
    string_array{count_index} = labl_file{string_index};
    count_index = count_index + 1;
end

% record object's position
%data_index = 1;
for search_index = 1 : length(string_array)
    
    % get a line from string array
    temp_cell = textscan(string_array{search_index}, '%s', 'Delimiter', ' ');
    
    % convert cell string to string
    temp_cell_string = temp_cell{1}(1);
    temp_string = temp_cell_string{1};
    
    % if the object is leash
    if (strcmp(object_name,'leash'))
        temp_string = temp_string(1:length(temp_string) - 2);
    end
    % compare object name with the label name in label file
    if (strcmp(temp_string, object_name))
        % record dog-walker index
        dog_walker_index = search_index;
        
        % get start index and end index for a specific sentence
        start_index = (4 * (dog_walker_index - 1) ) + 1;
        end_index = 4 * (dog_walker_index);
        
        % record the position information
        %object_position(data_index,:) = number_array(start_index:end_index);
        object_position = number_array(start_index:end_index);
        %data_index = data_index + 1;
    end
    
end











%{
        % deal with label file
        if strcmp(file_path , './new_image/') == 0
        
            % read label file
            full_path = [file_path, labl_files(file_index).name];
        
            % parse the lable file
            output = prasing(full_path, object_name);
        
            % convert the format of ground truth to the same format as proposals results
            ground_truth = [output(:,1), output(:,2), output(:,1) + output(:,3), output(:,2) + output(:,4)];
        
        elseif strcmp(file_path , './new_image/') == 1
        
            ground_truth = labl_files(file_index, :); 
        
        end
        %}



%{
% compute detection rate
detected_result = detected_result / length(image_files);
disp(detected_result);

% find median value in each raw in detected results
detection_rate_array = zeros(1, length(number_window_array));
for i = 1 : length(number_window_array)
    % find median value
    median_value = median(detected_result(i,:));
    % store median value into detection rate array
    detection_rate_array(1,i) = median_value; 
end



% plot the figure
figure;
hold on;
plot(number_window_array, detection_rate_array);
% draw variance result
for draw_index = 1 : length(number_window_array)
    line([number_window_array(draw_index), number_window_array(draw_index)], [min(detected_result(draw_index, :)), max(detected_result(draw_index, :))]);
end
xlabel('Number of Windows requested: maximum number is 200');
ylabel('Detection Rate');
title({'Detection Rate verses # of Windows, and IoU = 0.5', ['Searching Object: ', object_name]});
hold off;
%}

















%{
function IOU_ratio = compute_IOU_function(ground_truth, detected_rec)
%compute intersection anrea of ground_truth and detected_rec
%ground_truth and detected_rec - bounding boxes
%format is [xmin ymin xmax ymax] for two inputs 

c_xmin = max(ground_truth(1),detected_rec(1));
c_xmax = min(ground_truth(3),detected_rec(3));
c_ymin = max(ground_truth(2),detected_rec(2));
c_ymax = min(ground_truth(4),detected_rec(4));

% compute intersection area
if ((c_xmin > c_xmax) || (c_ymin > c_ymax))
    areaBB = 0;
else
    areaBB = (c_xmax - c_xmin + 1) * (c_ymax - c_ymin + 1);
end

IOU_ratio = areaBB / ( (ground_truth(3) - ground_truth(1) + 1) * ( ground_truth(4) - ground_truth(2) + 1) );
%}



%{
% get ground truth from label files
immediate_matrix = zeros(length(labl_files), 4);
if strcmp(file_path , './new_image/') == 0
    
    for label_index = 1 : length(labl_files)
        % read label file
        full_path = [file_path, labl_files(label_index).name];
        
        % get correct index
        correct_index = str2double(regexp(labl_files(label_index).name, '\d*', 'Match'));
        
        % parse the lable file
        output = prasing(full_path, object_name);
        % convert the format of ground truth to the same format as proposals results
        immediate_matrix(correct_index, :) = [output(:,1), output(:,2), output(:,1) + output(:,3), output(:,2) + output(:,4)];
        
    end         
    
elseif strcmp(file_path , './new_image/') == 1
    
    immediate_matrix = labl_files; 

end
%}

