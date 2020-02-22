%function run_RP_4(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number, nMinimumWindows)
function run_RP_4(configFile, file_path, labl_files, image_files, nMaximumWindows, interval_number, nMinimumWindows)
% setting window number array
number_window_array = round(linspace(nMinimumWindows, nMaximumWindows, interval_number));

% setting object array and counter
object_array = {'dog-walker', 'dog', 'leash'};

% setting parameters
% draw variance result
repeat_number = 5;
configParams = LoadConfigFile(configFile);
%detected_result = zeros(length(number_window_array), repeat_number);
detected_result = zeros(repeat_number, length(number_window_array));
random_seed_array = randperm(repeat_number * length(object_array));

% setting detection array
%detection_array = zeros(1, length(number_window_array));

% parsing grouth truth from label data
ground_truth_array = struct('coordinates',[]);
for small_index = 1 : length(object_array)
    
    temp = zeros(length(image_files), 4);
     % deal with label file
     if strcmp(file_path , './new_image/') == 0
         
         for img_index = 1 : length(image_files)
             
             % read label file
             full_path = [file_path, labl_files(img_index).name];
             
             % parse the lable file
             output = prasing(full_path,  object_array{small_index});
             
             % convert the format of ground truth to the same format as proposals results
             temp(img_index, :) = [output(:,1), output(:,2), output(:,1) + output(:,3), output(:,2) + output(:,4)];
         
         end % check each label file 
                    
         ground_truth_array(small_index).coordinates = temp;
         
     elseif strcmp(file_path , './new_image/') == 1
         
         labl_files = dlmread(['./new_image/gt_', object_array{small_index}, '.txt']);
         %ground_truth = labl_files(file_index, :); 
         ground_truth_array(small_index).coordinates = labl_files;
         
     end
    
end % object loop


% go through each window number
for window_index = 1 : length(number_window_array)
    
    % setting new requested window number
    configParams.approxFinalNBoxes = number_window_array(window_index);
    temp_array = zeros(1, repeat_number);
    
    % go through each testing image
    for file_index = 1 : length(image_files)
        
        % read each image
        img = imread([file_path, image_files(file_index).name]);
        
        % repeat times
        random_seed_count = 1;
        for repeat_index = 1 : repeat_number
        
            % go through each interesting object
            object_counter = 0;
            for object_index = 1 : length(object_array)
                
                % run randomized prim's algorithm
                configParams.rSeedForRun = random_seed_array(random_seed_count);
                proposals = RP(img, configParams);
            
                % get a proper window
                ground_truth = ground_truth_array(object_index).coordinates(file_index, :);
                detected_window = find_window(proposals, ground_truth);
            
                % compute IOU
                ratio_result = compute_IOU_function(ground_truth(1,:), detected_window);
            
                if (ratio_result >= 0.5)
                    object_counter = object_counter + 1;
                end
            
                random_seed_count = random_seed_count + 1;
            end % object loop
        
            if object_counter == 3
                temp_array(1, repeat_index) = temp_array(1,repeat_index ) + 1;
            end
        
        end % repeat loop
        
    end % image loop
    
    detected_result(:, window_index) = temp_array;
    %detection_array(1, window_index) = detection_array(1, window_index) + 1;
    
end % window loop

%disp(detected_result);

save('cumulative_image_number', 'detected_result');

% find median value in each raw in detected results
detection_rate_array = zeros(1, length(number_window_array));
for i = 1 : length(number_window_array)
    % find median value
    median_value = median(detected_result(:, i));
    % store median value into detection rate array
    detection_rate_array(1,i) = median_value; 
end

% plot the result on the figure
figure;
hold on;
plot(number_window_array, detection_rate_array, 'y', 'LineWidth', 3);
% draw variance result
for draw_index = 1 : length(number_window_array)
    line([number_window_array(draw_index), number_window_array(draw_index)], [min(detected_result(draw_index, :)), max(detected_result(draw_index, :))], ...
    'Color', 'y');
end
%axis([0 1100 0 120]);
xlabel(['Number of Windows requested: maximum number is ', num2str(nMaximumWindows)]);
ylabel('Number of images that include three objects');
title('Detected Numbers verses # of Windows, and IoU = 0.5');
hold off;







% find a proper window from a bunch of windows
function proper_window = find_window(proposals, ground_truth)

% compute the difference between ground truth position and proposals position
rec_difference = zeros(1, length(proposals(:,1)));

for rectangle_index = 1 : length(proposals(:,1))
    rec_difference(1, rectangle_index) = abs(proposals(rectangle_index,1) - ground_truth(:,1)) ... 
    + abs(proposals(rectangle_index,2) - ground_truth(:,2)) + abs(proposals(rectangle_index,3) - ground_truth(:,3)) ...
    + abs(proposals(rectangle_index,4) - ground_truth(:,4));
end

% find the closest rectangle from proposals    
min_value = min(rec_difference);
min_ind = find(rec_difference == min_value);
        
if (length(min_ind) > 1)
    min_ind = datasample(min_ind, 1);
end

proper_window = proposals(min_ind,:);


% parsing function
function object_position = prasing(full_path, object_name)
    
% read one label file
%file_ID = fopen('dog-walking92.labl');
file_ID = fopen(full_path);
string_line = fgetl(file_ID);
fclose(file_ID);

num_part = textscan(string_line, '%f', 'Delimiter', '|');
number_length = length(num_part{1});

input_file = textscan(string_line, '%s', 'Delimiter', '|');
labl_file = input_file{1};

% convert cell array to ordinary number array
number_array = zeros(1, number_length - 3);
for number_index = 4 : number_length
    number_array(number_index - 3) = str2double(labl_file{number_index});
end

% convert cell array to ordinary string array
string_array = cell(1, (length(labl_file) - number_length));
count_index = 1;
for string_index = (number_length + 1) : length(labl_file)
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


 
