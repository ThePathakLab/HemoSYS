function fn_cluster_analysis(param_list)
%% param_list
% 1. matlab_path
% 2. fiji_path
% 3. analysis_modules_list
% 4. input_data_folder
% 5. input_trials
% 6. input_phys_vars
% 7. analysis_module

color_map                               = 'jet';
resize_scale                            = 0.02;

%% START OF CODE
disp(strcat('Initiating', {' '}, param_list{7}, '...')); % Indicate module initiation.
trial                                   = fn_get_list_selection('Please select an experiment:', cellstr(param_list{5})); disp(strcat('Trial', {' '}, trial, {' '}, 'is selected.')); pause(3); % Prompt the user to select a trial.
fn_gfp_disp(param_list{4}, trial); % Visualize the tumor FoV.
output_folder                           = strcat(param_list{4}, '\', trial, '\', 'Outputs\');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Default output folder created at', {' '}, output_folder, '.'));
end

phys_var                                = fn_get_list_selection('Please select a variable:', cellstr(param_list{6})); pause(3); % Prompt the user to select a physiological variable.
disp(strcat('Physiological variable', {' '}, phys_var, {' '}, 'is selected.'));

input_data_folder                       = strcat(param_list{4}, '\', trial, '\', phys_var, '\');
img_names                               = fn_read_names(input_data_folder);
num_imgs                                = size(img_names, 1);
temp_img                                = imread(strcat(input_data_folder, '\', img_names(end, :)));

h                                       = figure; movegui(h,'north'); imagesc(temp_img), colormap(color_map), colorbar; grid on; axis image; title(cellstr(phys_var)); h.NumberTitle = 'off';
disp(strcat('Showing a preview of', {' '}, phys_var, '.')); pause(3);

mask                                    = fn_create_mask(param_list, trial, phys_var); pause(3);

[x, y, ~]                               = fn_select_roi(temp_img, phys_var, color_map); pause(3);
x                                       = max(floor(x * resize_scale), 1); 
y                                       = max(floor(y * resize_scale), 1); 

prompt                                  = {'Enter the time resolution (min) of the selected image stack''s time course:', 'Enter the number of images for each period:'};
dlgtitle                                = 'Please enter the processing specifications:';
dims                                    = [1 35];
definput                                = {'1', num2str(floor(num_imgs)/2)};
processing_specs                        = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
time_res                                = str2double(processing_specs{1});
block_size                              = str2double(processing_specs{2});
disp(strcat('Processing specs:', {' '}, 'Input Data Time Resolution =', {' '}, num2str(time_res), {' '}, 'min', ',', {' '}, 'Block Size', {' '}, '=', {' '}, num2str(block_size), {'.'} ));

waitfor(msgbox(['Please select an output folder.' sprintf('\n') sprintf('\n') 'The default folder is "/Outputs/".' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
output_folder_path                      = fn_get_dir(strcat(param_list{4}, '\', trial), 'Please select an output folder path:'); pause(3);
output_folder                           = strcat(output_folder_path, '\', lower(phys_var), '_', lower(param_list{7}), '\');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Output folder created at', {' '}, output_folder, '.'));
end
disp(strcat('Output folder is found at', {' '}, output_folder, '.')); pause(3);

disp({'Reading images...'});
num_rows                                = y(2) - y(1) + 1;
num_cols                                = x(2) - x(1) + 1;
img_stack                               = zeros(num_rows, num_cols, num_imgs);

mask                                    = (imresize(mask, resize_scale)> 0);
mask                                    = mask(y(1):y(2), x(1):x(2));

for i = 1:1:num_imgs
    img                                 = double(imread(strcat(input_data_folder, '\', img_names(i,:))));
    img                                 = imresize(img, resize_scale);
    img_stack(:,:,i)                    = (img(y(1):y(2), x(1):x(2))) .* mask;
end


num_blocks                              = floor(num_imgs/block_size); pause(3);

%% FIGURES B & C
zero_img                                = imread(strcat(input_data_folder, '\', img_names(1, :)));
zero_img                                = zero_img(y(1)/resize_scale: y(2)/resize_scale, x(1)/resize_scale: x(2)/resize_scale);

choice_visualization                    = questdlg('Would you like to select locations and visualize the time series?', '', 'Yes', 'No', 'Yes');
switch choice_visualization
    case 'Yes'
        option_choice                   = questdlg('Would you like to use the physiological variable''s actual values or its temporal derivative?', '', 'Actual Values', 'Temporal Derivative', 'Temporal Derivative');
        fn_select_time_course(zero_img, img_stack, resize_scale, phys_var, time_res, option_choice);
    case 'No'
        disp({'Not selecting locations for visualizing time series...'});
    case ''
        disp({'Not selecting locations for visualizing time series...'});
end
pause(3);

%% FIGURE D
% Prompt the user to select coordinates to look at microvascular connectivity maps.
choice_connectivity                     = questdlg('Would you like to select locations and check microvascular connectivity?', '', 'Yes', 'No', 'Yes');
switch choice_connectivity
    case 'Yes'
        option_choice                   = questdlg('Would you like to use the physiological variable''s actual values or its temporal derivative?', '', 'Actual Values', 'Temporal Derivative', 'Temporal Derivative');
        fn_visualize_connectivity_maps(processing_specs, img_stack, mask, phys_var, num_blocks, color_map, zero_img, resize_scale, option_choice);
    case 'No'
        disp({'Not selecting locations on microvascular connectivity maps...'});
    case ''
        disp({'Not selecting locations on microvascular connectivity maps...'});
end
pause(3);

%% FIGURE E & F

% Prompt the user to selectif they'd like to run the clustering algorithm.
choice_clustering                       = questdlg('Would you like to run the clustering algorithm?', '', 'Yes', 'No', 'Yes');

switch choice_clustering
    case 'Yes'
        
        prompt                          = {'Enter the correlation coefficient (r-value) threhold value:'};
        dlgtitle                        = 'Please enter the clustering specifications:';
        dims                            = [1 35];
        definput                        = {'0.7'};
        processing_specs_temp           = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
        r_value                         = str2double(processing_specs_temp{1});
        disp(strcat('Clustering specs:', {' '}, 'R-Value Threshold', {' '}, '=', {' '}, num2str(r_value), {'.'} ));

        option_choice                   = questdlg('Would you like to use the physiological variable''s actual values or its temporal derivative?', '', 'Actual Values', 'Temporal Derivative', 'Temporal Derivative');
        fn_svd_clustering(processing_specs, img_stack, mask, phys_var, num_blocks, color_map, r_value, option_choice); pause(3);

  
    case 'No'
        disp({'Did not run the clustering algorithm...'});
    case ''
        disp({'Did not run the clustering algorithm...'});
end


%% REPEAT CODE?
choice_rerun                            = questdlg('Would you like to run the clustering algorithm again?', '', 'Yes', 'No', 'Yes'); pause(3);
switch choice_rerun
    case 'Yes'
        close all; pause(3);
        fn_cluster_analysis(param_list);
    case 'No'
        disp(strcat('Exiting', {' '}, param_list{7}, '...'));
        disp(strcat('Here ends', {' '}, param_list{7}, '. Please re-run HemoSYS for further analysis.'));
end
end