clearvars; close all;
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

procedure_dir = fullfile(project_root,'data','procedure');
figs_dir = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

f =  1;
w = 1;
wsize = 1;
filter = ones(wsize,wsize)/wsize^2;

Target = 1;Distractor = 5;
%Target = 5;Distractor = 1;

load(fullfile(procedure_dir,'context_procedure_en1_mb.mat'));MB_BG_En1 = MB;
load(fullfile(procedure_dir,'context_procedure_en2_mb.mat'));MB_BG_En2 = MB;
load(fullfile(procedure_dir,'nocontext_procedure_en1_mb.mat'));MB_NoBG_En1 = MB;
load(fullfile(procedure_dir,'nocontext_procedure_en2_mb.mat'));MB_NoBG_En2 = MB;

% Extract the object idenx
[r_En1,c_En1] = find(MB_NoBG_En1(:,:,1)>0);
[r_En2,c_En2] = find(MB_NoBG_En2(:,:,1)>0);
ObjMaskEn1 = ~boolean(MB_NoBG_En1);
ObjMaskEn2 = ~boolean(MB_NoBG_En2);
Background_MB_En1_tmp = MB_BG_En1;
Background_MB_En2_tmp = MB_BG_En2;

% Extract the Background
Background_MB_En1 = ObjMaskEn1.*Background_MB_En1_tmp;
Background_MB_En2 = ObjMaskEn2.*Background_MB_En2_tmp;
Background_RGB_En1 = mb_image_to_rgb_image(Background_MB_En1);
Background_RGB_En2 = mb_image_to_rgb_image(Background_MB_En2);

% Estimation of Illuminant Colour
BG_MB_En1_Stats = take_weighted_mean(Background_MB_En1,w,filter);
BG_MB_En2_Stats = take_weighted_mean(Background_MB_En2,w,filter);

O1_LMS_Stats = mb_to_lms(BG_MB_En1_Stats);
O2_LMS_Stats = mb_to_lms(BG_MB_En1_Stats);
O3_LMS_Stats = mb_to_lms(BG_MB_En2_Stats);
O4_LMS_Stats = mb_to_lms(BG_MB_En2_Stats);

LMS_BG_En1 = mb_image_to_lms_image(MB_BG_En1);
LMS_BG_En2 = mb_image_to_lms_image(MB_BG_En2);
LMS_NoBG_En1 = mb_image_to_lms_image(MB_NoBG_En1);
LMS_NoBG_En2 = mb_image_to_lms_image(MB_NoBG_En2);

O1_MB = MB_NoBG_En1(1:end/2,:,:);O2_MB = MB_NoBG_En1(end/2+1:end,:,:);
O3_MB = MB_NoBG_En2(1:end/2,:,:);O4_MB = MB_NoBG_En2(end/2+1:end,:,:);
O1_LMS = LMS_NoBG_En1(1:end/2,:,:);O2_LMS = LMS_NoBG_En1(end/2+1:end,:,:);
O3_LMS = LMS_NoBG_En2(1:end/2,:,:);O4_LMS = LMS_NoBG_En2(end/2+1:end,:,:);

% Estimation of Surface Colour
O1_LMS_SC = take_mean_nonzeros(O1_LMS);
O2_LMS_SC = take_mean_nonzeros(O2_LMS);
O3_LMS_SC = take_mean_nonzeros(O3_LMS);
O4_LMS_SC = take_mean_nonzeros(O4_LMS);                
O1_MB_SC = lms_to_mb(O1_LMS_SC);
O2_MB_SC = lms_to_mb(O2_LMS_SC);
O3_MB_SC = lms_to_mb(O3_LMS_SC);
O4_MB_SC = lms_to_mb(O4_LMS_SC);
            
RGB_BG_En1 = mb_image_to_rgb_image(MB_BG_En1);
RGB_BG_En2 = mb_image_to_rgb_image(MB_BG_En2);
RGB_NoBG_En1 = mb_image_to_rgb_image(MB_NoBG_En1);
RGB_NoBG_En2 = mb_image_to_rgb_image(MB_NoBG_En2);

