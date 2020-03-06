function fn_redraw(img_num, img_stack, min_val, max_val)
imagesc(squeeze(img_stack(:,:, img_num)), [min_val max_val]); grid on; colormap(jet); colorbar; axis image;