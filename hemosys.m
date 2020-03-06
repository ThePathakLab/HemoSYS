%% hemosys.m
%Run this script to begin the HemoSYS toolkit.
%For further information please visit us at http://www.pathaklab.org/HemoSYS/

clear all;
close all;
clc;

%%
%Add the relevant folder paths to the MATLAB environment.
all_sub_folders_path                    = genpath(pwd);
addpath(all_sub_folders_path);

%internal_configs_list: matlab_path, fiji_path, analysis_modules_list
internal_configs_list                   = fn_load_internal_configs;                                             %Load the internal configurations needed for HemoSYS modules. Returns a list of configs.

%Prompts the user to pick an analysis module
analysis_module                         = fn_get_list_selection('Please select a module:', internal_configs_list{3}); pause(3);

input_data_folder                       = fn_get_dir(pwd, 'Please select an input data folder:'); pause(3);     %Prompts the user to select a data input folder.
[input_trials, input_phys_vars]         = fn_find_input_data_types(input_data_folder);                          %Extracts the number of trials and the types of physiological variables.
disp(strcat(input_data_folder, {' '}, 'is selected as the input data folder.'));

input_param_list                        = {input_data_folder, input_trials, input_phys_vars, analysis_module};  %Generate a list summarizing all input specs.
param_list                              = [internal_configs_list, input_param_list];                            %Generate a master list with all internal config and input parameters to be passed onto each HemoSYS module.

switch analysis_module
    case 'Propagation analysis'
        fn_propagation_analysis(param_list);
        
    case 'Cluster analysis'
        fn_cluster_analysis(param_list);
        
    case 'Coupling analysis'
        fn_coupling_analysis(param_list);
        
    case 'Perturbation analysis'
        fn_perturbation_analysis(param_list);
        
    case 'Fourier analysis'
        fn_fourier_analysis(param_list);
        
    case 'Test analysis'
        
        %Add more modules here. Also, add the new module names in the 'fn_load_internal_configs'.
end