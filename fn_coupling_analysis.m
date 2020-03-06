function fn_coupling_analysis(param_list)
%% param_list
% 1. matlab_path
% 2. fiji_path
% 3. analysis_modules_list
% 4. input_data_folder
% 5. input_trials
% 6. input_phys_vars
% 7. analysis_module

color_map                               = 'jet';                            %Default colormap to use.
resize_scale                            = 0.02;                             %Corresponds to downsizing by 50 times. UIsed as the defualt.


%% START OF CODE
disp(strcat('Initiating', {' '}, param_list{7}, '...')); % Indicate module initiation.
trial                                   = fn_get_list_selection('Please select an experiment:', cellstr(param_list{5})); disp(strcat('Trial', {' '}, trial, {' '}, 'is selected.')); pause(3); % Prompt the user to select a trial.
fn_gfp_disp(param_list{4}, trial);
output_folder                           = strcat(param_list{4}, '\', trial, '\', 'Outputs\');

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Default output folder created at', {' '}, output_folder, '.'));
end

phys_var_1                              = fn_get_list_selection('Select the 1st variable:', cellstr(param_list{6})); pause(3);
disp(strcat('Physiological variable', {' '}, phys_var_1, {' '}, 'is selected.'));
input_data_folder_1                     = strcat(param_list{4}, '\', trial, '\', phys_var_1, '\');
img_names_1                             = fn_read_names(input_data_folder_1);
num_imgs_1                              = size(img_names_1, 1);
temp_img_1                              = imread(strcat(input_data_folder_1, '\', img_names_1(end,:)));
h                                       = figure; movegui(h,'north'); imagesc(temp_img_1), colormap(color_map), colorbar; grid on; axis image; title(cellstr(strcat(phys_var_1, {' '}, '(t = 0)'))); h.NumberTitle = 'off';
disp(strcat('Showing a preview of', {' '}, phys_var_1, '.')); pause(3);

phys_var_2                              = fn_get_list_selection('Select the 2nd variable:', cellstr(param_list{6})); pause(3);
disp(strcat('Physiological variable', {' '}, phys_var_2, {' '}, 'is selected.'));
input_data_folder_2                     = strcat(param_list{4}, '\', trial, '\', phys_var_2, '\');
img_names_2                             = fn_read_names(input_data_folder_2);
num_imgs_2                              = size(img_names_2, 1);
temp_img_2                              = imread(strcat(input_data_folder_2, '\', img_names_2(end,:)));
h                                       = figure; movegui(h, 'north'); imagesc(temp_img_2), colormap(color_map), colorbar; axis image; grid on; title(cellstr(strcat(phys_var_2, {' '}, '(t = 0)'))); h.NumberTitle = 'off'; hold on;
disp(strcat('Showing a preview of', {' '}, phys_var_2, '.')); pause(3);

mask                                    = fn_create_mask(param_list, trial, phys_var_1); pause(3);

[x, y, choice_roi]                      = fn_select_roi(temp_img_1, phys_var_1, color_map); pause(3);
x                                       = max(floor(x * resize_scale), 1); 
y                                       = max(floor(y * resize_scale), 1); 
if strcmp(choice_roi, 'Yes') == 1
    rectangle('Position', [ floor(x(1)/resize_scale), floor(y(1)/resize_scale), floor((abs(x(2) - x(1)))/resize_scale), floor((abs(y(1) - y(2)))/resize_scale)], 'EdgeColor', 'Black', 'LineStyle', '--');
end
hold off;


disp({'Reading images...'});
mask                                    = (imresize(mask, resize_scale) > 0);
mask                                    = mask(y(1):y(2), x(1):x(2));

num_rows                                = y(2) - y(1) + 1;
num_cols                                = x(2) - x(1) + 1;
img_stack_1                             = zeros(num_rows, num_cols, num_imgs_1); img_stack_2 = zeros(num_rows, num_cols, num_imgs_2);
for i = 1:1:num_imgs_1
    img                                 = double(imread(strcat(input_data_folder_1, '\', img_names_1(i,:))));
    img                                 = imresize(img, resize_scale);
    img_stack_1(:,:,i)                  = img(y(1):y(2), x(1):x(2)) .* mask;
end
for i = 1:1:num_imgs_2
    img                                 = double(imread(strcat(input_data_folder_2, '\', img_names_2(i,:))));
    img                                 = imresize(img , resize_scale);
    img_stack_2(:,:,i)                  = img(y(1):y(2), x(1):x(2)).* mask;
end

% Prompt the user to select an output folder.
waitfor(msgbox(['Please select an output folder.' sprintf('\n') sprintf('\n') 'The default folder is "/Outputs/".' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
output_folder_path                      = fn_get_dir(strcat(param_list{4}, '\', trial), 'Please select an output folder path:');
output_folder                           = strcat(output_folder_path, '\', lower(phys_var_1), '_', lower(phys_var_2), '_',lower(param_list{7}), '\');

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Output folder created at', {' '}, output_folder, '.'));
end
disp(strcat('Output folder is found at', {' '}, output_folder, '.'));

%% FIGURE B
% Assess coupling by computing the correlation coefficient (r-value) between time series for each 50x50 pixel sub-region during each time period.
loop_var                                = 1;
while(loop_var)
    prompt                              = {'Enter the time resolution (min) of the selected image stack''s time course:', 'Enter the number of images for each period:'};
    dlgtitle                            = 'Please enter the processing specifications:';
    dims                                = [1 35];
    definput                            = {'1', num2str(floor(num_imgs_1)/2)};
    processing_specs                    = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
    time_res                            = str2double(processing_specs{1});
    block_size                          = str2double(processing_specs{2});
    disp(strcat('Processing specs:', {' '}, 'Input Data Time Resolution =', {' '}, num2str(time_res), {' '}, 'min', ',', {' '}, 'Block Size', {' '}, '=', {' '}, num2str(block_size), {'.'} ));
    
    num_blocks                          = floor(num_imgs_1/block_size);
    temp_dims                           = sort(factor(num_blocks));
    dims                                = temp_dims;
    if (length(temp_dims) > 2)
        dims                            = [temp_dims(end) prod(temp_dims(1:end-1))];
    end
    if (length(temp_dims) == 1)
        dims                            = [1 temp_dims];
    end
    corrcoef_matrix                     = zeros(num_rows, num_cols, num_blocks);
    
    h                                   = figure; 
    movegui(h, 'northeast'); 
    h.Name                              = cell2mat(strcat('Correlation cofficients (r) between', {' '}, phys_var_1, {' '}, 'and', {' '}, phys_var_2, {' '},'for', {' '}, num2str(num_blocks), {' '}, 'periods of', {' '}, num2str(block_size * time_res), {' '}, 'min')); 
    h.NumberTitle                       = 'off'; hold on;
  
    for i = 1:1:num_blocks
        start_index                     = block_size * (i - 1) + 1;
        end_index                       = start_index + block_size - 1;
        
        img_stack_1_temp                = img_stack_1(:, :, round(start_index):round(end_index));
        img_stack_2_temp                = img_stack_2(:, :, round(start_index):round(end_index));
        
        % Calculate pixel-vs-pixel correlations (in the downsized version).
        disp(strcat('Calculating correlation coefficients (r-values) between', {' '}, phys_var_1, {' '}, 'and', {' '}, phys_var_2, {' '}, 'at Period', {' '}, num2str(i), '...'));
  
        for j = 1:1:num_rows
            for k = 1:1:num_cols
                [r, p]                  = corrcoef(squeeze(img_stack_1_temp(j, k, :)), squeeze(img_stack_2_temp(j, k, :)));
                temp                    = r(2,1) * (p(2,1) < 0.01); temp(isnan(temp)) = 0;
                corrcoef_matrix(j, k, i)= temp;
            end
        end
   
        fprintf('\n\n');
        
        eval(strcat('subplot(', num2str(dims(1)), ',', num2str(dims(2)), ',', num2str(i), ')'));
        imagesc(corrcoef_matrix(:, :, i), [-1,1]); colormap(color_map); grid on; axis image; colorbar; title(cell2mat(strcat('Period', {' '}, num2str(i))));
        
        img_out = fn_white_bg_w_colormap_wlevs(corrcoef_matrix(:, :, i), -1, 1, mask, color_map, 64);
        imwrite(img_out, strcat(output_folder, 'period_', num2str(i), '_corr_map.png'));
        disp(strcat('Saving matrix at', {' '}, output_folder, 'period_', num2str(i), '_corr_map.png.')); pause(3);
    end
    disp({'Correlation calcuations between time series at each time period has completed.'});
    
    choice_loop                         = questdlg('Would you like to check coupling again?', '', 'Yes', 'No', 'Yes'); pause(3);
    if strcmp(choice_loop, 'No') == 1
        loop_var                        = 0;
    end
    if strcmp(choice_loop, 'Yes') == 1
        disp({'Checking coupling again...'}); pause(3);
    end
    
    hold off;
end

%% FIGURE C
% Visualize heterogeneity of coupling by classifying the tumor FoV into distinct regions based on the r-value threshold value across periods.
prompt                                  = {'Enter the correlation coefficient (r-value) threhold value:'};
dlgtitle                                = 'Please enter the clustering specifications:';
dims                                    = [1 35];
definput                                = {'0.7'};
processing_specs                        = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
r_value                                 = str2double(processing_specs{1});
coupling_map                            = zeros(num_rows, num_cols);
if num_blocks > 1
    blocks_option                       = questdlg('Would you like to want to classify based on coupling among periods?', '', 'Yes', 'No', 'Yes'); pause(3);
    switch blocks_option
        case 'Yes'
            prompt                      = {'Enter the 1st period to use:', 'Enter the 2nd period to use:'};
            dlgtitle                    = 'Please enter the clustering specifications:';
            dims                        = [1 35];
            definput                    = {'1', num2str(num_blocks)};
            blocks_specs                = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
            first_block                 = str2double(blocks_specs{1});
            second_block                = str2double(blocks_specs{2});
            for j = 1:1:num_rows 
                for k = 1:1:num_cols 
                    if mask(j, k) ~= 0
                        if corrcoef_matrix(j, k, [first_block second_block]) > r_value
                            coupling_map(j, k) = 1; % always coupled
                        elseif corrcoef_matrix(j, k, [first_block second_block]) < r_value
                            coupling_map(j, k) = -1; % always uncoupled
                        else
                            coupling_map(j, k) = 0; % intermittent
                        end
                    else
                        coupling_map(j, k) = 1e-6; % "background" values
                    end
                end
            end
        case 'No'
            for j = 1:1:num_cols
                for k = 1:1:num_rows
                    if mask(j, k) ~= 0
                        if corrcoef_matrix(j, k, :) > r_value
                            coupling_map(j, k) = 1; % always coupled
                        elseif corrcoef_matrix(j, k, :) < r_value
                            coupling_map(j, k) = -1; % always uncoupled
                        else
                            coupling_map(j, k) = 0; % intermittent
                        end
                    else
                        coupling_map(j, k) = 1e-6; % "background" values
                    end
                end
            end
    end
end
h                                       = figure; movegui(h, 'southwest'); h.NumberTitle = 'off'; hold on;
% img_out = fn_white_bg_w_colormap_wlevs(coupling_map, -1, 1, mask, color_map, 3);
imagesc(coupling_map, [-1, 1]); colormap(color_map); grid on; axis image; title(cell2mat(strcat('Coupling Map between', {' '}, phys_var_1, {' '}, '&', {' '}, phys_var_2)));
cb                                      = colorbar; set(cb, 'Ticks', [-1 0 1], 'TickLabels', {'Poorly coupled', 'Intermittently coupled', 'Tightly coupled'}); pause(3);

imwrite(img_out, strcat(output_folder, 'coupling_map.png'));
disp(strcat('Saving coupling map at', {' '}, output_folder, 'coupling_map.png')); pause(3);

%% FIGURE D
% Computing the prevalence of each coupling category as a fraction of the tumor FoV’s area.
tumor_area_total                        = sum(find(mask));
always_coupled_percentage               = sum(find(coupling_map == 1)) / tumor_area_total * 100;
always_uncoupled_percentage             = sum(find(coupling_map == -1)) / tumor_area_total * 100;
intermittent_percentage                 = sum(find(coupling_map == 0)) / tumor_area_total * 100;
% percent tumor area values (table)
fprintf('\n\n'); disp(table(always_coupled_percentage, always_uncoupled_percentage, intermittent_percentage,'VariableNames',{'Coupled', 'Uncoupled', 'Intermittent'})); fprintf('\n\n'); pause(3);

%% FIGURE E
% Identify coupling trends during each time period by plotting ?coupling between periods vs. coupling during the first period.
choice_scatter_plot                     = questdlg('Would you like to plot the change in coupling between one periods vs. coupling during the subsequent period?', '', 'Yes', 'No', 'Yes');
switch choice_scatter_plot
    case 'Yes'
        temp_dims                       = sort(factor(num_blocks - 1));
        dims                            = temp_dims;
        if (length(temp_dims) > 2)
            dims                        = [temp_dims(end) prod(temp_dims(1:end-1))];
        end
        if (length(temp_dims) == 1)
            dims                        = [1 temp_dims];
        end
        
        h = figure; movegui(h, 'south'); h.NumberTitle = 'off'; hold on;
        for i = 1:1:(num_blocks - 1)
            eval(strcat('subplot(', num2str(dims(1)), ',', num2str(dims(2)), ',', num2str(i), ')'));
            temp_1 = corrcoef_matrix(:, :, i); temp_2 = corrcoef_matrix(:, :, i + 1);
            scatter(temp_1(mask > 0), temp_2(mask > 0)-temp_1(mask > 0), 'k', 'filled'); grid on;
            corrcoef_matrix_1 = temp_1(mask > 0);
            corrcoef_matrix_2 = temp_2(mask > 0);
            save(strcat(output_folder, 'period', num2str(i), '_period', num2str(i), '_corr.mat'), 'corrcoef_matrix_1', 'corrcoef_matrix_2');
            xlabel(cell2mat(strcat('Coupling during', {' '},  num2str((i-1) * block_size * time_res), {' '}, '–', {' '}, num2str(i * block_size * time_res), {' '}, 'mins'))); ylabel('\delta Coupling');
            disp(strcat('Plotting Delta Coupling between Period', {' '}, num2str(i), {' '}, 'and Period', {' '}, num2str(i + 1), {' '}, 'vs. Coupling during Period', {' '}, num2str(i), '.')); pause(3);
        end
end
hold off; pause(3);

%% REPEAT CODE?
repeat_coupling = questdlg('Would you like to run the coupling algorithm again?', '', 'Yes', 'No', 'Yes'); pause(3);
switch repeat_coupling
    case 'Yes'
        close all; pause(3);
        fn_coupling_analysis(param_list);
    case 'No'
        disp(strcat('Exiting', {' '}, param_list{7}, '...'));
        disp(strcat('Here ends', {' '}, param_list{7}, '. Please re-run HemoSYS for further analysis.'));
end

end