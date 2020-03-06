function mask = fn_create_mask(param_list, trial, phys_var)
%% param_list
% 1. matlab_path
% 2. fiji_path
% 3. analysis_modules_list
% 4. input_data_folder
% 5. input_trials
% 6. input_phys_vars
% 7. analysis_module

%%
mask_options                    = {'No need to use a mask', 'Select previously created mask', 'Create a mask now'};
mask_choice                     = questdlg('How would you like to implement a mask?', 'Select Mask', mask_options{1}, mask_options{2}, mask_options{3}, mask_options{1});
folder_path                     = strcat(param_list{4}, '\', trial, '\', phys_var);
img_names                       = fn_read_names(folder_path);
temp_img                        = double(imread(strcat(folder_path, '\', img_names(1,:))));
switch mask_choice
    case ''
        mask                    = ones(size(temp_img));
        disp({'No mask was selected.'}); pause(3);
    case mask_options{1}
        mask                    = ones(size(temp_img));
        disp({'No mask was selected.'}); pause(3);
    case mask_options{2}
        [mask_name, mask_folder] = uigetfile('*.*', 'Please select the mask.');
        mask                     = double(imread(strcat(mask_folder, '\', mask_name)));
        disp(strcat('A mask at', {' '}, mask_folder, '\', mask_name, {' '}, 'was selected.')); pause(3);
    case mask_options{3}
        waitfor(msgbox(['Please left click on the periphery of the region that needs to be included. Complete a closed area. Then right click inside this region, and from the drop down list, select the create mask option.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(1);
        temp                     = temp_img(:);
        stemp                    = sort(temp);
        max_val                  = stemp(end);
        mask                       = roipoly(temp_img/max_val);
        disp({'Mask created!!!'}); pause(3);
end
end