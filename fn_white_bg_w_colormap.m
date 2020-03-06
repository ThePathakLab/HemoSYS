function img_out = fn_white_bg_w_colormap(img_in, min_val, max_val, mask, mapname)

color_levs           = 64;
[num_rows, num_cols] = size(img_in);
img_colord            = ones(num_rows, num_cols, 3);

figure(999)
cmap                 = colormap(mapname);
close(999)

img_in_normd         = floor((color_levs - 1)*max(min((img_in - min_val)/(max_val - min_val), 1),0));
img_in_normd         = img_in_normd + 1;

for i = 1:1:num_rows
    for j = 1:1:num_cols
        img_colord(i,j,1:3) = cmap(img_in_normd(i,j),1:3);
    end
end

mask_mat = repmat(mask, [1 1 3]);
img_out = mask_mat.*img_colord + (1 - mask_mat);