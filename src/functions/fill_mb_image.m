function MBOut = fill_mb_image(MB,MB_Fill)
% FILL_MB_IMAGE  Repaint a masked region with a single MacLeod-Boynton colour.
%
%   MB      h x w x 3 image in MacLeod-Boynton coordinates (r, b, luminance),
%           with zeros marking pixels outside the region of interest.
%   MB_Fill 1 x 3 colour [r b luminance] to paint over every non-zero pixel.
%
%   Used by the Experiment 2 stimulus figure to show what an object or its
%   surround would look like if it were filled uniformly with the mean colour
%   of that region, which is the quantity the models actually estimate.
    
    MBOut = zeros(size(MB));
    
    r = MB(:,:,1);b = MB(:,:,2);Lum = MB(:,:,3);
    r(r>0) = MB_Fill(1);
    b(b>0) = MB_Fill(2);
    Lum(Lum>0) = MB_Fill(3);
    
    MBOut(:,:,1) = r;MBOut(:,:,2) = b;MBOut(:,:,3) = Lum;
end