%% Paths
addpath('matlab');
addpath('cmex');

%% Global variables (needed for callbacks)
global configFile;

%% Input
%file_path = './StanfordSimpleDogWalking/';
%file_path = './portland_state/';
file_path = './new_image/';
configFile = 'config/rp.mat';
image_files = dir([file_path, '*.jpg']);
object_name = 'leash';
nMaximumWindows = 400;
interval_number = nMaximumWindows / 10;
nMinimumWindows = 10;
if strcmp(file_path, './new_image/') == 1
    labl_files = dlmread(['./new_image/gt_', object_name, '.txt']);
elseif strcmp(file_path, './new_image/') == 0
    labl_files= dir([file_path, '*.labl']);
end
%% Processing:
%parser(configFile, object_name, file_path, labl_files, image_files);
%run_RP(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number);
%run_RP_2(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number);
%run_RP_3(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number, nMinimumWindows);
%run_RP_4(configFile, file_path, labl_files, image_files, nMaximumWindows, interval_number, nMinimumWindows);
%run_RP_5(configFile, object_name, file_path, labl_files, image_files, nMaximumWindows, interval_number, nMinimumWindows);



%{
configParams = LoadConfigFile(configFile);
bbb = struct('proposal',[]);
aaa = cell([1, 500]);
tic
for i = 1 : 5
    for j = 1 : 500
        aaa{j} = RP(imread([file_path, image_files(j).name]), configParams);
    end
    bbb(i).proposal = aaa;
end
toc
%}


%{
configParams = LoadConfigFile(configFile);
aaa = struct('proposal',[]);

parpool(8);

tic
for j = 1:5
   configParams.rSeedForRun = j;
parfor i = 1:10
    img = imread([file_path, image_files(i).name]);
    aaa(i).proposal = RP(img, configParams);
    %bbb = RP(img, configParams);
    
end
disp(aaa(1).proposal);
end
toc
%}


%{
tic
for j = 1:1000
for i = 1 :2
    %temp_struct(i).image = imread([file_path, image_files(i).name]);
    %imshow(temp_struct(i).image);
    imgs = imread([file_path, image_files(i).name]);
    %imshow(imgs);
end
end
toc
%}
%{
temp_struct = struct('image',[]);
tic
for i = 1:2
    temp_struct(i).image = imread([file_path, image_files(i).name]);
end
for j = 1000
    for k = 1:2
        temp_struct(k).image;
    end
end
toc
%}









% load three detection result.
load('result_portland_dog');
load('result_portland_dog_walker');
load('result_portland_leash');

number_window_array = round(linspace(nMinimumWindows, nMaximumWindows, interval_number));
detection_result = zeros(length(number_window_array),5);

for u = 1 : length(number_window_array)
    for j = 1 : 5
        for k = 1 :  length(image_files)
            
            if detection_portland_dog(u,j,k) == 1 && detection_portland_dog_walker(u,j,k) == 1 && detection_portland_leash(u,j,k) == 1
                detection_result(u,j) = detection_result(u,j) + 1;
            end
            
        end
    end
end

disp(detection_result);

% find median value in each raw in detected results
detection_rate_array = zeros(1, length(number_window_array));
for i = 1 : length(number_window_array)
    % find median value
    median_value = median( sort( detection_result(i, :) ) );
    % store median value into detection rate array
    detection_rate_array(1,i) = median_value; 
end

% plot the result on the figure
figure;
hold on;
plot(number_window_array, detection_rate_array, 'y', 'LineWidth', 3);
% draw variance result
for draw_index = 1 : length(number_window_array)
    line([number_window_array(draw_index), number_window_array(draw_index)], [min(detection_result(draw_index, :)), max(detection_result(draw_index, :))], ...
    'Color', 'y', 'LineWidth', 2);
end
%axis([0 1100 0 120]);
xlabel(['Number of Windows requested: maximum number is ', num2str(nMaximumWindows)]);
ylabel('Number of images that include three objects');
title({'Detected Numbers verses # of Windows, and IoU = 0.5', 'PortlandState Testing Data'});
hold off;














%{
configParams = LoadConfigFile(configFile);
random_seed_vector = randperm(5 * 3);
random_seed_array = reshape(random_seed_vector, 3, 5);
vector_s = random_seed_array(:,1);
for i = 1 : 3
    configParams(i).approxFinalNBoxes = configParams.approxFinalNBoxes;
    configParams(i).rSeedForRun =  vector_s(i);
    configParams(i).q = configParams.q;
    configParams(i).segmentations = configParams.segmentations;
end
img = imread([file_path, image_files(1).name]);
tic;
for j = 1 : 3
    proposals = RP(img, configParams(j));
end
toc;
%}
%{

configParams.approxFinalNBoxes = 10;
output_structure = struct('proposals',[]);

%parpool;

tic;
for i = 1:3
    configParams.rSeedForRun = i;
for index = 1 : 3
    output_structure(index).proposals = RP(img, configParams);
end
end
toc;
%}

%random_seed_vector = randperm(5 * 3);
%random_seed_array = reshape(random_seed_vector, 3, 5);


%{
configParams = LoadConfigFile(configFile);

img = imread([file_path, image_files(1).name]);
configParams.approxFinalNBoxes = 10;

% read label file
%full_path = [file_path, labl_files(1).name];
%


for repeat_index = 1 : 3
configParams.rSeedForRun = repeat_index;
proposals = RP(img, configParams);

% parse the lable file
%output = prasing(full_path, object_name);

disp(proposals);
disp('====');

imshow(img, 'Border', 'tight');

for i = 1: length(proposals(:,1))
hold on
%rectangle('Position', output(i,:),'EdgeColor', 'y', 'LineWidth', 2);
rectangle('Position', [proposals(i,1), proposals(i,2), proposals(i,3) - proposals(i,1), proposals(i,4) - proposals(i,2)], 'EdgeColor', 'y','LineWidth', 2);
%f = getframe(gca);
%im = frame2im(f);
hold off;
end

end
%}

