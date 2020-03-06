function fn_visualize_vessel_classes(class_list, num_segs, roi_img)

[num_rows, num_cols] = size(roi_img);
class_img_init      = zeros(num_rows, num_cols); 


for i = 1:1:num_segs
    seg             = (roi_img == i);
    class_img_init  = class_img_init + seg*class_list(i,1);
end




figure, imagesc(class_img_init, [-3 3]); colormap(jet); colorbar; grid on; axis image;