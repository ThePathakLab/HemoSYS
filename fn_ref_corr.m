function [r_img]      = fn_ref_corr(img_stack, ref_trace)

[num_rows, num_cols, ~] = size(img_stack);

r_img                   = zeros(num_rows, num_cols);

ref_trace               = squeeze(ref_trace);
for i = 1:1:num_rows
    for j = 1:1:num_cols
        trace           = squeeze(img_stack(i,j,:));
        [temp1, temp2]   = corrcoef(trace, ref_trace);  
        corr_val        = temp1(1,2);
        pval            = temp2(1,2);
        corr_val(isnan(corr_val)) = 0;
        corr_val(isinf(corr_val)) = 0;
        corr_val        = max( min(corr_val, 1),-1);
        r_img(i,j)      = corr_val*(pval <= 0.01);
    end
end

