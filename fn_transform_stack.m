function img_stack_txd              = fn_transform_stack(img_stack, tx_string)
[num_cols, num_rows, num_imgs]      = size(img_stack);
img_stack_txd                       = zeros(num_rows, num_cols, num_imgs - 1);

if (strcmp(tx_string, 'Temporal Derivative'))
    img_stack_txd                   = diff(img_stack, 1, 3)./img_stack(:,:, 1: num_imgs - 1);
end

if (strcmp(tx_string, 'Actual Values'))
    mean_img                        = mean(img_stack, 3);
    mean_img_stack                  = repmat(mean_img, [1 1 size(img_stack, 3)]);
    img_stack_txd                   = img_stack./mean_img_stack;
end

%Add more options later.
img_stack_txd(isinf(img_stack_txd)) = 0;
img_stack_txd(isnan(img_stack_txd)) = 0;