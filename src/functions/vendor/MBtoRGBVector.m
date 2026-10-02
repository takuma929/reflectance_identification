function [RGBVector] = MBtoRGBVector(MBVector,LumFactor)

Matrix_LMS2RGB = [0.071311	-0.138524	0.001967
    -0.013737	0.078581	-0.002962
    -0.000745	-0.004354	0.014493];

imagesize = size(MBVector);

Luminance = MBVector(:,3)*LumFactor;
Redness = MBVector(:,1);
Blueness = MBVector(:,2);

L = Luminance.*Redness;
S = Luminance.*Blueness;
M = Luminance-L;
RGBVector = zeros(imagesize(1),3);

for i = 1:imagesize(1)
    RGBVector(i,:) = Matrix_LMS2RGB*[L(i,1);M(i,1);S(i,1)];
end

%RGBImage = real(power(RGBImage,1/2.2));

end
