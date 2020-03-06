function timeStamp = fn_extract_timestamp_bt(imgName,label)                   % Label until the image number starts. 

beginPosNum = size(label,2) +1;                                           % First digit is just after the label ends.                  
endPosNum = beginPosNum;
while(~strcmp(imgName(1,endPosNum + 1),'-'))                               % Starting from the beginPos search for the next occcurance of '-'. End of the image number representation.
    endPosNum = endPosNum + 1;
end
beginPosNum = endPosNum + 2;                                               % Beginning of the time stamp.
endPosNum = size(strtrim(imgName),2) - 4;                                  % End of the time stamp.
timeString = imgName(1, beginPosNum: endPosNum);                           % String contianing the time.

hourStamp = str2double(timeString(1,1:2));                                 % Extract hour stamp. 

beginPosNum = 4;                                                           % Extract min stamp.
endPosNum = 4;
if(~strcmp(timeString(1,endPosNum + 1),'-'))
    endPosNum = endPosNum + 1;
end
minStamp = str2double(timeString(1,beginPosNum: endPosNum));

beginPosNum = endPosNum + 2;                                               % Extract sec stamp.
endPosNum = beginPosNum;
if(~strcmp(timeString(1,endPosNum + 1),'-'))
    endPosNum = endPosNum + 1;
end
secStamp = str2double(timeString(1,beginPosNum: endPosNum));

beginPosNum = endPosNum + 2;                                               % Extract mil stamp.
endPosNum = size(timeString,2);
milStamp = str2double(timeString(1,beginPosNum: endPosNum));

timeStamp = hourStamp*3600 + minStamp*60 + secStamp + milStamp*0.001;      % Calculate total time stamp in secs.
