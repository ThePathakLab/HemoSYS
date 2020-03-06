function fn_propagation_analysis(param_list)
%% param_list
% 1. matlab_path
% 2. fiji_path
% 3. analysis_modules_list
% 4. input_data_folder
% 5. input_trials
% 6. input_phys_vars
% 7. analysis_module

color_map                               = 'jet';
h_contours                              = ones(3,3)/9;
resize_rows                             = 64; 
resize_cols                             = 64;

%% START OF CODE
disp(strcat('Initiating', {' '}, param_list{7}, '...')); % Indicate module initiation.
trial                                   = fn_get_list_selection('Please select an experiment:', cellstr(param_list{5})); disp(strcat('Trial', {' '}, trial, {' '}, 'is selected.')); pause(3); % Prompt the user to select a trial.
fn_gfp_disp(param_list{4}, trial);
output_folder = strcat(param_list{4}, '\', trial, '\', 'Outputs\');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Default output folder created at', {' '}, output_folder, '.'));
end
phys_var                                = fn_get_list_selection('Please select a variable:', cellstr(param_list{6})); disp(strcat('Physiological variable', {' '}, phys_var, {' '}, 'is selected.')); pause(3); % Prompt the user to select a physiological variable.

% Initially read in the selected image stack.
input_data_folder                       = strcat(param_list{4}, '\', trial, '\', phys_var, '\');
img_names                               = fn_read_names(input_data_folder);
num_imgs                                = size(img_names, 1);
temp_img                                = imread(strcat(input_data_folder, '\', img_names(end, :)));
temp_img_stack                          = zeros(size(temp_img, 1), size(temp_img, 2), num_imgs);
for i = 1:1:num_imgs
    temp_img_stack(:,:,i)               = imread(strcat(input_data_folder, '\', img_names(i,:)));
end


% Calculate the range of intensity values for display as default values.
max_intensity                           = ceil(.995 * max(max(max(temp_img_stack, [], 3))));
min_intensity                           = ceil(0.005 * max(max(max(temp_img_stack, [], 3))));

% Prompt the user for input meta data parameters.
prompt                                  = {'Enter the time resolution (min) of the selected image stack''s time course:', 'Enter minimum intensity value to display:', 'Enter maximum intensity value to display:'};
dlgtitle                                = 'Please enter the data acquistion parameters:';
dims                                    = [1 35];
definput                                = {'1', num2str(min_intensity), num2str(max_intensity)};
meta_data                               = fn_get_input_selection(prompt,dlgtitle,dims,definput); pause(3);
time_res                                = str2double(meta_data{1});
min_intensity                           = str2double(meta_data{2});
max_intensity                           = str2double(meta_data{3});
disp(strcat('Input data time resolution:', {' '}, num2str(time_res), {' '}, 'min.'));

% f1 = fn_videofig(num_imgs, @(frm) fn_redraw(frm, temp_img_stack, min_intensity, max_intensity));
% f1.Name = phys_var; movegui(f1, 'southeast');

% Prompt the user to select an output folder.
waitfor(msgbox(['Please select an output folder.' sprintf('\n') sprintf('\n') 'The default folder is "/Outputs/".' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
output_folder_path                      = fn_get_dir(strcat(param_list{4}, '\', trial), 'Please select an output folder path:'); pause(3);
output_folder                           = strcat(output_folder_path, '\', lower(phys_var), '_', lower(param_list{7}), '\');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Output folder created at', {' '}, output_folder, '.'));
end
disp(strcat('Output folder is found at', {' '}, output_folder, '.'));

%% FIGURE A
% Preview an image from the image stack.
f                                       = figure; movegui(f,'north'); f.NumberTitle = 'off';
imagesc(temp_img, [min_intensity, max_intensity]), colormap(color_map), colorbar; grid on; axis image;  title(cellstr(phys_var));
disp(strcat('Showing a preview of', {' '}, phys_var, '.')); pause(3);

[x, y, ~]                               = fn_select_roi(temp_img, phys_var, color_map);


%% FIGURE B
% Read the selected region in all images.
disp({'Reading images...'});
num_rows                                = y(2) - y(1) + 1;
num_cols                                = x(2) - x(1) + 1;
img_stack                               = zeros(num_rows, num_cols, num_imgs);
for i = 1:1:num_imgs
    img                                 = imread(strcat(input_data_folder, '\', img_names(i,:)));
    img_stack(:,:,i)                    = img(y(1):y(2), x(1):x(2));
end

% Visualize time lapse images if selected.
choice                                  = questdlg(strcat('Would you like to visualize the', {' '}, phys_var, {' '}, 'time lapse images?'), '', 'Yes', 'No', 'Yes'); pause(3);
repeat                                  = 'Revisualize';
switch choice
    case 'Yes'
        while strcmp(repeat, 'Revisualize') == 1
            disp({'Showing time lapse data...'});
            prompt                          = {cell2mat(strcat('Enter time lapse spacing (between 1 and', {' '}, num2str(num_imgs * time_res), {' '}, 'min):')), 'Enter minimum intensity value to display:', 'Enter maximum intensity value to display:'};
            dlgtitle                        = 'Please enter the time lapse visualization parameters:';
            dims                            = [1 35];
            definput                        = {num2str(ceil(num_imgs/6)), num2str(min_intensity), num2str(max_intensity)};
            time_lapse_specs                = fn_get_input_selection(prompt,dlgtitle,dims,definput); pause(3);
            time_lapse_spacing              = str2double(time_lapse_specs{1});
            min_intensity                   = str2double(time_lapse_specs{2});
            max_intensity                   = str2double(time_lapse_specs{3});
            
            num_time_lapse_imgs             = floor(num_imgs*time_res/time_lapse_spacing) + 1;
            temp_dims                       = sort(factor(num_time_lapse_imgs));
            dims                            = temp_dims;
            if (length(temp_dims) > 2)
                dims                        = [temp_dims(end) prod(temp_dims(1:end-1))];
            end
            if (length(temp_dims) == 1)
                dims                        = [1 temp_dims];
            end
            
            time_lapse_folder = strcat(output_folder, 'time_lapse_images\');
            if ~exist(time_lapse_folder, 'dir')
                mkdir(time_lapse_folder);
            end
            for img_count=1:1:num_time_lapse_imgs
                time_count                  = (img_count - 1)*(time_lapse_spacing/time_res) + 1;
                img_out                     = fn_white_bg_w_colormap(squeeze(img_stack(:,:, time_count)), min_intensity, max_intensity, ones(num_rows, num_cols), color_map);
                imwrite(img_out, strcat(time_lapse_folder, num2str(time_count - 1), 'min.png'));
            end
            disp({'Saving time lapse data...'});
            
            f = figure; f.NumberTitle = 'off'; movegui(f, 'northeast');
            for img_count=1:1:num_time_lapse_imgs
                temp                        = subplot(dims(1), dims(2), img_count);
                temp.Position(3:4)          = [0.6/dims(2), 1/dims(1)];
                
                time_count                  = (img_count - 1)*(time_lapse_spacing/time_res) + 1;
                imagesc(img_stack(:,:, time_count), [min_intensity max_intensity]);
                colormap(temp, color_map); title(temp, strcat(num2str((time_count -1)*time_res), ' min')); grid on; axis image;
            end
            colorbar('Position', [.92 .35 .025 .5], 'Ticks', [min_intensity max_intensity], 'TickLabels', {num2str(min_intensity), num2str(max_intensity)}); pause(3);
            
            repeat = questdlg(strcat('Would you like to continue or revisualize the', {' '}, phys_var, {' '}, 'time lapse images?'), 'Time Lapse Visualization', 'Continue', 'Revisualize', 'Continue'); pause(3);
        end
end

%% FIGURE C
repeat                                  = 'Rerun';
while strcmp(repeat, 'Rerun') == 1
    % Prompting the user to select propagation analysis parameters.
    disp({'Prompting the user to select propagation analysis parameters...'});
    
    prompt                                  = {'Enter smoothing kernel size (px):', 'Enter the threshold intensity value which defines hypoxia:', 'Enter contour plot time step size (min):', 'Enter pixel size (in microns):'};
    dlgtitle                                = 'Please enter the processing parameters:';
    dims                                    = [1 35];
    definput                                = {'50', num2str(ceil(0.3 * max_intensity)), '1', '5'};
    processing_specs                        = fn_get_input_selection(prompt,dlgtitle,dims,definput); pause(3);
    smoothing_kernel                        = 2*str2double(processing_specs{1}) + 1;
    hypoxia_thres                           = str2double(processing_specs{2});
    contour_step_size                       = str2double(processing_specs{3});
    pixel_size                              = str2double(processing_specs{4});
    
    disp(strcat('Processing specs:', {' '}, 'Smoothing kernel size', {' '}, '=', {' '}, num2str(smoothing_kernel), 'x', num2str(smoothing_kernel), ',', {' '}, 'Hypoxic threshold intensity', {' '}, '=', {' '}, num2str(hypoxia_thres), ',', {' '}, 'Contour plot step size', {' '}, '=', {' '}, num2str(contour_step_size), '.'));
    
%     smoothed_data_folder                    = strcat(output_folder, '\', smoothing_kernel, 'x', smoothing_kernel,'-smoothed_data');
%     if ~exist(smoothed_data_folder, 'dir')
%         mkdir(smoothed_data_folder);
%     end
    
    % MIJI
%     fn_init_miji(param_list{1}, param_list{2}); % Initiate Miji.
%     MIJ.run('Image Sequence...', strcat('open=[', strcat(input_data_folder, '\') , img_names(1,:) , '] sort'));
%     MIJ.run('Mean...', strcat('radius=', num2str(smoothing_kernel/2), ' stack'));
%     MIJ.run('Image Sequence... ', strcat('format=TIFF', ' save=[', smoothed_data_folder, '/0000.tif',']'));
%     MIJ.run('Close');
%     MIJ.exit();
%     
%     disp(strcat('Smoothed data was saved in:', {' '}, smoothed_data_folder)); pause(3);
    
    % Read the smoothed image stack.
%     smoothed_img_stack = zeros(num_rows, num_cols, num_imgs);
%     disp({'Reading the smoothed image stack...'});
%     smoothed_img_names                      = fn_read_names(smoothed_data_folder);
%     for i = 1:1:num_imgs
%         img                                 = double(imread(strcat(smoothed_data_folder, '\', smoothed_img_names(i,:))));
%         img                                 = img(y(1):y(2),x(1):x(2));
%         smoothed_img_stack(:,:,i)           = img;
%     end

    smoothed_img_stack                      = zeros(num_rows, num_cols, num_imgs);
    h                                       = ones(smoothing_kernel,  smoothing_kernel)/( smoothing_kernel^2);
    for i = 1:1:num_imgs
        img                                 = double(imread(strcat(input_data_folder, '\', img_names(i,:))));
        img                                 = conv2(img, h, 'same');
        img                                 = img(y(1):y(2),x(1):x(2));
        smoothed_img_stack(:,:,i)           = img;
    end
    
    % Create contours based on the threshold.
    disp({'Creating a contour plot based on the threshold intensity...'});
    img_stack_thres = zeros(size(smoothed_img_stack)); img_stack_contour = zeros(size(smoothed_img_stack));
    for i = 1:1:num_imgs
        img                                 = smoothed_img_stack(:,:,i);
        img                                 = double(edge(img > hypoxia_thres));
        img_stack_thres(:, :, i)            = (i - 1) * img;
        img                                 = conv2(img, h_contours, 'same') > 0;
        img_stack_contour(:, :, i)          = i * img;
    end
    
    % Save the contour image as a negative gray scales image.
    max_img                                 = max(img_stack_contour,[],3);
    img_out                                 = fn_white_bg_w_colormap(num_imgs - max_img, 0, num_imgs, max_img > 0, hot);
    imwrite(img_out, strcat(output_folder, '\', phys_var, '-', 'contours.png'));
    
    disp({cell2mat(strcat('Contours plot was saved as', {' '}, output_folder, '\', phys_var, '-', 'contours.png'))}); pause(3);
    
    % Display the contour image.
    f = figure; movegui(f, 'west'); f.NumberTitle = 'off';
    imagesc(max_img); colormap(jet); colorbar; grid on; axis image; title(strcat(phys_var, {' '}, 'Contour Plot (Threshold Value of', {' '}, num2str(hypoxia_thres), ', Step Size of', {' '}, num2str(contour_step_size), {' '}, 'min)'));
    disp({'Displaying the contour image...'});
    pause(3);
    
    repeat = questdlg('Would you like to continue or rerun the contour plot generation?', 'Contour Plot Generation', 'Continue', 'Rerun', 'Continue'); pause(3);
    
end

%% FIGURE D
repeat = 1;
while(repeat) % Allow repeatedly to pick points.
    f = figure; movegui(f, 'center'); f.NumberTitle = 'off';
    imagesc(img_out); colormap('hot'); colorbar('Direction','reverse', 'Ticks', [0 1], 'TickLabels', {cell2mat(strcat(num2str(num_imgs*time_res), {' '}, 'min')), '0 min'}); hold on;
    title(strcat(phys_var, {' '}, 'Contour Plot (Threshold Value of', {' '}, num2str(hypoxia_thres), ', Step Size of', {' '}, num2str(contour_step_size), {' '}, 'min)'));
    
    waitfor(msgbox(['To select a direction for analysis, please click two points.' sprintf('\n') sprintf('\n') 'The first point defines the start of the linear path.' sprintf('\n') sprintf('\n') 'The second point defines the end of the linear path.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
    [x2, y2] = ginput(2); line(x2, y2, 'Color', 'k', 'LineStyle', '--'); hold off;
    
    prof_points                         = contour_step_size * (improfile(max(img_stack_thres, [], 3)/contour_step_size, x2, y2));
    num_points                          = size(prof_points, 1);
    val_points                          = prof_points > 0;
    num_val_points                      = sum(val_points, 1);
    val_point_locs                      = find(val_points == 1);
    
    speeds = zeros(num_points, 1); temp = 0;
    for i = 1:1:num_val_points - 1
        p1_time                         = prof_points(val_point_locs(i, 1), 1);
        p2_time                         = prof_points(val_point_locs(i + 1, 1));
        
        speed                           = pixel_size * (val_point_locs(i + 1, 1) - val_point_locs(i,1))/ (p2_time - p1_time);
        if(isinf(speed) == 1)
            speed                       = temp;
        end
        speeds(val_point_locs(i, 1):val_point_locs(i + 1, 1), 1) = speed;
        temp                            = speed;
    end
    
    distances                           = pixel_size * (0:1:num_points - 1)';
    f = figure; movegui(f, 'east'); f.NumberTitle = 'off'; pause(3);
    plot(distances, speeds); xlabel('Distance (\mu m)'); ylabel('Speed (\mu m/min)'); axis([0 max(distances) min(speeds) max(speeds)]);
    save(strcat(output_folder, '\propogation-x[',num2str(x2(1)),',',num2str(x2(2)),']-y[',num2str(y2(1)),',',num2str(y2(2)),'].mat'), 'distances', 'speeds');
    
    disp(strcat('The angle between the selected points is', {' '}, num2str((180/pi)*atan((y2(2) - y2(1))/(x2(2) - x2(1)))), ' degrees.')); % Display angle between defined points.
    choice = questdlg('Would you like to select more points on the hypoxic wave?', '', 'Yes', 'No', 'Yes'); pause(3);
    
    switch choice
        case 'Yes'
            repeat = 1;
        case 'No'
            repeat = 0;
    end
end

%% FIGURE E
waitfor(msgbox(['Correlate changes in a physiological variable vs. another physiological variable to characterize acutely hypoxic vs. normoxic tumor regions.' sprintf('\n') sprintf('\n') 'The original ' num2str(num_rows) 'x' num2str(num_cols) ' selection has been resized to 64x64.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);

[r_rows, r_cols]                        = size(imresize(img, [resize_rows, resize_cols]));
phys_var_img_stack_resized = zeros(r_rows, r_cols, num_imgs); phys_var_2_img_stack_resized = zeros(r_rows, r_cols, num_imgs); phys_var_3_img_stack_resized = zeros(r_rows, r_cols, num_imgs);

phys_var_2                              = fn_get_list_selection('Select 1st scatter plot variable:', cellstr(param_list{6})); pause(3);
disp(strcat('Physiological variable', {' '}, phys_var_2, {' '}, 'is selected.'));
input_data_folder_2                     = strcat(param_list{4}, '\', trial, '\', phys_var_2, '\');
img_names_2                             = fn_read_names(input_data_folder_2);

phys_var_3                              = fn_get_list_selection('Select 2nd scatter plot variable:', cellstr(param_list{6})); pause(3);
disp(strcat('Physiological variable', {' '}, phys_var_3, {' '}, 'is selected.'));
input_data_folder_3                     = strcat(param_list{4}, '\', trial, '\', phys_var_3, '\');
img_names_3                             = fn_read_names(input_data_folder_3);

for i = 1:1:num_imgs
    img                                 = imread(strcat(input_data_folder, '\', img_names(i,:)));
    img                                 = img(y(1):y(2), x(1):x(2));
    phys_var_img_stack_resized(:,:,i)   = imresize(img, [resize_rows, resize_cols]);
    
    img                                 = imread(strcat(input_data_folder_2, '\', img_names_2(i,:)));
    img                                 = img(y(1):y(2), x(1):x(2));
    phys_var_2_img_stack_resized(:,:,i) = imresize(img, [resize_rows, resize_cols]);
    
    img                                 = imread(strcat(input_data_folder_3, '\', img_names_3(i,:)));
    img                                 = img(y(1):y(2), x(1):x(2));
    phys_var_3_img_stack_resized(:,:,i) = imresize(img, [resize_rows, resize_cols]);
end
output_folder                           = strcat(output_folder, '\', phys_var_2, '_vs_', phys_var_3, '-', lower(param_list{7}), '\');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

num_rows = resize_rows; num_cols = resize_cols;
phys_var_2_acute = zeros(num_rows, num_cols); phys_var_3_acute = zeros(num_rows, num_cols); phys_var_2_norm = zeros(num_rows, num_cols); phys_var_3_norm = zeros(num_rows, num_cols);
for i = 1:1:num_rows
    for j = 1:1:num_cols
        if (phys_var_img_stack_resized(i, j, 1) > hypoxia_thres && phys_var_img_stack_resized(i, j, end) < hypoxia_thres) % assume monotonicity
            phys_var_2_acute(i,j)       = (phys_var_2_img_stack_resized(i,j,1) - phys_var_2_img_stack_resized(i,j,end))/mean(phys_var_2_img_stack_resized(i,j,:)); % calculate first variable's fluctuations
            phys_var_3_acute(i,j)   	= (phys_var_3_img_stack_resized(i,j,1) - phys_var_3_img_stack_resized(i,j,end))/mean(phys_var_3_img_stack_resized(i,j,:)); % calculate second variable's fluctuations
        end
        if (phys_var_img_stack_resized(i, j, 1) > hypoxia_thres && phys_var_img_stack_resized(i, j, end) > hypoxia_thres) % assume monotonicity
            phys_var_2_norm(i,j)     	= (phys_var_2_img_stack_resized(i,j,1) - phys_var_2_img_stack_resized(i,j,end))/mean(phys_var_2_img_stack_resized(i,j,:)); % calculate first variable's fluctuations
            phys_var_3_norm(i,j)        = (phys_var_3_img_stack_resized(i,j,1) - phys_var_3_img_stack_resized(i,j,end))/mean(phys_var_3_img_stack_resized(i,j,:)); % calculate second variable's fluctuations
        end
    end
end

pause(3); f = figure; movegui(f, 'southwest'); f.NumberTitle = 'off';
scatter(reshape(phys_var_2_norm, 1, []), reshape(phys_var_3_norm, 1, []), 100, 'g', 'filled'); hold on;
scatter(reshape(phys_var_2_acute, 1, []),reshape(phys_var_3_acute, 1, []), 100, 'r', 'filled');
xlabel(strcat(phys_var_2, ' fluctuations')); ylabel(strcat(phys_var_3, ' fluctuations')); legend('GROUP 1', 'GROUP 2'); grid on;
waitfor(msgbox(['GROUP 1: Regions where the first image of the original stack is greater than the hypoxia threshold value and the last image of the original stack is also greater than the hypoxia threshold value.' sprintf('\n') sprintf('\n') 'GROUP 2: Regions where the first image of the original stack is greater than the hypoxia threshold value and the last image of the original stack is less than the hypoxia threshold value.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
disp('GROUP 1: Regions where the first image of the original stack > hypoxia threshold value & the last image of the original stack > hypoxia threshold value.');
disp('GROUP 2: Regions where the first image of the original stack > hypoxia threshold value & the last image of the original stack < hypoxia threshold value.');

acute_hypoxic_regions                   = (phys_var_img_stack_resized(:, :, 1) > hypoxia_thres) & (phys_var_img_stack_resized(:, :, end));
img_out                                 = fn_white_bg_w_colormap(acute_hypoxic_regions < hypoxia_thres, 0, 1, ones(num_rows, num_cols), gray);
imwrite(img_out, strcat(output_folder, 'acute_hypoxic_regions.png'));
pause(3);

%% REPEAT CODE?
choice_connectivity = questdlg('Would you like to run the propagation algorithm again?', '', 'Yes', 'No', 'Yes'); pause(3);
switch choice_connectivity
    case 'Yes'
        close all; pause(3);
        fn_propagation_analysis(param_list);
    case 'No'
        disp(strcat('Exiting', {' '}, param_list{7}, '...'));
        disp(strcat('Here ends', {' '}, param_list{7}, '. Please re-run HemoSYS for further analysis.'));
end
end