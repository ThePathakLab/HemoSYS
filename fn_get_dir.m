function selected_folder = fn_get_dir(path, prompt)

selected_folder = uigetdir(path, prompt);
if selected_folder == 0
    button = questdlg('Would you like to quit the program?', 'Exit Program', 'Yes', 'No', 'No');
    switch button
        case ''
            selected_folder = fn_get_dir(path, prompt);
        case 'Yes'
            disp({'Quitting HemoSYS...'});
            pause(3);
            quit;
        case 'No'
            selected_folder = fn_get_dir(path, prompt);
    end
end
end