% von Kries Scaling
O1_LMS_CSC = O1_LMS_SC.*((O3_LMS_Stats+O4_LMS_Stats)/2)./O1_LMS_Stats;
O2_LMS_CSC = O2_LMS_SC.*((O3_LMS_Stats+O4_LMS_Stats)/2)./O2_LMS_Stats;
O3_LMS_CSC = O3_LMS_SC;
O4_LMS_CSC = O4_LMS_SC;

O1_MB_CSC = lms_to_mb(O1_LMS_CSC);
O2_MB_CSC = lms_to_mb(O2_LMS_CSC);
O3_MB_CSC = lms_to_mb(O3_LMS_CSC);
O4_MB_CSC = lms_to_mb(O4_LMS_CSC);

O1_SC_MB_Filled = fill_mb_image(O1_MB,O1_MB_SC);
O2_SC_MB_Filled = fill_mb_image(O2_MB,O2_MB_SC);
O3_SC_MB_Filled = fill_mb_image(O3_MB,O3_MB_SC);
O4_SC_MB_Filled = fill_mb_image(O4_MB,O4_MB_SC);

O1_CSC_MB_Filled = fill_mb_image(O1_MB,O1_MB_CSC);
O2_CSC_MB_Filled = fill_mb_image(O2_MB,O2_MB_CSC);
O3_CSC_MB_Filled = fill_mb_image(O3_MB,O3_MB_CSC);
O4_CSC_MB_Filled = fill_mb_image(O4_MB,O4_MB_CSC);

BG_En1_MB_Filled = fill_mb_image(Background_MB_En1,BG_MB_En1_Stats);
BG_En2_MB_Filled = fill_mb_image(Background_MB_En2,BG_MB_En2_Stats);

% Native Image
GrayGap = 0.7*ones(size(RGB_BG_En1,1),50,3);
Native = [RGB_BG_En1*1.2,GrayGap,RGB_BG_En2*1.2];
figure(f);f = f + 1;imshow(Native.^(1/1.8));imwrite(Native.^(1/1.8),fullfile(figs_dir,'fig4_native.tif'));

% Objects Only
ObjectsOnly = [RGB_NoBG_En1*0.4,GrayGap,RGB_NoBG_En2*0.6];
figure(f);f = f + 1;imshow(ObjectsOnly.^(1/1.8));imwrite(ObjectsOnly.^(1/1.8),fullfile(figs_dir,'fig4_objects_only.tif'));

% BackGround Only
BackGroundOnly = [Background_RGB_En1,GrayGap,Background_RGB_En2];
figure(f);f = f + 1;imshow(BackGroundOnly.^(1/1.8));imwrite(BackGroundOnly.^(1/1.8),fullfile(figs_dir,'fig4_background_only.tif'));

EstimatedSC = [mb_image_to_rgb_image(vertcat(O1_SC_MB_Filled,O2_SC_MB_Filled)),GrayGap,mb_image_to_rgb_image(vertcat(O3_SC_MB_Filled,O4_SC_MB_Filled))];
EstimatedCSC = [mb_image_to_rgb_image(vertcat(O1_CSC_MB_Filled,O2_CSC_MB_Filled)),GrayGap,mb_image_to_rgb_image(vertcat(O3_CSC_MB_Filled,O4_CSC_MB_Filled))];
EstimatedBG = [mb_image_to_rgb_image(BG_En1_MB_Filled),GrayGap,mb_image_to_rgb_image(BG_En2_MB_Filled)];

figure(f);f = f + 1;imshow(EstimatedSC);imwrite(EstimatedSC,fullfile(figs_dir,'fig4_estimated_sc.tif'));
figure(f);f = f + 1;imshow(EstimatedCSC);imwrite(EstimatedCSC,fullfile(figs_dir,'fig4_estimated_csc.tif'));
figure(f);f = f + 1;imshow(EstimatedBG);imwrite(EstimatedBG,fullfile(figs_dir,'fig4_estimated_bg.tif'));
