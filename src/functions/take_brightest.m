function Brightest = take_brightest(MB,filter)
% TAKE_BRIGHTEST  MacLeod-Boynton colour of the brightest point in a region.
%
%   MB     h x w x 3 image in MacLeod-Boynton coordinates (r, b, luminance).
%   filter smoothing kernel applied to the luminance plane before the maximum
%          is taken, so that the estimate reflects a small bright area rather
%          than a single noisy pixel.
%
%   This implements the "brightest pixel" illuminant estimate [Land 1977], one
%   of the three statistics compared in the paper.
    Lum = imfilter(MB(:,:,3),filter);
    [~,I] = max(Lum(:));
    [I_row, I_col] = ind2sub(size(Lum),I);
    Brightest = [MB(I_row,I_col,1),MB(I_row,I_col,2),MB(I_row,I_col,3)];
end