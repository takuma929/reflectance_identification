% Fucntion to convert MB image to LMS image
function LMS = mb_image_to_lms_image(MB)
    LMS(:,:,1) = MB(:,:,1).*MB(:,:,3);
    LMS(:,:,3) = MB(:,:,2).*MB(:,:,3);
    LMS(:,:,2) = MB(:,:,3)-LMS(:,:,1);
end