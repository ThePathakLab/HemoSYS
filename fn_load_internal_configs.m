function internal_configs_list          = fn_load_internal_configs
analysis_modules_list                   = {'Propagation analysis', 'Cluster analysis', 'Coupling analysis', 'Perturbation analysis', 'Fourier analysis'}; %, 'Test analysis' };
matlab_path                             = 'C:\Program Files\MATLAB\';                                           %Where Matlab is installed in the PC.
dummy_path                              = '';
internal_configs_list                   = {matlab_path, dummy_path, analysis_modules_list};                      %Create the internal_configs_list