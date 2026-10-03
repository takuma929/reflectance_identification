% Fucntion to convert LMS value to MB value
function MB = lms_to_mb(LMS)
    MB(1) = LMS(1)./(LMS(1)+LMS(2));
    MB(2) = LMS(3)./(LMS(1)+LMS(2));
    MB(3) = LMS(1)+LMS(2);
    MB(isnan(MB)) = 0;
end