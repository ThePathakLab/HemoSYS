function selection = fn_get_list_selection(prompt, list)

[index,tf] = listdlg('PromptString', prompt, 'ListString', list, 'SelectionMode', 'single');
selection = ''; % default selection

if tf == 1
    selection = list{index};
elseif tf == 0
    button = questdlg('Would you like to quit the program?', 'Exit Program', 'Yes', 'No', 'No');
    switch button
        case ''
            selection = fn_get_list_selection(prompt, list);
        case 'Yes'
            disp({'Quitting HemoSYS...'});
            pause(3);
            quit;
        case 'No'
            selection = fn_get_list_selection(prompt, list);
    end
end