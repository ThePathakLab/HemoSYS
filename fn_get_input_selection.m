function parameters = fn_get_input_selection(prompt, dlgtitle, dims, definput)

parameters = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(parameters)
    button = questdlg('Would you like to quit the program?', 'Exit Program', 'Yes', 'No', 'No');
    switch button
        case ''
            parameters = fn_get_input_selection(prompt, dlgtitle, dims, definput);
        case 'Yes'
            disp({'Quitting HemoSYS...'});
            pause(3);
            quit;
        case 'No'
            parameters = fn_get_input_selection(prompt, dlgtitle, dims, definput);
    end
end