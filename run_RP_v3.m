function run_RP_v3(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number)

% read configuration file
configParams = LoadConfigFile(configFile);

% setting window number array
number_window_array = round(linspace(1, nMaximumWindows, interval_number));

% setting detected result
%detected_result = struct('nWindow', [],'detected_array', []);
detected_result = zeros(length(number_window_array), 5);


% repeat the method a couple of times to get different detection rate
for repeat_index = 1 : 5

    % test each window number
    for window_array_index = 1: length(number_window_array)

        % test each testing image and compute detected number over the testing image 
        % to each window number
        %count_number = 0;
        %temp_array = zeros(1, 5);
        for file_index = 1 : length(image_files)

            % read each image
            img = imread([file_path, image_files(file_index).name]);

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

            % compute detected number: two cases
            % get proposals(a bunch of windows): the format is [xmin, ymin, xmax, ymax]
            proposals = RP(img, configParams);

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

 
            % get a proper window
            detected_window = find_window(proposals, ground_truth);

            % compute IOU
            ratio_result = compute_IOU_function(ground_truth(1,:), detected_window);

            if (ratio_result >= 0.5)
                detected_result(window_array_index, repeat_index) = detected_result(window_array_index, repeat_index) + 1;
            end



        end % read each testing image

    end % reach window number array

end % repeat number

% compute detection rate
detected_result = detected_result / length(image_files);


disp(detected_result);


  
    
    
    
        

        

        
            
            

            


%{
% plot the figure
figure;
hold on;
plot(number_window_array, detected_result(:,1));
% draw variance result
for draw_index = 1 : length(number_window_array)
    line([number_window_array(draw_index), number_window_array(draw_index)], [min(detected_result(draw_index, :)), max(detected_result(draw_index, :))]);
end
xlabel('Number of Windows: maximum number is 800');
ylabel('Detection Rate');
title({'Detection Rate verses # of Windows, and IoU = 0.5', ['Searching Object: ', object_name]});
hold off;
%}

















% find a proper window from a bunch of wndows
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

