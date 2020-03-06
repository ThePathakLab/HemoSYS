function [img_names, num_imgs] = fn_read_names(pathname)
%Function description.
%Takes the path of the folder and returns all the names of the images in
%it.

%Function specifications.
%%'pathname' needs to have a backward slash at the end.

%Function state space.
%Null.

%Function implementation.
if ispc
    img_names                   = ls(pathname);
    [r, ~]                      = size(img_names);
    img_names                   = img_names(3:r,:);
elseif ismac
    img_names                   = cell2mat(pad(strsplit(strip(ls(pathname)),{'\n','\t'}))');
end
[num_imgs, ~]                   = size(img_names);