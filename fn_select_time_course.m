function []                         = fn_select_time_course(zero_img, img_stack, resize_scale, phys_var, time_res, option)
grid_size                           = 1/resize_scale;

%% FIGURE B
[num_rows_ds, num_cols_ds]          = size(imresize(zero_img, resize_scale));
loop_var                            = 1; 
legend_array                        = [];

while(loop_var)
    h                               = figure; 
    h.NumberTitle                   = 'off'; 
    movegui(h, 'north'); 
    imagesc(zero_img); axis image; colormap(gray); colorbar; axis image; grid on; title(strcat(phys_var, {' '}, '(t = 0 min)')); hold on;
    ax                              = gca;
    ax.XTick                        = 0:grid_size: num_cols_ds*grid_size; 
    ax.YTick                        = 0:grid_size: num_rows_ds*grid_size;
    [x,y]                           = ginput(1); 
    plot((1:1:size(zero_img, 2)), y*ones(size(zero_img, 2)), 'y', 'LineStyle', '--'); plot(x*ones(size(zero_img, 1)),(1:1:size(zero_img, 1)), 'y', 'LineStyle', '--'); hold off;
    x                               = max(floor(x / grid_size), 1); 
    y                               = max(floor(y / grid_size), 1);
    
    %% FIGURE C
    img_stack_txd                   = fn_transform_stack(img_stack, option);
    trace                           = 100 * img_stack_txd(y, x, :);
    legend_array                    = vertcat(legend_array, strcat('S(', num2str(x, '%02.0f'), ',', num2str(y, '%02.0f'), ')'));
    h = figure(999); h.NumberTitle = 'off'; movegui(h, 'northeast'); plot(time_res * (1:1:length(trace)), squeeze(trace)); grid on; xlabel('Time (min)'); ylabel(strcat(option, {' '},'(%)')); legend(legend_array); hold on;
    
    choice_loop                     = questdlg('Would you like to select another location?', '', 'Yes', 'No', 'Yes');
    if (strcmp(choice_loop, 'No') == 1)
        loop_var = 0;
        hold off;
    end
end
end