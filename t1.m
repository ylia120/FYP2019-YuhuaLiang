clear all;clc;close all;

% video input
v = VideoReader('test1-GABC-1.mov');
n = v.NumberOfFrames;
fps = 2;
amplitude = zeros(6,round(n/fps));
vibraIdxArr = zeros(1,length(1:fps:n));
calibArr = zeros(1,length(1:fps:n));

% iteration set for testing
test1 = round([2.5*n/22:fps:3.5*n/22, 7.5*n/22:fps:8.5*n/22, 11.5*n/22:fps:12.5*n/22 16.5*n/22:fps:17.5*n/22]);
test2 = round([2.5*n/22:fps:3.5*n/22, 7.5*n/22:fps:8.5*n/22, 12.5*n/22:fps:13.5*n/22 16.5*n/22:fps:17.5*n/22]);
test3 = round([2.5*n/21:fps:3.5*n/21, 6.5*n/21:fps:7.5*n/21, 11.5*n/21:fps:12.5*n/21 15.5*n/21:fps:16.5*n/21]);
test4 = round([2.5*n/17:fps:3.5*n/17, 6.5*n/17:fps:7.5*n/17, 8.5*n/17:fps:9.5*n/17 11.5*n/17:fps:12.5*n/17]);
test5 = round([1.5*n/31:fps:2.5*n/31, 5.5*n/31:fps:6.5*n/31, 8.5*n/31:fps:9.5*n/31 11.5*n/31:fps:12.5*n/31 14.5*n/31:fps:15.5*n/31 18.5*n/31:fps:19.5*n/31 22.5*n/31:fps:23.5*n/31 24.5*n/31:fps:25.5*n/31]);

% program starts
for f = test1
    [G0,lines] = extractImg(v,f);

    [imgHeight,imgWidth] = size(G0);
    sampRate = 5;
    sampTemp = zeros(round(imgHeight/sampRate)-1,imgWidth);

    % sample the image with sampling rate, along the direction of strings
    for i=1:(round(imgHeight/sampRate))-1
        sampTemp(i,:) = mean(G0((i*sampRate-sampRate+1):(i*sampRate),:));
    end
    strLoc = [];

    % detect the string location
    % go through all rows so that the "width" of strings can be identified as well
    for i=1:(round(imgHeight/sampRate)-1)
        indexVec = sampTemp(i,:);
        startPoint = 0;
        endPoint = 0;
        % go through all columns to detect the strings
        for j=1:imgWidth-1
            % if index is not continuous, startPoint start counting 
            % and be stored while the index is continuous
            if (indexVec(j) == 0) && (indexVec(j+1) ~= 0)
                startPoint = j+1;
            end
            % if index is continuous, endPoint start counting 
            % and be stored while the index is not continuous
            if (indexVec(j) ~= 0) && (indexVec(j+1) == 0)
                endPoint = j;
            end
            % 33 88 143 202 259 317
            % detect any pixels in continuous, calculate their middles
            % and put their column index into an array, strLoc
            if (endPoint > startPoint) && (indexVec(j) == 0)
                midPoint = (endPoint+startPoint)/2;
                strLoc = [strLoc midPoint];
            end
        end
    end

    thickness = endPoint-startPoint;
    % eliminate the repeated data and sort
    strLoc = unique(round(strLoc));
    strLoc = [strLoc 0];
    
    %%
    % detect the vibrating string as the string has largest amplitude, which means widest
    count = 0;
    vibraArr = [];
    midLineArr = [];
    for i=1:length(strLoc)-1
        % difference equals to 1 - continuous
        % count - the width that from peak to peak
        if abs(strLoc(i+1)-strLoc(i)) < mean(abs(diff(strLoc)))
            count = count + 1;
        end
        if abs(strLoc(i+1)-strLoc(i)) > mean(abs(diff(strLoc)))
            % vibraArr [1*6 double] - width of the region of each single string
            vibraArr = [vibraArr ((strLoc(i)+round(2*thickness)))-(strLoc(i-count)-round(2*thickness))];
            % midLineArr [1*6 double] - the index of 'mean' of the string wave
            midLineArr = [midLineArr (((strLoc(i)+round(2*thickness)))+(strLoc(i-count)-round(2*thickness)))/2];
            count = 0;
        end
    end
    % vibraIdx - the index of string that is vibrating
