% _1 was added after mean correction for seg_vec.
function class_list = fn_class_type_svd(corr_mat, num_svds_to_use)

num_segs            = size(corr_mat,1);

%SVD
[U,S,V]             = svd(corr_mat);

%Pick prominant ones.
svd_mat             = U(:, 1: num_svds_to_use);

%Classify seeds to these prominant ones.
class_list           = zeros(num_segs, 1);

mean_mat             = mean(corr_mat, 1);

for i = 1:1:num_segs
    seg_vec         = corr_mat(i,:);
    mul_vals        = (seg_vec - mean_mat)*svd_mat;
    mul_vals_abs    = abs(mul_vals);
    [~, index]      = max(mul_vals_abs);
    sgn             = mul_vals_abs(index)/ mul_vals(index);
    sgn(isnan(sgn)) = 0;                                                    %if max val is zero, class will become zero.                                                       
    sgn(isinf(sgn)) = 0;
    class_list(i,1) = sgn*index;
end