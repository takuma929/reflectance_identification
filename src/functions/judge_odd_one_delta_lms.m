function Response = judge_odd_one_delta_lms(LMS1,LMS2,LMS3,LMS4,LMS_sd_En1,LMS_sd_En2)

    %LMSw = [0.689903,0.348322,0.0371597/0.0192];
    
    % divide by sd in environment;Judging is made based on luminance weighted
    % chromaticity
    LMS1_N = LMS1./LMS_sd_En1;
    LMS2_N = LMS2./LMS_sd_En1;
    LMS3_N = LMS3./LMS_sd_En2;
    LMS4_N = LMS4./LMS_sd_En2;
    
    LMS1_N = LMS1_N/(sum(LMS1_N+LMS2_N)/2);
    LMS2_N = LMS2_N/(sum(LMS1_N+LMS2_N)/2);
    LMS3_N = LMS3_N/(sum(LMS3_N+LMS4_N)/2);
    LMS4_N = LMS4_N/(sum(LMS3_N+LMS4_N)/2);

    D1to234 = sum([pdist2(LMS1_N,LMS2_N),pdist2(LMS1_N,LMS3_N),pdist2(LMS1_N,LMS4_N)]);
    D2to134 = sum([pdist2(LMS2_N,LMS1_N),pdist2(LMS2_N,LMS3_N),pdist2(LMS2_N,LMS4_N)]);
    D3to124 = sum([pdist2(LMS3_N,LMS1_N),pdist2(LMS3_N,LMS2_N),pdist2(LMS3_N,LMS4_N)]);
    D4to123 = sum([pdist2(LMS4_N,LMS1_N),pdist2(LMS4_N,LMS2_N),pdist2(LMS4_N,LMS3_N)]);
    
    Distance = [D1to234,D2to134,D3to124,D4to123];
    [~,Response] = max(Distance);
end