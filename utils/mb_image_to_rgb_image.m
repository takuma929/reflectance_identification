% Fucntion to convert MB image to RGB image
function RGBImage = mb_image_to_rgb_image(MBImage)
Matrix_LMS2RGB = [0.071311	-0.138524	0.001967
    -0.013737	0.078581	-0.002962
    -0.000745	-0.004354	0.014493];

imagesize = size(MBImage);

Luminance = MBImage(:,:,3);
Redness = MBImage(:,:,1);
Blueness = MBImage(:,:,2);

L = Luminance.*Redness;
S = Luminance.*Blueness;
M = Luminance-L;
RGBImage = zeros(imagesize(1),imagesize(2),3);

for i = 1:imagesize(1)
    for j = 1:imagesize(2)
        RGBImage(i,j,:) = Matrix_LMS2RGB*[L(i,j);M(i,j);S(i,j)];
    end
end

RGBImage= RGBImage/max(max(RGBImage(:)));
RGBImage = max(RGBImage,0);
RGBImage = power(RGBImage,1/2.2);
end
