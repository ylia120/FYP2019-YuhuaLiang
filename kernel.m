function [output] = kernel(input,mask)
    % convolution of images/inputs with filters/masks
    input = im2double(input);
    [m,n] = size(input);
    [a,b] = size(mask);
    output = zeros(m-a+1,n-b+1);
    [p,q] = size(output);
    for i=1:p
        for j=1:q
            temp1 = mask.*input(i:i+a-1,j:j+b-1);
            output(i,j) = sum(sum(temp1));
        end
    end
end