clearvars; close all;
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

stimuli_dir = fullfile(project_root,'data','stimuli_exp2');
figs_dir = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

f =  1;
w = 1;
wsize = 1;
filter = ones(wsize,wsize)/wsize^2;

Target = 1;Distractor = 5;
%Target = 5;Distractor = 1;

load(fullfile(stimuli_dir,'potato_shiny_context_e3_hueupper4_huelower1_difmin.mat'));
RGB_Shiny_Context = mb_image_to_rgb_image(MB(104:768-400,60:384-60,:));
imshow(RGB_Shiny_Context*5);imwrite(RGB_Shiny_Context*5,fullfile(figs_dir,'fig9_shiny_context.tif'))

load(fullfile(stimuli_dir,'potato_matte_context_e3_hueupper4_huelower1_difmin.mat'));
RGB_Matte_Context = mb_image_to_rgb_image(MB(104:768-400,60:384-60,:));
imshow(RGB_Matte_Context);imwrite(RGB_Matte_Context,fullfile(figs_dir,'fig9_matte_context.tif'))

load(fullfile(stimuli_dir,'potato_shiny_nocontext_e3_hueupper4_huelower1_difmin.mat'));
RGB_Shiny_NoContext = mb_image_to_rgb_image(MB(104:768-400,60:384-60,:));
imshow(RGB_Shiny_NoContext*5);imwrite(RGB_Shiny_NoContext*5,fullfile(figs_dir,'fig9_shiny_nocontext.tif'))

load(fullfile(stimuli_dir,'potato_matte_nocontext_e3_hueupper4_huelower1_difmin.mat'));
RGB_Matte_NoContext = mb_image_to_rgb_image(MB(104:768-400,60:384-60,:));
imshow(RGB_Matte_NoContext*0.5);imwrite(RGB_Matte_NoContext*0.5,fullfile(figs_dir,'fig9_matte_nocontext.tif'))

load(fullfile(stimuli_dir,'potato_shiny_context_e3_hueupper3_huelower3_difmax.mat'));MB_BG_En3 = MB;
load(fullfile(stimuli_dir,'potato_shiny_context_e4_hueupper1_huelower3_difmax.mat'));MB_BG_En4 = MB;
load(fullfile(stimuli_dir,'potato_shiny_nocontext_e3_hueupper3_huelower3_difmax.mat'));MB_NoBG_En3 = MB;
load(fullfile(stimuli_dir,'potato_shiny_nocontext_e4_hueupper1_huelower3_difmax.mat'));MB_NoBG_En4 = MB;

% Extract the object idenx
[r_En3,c_En3] = find(MB_NoBG_En3(:,:,1)>0);
[r_En4,c_En4] = find(MB_NoBG_En4(:,:,1)>0);
ObjMaskEn3 = ~boolean(MB_NoBG_En3);
ObjMaskEn4 = ~boolean(MB_NoBG_En4);
Background_MB_En3_tmp = MB_BG_En3;
Background_MB_En4_tmp = MB_BG_En4;

% Extract the Background
Background_MB_En3 = ObjMaskEn3.*Background_MB_En3_tmp;
Background_MB_En4 = ObjMaskEn4.*Background_MB_En4_tmp;
Background_RGB_En3 = mb_image_to_rgb_image(Background_MB_En3);
Background_RGB_En4 = mb_image_to_rgb_image(Background_MB_En4);

% Estimation of Illuminant Colour
BG_MB_En3_Stats = take_weighted_mean(Background_MB_En3,w,filter);
BG_MB_En4_Stats = take_weighted_mean(Background_MB_En4,w,filter);

O1_LMS_Stats = mb_to_lms(BG_MB_En3_Stats);
O2_LMS_Stats = mb_to_lms(BG_MB_En3_Stats);
O3_LMS_Stats = mb_to_lms(BG_MB_En4_Stats);
O4_LMS_Stats = mb_to_lms(BG_MB_En4_Stats);

LMS_BG_En3 = mb_image_to_lms_image(MB_BG_En3);
LMS_BG_En4 = mb_image_to_lms_image(MB_BG_En4);
LMS_NoBG_En3 = mb_image_to_lms_image(MB_NoBG_En3);
LMS_NoBG_En4 = mb_image_to_lms_image(MB_NoBG_En4);

