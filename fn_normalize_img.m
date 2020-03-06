function img_n = fn_normalize_img(img, p)

img_lin     = img(:);
img_lin     = sort(img_lin);
num_pix     = size(img_lin,1);

lb          = img_lin(ceil(0.5*p*num_pix), 1);
ub          = img_lin(ceil((1 - 0.5*p)*num_pix), 1);
range       = ub - lb;

img_n       = (img - lb)/range;
img_n       = max(min(img_n, 1), 0);
