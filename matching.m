function [note] = matching(strTemp)
    % strTemp - detected vibrating string from video
    % match with dictionary and find out which is the vibrating string
    load string3.mat;
    % [waveLength,waveNumber] = size(str);
    [row, col] = size(str);
    if length(strTemp) <= row
        waveLengthTemp = length(strTemp);
        str = abs(str(1:waveLengthTemp,:));
    else
        waveLengthTemp = row;
        strTemp = abs(strTemp(1:waveLengthTemp));
    end
    
    dotProductArr = zeros(col,waveLengthTemp);
    dotProductArrTemp = zeros(col,1);
    for i=1:col
        str(:,i) = str(:,i)./norm(str(:,i));
    end
    
    strTemp = strTemp./norm(strTemp);
    for i=1:col
        for j=1:waveLengthTemp
            dotProductArr(i,j) = mean(strTemp(j:waveLengthTemp).*str(1:waveLengthTemp-j+1,i));
        end
    end

    % find the max of each row in dotProductArr, produce [6*1]
    % then find the max of the 6 numbers
    for i=1:col
        dotProductArrTemp(i) = max(dotProductArr(i,:));
    end
    [val,noteIdx] = max(dotProductArrTemp);
    switch noteIdx
        case 1
            note = 'G';
        case 2
            note = 'A';
        case 3
            note = 'B';
        case 4
            note = 'C';
    end
end