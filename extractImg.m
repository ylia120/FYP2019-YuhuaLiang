function [G0,lines] = extractImg(v,n)
    % extract edge detected frames(G0) by video source(v) and number of
    % frame(n); also outputting a structure of hough line(lines), which
    % include the end points, the position from the left edge, and rotation
    % angle from the vertical line of each straight line
    frame = read(v,n);
    frame = imcrop(frame,[420,70,980,2200]);
    frame = rgb2gray(frame);
    k = (1/159)*[2 4 5 4 2; 4 9 12 9 4; 5 12 15 12 5; 4 9 12 9 4; 2 4 5 4 2];
    B = kernel(frame,k);

    xs = [-1 0 1; -2 0 2; -1 0 1];
    ys = [-1 -2 -1; 0 0 0; 1 2 1];
    Bx = kernel(B,xs);
    By = kernel(B,ys);
    G = sqrt(Bx.^2+By.^2);
    sigma = round(atan2d(By,Bx)/45)*45;
    
    [p,q]=size(G);
    G0 = G;
    for i=2:p-1 
        for j=2:q-1
            if abs(sigma(i,j))==0 || abs(sigma(i,j))==180
                if (G(i,j)<=G(i,j+1)) || (G(i,j)<=G(i,j-1))
                    G0(i,j)=0;
                end
            elseif abs(sigma(i,j))==90
                if (G(i,j)<=G(i+1,j)) || (G(i,j)<=G(i-1,j))
                    G0(i,j)=0;
                end
            elseif sigma(i,j)==135 || sigma(i,j)==-45
                if (G(i,j)<=G(i-1,j+1)) || (G(i,j)<=G(i+1,j-1))
                    G0(i,j)=0;
                end
            elseif sigma(i,j)==45 || sigma(i,j)==-135
                if (G(i,j)<=G(i+1,j+1)) || (G(i,j)<=G(i-1,j-1))
                    G0(i,j)=0;
                end
            end
        end
    end
    G0(G0<=mean(mean(G0(G0~=0)))) = 0;
    thre = median(median(G0(G0~=0)));
    G0(G0<=thre) = 0;
    G0(G0>thre) = max(max(G0));
    % one more x-conv to filter horizontal elements
    G0 = kernel(G0,xs);
    
    % mean and median filter for straight lines
    % using mean to eliminate the values which are too small, e.g. e-14
    % using median to find the threshold
    % one more x-conv to enhance vertical elements
    G0 = kernel(G0,xs);
    G0(G0<=mean(mean(G0(G0~=0)))) = 0;
    thre = median(median(G0(G0~=0)));
    G0(G0<=thre) = 0;
    G0(G0>thre) = max(max(G0));

    
    
    
    % detect straight lines by hough transform. lines include the edge points, 
    % angle to the vertical lines, and the distance to the left edge of image
    [H,T,R] = hough(G0);
    P = houghpeaks(H,6,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(G0,T,R,P,'FillGap',5,'MinLength',7);
    
    if length(lines) == 0
        return
    end
    % check the angle and rotate to vertical
    if mean([lines.theta])~=0
        G0 = imrotate(G0,mean([lines.theta]));
    end
    
    % output the corrected lines
    [H,T,R] = hough(G0);
    P = houghpeaks(H,6,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(G0,T,R,P,'FillGap',5,'MinLength',7);
    
    
    
    % imcrop that only outputting the part of strings
    x1_cord = zeros(1,length(lines));
    y1_cord = zeros(1,length(lines));
    x2_cord = zeros(1,length(lines));
    y2_cord = zeros(1,length(lines));
    points1 = [lines.point1];
    points2 = [lines.point2];
    
    for k = 1:length(lines)      
        x1_cord(k) = points1(2*k-1);
        y1_cord(k) = points1(2*k);
        x2_cord(k) = points2(2*k-1);
        y2_cord(k) = points2(2*k);
    end
    originY = median(y1_cord);
    x1_cord = min([lines.rho]);
    x2_cord = max([lines.rho]);
    
    G0 = imcrop(G0,[x1_cord-50,originY,x2_cord-x1_cord+100,(max(y2_cord)-originY)]);
    
    % output the corrected lines
    [H,T,R] = hough(G0);
    P = houghpeaks(H,6,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(G0,T,R,P,'FillGap',5,'MinLength',7);
end