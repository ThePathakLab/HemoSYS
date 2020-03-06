function analysis_module    = fn_get_analysis_module(list)

[index,tf]                  = listdlg('PromptString','Please select an analysis module.','ListString',list, 'SelectionMode','single');
analysis_module             = 'none';

if tf == 1
          analysis_module   = list{index}; 
end
