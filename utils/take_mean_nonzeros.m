function Mean = take_mean_nonzeros(MB)
% TAKE_MEAN_NONZEROS  Mean MacLeod-Boynton colour over a masked region.
%
%   Averages each of the three planes over non-zero pixels only, so that the
%   zeros used to mask out everything outside the region do not drag the mean
%   down. This implements the "mean chromaticity" illuminant estimate
%   [Buchsbaum 1980].
    Mean = [mean(nonzeros(MB(:,:,1))),mean(nonzeros(MB(:,:,2))),mean(nonzeros(MB(:,:,3)))];
end