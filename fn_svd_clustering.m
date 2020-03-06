function [] = fn_svd_clustering(processing_specs, img_stack, mask, phys_var, num_blocks, color_map, r_value, option)
%% param_list
% 1. matlab_path
% 2. fiji_path
% 3. analysis_modules_list
% 4. input_data_folder
% 5. input_trials
% 6. input_phys_vars
% 7. analysis_module

%%
block_size                          = str2double(processing_specs{2});
loop_var                            = 1;
[num_rows, num_cols, ~]             = size(img_stack);

while(loop_var)
    prompt                              = {'Enter the number of singular values to use for SVD:', 'Enter the size threshold for each cluster:'};
    dlgtitle                            = 'Please enter the clustering specifications:';
    dims                                = [1 35];
    definput                            = {'5', '0.05'};
    clustering_specs                    = fn_get_input_selection(prompt, dlgtitle, dims, definput); pause(3);
    num_svds_to_use                     = str2double(clustering_specs{1});
    size_threshold_original             = str2double(clustering_specs{2});
    disp(strcat('Clustering specs:', {' '}, 'Singular Values to Use for SVD =', {' '}, num2str(num_svds_to_use), ',', {' '}, 'Cluster Size Threshold', {' '}, '=', {' '}, num2str(size_threshold_original), {'.'} )); pause(3);
    
    for block = 1:1:num_blocks
        start_index                     = block_size * (block - 1) + 1;
        end_index                       = start_index + block_size - 1;
        img_stack_block                 = img_stack(:, :, start_index:end_index);
        img_stack_txd                   = fn_transform_stack(img_stack_block, option);
        
        num_imgs                        = size(img_stack_txd, 3);
        num_pix                         = sum(mask(:) > 0, 1);
        val_list                        = zeros(num_pix, num_imgs);
        corr_mat                        = zeros(num_rows, num_cols);
        corr_mat_final                  = zeros(num_pix, num_pix);
        
        loc_mat_r                       = repmat((1:1:num_rows)', [1 num_cols]);
        loc_mat_c                       = repmat(1:1:num_cols, [num_rows 1]);
        loc_list_r                      = loc_mat_r(mask > 0);
        loc_list_c                      = loc_mat_c(mask > 0);
        
        for p = 1:1:num_pix
            seed_trace                  = squeeze(img_stack_txd(loc_list_r(p), loc_list_c(p), :));
            for i = 1:1:num_rows
                for j = 1:1:num_cols
                    vals                = squeeze(img_stack_txd(i,j,:));
                    val_list(p, :)      = seed_trace';
                    [temp1, temp2]      = corrcoef(vals, seed_trace);
                    corr_val            = temp1(1,2);
                    pval                = temp2(1,2);
                    corr_val(isnan(corr_val)) = 0;
                    corr_val(isinf(corr_val)) = 0;
                    corr_val            = max( min(corr_val, 1),-1);
                    corr_mat(i,j)       = corr_val*(pval <= 0.01);
                end
            end
            corr_mat_final(p, :)        = (corr_mat(mask > 0))';
        end
        
        size_threshold                  = floor(num_pix * size_threshold_original);
        area_list                       = ones(num_pix, 1);
        total_area                      = sum(area_list);
        
        class_list                      = fn_class_type_svd(corr_mat_final, num_svds_to_use);
        max_num_classes                 = 2*num_svds_to_use;
        class_labels                    = [(-1*num_svds_to_use:1:-1)'; (1:1:num_svds_to_use)'];
        
        roi_img                         = zeros(num_rows, num_cols);
        for p = 1:1:num_pix
            roi_img(loc_list_r(p), loc_list_c(p)) = p;
        end
        
        cont = 1;
        while(cont > 0)
            tic
            
            class_count                 = size(class_labels,1);
            class_time_traces           = zeros(class_count, num_imgs);
            for i = 1:1:class_count
                segs_in_class           = find(class_list == class_labels(i,1));
                time_traces_in_class    = val_list(segs_in_class,:);
                areas_in_class          = area_list(segs_in_class, 1);
                areas_in_class_mat      = repmat(areas_in_class, [1 num_imgs]);
                avg_time_trace_for_class = sum(areas_in_class_mat.*time_traces_in_class, 1)/ sum(areas_in_class,1);
                avg_time_trace_for_class(isnan(avg_time_trace_for_class)) = 0;
                class_time_traces(i,:) = avg_time_trace_for_class;
            end
            
            cc_mat                      = zeros(num_pix, class_count);
            for i = 1:1:num_pix
                for j = 1:1:class_count
                    [temp1, temp2]      = corrcoef(val_list(i,:)', class_time_traces(j,:)');
                    r                   = temp1(2,1);
                    p_val               = temp2(2,1);
                    cc_mat(i,j)         = r*(p_val < 0.01);
                end
            end
            cc_mat(isnan(cc_mat))       = 0;
            
            [max_cc_list, temp_new_class_list_indices]= max(cc_mat, [], 2);
            
            temp_new_class_list         = zeros(num_pix, 1);
            for i = 1:1:num_pix
                temp_new_class_list(i,1) = class_labels(temp_new_class_list_indices(i,1));
            end
            temp_new_class_list         = temp_new_class_list.*(max_cc_list ~= 0);
            
            for i = 1:1:class_count
                area_indices            = (temp_new_class_list == class_labels(i,1));
                temp_class_size         = 100*sum(area_list(area_indices))/total_area;
                
                if (temp_class_size < size_threshold)
                    temp_new_class_list = temp_new_class_list.*(temp_new_class_list ~= class_labels(i,1));
                end
            end
            
            new_class_list              = temp_new_class_list;
            temp_new_class_labels       = zeros(max_num_classes,1);
            temp_new_class_count        = 0;
            
            for i = -1*num_svds_to_use:1:-1
                if (sum((new_class_list == i)) > 0)
                    temp_new_class_count = temp_new_class_count + 1;
                    temp_new_class_labels(temp_new_class_count, 1) = i;
                end
            end
            
            for i = 1:1:num_svds_to_use
                if (sum((new_class_list == i)) > 0)
                    temp_new_class_count = temp_new_class_count + 1;
                    temp_new_class_labels(temp_new_class_count, 1) = i;
                end
            end
            new_class_labels            = temp_new_class_labels(1 : temp_new_class_count,1);
            
            cont = cont + 1;
            if(sum(new_class_list ~= class_list)== 0)
                cont = 0;
            end
            
            class_list                  = new_class_list;
            class_labels                = new_class_labels;
            class_count                 = temp_new_class_count;
            
            toc
        end
        
        class_time_traces               = zeros(class_count, num_imgs);
        class_sizes                     = zeros(class_count, 1);
        
        for i = 1:1:class_count
            segs_in_class               = find(class_list == class_labels(i,1));
            time_traces_in_class        = val_list(segs_in_class,:);
            areas_in_class              = area_list(segs_in_class, 1);
            areas_in_class_mat          = repmat(areas_in_class, [1 num_imgs]);
            avg_time_trace_for_class    = sum(areas_in_class_mat.*time_traces_in_class, 1)/ sum(areas_in_class,1);
            avg_time_trace_for_class(isnan(avg_time_trace_for_class))= 0;
            class_time_traces(i,:)      = avg_time_trace_for_class;
            class_sizes(i, 1)           = sum(areas_in_class,1);
        end
        
        [~, I]                          = sort(class_sizes);
        class_unif_labels               = zeros(class_count, class_count);
        for i = 1:1:class_count
            for j = 1:1:class_count
                [temp1, temp2]          = corrcoef(class_time_traces(i,:)', class_time_traces(j,:)');
                r                       = temp1(2,1); 
                p_val                   = temp2(2,1);
                class_unif_labels(i,j)  = i*(r > r_value)*(p_val < 0.01);
                if (class_unif_labels(i,j) == 0)
                    class_unif_labels(i,j) = j;
                end
            end
            class_unif_labels(i,i)      = i;
        end
        
        for i = 1:1:class_count
            for j = 1:1:class_count
                class_unif_labels(i,j)  = find(I == class_unif_labels(i,j));
            end
        end
        
        unif_labels                     = max(class_unif_labels, [],1);
        new_unif_labels                 = zeros(1, class_count);
        for i = 1:1:class_count
            new_unif_labels(1,i)        = class_labels(I(unif_labels(1,i)));
        end
        
        new_class_labels                = new_unif_labels';
        new_class_list                  = zeros(num_pix, 1);
        
        for i = 1:1:num_pix
            old_class                   = class_list(i,1);
            class_loc                   = find(class_labels == old_class);
            if (class_loc > 0)
                new_class_list(i, 1)    = new_class_labels(class_loc, 1);
            end
        end
        
        class_list                      = new_class_list;
        class_labels                    = unique(new_class_labels);
        class_count                     = size(unique(class_labels), 1);
        class_img                       = fn_get_classes_img(class_list, num_pix, roi_img);
        class_img_relabelled            = zeros(size(class_img));
        class_relabels                  = (1:1:class_count)';
        
        for i = 1:1:num_rows
            for j = 1:num_cols
                temp                    = class_img(i,j);
                if (temp ~= 0)
                    index               = find(class_labels == temp, 1, 'first');
                    class_img_relabelled(i,j) = class_relabels(index);
                end
            end
        end
        
        h = figure; movegui(h, 'south');
        imagesc(class_img_relabelled); colormap(color_map); colorbar; grid on; axis image; title(strcat('Major Vasodilation Clusters of', {' '}, phys_var, {' '}, 'at Period', {' '}, num2str(block)));
    end
    
    choice_loop                         = questdlg('Would you like to reidentify clusters?', '', 'Yes', 'No', 'Yes');
    if (strcmp(choice_loop, 'No') == 1)
        loop_var = 0;
    end
end
end