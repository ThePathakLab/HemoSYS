function [] = fn_gfp_disp(input_data_folder, trial) % Prompt the user to select an image showing the tumor extend if they have one.
choice_tumor_img                        = questdlg('Would you like to visualize the tumor extent (only if you have an image)?', 'Tumor Image Display', 'Yes', 'No', 'Yes');
pause(3);
switch choice_tumor_img
    case 'Yes'
        old_path                        = cd(strcat(input_data_folder, '\', trial));
        [file, path]                    = fn_get_file('*.*', 'Please select the tumor image:'); % Prompts the user to select a data input folder.
        tumor_img_path                  = strcat(path, '\', file);
        cd(old_path);
        tumor_img                       = double(imread(tumor_img_path));
        h = figure; movegui(h, 'northwest'); h.NumberTitle = 'off';
        green_map = zeros(64, 3); green_map(:, 2) = 0:1/63:1;
        imagesc(tumor_img); colormap(green_map); colorbar; grid on; axis image; title('Tumor image');
        disp({'Displaying the tumor image...'});
    case 'No'
        disp({'A tumor image is not displayed...'});
    case ''
        disp({'A tumor image is not displayed...'});
end
end