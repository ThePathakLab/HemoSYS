function [selected_file, file_path] = fn_get_file(path, prompt)

[selected_file, file_path] = uigetfile(path, prompt);
if selected_file == 0
    button = questdlg('Would you like to quit the program?', 'Exit Program', 'Yes', 'No', 'No');
    switch button
        case ''
            [selected_file, file_path] = fn_get_file(path, prompt);
        case 'Yes'
            disp({'Quitting HemoSYS...'});
            pause(3);
            quit;
        case 'No'
            [selected_file, file_path] = fn_get_file(path, prompt);
    end
end
end