O1_MB = MB_NoBG_En3(1:end/2,:,:);O2_MB = MB_NoBG_En3(end/2+1:end,:,:);
O3_MB = MB_NoBG_En4(1:end/2,:,:);O4_MB = MB_NoBG_En4(end/2+1:end,:,:);
O1_LMS = LMS_NoBG_En3(1:end/2,:,:);O2_LMS = LMS_NoBG_En3(end/2+1:end,:,:);
O3_LMS = LMS_NoBG_En4(1:end/2,:,:);O4_LMS = LMS_NoBG_En4(end/2+1:end,:,:);

% Estimation of Surface Colour
O1_LMS_SC = take_mean_nonzeros(O1_LMS);
O2_LMS_SC = take_mean_nonzeros(O2_LMS);
O3_LMS_SC = take_mean_nonzeros(O3_LMS);
O4_LMS_SC = take_mean_nonzeros(O4_LMS);                
O1_MB_SC = lms_to_mb(O1_LMS_SC);
O2_MB_SC = lms_to_mb(O2_LMS_SC);
O3_MB_SC = lms_to_mb(O3_LMS_SC);
O4_MB_SC = lms_to_mb(O4_LMS_SC);
            
RGB_BG_En3 = mb_image_to_rgb_image(MB_BG_En3);
RGB_BG_En4 = mb_image_to_rgb_image(MB_BG_En4);
RGB_NoBG_En3 = mb_image_to_rgb_image(MB_NoBG_En3);
RGB_NoBG_En4 = mb_image_to_rgb_image(MB_NoBG_En4);

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

BG_En3_MB_Filled = fill_mb_image(Background_MB_En3,BG_MB_En3_Stats);
BG_En4_MB_Filled = fill_mb_image(Background_MB_En4,BG_MB_En4_Stats);

% Native Image
GrayGap = 0.7*ones(size(RGB_BG_En3,1),50,3);
Native = [RGB_BG_En3*7,RGB_BG_En4*3.5];
figure(f);f = f + 1;imshow(Native.^(1/1.8));imwrite(Native.^(1/1.8),fullfile(figs_dir,'fig9_native.tif'));

% Objects Only
ObjectsOnly = [RGB_NoBG_En3*5,RGB_NoBG_En4*3];
figure(f);f = f + 1;imshow((ObjectsOnly.^(1/1.8)));imwrite(ObjectsOnly.^(1/1.8),fullfile(figs_dir,'fig9_objects_only.tif'));

% BackGround Only
BackGroundOnly = [Background_RGB_En3,Background_RGB_En4];
figure(f);f = f + 1;imshow(BackGroundOnly.^(1/1.8));imwrite(BackGroundOnly.^(1/1.8),fullfile(figs_dir,'fig9_background_only.tif'));

EstimatedSC = [mb_image_to_rgb_image(vertcat(O1_SC_MB_Filled,O2_SC_MB_Filled)),mb_image_to_rgb_image(vertcat(O3_SC_MB_Filled,O4_SC_MB_Filled))];
EstimatedCSC = [mb_image_to_rgb_image(vertcat(O1_CSC_MB_Filled,O2_CSC_MB_Filled)),mb_image_to_rgb_image(vertcat(O3_CSC_MB_Filled,O4_CSC_MB_Filled))];
EstimatedBG = [mb_image_to_rgb_image(BG_En3_MB_Filled),mb_image_to_rgb_image(BG_En4_MB_Filled)];

figure(f);f = f + 1;imshow(EstimatedSC);imwrite(EstimatedSC,fullfile(figs_dir,'fig9_estimated_sc.tif'));
figure(f);f = f + 1;imshow(EstimatedCSC);imwrite(EstimatedCSC,fullfile(figs_dir,'fig9_estimated_csc.tif'));
figure(f);f = f + 1;imshow(EstimatedBG);imwrite(EstimatedBG,fullfile(figs_dir,'fig9_estimated_bg.tif'));
