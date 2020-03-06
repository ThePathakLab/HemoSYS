function [input_trials, input_phys_variables]   = fn_find_input_data_types(input_data_folder)

%First level is the collection of individual trials.
input_trials                                    = fn_read_names(input_data_folder);
%Second level is the types of variables used.
input_phys_variables                            = fn_read_names(strcat(input_data_folder, '\', input_trials(1,:)));

for i = 1:1:size(input_phys_variables, 1)
    % Output folder is also found on second level.
    if ~isempty(strfind(input_phys_variables(i, :), 'Outputs'))
        input_phys_variables(i, :) = [];
    end
end