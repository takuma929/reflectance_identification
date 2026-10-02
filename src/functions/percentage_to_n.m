function n = percentage_to_n(P)
% PERCENTAGE_TO_N  Bin a proportion correct into a 0-5 shading level.
%
%   Maps performance in the range [0, 0.5] onto five bands, with 1 for the best
%   band (0.4-0.5) and 5 for the worst (0-0.1); anything at or above 0.5 gives
%   0. Used only to shade the per-reflectance-pair performance matrices, where
%   0.5 is chance and lower values mark the harder pairs.
if  P < 0.5 && P >=0.4 
    n = 1;
elseif P < 0.4 && P >=0.3
    n = 2;
elseif P < 0.3 && P >=0.2
    n = 3;
elseif P < 0.2 && P >=0.1
    n = 4;
elseif P < 0.1 && P >=0
    n = 5;
else
    n = 0;
end
end

