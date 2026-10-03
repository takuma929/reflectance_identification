function WMean = take_weighted_mean(MB,w,filter)
    Lum = imfilter(MB(:,:,3),filter);
    
    if w ~= -1
        Weight = Lum.^w;
    else
        Weight = max(Lum(:))-Lum;
        Weight(Weight > max(Lum(:))*0.9) = 0;
    end
    %Weight(~isfinite(Weight)) = 0;
    
    WeightedMB(:,:,1) = Weight.*MB(:,:,1);
    WeightedMB(:,:,2) = Weight.*MB(:,:,2);
    scale = sum(sum(sum(Weight)));
    WMean = [sum(nonzeros(WeightedMB(:,:,1)))/scale,sum(nonzeros(WeightedMB(:,:,2)))/scale,sum(nonzeros(MB(:,:,3)))];
end
