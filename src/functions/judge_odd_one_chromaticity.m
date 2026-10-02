function Response = judge_odd_one_chromaticity(MB1,MB2,MB3,MB4,rg_threshold,yb_threshold)
    
    % divide by threshold;Judging is made based on luminance weighted
    % chromaticity
    MB1_N = [(MB1(1)-0.7078)/rg_threshold,(MB1(2)-1)/yb_threshold];
    MB2_N = [(MB2(1)-0.7078)/rg_threshold,(MB2(2)-1)/yb_threshold];
    MB3_N = [(MB3(1)-0.7078)/rg_threshold,(MB3(2)-1)/yb_threshold];
    MB4_N = [(MB4(1)-0.7078)/rg_threshold,(MB4(2)-1)/yb_threshold];
    
    D1to234 = sum([pdist2(MB1_N,MB2_N),pdist2(MB1_N,MB3_N),pdist2(MB1_N,MB4_N)]);
    D2to134 = sum([pdist2(MB2_N,MB1_N),pdist2(MB2_N,MB3_N),pdist2(MB2_N,MB4_N)]);
    D3to124 = sum([pdist2(MB3_N,MB1_N),pdist2(MB3_N,MB2_N),pdist2(MB3_N,MB4_N)]);
    D4to123 = sum([pdist2(MB4_N,MB1_N),pdist2(MB4_N,MB2_N),pdist2(MB4_N,MB3_N)]);
    
    Distance = [D1to234,D2to134,D3to124,D4to123];
    [~,Response] = max(Distance);
end
