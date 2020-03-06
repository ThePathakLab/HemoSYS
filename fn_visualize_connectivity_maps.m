function fn_visualize_connectivity_maps(processing_specs, img_stack, mask, phys_var, num_blocks, color_map, zero_img, resize_scale, option)
%% param_list
% 1. matlab_path
% 2. fiji_path
% 3. analysis_modules_list
% 4. input_data_folder
% 5. input_trials
% 6. input_phys_vars
% 7. analysis_module

%%
block_size                      = str2double(processing_specs{2});
temp_img                        = img_stack(:, :, end);
loop_var                        = 1;
while(loop_var)
    h                           = figure; movegui(h, 'southwest'); imagesc(zero_img), colormap(color_map), colorbar; axis image; grid on; title(cellstr(phys_var)); h.NumberTitle = 'off'; hold on;
    [x, y]                      = ginput(1); 
    x                           = max(floor(x * resize_scale), 1); 
    y                           = max(floor(y * resize_scale), 1);
    plot((1:1:size(zero_img, 2)), y*(1/resize_scale)*ones(1, size(zero_img, 2)), 'k', 'LineStyle', '--'); plot(x*(1/resize_scale)*ones(size(zero_img, 1),1),(1:1:size(zero_img, 1)), 'k', 'LineStyle', '--'); hold off; pause(3);
    
    for i = 1:1:num_blocks
        start_index             = block_size * (i - 1) + 1;
        end_index               = start_index + block_size - 1;
        img_stack_block         = img_stack(:, :, start_index:end_index);
        img_stack_txd           = fn_transform_stack(img_stack_block, option);
        
        [num_rows, num_cols]    = size(temp_img);
        corr_mat                = zeros(num_rows, num_cols);
        seed_trace              = squeeze(img_stack_txd(y, x, :));
        for j = 1:1:num_rows
            for k = 1:1:num_cols
                [temp1, temp2]      = corrcoef(squeeze(img_stack_txd(j, k, :)), seed_trace);
                corr_val            = temp1(1, 2);
                pval                = temp2(1, 2);
                corr_val(isnan(corr_val)) = 0; corr_val(isinf(corr_val)) = 0;
                corr_val            = max(min(corr_val, 1), -1);
                corr_mat(j,k)       = corr_val * (pval <= 0.01);
            end
        end
        corr_mat                 = corr_mat .* (mask > 0); pause(3);
        h = figure; movegui(h, 'south'); h.NumberTitle = 'off';
        imagesc(corr_mat, [-1 1]); grid on; axis image; colormap(jet); colorbar; title(strcat('Correlation Map of', {' '}, phys_var, {' '}, 'against' , {' '}, 'S(', num2str(x, '%02.0f'), ',', num2str(y, '%02.0f'), ')', {' '}, 'at Period', {' '}, num2str(i))); hold on;
        plot((1:1:size(corr_mat, 2)), y * ones(size(corr_mat, 2)), 'k', 'LineStyle', '--'); plot(x * ones(size(corr_mat, 1)),(1:1:size(corr_mat, 1)), 'k', 'LineStyle', '--'); hold off; pause(3);
    end
    
    choice_loop                  = questdlg('Would you like to select another location?', '', 'Yes', 'No', 'Yes');
    if (strcmp(choice_loop, 'No') == 1)
        loop_var = 0;
    end
end
end