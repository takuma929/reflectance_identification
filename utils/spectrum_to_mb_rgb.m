function [MBVector,RGBVector] = spectrum_to_mb_rgb(multispectralVector)
% SPECTRUM_TO_MB_RGB  MacLeod-Boynton and RGB coordinates of reflectance
% spectra sampled at 400:10:700 nm (one spectrum per row).

load('lms_400to700.mat');

Matrix_LMS2RGB = [0.071311	-0.138524	0.001967
    -0.013737	0.078581	-0.002962
    -0.000745	-0.004354	0.014493];

vectorlength = size(multispectralVector,1);
    
Lw = 0.689903;
Mw = 0.348322;
Sw = 0.0371597/0.0192; 

Rlms_reshaped = multispectralVector*lms_400to700(:,2:4);
Rlms = reshape(Rlms_reshaped,vectorlength,3);

MBVector = zeros(vectorlength,3);

Lum = Lw*Rlms(:,1) + Mw*Rlms(:,2);
r = Lw*Rlms(:,1)./Lum;
b = Sw*Rlms(:,3)./Lum;
r(isnan(r))=0;
b(isnan(b))=0;

MBVector(:,3) = Lum;
MBVector(:,1) = r;
MBVector(:,2) = b;

Rlms_Weighted(:,1) = Lw*Rlms(:,1);
Rlms_Weighted(:,2) = Mw*Rlms(:,2);
Rlms_Weighted(:,3) = Sw*Rlms(:,3);

RGBVector = Matrix_LMS2RGB*Rlms_Weighted';

RGBVector= RGBVector/max(RGBVector(:));
RGBVector = max(RGBVector,0);
RGBVector = power(RGBVector,1/2.2);
end
