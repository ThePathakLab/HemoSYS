function sortedImgNames = fn_sort_img_names_bt(imgNames,label, label2)                % Label until the image number starts. 

numImgs = size(imgNames, 1);
numMat = zeros(numImgs,1);
beginPosNum = size(label,2) + 1;                                           % First digit is just after the label ends.
sortedImgNames = cell(numImgs,1);

for i = 1:1:numImgs
    imgName = imgNames(i,:);
    endPosNum = beginPosNum;                                               % Starting from the beginPos search for the next occcurance of '-'
    while(~strcmp(imgName(1,endPosNum + 1),label2))
        endPosNum = endPosNum + 1;
    end
    
    numMat(i,1) = str2double(imgName(1,beginPosNum:endPosNum));            % Convert the image number intothe index 
    
    if (strcmp(label2, 's')||(strcmp(label2, '_')))
        numMat(i,1) = numMat(i,1) + 1;
    end
    sortedImgNames(numMat(i,1) ,1) = cellstr(imgNames(i,:));               % Assign image name to the propoer place in the sorted array
end

sortedImgNames = char(sortedImgNames);

