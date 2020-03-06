function [x, y, choice_roi] = fn_select_roi(temp_img, phys_var, color_map)
choice_roi                              = questdlg('Would you like to select a rectangular region of interest (ROI)?', 'ROI Selection', 'Yes', 'No', 'Yes');
repeat                                  = 'Reselect';
switch choice_roi
    case 'Yes'
        while strcmp(repeat, 'Reselect') == 1
            close; h = figure; movegui(h,'north'); h.NumberTitle = 'off';
            imagesc(temp_img), colormap(color_map), colorbar; grid on; axis image; title(cellstr(phys_var)); hold on;
            
            % Prompt the user to select the ROI.
            disp({'Selecting a region to analyze data...'});
            waitfor(msgbox(['To select a rectangular region for analysis, please click two points.' sprintf('\n') sprintf('\n') 'The first point defines the top left corner of the region.' sprintf('\n') sprintf('\n') 'The second point defines the bottom right corner of this region.' sprintf('\n') sprintf('\n') 'Please click OK to continue.']));
            [x, y]                      = ginput(2); 
            x                           = max(floor(x), 1); 
            y                           = max(floor(y), 1);
            
            if (y(2) > y(1) && x(2) > x(1))
                disp(strcat('Top left corner:', {' '}, '(',num2str(x(1)),',', num2str(y(1)),'.)' ,{' '}, 'Bottom right corner:', {' '}, '(', num2str(x(2)), ',', num2str(y(2)), ').'));
                rectangle('Position',[x(1), y(1), abs(x(2) - x(1)), abs(y(1) - y(2))], 'EdgeColor', 'Black', 'LineStyle', '--');
                hold off; pause(3);
                repeat = questdlg('Would you like to continue or reselect the ROI?', 'ROI Selection', 'Continue', 'Reselect', 'Continue'); pause(3);
            else
                waitfor(msgbox(['Invalid selected rectangular region.' sprintf('\n') sprintf('\n') 'Please click OK to continue.'])); pause(3);
                repeat = 'Reselect';
            end
        end
    otherwise
        x = [1 size(temp_img, 2)]; y = [1 size(temp_img, 1)];
end
end