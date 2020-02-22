function run_RP(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number)

% read configuration file
configParams = LoadConfigFile(configFile);

% setting variables
%ratio_range = [0.5, 0.6, 0.7, 0.8, 0.9];
%detected_number = zeros(1,length(ratio_range));
%total_number = 0;

% setting variables
total_number = nMaximumWindows / interval_number;

%number_window_array = unique(round(logspace(0, log10(nMaximumWindows), 100)));
number_window_array = zeros(1, total_number);
array_index = 1;
for i = 100 : 100 : nMaximumWindows
    number_window_array(1, array_index) = i;
    array_index = array_index + 1;
end

detected_number = zeros(1, length(number_window_array));

% read multiple lable files and testing images
for file_index = 1 : length(image_files)
    
    % read each image
    img = imread([file_path, image_files(file_index).name]);
    
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
    
    % compute detected number in different window numbers
    for window_array_index = 1: length(number_window_array)
        
        % Compute proposals: the format is [xmin, ymin, xmax, ymax]
        proposals = RP(img, configParams);
        
        % deal with two different situations
        if (number_window_array(window_array_index) > length(proposals(:,1)))
            
            % repeat RP algorithm to increase proposal numbers until proposal number is greater than window numbers
            while (1)
                % run RP algorithm and generate new proposals
                new_proposals = RP(img, configParams);
                
                % integrate original proposal and new proposal
                proposals = [proposals; new_proposals];
                
                if ( length(proposals(:,1)) >= number_window_array(window_array_index) )
                    break;
                end
            end
            
            % get certain numbers for windows from proposals
            proposals = proposals(1:number_window_array(window_array_index), :);
            
        elseif (number_window_array(window_array_index) < length(proposals(:,1)))
            
            % sample the certain number of windows.
            ranId = randperm(length(proposals(:,1)), number_window_array(window_array_index));
            
            % get the certain number of windows
            proposals = proposals(ranId(1:number_window_array(window_array_index)), :);
            
        end
        
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
        
        detected_rec = proposals(min_ind,:);
        
        disp(detected_rec);
        
        % compute IOU
        ratio_result = compute_IOU_function(ground_truth(1,:), detected_rec);
        
        
        if (ratio_result >= 0.5)
            detected_number(1,window_array_index ) = detected_number(1, window_array_index) + 1;
        end
        
        %{
        %figure;
        imshow(img, 'Border', 'tight');
        %hold on
        rectangle('Position',output, 'EdgeColor', 'r','LineWidth', 2);
        rectangle('Position', [proposals(min_ind,1), proposals(min_ind,2), proposals(min_ind,3) - proposals(min_ind,1), proposals(min_ind,4) - proposals(min_ind,2)],'EdgeColor', 'g','LineWidth', 2);
        
        %hold off
        f = getframe(gca);
        im = frame2im(f);
        %}
    end
    
    %imwrite(im,['./temp/', num2str(file_index),'.jpg']);
end

disp(detected_number);


% compute detection rate
detection_rate = detected_number / length(image_files);


% plot the figure
figure;
hold on;
plot(number_window_array, detection_rate);
%axis([-2 3002 -0.1 1.01]);
xlabel('Number of Windows');
ylabel('Detection Rate');
title('Detection Rate verses # of Windows, and IoU = 0.5');
hold off;





%{
% read multiple label file and testing images
for file_index = 1 : length(labl_files)
    
    % read label file
    full_path = [file_path, labl_files(file_index).name];
    % read each image
    img = imread([file_path, image_files(file_index).name]);
    
    % parse the lable file
    output = prasing(full_path, object_name);
    % calculate total numbers of the specific object
    total_number = total_number + length(output(:,1));
    
    % convert the format of ground truth to the same format as proposals results
    ground_truth = [output(:,1), output(:,2), output(:,1) + output(:,3), output(:,2) + output(:,4)];
    
    % Compute proposals: the format is [xmin, ymin, xmax, ymax]
    proposals = RP(img, configParams);
    
    disp(length  (proposals(:,1)  ) );
    
    detected_rec = zeros(length(ground_truth(:,1)), 4);
    for gt_index = 1: length(ground_truth(:,1))
        
        % compute the difference between ground truth position and proposals position
        rec_difference = zeros(1, length(proposals(:,1)));
        for rectangle_index = 1 : length(proposals(:,1))
            rec_difference(1, rectangle_index) = abs(proposals(rectangle_index,1) - ground_truth(gt_index,1)) ... 
            + abs(proposals(rectangle_index,2) - ground_truth(gt_index,2)) + abs(proposals(rectangle_index,3) - ground_truth(gt_index,3)) ...
            + abs(proposals(rectangle_index,4) - ground_truth(gt_index,4));
        end
        
        % find the closest rectangle from proposals    
        min_value = min(rec_difference);
        min_ind = find(rec_difference == min_value);
        
        if (length(min_ind) > 1)
            min_ind = datasample(min_ind, 1);
        end
        
        detected_rec(gt_index,:) = proposals(min_ind,:);
        
        % compute IOU
        ratio_result(file_index, gt_index) = compute_IOU_function(ground_truth(gt_index,:), detected_rec(gt_index,:));
        
    end
    
    %if (ratio_value >= 0.9)
    %    detected_number = detected_number + 1;
    %end
    
    %{
    figure;
    imshow(img, 'Border', 'tight');
    hold on
    rectangle('Position',output);
    rectangle('Position', [proposals(min_ind,1), proposals(min_ind,2), proposals(min_ind,3) - proposals(min_ind,1), proposals(min_ind,4) - proposals(min_ind,2)]);
    %}
    
end

% compute detected number
for ratio_index = 1 : length(ratio_range)
    for temp_index = 1 : length(ratio_result(:,1))
        for sub_index = 1: length(ratio_result(temp_index,:))
            if (ratio_result(temp_index, sub_index) >= ratio_range(ratio_index))
                detected_number(1, ratio_index) = detected_number(1, ratio_index) + 1;
            end
        end
    end
end

% display detected numbers, total numbers, and detection rate
%disp(ratio_result);
disp(detected_number);
disp(total_number);
disp(detected_number / total_number);

% plot the figure
figure;
hold on;
plot(ratio_range, detected_number / total_number);
axis([0.45 0.95 0.2 1.01]);
xlabel('IOU Value');
ylabel('Detection Rate');
title('Detection Rate verses IOU value');
hold off;
%}


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

% record dog-walker position
data_index = 1;
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
        object_position(data_index,:) = number_array(start_index:end_index);
        
        data_index = data_index + 1;
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
