% Fucntion to convert MB value to LMS value
function LMS = mb_to_lms(MB)
    LMS(1) = MB(1)*MB(3);
    LMS(2) = MB(3)-LMS(1);
    LMS(3) = MB(2)*MB(3);
end