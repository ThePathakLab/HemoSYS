function fn_fourier_analysis(param_list)
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
zero_img                                = double(imread(strcat(input_data_folder, '\', img_names(1,:))));
h = figure; movegui(h,'north'); imagesc(zero_img), colormap(color_map), colorbar; axis image; title(cellstr(phys_var)); h.NumberTitle = 'off';
disp(strcat('Showing a preview of', {' '}, phys_var, '.')); pause(3);

mask                                    = fn_create_mask(param_list, trial, phys_var); pause(3);

[x, y]                                  = fn_select_roi(zero_img, phys_var, color_map); pause(3);
x                                       = max(floor(x * resize_scale), 1); 
y                                       = max(floor(y * resize_scale), 1);

mask                                    = (imresize(mask, resize_scale)> 0);
mask                                    = mask(y(1):y(2), x(1):x(2));

zero_img                                = zero_img(y(1)*(1/resize_scale): y(2)*(1/resize_scale), x(1)*(1/resize_scale): x(2)*(1/resize_scale));

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
num_rows                                = y(2) - y(1) + 1;
num_cols                                = x(2) - x(1) + 1;
img_stack                               = zeros(num_rows, num_cols, num_imgs);
for i = 1:1:num_imgs
    img                                 = double(imread(strcat(input_data_folder, '\', img_names(i,:))));
    img                                 = imresize(img, resize_scale);
    img_stack(:,:,i)                    = img(y(1):y(2), x(1):x(2)).*mask;
end
close;

prompt                                  = {'Enter the number of points to use for FFT:', 'Enter the time resolution (min) of the selected image stack''s time course:', 'Enter the signal cycle time that demarcates low vs. high frewuencies (min):'};
dlgtitle                                = 'Enter the Fourier parameters:';
dims                                    = [1 35];
definput                                = {num2str(num_imgs), '1', '10'};
fourier_specs                           = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
n_fft                                   = str2double(fourier_specs{1});
Fs                                      = 1/(str2double(fourier_specs{2})*60);
f_max                                   = Fs/2;
f_res                                   = Fs/n_fft;
lf_max                                  = 1/(str2double(fourier_specs{3})*60);
lf_max                                  = floor(lf_max/f_res);
hf_min                                  = lf_max + 1;

disp(strcat('Fourier specs:', {' '}, 'N of FFT =', {' '}, num2str(n_fft), ',', {' '}, 'Lf Band Maximum =', {' '}, num2str(lf_max), ',', {' '}, 'Hf Band Minimum =', {' '}, num2str(hf_min), ',', {' '}, 'Sampling Frequency =', {' '}, num2str(Fs), {'Hz.'} ));

%% FIGURE B
choice_visualize_fft_original           = questdlg('Would you like to select a location to assess its power distribution in the frequency domain via the Fourier transform.?', '', 'Yes', 'No', 'Yes'); pause(3);

switch choice_visualize_fft_original
    case 'Yes'

        loop_var                        = 1;
        while(loop_var)

            h                           = figure; 
            movegui(h,'north'); 
            imagesc(zero_img); 
            colormap(color_map); 
            colorbar; axis image; 
            title(cellstr(phys_var)); 
            h.NumberTitle               = 'off'; 
            hold on;
            disp(strcat('Showing the selected preview of', {' '}, phys_var, '.')); pause(1);

            try_again                   = 1;
            while(try_again)
                [x_loc, y_loc]          = ginput(1); 
                x_loc                   = max(floor(x_loc*resize_scale), 1);
                y_loc                   = max(floor(y_loc*resize_scale), 1); pause(1);
            
                
                
                if mask(y_loc, x_loc) == 0
                    try_again           = 1;
                    waitfor(msgbox(['Invalid location. Please select another location to assess its power distribution in the frequency domain via the Fourier transform.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
                else
                    try_again           = 0;
                end
            end

            plot((1:1:size(zero_img, 2)), (y_loc/resize_scale)*ones(size(zero_img, 2)), 'k', 'LineStyle', '--'); plot((x_loc/resize_scale)*ones(size(zero_img, 1)),(1:1:size(zero_img, 1)), 'k', 'LineStyle', '--'); hold off;
            disp(strcat('Selected point:', {' '}, '(',num2str(x),',', num2str(y),').'));
            
            point_stack                 = zeros(num_imgs, 1);
            for i = 1:1:num_imgs
                img                     = img_stack(:,:,i);
                point_stack(i)          = img(y_loc, x_loc);
            end

            fourier_transform           = fft(point_stack, n_fft)';
            P2                          = abs(fourier_transform / n_fft); % N
            P1                          = P2(1:n_fft/2 + 1);
            P1(2:end - 1)               = 2 * P1(2:end - 1);
            POW1                        = (P1(2:end).^2)/2;             % Excluded the dc!
            POW                         = sum(POW1, 1);
            f                           = Fs * (1:n_fft/2) / n_fft;

            h                           = figure; movegui(h,'northeast'); 
            h.NumberTitle               = 'off'; 
            grid on; 
            hold on; 
            plot(f, 10 * log10(POW1 ./ (mean(point_stack).^2))); 
            xlabel('Frequency (Hz)'); 
            ylabel('Power Spectrum (dB)'); 
            hold off; 
            pause(3);

            choice_loop                 = questdlg('Would you like to select another time trace?', '', 'Yes', 'No', 'Yes'); pause(3);
            if (strcmp(choice_loop, 'No') || strcmp(choice_loop, '')) == 1
                loop_var                = 0;
            end
            if strcmp(choice_loop, 'Yes') == 1
                disp({'Selecting another time trace...'}); pause(1);
            end
        end

        
    case 'No'
        disp({'No locations were selected to visualize the fft...'});
    case ''
        disp({'No locations were selected to visualize the fft...'});
        
end 


%% FIGURE C
stack_fourier_transform                     = fft(img_stack, n_fft, 3);
P2                                          = abs(stack_fourier_transform / n_fft);
P1                                          = P2(:, :, 1:(n_fft/2) + 1);             
P1(:, :, 2:end - 1)                         = 2 * P1(:, :, 2:end - 1);
pow                                         = (P1(:,:, 2:end).^2)/2;         %dc offset is not included. Nice!
mean_stack                                  = repmat(mean(img_stack, 3), [1 1 (0.5 * n_fft)]);
pow                                         = pow./(mean_stack.^2);

pow(isnan(pow))                             = 0;
pow(isinf(pow))                             = 0;
lf                                          = sum(pow(:, :, 1:lf_max), 3); % low frequency band
hf                                          = sum(pow(:, :, hf_min:end), 3); % high frequency band
hf_lf_ratio                                 = hf./lf;
hf_lf_ratio(isnan(hf_lf_ratio))             = 0;
hf_lf_ratio(isinf(hf_lf_ratio))             = 0;

lf_values                                   = sort(lf(:)); lf_size = length(lf_values);
hf_values                                   = sort(hf(:)); hf_size = length(hf_values);
hf_lf_ratio_values                          = sort(hf_lf_ratio(:)); hf_lf_ratio_size = length(hf_lf_ratio_values);


lf_disp_max                                 = lf_values(floor(lf_size * .995));
lf_disp_min                                 = lf_values(max(floor(lf_size * .005),1));
hf_disp_max                                 = hf_values(floor(hf_size * .995));
hf_disp_min                                 = hf_values(max(floor(hf_size * .005),1));
hf_lf_ratio_disp_max                        = hf_lf_ratio_values(floor(hf_lf_ratio_size*.995));
hf_lf_ratio_disp_min                        = hf_lf_ratio_values(max(floor(hf_lf_ratio_size*.005), 1));

choice_visualize_pow_het                    = questdlg(strcat('Would you like to visualize the power heterogeneity for', {' '}, phys_var, {' '}, 'within Lf and Hf bands, as well as the Hf/Lf power ratio.'), '', 'Yes', 'No', 'Yes'); 
pause(1);

switch choice_visualize_pow_het 
    case 'Yes'
        h                                   = figure; 
        movegui(h,'southwest'); 
        h.NumberTitle                       = 'off'; 
        h.Name                              = 'Spatial Distribution of Power Levels'; 
        imagesc(10*log10(lf), max(10*log10([lf_disp_min lf_disp_max]), -60));
        grid on; 
        axis image; 
        title(strcat('L_{f} power of', {' '}, phys_var, {' '}, '(dB)')); 
        colormap(color_map); 
        colorbar;

        h                                   = figure; 
        movegui(h,'southwest'); 
        h.NumberTitle                       = 'off'; 
        h.Name                              = 'Spatial Distribution of Power Levels'; 
        imagesc(10*log10(hf), max(10*log10([hf_disp_min hf_disp_max]), -60)); 
        grid on; 
        axis image; 
        title(strcat('H_{f} power of', {' '}, phys_var, {' '}, '(dB)')); 
        colormap(color_map); 
        colorbar;

        h                                   = figure;
        movegui(h,'southwest'); 
        h.NumberTitle                       = 'off'; 
        h.Name                              = 'Spatial Distribution of Power Levels'; 
        imagesc(hf./lf,[hf_lf_ratio_disp_min hf_lf_ratio_disp_max]); 
        grid on; 
        axis image; 
        title(strcat('H_{f}/L_{f} ratio of', {' '}, phys_var)); 
        colormap(color_map); 
        colorbar;
        
        img_out                             = fn_white_bg_w_colormap(10*log10(lf), lf_disp_min, lf_disp_max, mask, jet); 
        imwrite(img_out, strcat(output_folder, '-', phys_var, '-lf-', max(num2str(10*log10(lf_disp_min)), -60), '-', num2str(10*log10(lf_disp_max)), '.png'));

        img_out                             = fn_white_bg_w_colormap(10*log10(hf), hf_disp_min, hf_disp_max, mask, jet); 
        imwrite(img_out, strcat(output_folder, '-', phys_var, '-hf-', max(num2str(10*log10(hf_disp_min)), -60), '-', num2str(10*log10(hf_disp_max)), '.png'));

        img_out                             = fn_white_bg_w_colormap(hf./lf, hf_lf_ratio_disp_min, hf_lf_ratio_disp_max, mask, jet); 
        imwrite(img_out, strcat(output_folder, '-', phys_var, '-hf-div-lf-',num2str(hf_lf_ratio_disp_min),'-', num2str(hf_lf_ratio_disp_max),'.png'));

        pause(3);

        
    case 'No'
        disp({'Did not visualize spatial heterogeneity in the power spectrum...'});
        
    case ''
        disp({'Did not visualize spatial heterogeneity in the power spectrum...'});
end

%% FIGURE D


choice_visualize_more                       = questdlg(strcat('Would you like to make a scatter plot of the power of another hemodynamic variable against the power of', {' '}, phys_var, {' '}, 'at a selected frequency.'),'', 'Yes', 'No', 'Yes'); 
pause(1);

switch choice_visualize_more 
    case 'Yes'
        loop_var                            = 1;
        
        while(loop_var)
            
            phys_var_1                     = fn_get_list_selection('Please select a variable:', cellstr(param_list{6})); 
            pause(1);
            disp(strcat('Physiological variable', {' '}, phys_var_1, {' '}, 'is selected.'));
            input_data_folder_1            = strcat(param_list{4}, '\', trial, '\', phys_var_1, '\');
            img_names_1                    = fn_read_names(input_data_folder_1);

            prompt                         = {'Enter a cycle time (min):'};
            dlgtitle                       = 'Select a frequency (i.e. a cycle time)';
            dims                           = [1 35];
            definput                       = {num2str(n_fft/2)};
            cycle_time_spec                = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(1);
            cycle_time                     = str2double(cycle_time_spec {1});
            selected_freq                  = 1/(60*cycle_time);
            selected_freq                  = f_res*max(floor(selected_freq/f_res),1);
            selected_freq                  = min(f_max, selected_freq);
            cycle_time                     = 1/(60*selected_freq);
            selected_freq_index            = max((selected_freq/f_res),1);

            phys_var_1_img_stack_resized   = zeros(num_rows, num_cols, num_imgs); 

            for i = 1:1:num_imgs
                img                        = double(imread(strcat(input_data_folder_1, '\', img_names_1(i,:))));
                img                        = imresize(img, resize_scale);
                phys_var_1_img_stack_resized(:,:,i) = img(y(1):y(2), x(1):x(2)).*mask;
            end

            output_folder                  = strcat(output_folder, '\delta_', phys_var_1, '_vs_delta_', lower(param_list{7}), '\');
            if ~exist(output_folder, 'dir')
                mkdir(output_folder);
            end

            stack_fourier_transform_1     = fft(phys_var_1_img_stack_resized, n_fft, 3);
            P2                            = abs(stack_fourier_transform_1 / n_fft);
            P1_1                          = P2(:, :, 1:n_fft/2 + 1);
            P1_1(:, :, 2:end - 1)         = 2 * P1_1(:, :, 2:end - 1);
            pow_1                         = (P1_1(:,:, 2:end).^2)/2;
            mean_stack_1                  = repmat(mean(phys_var_1_img_stack_resized, 3), [1 1 0.5*n_fft]);
            pow_1                         = pow_1./(mean_stack_1.^2);

            cycle_0                       = 10*log10(pow(:, :, selected_freq_index));
            cycle_1                       = 10*log10(pow_1(:, :, selected_freq_index));

            f                             = figure; 
            movegui(f, 'south'); 
            f.NumberTitle                 = 'off'; 

            scatter(cycle_0(mask), cycle_1(mask), 100, 'k', 'filled'); title(strcat('The relationship between powers of', {' '}, phys_var, {' '}, 'and', {' '}, phys_var_1, {' '}, 'at the cycle time of', {' '}, num2str(cycle_time), {' '}, 'mins')); 
            xlabel(strcat(phys_var, {' '},'power (dB)')); 
            ylabel(strcat(phys_var_1, {' '}, 'power (dB)')); 
            grid on; 
            pause(3);
            
            choice_loop                 = questdlg('Would you like to select another variable or another frequency?', '', 'Yes', 'No', 'Yes'); pause(3);
            if (strcmp(choice_loop, 'No') || strcmp(choice_loop, '')) == 1
                loop_var                = 0;
            end
            if strcmp(choice_loop, 'Yes') == 1
                disp({'Selecting another variable or frequency...'}); pause(1);
            end
            
        end
    case 'No'
        disp({'Did not visualize the rest of the relationships...'});
        
    case ''
        disp({'Did not visualize the rest of the relationships...'});
end
       
%% REPEAT CODE?
choice_perturbation = questdlg('Would you like to run the Fourier algorithm again?', '', 'Yes', 'No', 'Yes'); pause(3);
switch choice_perturbation
    case 'Yes'
        close all; pause(3);
        fn_perturbation_analysis(param_list);
    case 'No'
        disp(strcat('Exiting', {' '}, param_list{7}, '...'));
        disp(strcat('Here ends', {' '}, param_list{7}, '. Please re-run HemoSYS for further analysis.'));
end
end