function fn_perturbation_analysis(param_list)
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
fn_gfp_disp(param_list{4}, trial);
output_folder                           = strcat(param_list{4}, '\', trial, '\', 'Outputs\');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Default output folder created at', {' '}, output_folder, '.'));
end

phys_var                                = fn_get_list_selection('Please select a variable:', cellstr(param_list{6})); pause(3);
disp(strcat('Physiological variable', {' '}, phys_var, {' '}, 'is selected.'));

input_data_folder                       = strcat(param_list{4}, '\', trial, '\', phys_var, '\');
img_names                               = fn_read_names(input_data_folder);
num_imgs                                = size(img_names, 1);
temp_img                                = double(imread(strcat(input_data_folder, '\', img_names(end,:))));
h                                       = figure; movegui(h,'north'); imagesc(temp_img), colormap(color_map), colorbar; axis image; grid on; title(cellstr(phys_var)); h.NumberTitle = 'off';
disp(strcat('Showing a preview of', {' '}, phys_var, '.')); pause(3);


mask                                    = fn_create_mask(param_list, trial, phys_var); pause(3);

[x, y, ~]                               = fn_select_roi(temp_img, phys_var, color_map); pause(3);
x                                       = max(floor(x * resize_scale), 1); 
y                                       = max(floor(y * resize_scale), 1); 

x_originals                             = x;
y_originals                             = y;


% Prompt the user to select an output folder.
waitfor(msgbox(['Please select an output folder.' sprintf('\n') sprintf('\n') 'The default folder is "/Outputs/".' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
output_folder_path                      = fn_get_dir(strcat(param_list{4}, '\', trial), 'Please select an output folder path:');
output_folder                           = strcat(output_folder_path, '\', lower(phys_var), '_', lower(param_list{7}), '\');

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
    disp(strcat('Output folder created at', {' '}, output_folder, '.'));
end
disp(strcat('Output folder is found at', {' '}, output_folder, '.'));

disp({'Reading images...'});

zero_img                                = double(imread(strcat(input_data_folder, '\', img_names(1, :))));
zero_img                                = zero_img(y(1)/resize_scale: y(2)/resize_scale, x(1)/resize_scale: x(2)/resize_scale);

num_rows                                = y(2) - y(1) + 1;
num_cols                                = x(2) - x(1) + 1;
img_stack                               = zeros(num_rows, num_cols, num_imgs);

mask                                    = (imresize(mask, resize_scale)> 0);
mask                                    = mask(y(1):y(2), x(1):x(2));

for i = 1:1:num_imgs
    img                                 = double(imread(strcat(input_data_folder, '\', img_names(i,:))));
    img                                 = imresize(img, resize_scale);
    img_stack(:,:,i)                    = (img(y(1):y(2), x(1):x(2))).*mask;
end
close;

prompt                                  = {'Enter the time resolution (min) of the selected image stack''s time course:', 'Enter the correlation coefficient (r-value) threhold value:'};
dlgtitle                                = 'Please enter the data acquistion parameters:';
dims                                    = [1 35];
definput                                = {'1', '0.7'};
processing_specs                        = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
time_res                                = str2double(processing_specs{1});
r_value                                 = str2double(processing_specs{2});
disp(strcat('Processing specs:', {' '}, 'Input Data Time Resolution =', {' '}, num2str(time_res), {' '}, 'min', ',', {' '}, 'R-Value Threshold', {' '}, '=', {' '}, num2str(r_value), {'.'} )); pause(3);

prompt                                  = {'Enter the starting point (min) of the initial baseline:', 'Enter the ending point (min) of the initial baseline:', 'Enter the starting point (min) of the perturbation event:', 'Enter the ending point (min) of the perturbation event:'};
dlgtitle                                = 'Enter the perturbation time-series parameters:';
dims                                    = [1 35];
definput                                = {'0', '9', '10', '19'};
perturbation_specs                      = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
baseline_start_point                    = str2double(perturbation_specs{1}) + 1;
baseline_end_point                      = str2double(perturbation_specs{2}) + 1;
ca_start_point                          = str2double(perturbation_specs{3}) + 1;
ca_end_point                            = str2double(perturbation_specs{4}) + 1;
disp(strcat('Perturbation specs:', {' '}, 'Initial Baseline Start Position =', {' '}, num2str(baseline_start_point), {' '}, 'min', ',', {' '}, 'Initial Baseline End Position =', {' '}, num2str(baseline_end_point), {' '}, 'min', ',', {' '}, 'Perturbation Start Position =', {' '}, num2str(ca_start_point), {' '}, 'min', ',', {' '}, 'Perturbation End Position =', {' '}, num2str(ca_end_point), {' '}, 'min',{'.'} ));

step_size                               = ca_end_point - ca_start_point + 1;
imaging_end_point                       = num_imgs * time_res; % end_point = imaging_end_point - 0.5*step_size + 1;
h                                       = ones(0.5*step_size,1)/(0.5*step_size);
ref_time_series                         = zeros(imaging_end_point, 1);
ref_time_series(ca_start_point:ca_end_point, 1) = 1;
ref_time_series_convd                   = conv(ref_time_series, h);
ref_time_series_convd                   = ref_time_series_convd(0.5 * step_size:end);

%% FIGURE B

choice_loop_original                    = questdlg('Would you like to select a locaition and observe its response to the perturbation?', '', 'Yes', 'No', 'Yes'); pause(3);

switch choice_loop_original
    case 'Yes'
        
        loop_var                                = 1;
        counter                                 = 0;
        while(loop_var)
            temp_img                            = img_stack(:, :, 1);
            h                                   = figure; movegui(h,'north'); imagesc(zero_img), colormap(color_map), colorbar; grid on; axis image; title(cellstr(phys_var)); h.NumberTitle = 'off';hold on;
            disp(strcat('Showing the selected preview of', {' '}, phys_var, '.')); pause(1);

            waitfor(msgbox(['Select a location to visualize its time-series versus the perturbation time-series.' sprintf('\n') sprintf('\n') 'The correlation (r-value) between the perturbation time-series and that of ' phys_var 'will be computed.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(1);
            [x, y]                              = ginput(1); 
            plot((1:1:size(zero_img, 2)), y*ones(size(zero_img, 2)), 'k', 'LineStyle', '--'); plot(x*ones(size(zero_img, 1)),(1:1:size(zero_img, 1)), 'k', 'LineStyle', '--'); hold off;
             
            x                                   = max(floor(x * resize_scale), 1); 
            y                                   = max(floor(y * resize_scale), 1);
         
            pause(1);

            point_stack                         = zeros(num_imgs, 1);
            for i = 1:1:num_imgs
                img                             = img_stack(:,:,i);
                point_stack(i)                  = img(y, x);
            end

            point_plot                          = point_stack/mean(point_stack(baseline_start_point:baseline_end_point, 1));
            point_plot(isnan(point_plot))       = 0;
            point_plot(isinf(point_plot))       = 0;
                h                                   = figure; movegui(h,'northeast'); h.NumberTitle = 'off'; grid on; hold on;
            plot(point_plot); 
            plot(ref_time_series_convd);
            min_y                               = min(squeeze(point_plot)) - 0.1;
            max_y                               = max(squeeze(point_plot)) + 0.1;
            xlabel('Time (mins)'); ylabel(strcat(cellstr(phys_var), {' '}, '(Normalized by Baseline Mean)')); axis([0 (ca_end_point + (baseline_end_point - baseline_start_point)) min_y max_y]); 
            legend(strcat(cellstr(phys_var), {' '}, 'Time-Series'), 'Perturbation Time-Series'); 
            pause(3);


            % Calculate correlation between the perturbation time-series and hemodynamic variable
            disp(strcat('Calculating correlation coefficient (r-values) between the perturbation time-series and', {' '}, phys_var, '...'));
            [r, pval]                           = corrcoef(point_plot, ref_time_series_convd);
            temp                                = r(2,1) * (pval(2,1) < 0.01); 
            temp(isnan(temp))                   = 0; 
            pause(3);
            disp(strcat('The correlation coefficient (r-value) between the perturbation time-series and', {' '}, phys_var, {' '}, 'is', {' '}, num2str(temp), {'.'}));

            if (temp > r_value)
                waitfor(msgbox(['Because r = ' num2str(temp) ' > ' num2str(r_value), ', ', phys_var, ' was considered responsive.' sprintf('\n') 'Please click OK to continue.'])); pause(3);
            else
                waitfor(msgbox(['Because r = ' num2str(temp) ' < ' num2str(r_value), ', ', phys_var, ' was considered unresponsive.' sprintf('\n') 'Please click OK to continue.'])); pause(3);
            end

            choice_loop                        = questdlg('Would you like to select another locaition and observe its response to the perturbation?', '', 'Yes', 'No', 'Yes'); pause(3);
            if (strcmp(choice_loop, 'No') || strcmp(choice_loop, '')) == 1
                loop_var = 0;
            end

            if strcmp(choice_loop, 'Yes') == 1
                counter = counter + 1;
                disp({'Selecting another time trace...'}); pause(3);
            end

            hold off;
        end
        
   case 'No'
        disp({'No locations were selected to visualize the response to the perturbation...'});
    case ''
        disp({'No locations were selected to visualize the response to the perturbation...'});
end

%% FIGURE C
choice_visualization                    = questdlg('Would you like to visualize the heterogeneity of the perturbation response?', '', 'Yes', 'No', 'Yes');
switch choice_visualization
    case 'Yes'
        ref_time_series_to_use          = ref_time_series_convd(1:num_imgs);
        % r_img = fn_ref_corr(img_stack, ref_time_series_to_use);
        delta_img                       = (mean(img_stack(:,:,ca_start_point:ca_start_point + 0.5*step_size - 1), 3) - mean(img_stack(:,:,baseline_start_point:baseline_end_point), 3))./mean(img_stack(:,:,baseline_start_point:baseline_end_point), 3); delta_img(isnan(delta_img)) = 0;
        
        h                               = figure; 
        movegui(h, 'southwest'); 
        h.NumberTitle = 'off'; 
        title(cellstr(phys_var)); 
        grid on; 
        h.Name                          = 'Change in reponsive regions';
        imagesc(delta_img, [0 0.3]); axis image; title(strcat(cellstr(phys_var), ':',{' '}, 'Amount of change/mean  (%)')); colormap(color_map); colorbar;
        disp(strcat('Visualizing the heterogeneity of the perturbation response by mapping change in', {' '}, phys_var, {' '}, 'above the r-value threshold (r >', {' '}, num2str(r_value), {').'})); pause(3);
        
        % delta_img = fn_white_bg_w_colormap(delta_img, 0, 0.3, r_img > r_value, jet);
        imwrite(delta_img, strcat(output_folder, 'delta_img-', phys_var, '.png'));
        delta_save                      = delta_img .* (delta_img > r_value);
        % delta_save = delta_save(mask > 0);
        save(strcat(output_folder, 'delta_img-', phys_var, '.mat'), 'delta_save'); pause(3);
    case 'No'
        disp({'Not visualizing the perturbation response...'});
    case ''
        disp({'Not visualizing the perturbation response...'});
end
pause(3);

%% FIGURE D
x                                       = x_originals;
y                                       = y_originals;

choice_assess_similarities              = questdlg('Would you like to assess the similarities in response to the perturbation among multiple variables ?', '', 'Yes', 'No', 'Yes');
switch choice_assess_similarities 

    case 'Yes'
        waitfor(msgbox(['We will assess this by plotting change in each one against each other in responsive regions (above the r-value threshold, r > ' num2str(r_value) ').' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);

        phys_var_1                              = fn_get_list_selection('Please select first scatter plot variable:', cellstr(param_list{6})); pause(3);
        disp(strcat('Physiological variable', {' '}, phys_var_1, {' '}, 'is selected.'));
        input_data_folder_1                     = strcat(param_list{4}, '\', trial, '\', phys_var_1, '\');
        img_names_1                             = fn_read_names(input_data_folder_1);
 

        phys_var_2                              = fn_get_list_selection('Please select second scatter plot variable:', cellstr(param_list{6})); pause(3);
        disp(strcat('Physiological variable', {' '}, phys_var_2, {' '}, 'is selected.'));
        input_data_folder_2                     = strcat(param_list{4}, '\', trial, '\', phys_var_2, '\');
        img_names_2                             = fn_read_names(input_data_folder_2);

        phys_var_1_img_stack_resized            = zeros(num_rows, num_cols, size(img_names_1, 1)); 
        phys_var_2_img_stack_resized            = zeros(num_rows, num_cols, size(img_names_1, 1));
        for i = 1:1:num_imgs
            img                                 = double(imread(strcat(input_data_folder_1, '\', img_names_1(i,:))));
            img                                 = imresize(img, resize_scale);
            phys_var_1_img_stack_resized(:,:,i) = img(y(1):y(2), x(1):x(2)).*mask;

            img                                 = double(imread(strcat(input_data_folder_2, '\', img_names_2(i,:))));
            img                                 = imresize(img, resize_scale);
            phys_var_2_img_stack_resized(:,:,i) = img(y(1):y(2), x(1):x(2)).*mask;
        end
        output_folder                           = strcat(output_folder, '\delta_', phys_var_1, '_vs_delta_', phys_var_2, '-', lower(param_list{7}), '\');
        if ~exist(output_folder, 'dir')
            mkdir(output_folder);
        end

        phys_var_1_delta_img                    = (mean(phys_var_1_img_stack_resized(:,:,ca_start_point:ca_start_point + 0.5*step_size - 1), 3) - mean(phys_var_1_img_stack_resized(:,:,baseline_start_point:baseline_end_point), 3))./mean(phys_var_1_img_stack_resized(:,:,baseline_start_point:baseline_end_point), 3); phys_var_1_delta_img(isnan(phys_var_1_delta_img)) = 0;
        phys_var_2_delta_img                    = (mean(phys_var_2_img_stack_resized(:,:,ca_start_point:ca_start_point + 0.5*step_size - 1), 3) - mean(phys_var_2_img_stack_resized(:,:,baseline_start_point:baseline_end_point), 3))./mean(phys_var_2_img_stack_resized(:,:,baseline_start_point:baseline_end_point), 3); phys_var_2_delta_img(isnan(phys_var_2_delta_img)) = 0;

        tic
        phys_var_1_responsive                   = zeros(num_rows, num_cols); 
        phys_var_2_responsive                   = zeros(num_rows, num_cols);
        for i = 1:1:num_rows
            for j = 1:1:num_cols
                point_stack_1                   = squeeze(phys_var_1_img_stack_resized(i, j, :));
                point_plot_1                    = point_stack_1/mean(point_stack_1(baseline_start_point:baseline_end_point, 1));
                [r, pval]                       = corrcoef(point_plot_1, ref_time_series_convd);
                temp_1                          = r(2,1) * (pval(2,1) < 0.01); temp_1(isnan(temp_1)) = 0;
                point_stack_2                   = squeeze(phys_var_2_img_stack_resized(i, j, :));
                point_plot_2                    = point_stack_2/mean(point_stack_2(baseline_start_point:baseline_end_point, 1));
                [r, pval]                       = corrcoef(point_plot_2, ref_time_series_convd);
                temp_2                          = r(2,1) * (pval(2,1) < 0.01); temp_2(isnan(temp_2)) = 0;

                if (temp_1 > r_value)
                    phys_var_1_responsive(i, j) = phys_var_1_delta_img(i, j);
                else
                    phys_var_1_responsive(i, j) = 0;
                end
                if (temp_2 > r_value)
                    phys_var_2_responsive(i, j) = phys_var_2_delta_img(i, j);
                else
                    phys_var_2_responsive(i, j) = 0;
                end
            end
        end
        toc
        disp('\n');

        pause(3); 
        f = figure; 
        movegui(f, 'south'); f.NumberTitle = 'off';
        scatter(reshape(phys_var_1_responsive, 1, []), reshape(phys_var_2_responsive, 1, []), 100, 'k', 'filled');
        xlabel(strcat(phys_var_1, ' fluctuations (std/mean)')); ylabel(strcat(phys_var_2, ' fluctuations: std/mean [%]')); grid on; pause(3);
        disp(strcat('Shown is the change in', phys_var_1, {' '}, 'vs. change in', phys_var_2, {' '}, 'plot for the tumor FoV.')); pause(3);

    case 'No'
        disp({'Did not assess similarity in perturbation responses...'});
    case ''
        disp({'Did not assess similarity in perturbation responses...'});
end


%% REPEAT CODE?
choice_perturbation                     = questdlg('Would you like to run the perturbation algorithm again?', '', 'Yes', 'No', 'Yes'); pause(3);
switch choice_perturbation
    case 'Yes'
        close all; pause(3);
        fn_perturbation_analysis(param_list);
    case 'No'
        disp(strcat('Exiting', {' '}, param_list{7}, '...'));
        disp(strcat('Here ends', {' '}, param_list{7}, '. Please re-run HemoSYS for further analysis.'));
end
end