%     gap = diff(vibraArr);
%     vibraIdxTemp = find(min(gap));
    [maxVal, vibraIdx] = max(vibraArr);
%     if ~((vibraIdx==vibraIdxTemp+1)||(vibraIdx==vibraIdxTemp-1))
%         vibraIdx = 0;
%     end

    %% the region of single string from peak to peak
    strRegion = zeros(1,2*length(midLineArr));
    % strRegion in the pattern of [min1 max1 min2 max2 ....]
    peakTemp = [];
    for i=1:length(midLineArr)
        for j=1:length(strLoc)-2
            if i >= 2
                % locTemp - the index of previous max in strLoc
                % so that the iteration can start from current min
                locTemp = find(strLoc==strRegion(2*i-2));
                k = locTemp + j;
            else
                k = j;
            end

            % peakTemp - a temp of index of pixels for each string
            % two pixels distance larger than 2, and the difference between 
            % the mean of min and max, and the defined 'mean' of the string 
            % wave is smaller than 5, 
            % count the region by just the peak
            if k<=length(strLoc)-1
                peakTemp(j) = strLoc(k);
                % improvement: comparator for two pixels distance can be
                % defined by mean of max and min distance
                if abs(strLoc(k+1)-strLoc(k)) > mean(abs(diff(strLoc))) && abs((max(peakTemp)+min(peakTemp))/2 - midLineArr(i)) <= 5
                    peakTemp = nonzeros(peakTemp);
                    strRegion(2*i-1) = min(peakTemp);
                    strRegion(2*i) = max(peakTemp);
                    break
                end
            end
        end
        clear peakTemp;
    end

    %% convert data into waveform
    % magnitude between each point to the mean placed on rows
    % strings placed on columns
    strWave = zeros(imgHeight,length(midLineArr));
    for j=1:length(midLineArr)
        for i=1:imgHeight
            midTempArr = [];
            % midTempArr - find the index of pixel of individual string 
            % from the image, by the peaks found on strRegion
            midTempArr = find(G0(i,strRegion(2*j-1):strRegion(2*j)));
            % initially index start from the min of the individual string region
            % merge with (strRegion(2*j-1) - 1) so that the index start from the image
            % (strRegion(2*j-1) - 1) min of current string region
            midTempArr = midTempArr + strRegion(2*j-1) - 1;
            if isempty(midTempArr)
                continue
            end
            % mean of this row of pixel, representing the data with a single
            % value as a sample point in discrete signal
            midTemp = (max(midTempArr)+min(midTempArr))/2;
            % magnitude between each point to the mean, calculated by index,
            % also means the distance of pixels
            strWave(i,j) = midLineArr(j) - midTemp;
        end
    end

    %% reconstruct the burst peaks of vibrating string
    % magnitude difference between each sample point
    d = diff(strWave(:,vibraIdx));
    d = mean(abs(nonzeros(d)));
    % reconstruct the peak with the magnitude difference if it is burst
    [peak,idx] = max(strWave(:,vibraIdx));
    if idx == 1
        idx = 2;
    end
    if peak-strWave(idx-1,vibraIdx)>=d
        peak = strWave(idx-1,vibraIdx)+d;
        strWave(idx,vibraIdx) = peak;
    end
    [peak,idx] = min(strWave(:,vibraIdx));
    if idx == 1
        idx = 2;
    end
    if strWave(idx-1,vibraIdx)-peak>=d
        peak = strWave(idx-1,vibraIdx)-d;
        strWave(idx,vibraIdx) = peak;
    end

    %% virtual period and calibration
%     for i=1:length(midLineArr)
%         if f>fps
%             f_temp = (f-1)/fps;
%         else
%             f_temp = f;
%         end
%         amplitude(i,f_temp)=(max(max(strWave(:,i)))-min(min(strWave(:,i))))/2;
%     end
    
%     if f>fps
%         f_temp = (f-1)/fps;
%     else
%         f_temp = f;
%     end
%     calib = mean(diff(unique([lines.rho])));
%     calibArr(f_temp) = calib;

%% resulting
    [note] = matching(strWave(:,vibraIdx));
    note=append(note,'-frames-',num2str(f),'_',num2str(n))
end







%%
% figure;
% imshow(G0);
% hold on
% 
% for k = 1:length(lines)
%     xy = [lines(k).point1; lines(k).point2];
% 
%     plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
% 
%     % Plot beginnings and ends of lines
%     plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
%     plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
% end
