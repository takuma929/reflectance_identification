function [MBImage] = MultiSpectralImagetoMB_Optimized(multispectralImage)

load('lms.mat');

imagesize = size(multispectralImage);
    
Lw = 0.689903;
Mw = 0.348322;
Sw = 0.0371597/0.0192; 

Rl=zeros(imagesize(1),imagesize(2));
Rm=zeros(imagesize(1),imagesize(2));
Rs=zeros(imagesize(1),imagesize(2));

Spectrum = zeros(1,31);

for i = 1:imagesize(1)
    for j = 1:imagesize(2)
        Spectrum(1,1:31) = multispectralImage(i,j,:);
        Rl(i,j) = Spectrum*lms(:,2);
        Rm(i,j) = Spectrum*lms(:,3);
        Rs(i,j) = Spectrum*lms(:,4);
    end
end

MBImage = zeros(imagesize(1),imagesize(2),3);

Lum = Lw*Rl + Mw*Rm;
r = Lw*Rl./Lum;
b = Sw*Rs./Lum;
r(isnan(r))=0;
b(isnan(b))=0;

%Lum_norm = Lum/max(Lum(:));

MBImage(:,:,3) = Lum;
MBImage(:,:,1) = r;
MBImage(:,:,2) = b;

end
