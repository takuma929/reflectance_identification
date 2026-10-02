% run_simulation_exp1
% -----------------------------------------------------------------------------
% Run every computational observer through every Experiment 1 trial.
%
% Each model sees the same rendered images the observers saw and performs the
% same odd-one-out task, so its responses can be compared with a person's trial
% by trial. A model works in three steps (see Figure 7 of the paper):
%
%   1. Segment the image into object and surround regions.
%   2. Estimate the illuminant from one region using one statistic --
%        mean chromaticity          [Buchsbaum 1980]
%        brightest pixel            [Land 1977]
%        luminance-weighted mean    [Khang 2004], with luminance raised to
%                                   the power 1, 3 or 5
%      taken either over the surround or, in the "acrssobj" variants, over the
%      object regions themselves (the only route available with no surround,
%      and the one that could exploit specular highlights).
%   3. Discount it with a diagonal (Ives) transformation and pick the object
%      whose corrected chromaticity is the outlier.
%
% Gaussian noise is added to every estimated cone signal to represent internal
% noise; the level is expressed as a percentage of the variation across the
% environment. The "null" model skips step 2 entirely and provides the
% no-correction baseline.
%
% Models may also integrate the illuminant estimate over past trials with an
% exponential kernel of time constant tau (tau0 = single trial, tauinf = all
% past trials weighted equally), which tests whether observers could be
% exploiting the fact that each environment stayed on the same side throughout.
%
% Output: results/model/exp1/model_<condition>_session<n>_<model>.mat, one
% struct per condition x session x model holding the per-trial responses.
%
% SLOW: this is the only part of the pipeline that takes hours. It uses parfor
% where possible. main(true) calls it; main() reuses the saved output.
% -----------------------------------------------------------------------------

clearvars; close all;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(project_root,'src')));

stimuli_dir = fullfile(project_root,'data','stimuli','exp1');
config_dir  = fullfile(project_root,'data','config');
env_dir     = fullfile(project_root,'data','environments');
model_dir   = fullfile(project_root,'results','model','exp1');

if ~exist(model_dir,'dir'); mkdir(model_dir); end

NoS = 4; % Number of Session
weightingList = [1 3 5]; % Number of Weighting

%NoiseLevel = 0:0.5:2;
NoiseLevel = [0 0.25 0.5 1.0];

VisualizationFlag = 1;

% n
% 1 3
% 2 4

% Caluclation
% P: overall performance
% P_HueDif: Performance as a function of hue difference
% P_SC : Percentage of Side Correct
load(fullfile(config_dir,'variance_environment.mat'));

% All LMS are operetad in weighted form (Lw = 0.689903, Mw = 0.348322, Sw = 0.0371597/0.0192)
load(fullfile(env_dir,'mbandrgb_en1to4.mat'))
LMS_En1 = reshape(mb_image_to_lms_image(MB_En1),size(MB_En1,1)*size(MB_En1,2),size(MB_En1,3));
LMS_En2 = reshape(mb_image_to_lms_image(MB_En2),size(MB_En2,1)*size(MB_En2,2),size(MB_En2,3));

LMS_En1 = LMS_En1(sum(LMS_En1,2)>0,:);
LMS_En2 = LMS_En2(sum(LMS_En2,2)>0,:);

% Noise Scale based on sd in each environment
NoiseScale_LMS_En1 = std(LMS_En1);
NoiseScale_LMS_En2 = std(LMS_En2);

load(fullfile(config_dir,'threshold.mat'));

rg_threshold_PreExp = max(max(abs(0.7078-Threshold(:,1,:))));
yb_threshold_PreExp = max(max(abs(1-Threshold(:,2,:))));

rg_threshold = 0.0071;
yb_threshold = 0.1325;

% Trial to Trial Anaylysis
o = 0;sh = 0;sp = 0;bg = 0;

wsize = 3;
filter = ones(wsize,wsize)/wsize^2;

%Full List of Models and condition
ModelsList = {'Mean_History','Brightest_History','WMean_History',...
         'MeanAcrssObj_History','BrightestAcrssObj_History','WMeanAcrssObj_History','Null'};
%ModelsList = {'Mean_History'};

specularList = {'Matte','Shiny'};
backgroundList = {'Context','NoContext'};

load(fullfile(config_dir,'target_seed.mat'))
AllTrialN = 2304;
trialN_condition = 144;

for observerN = 1:length(ModelsList)
observer = ModelsList(observerN);
if strcmp(observer{1},'Null')
    tauList = 0;
else
    tauList = [0 1 10 100 1000 100-00 Inf];
end
    
parfor tauN = 1:length(tauList)
tau = tauList(tauN); 
if tau == 0
    weighting = zeros(AllTrialN,1);
    weighting(end) = 1;
else
    weighting = flipud(exp(-(0:AllTrialN-1)/tau)');
end

% Some models never consult the surround, so the Context and NoContext
% conditions pose them exactly the same problem. The "Null" model applies no
% illuminant correction at all, and the "AcrssObj" models take their estimate
% from the object regions, which are read from the no-surround renders in both
% conditions (see the O1_MB ... O4_MB assignment below). With tau = 0 nothing is
% carried over from earlier trials either, so the computation is identical.
% Simulating such a model twice would only draw fresh internal noise and open a
% gap of a few percentage points between two conditions that are, for it, the
% same condition. It is therefore run once, in the Context pass, and its
% responses are written out under both condition names.
surroundBlind = tau == 0 && (strcmp(observer{1},'Null') || ...
                             contains(lower(observer{1}),'acrssobj'));

for w = weightingList
if w == 1 || strcmp(observer{1},'WMean_History')||strcmp(observer{1},'GlobalWMean_History')||strcmp(observer{1},'WMeanAcrssObj_History')
for NoiseStrength = NoiseLevel
cnt_History = 0;
O1_LMS_Stats = zeros(AllTrialN,3);O2_LMS_Stats = zeros(AllTrialN,3);
O3_LMS_Stats = zeros(AllTrialN,3);O4_LMS_Stats = zeros(AllTrialN,3);
response_LMS = zeros(trialN_condition,1);correct_LMS = zeros(trialN_condition,1); 
response_Chromaticity = zeros(trialN_condition,1);correct_Chromaticity = zeros(trialN_condition,1); 

for session = 1:NoS
disp(['    Session',num2str(session),' Simulating...'])
for specularN =  1:2
specular = specularList(specularN);
for backgroundN =  1:2
if surroundBlind && backgroundN > 1
    continue   % already simulated and written out in the Context pass
end
background = backgroundList(backgroundN);

disp(['Model:',observer{1},' Condition:',specular{1},background{1}])
disp(['NoiseLevel:',num2str(NoiseStrength*100),'%',' Weighting:',num2str(w)])
disp(['tau:',num2str(tau)])

conditionname_BG = ['bumpy_',lower(specular{1}),'_context_'];
conditionname_NoBG = ['bumpy_',lower(specular{1}),'_nocontext_'];

%number of hues tested
noh = 8;

% The order of condition
% Format : HueCombination(Target Hue,Distractor Hue,Environment that has the Target)

Hue = combnk(1:noh+1,2);
Hue_reverse = [Hue(:,2) Hue(:,1)];
HueCombination = vertcat(Hue,Hue_reverse,Hue,Hue_reverse);

s_huecombination = size(HueCombination);
s_huecombination = s_huecombination(1);

HueCombination(1:s_huecombination/2,3) = ones(s_huecombination/2,1);
HueCombination(s_huecombination/2+1:s_huecombination,3) = 2*ones(s_huecombination/2,1);

% % Use the fixed order for reproduciability
fixedseed = [36,76,79,135,9,34,64,6,92,86,32,102,55,53,59,123,3,11,22,98,103,131,38,63,23,...
    58,112,46,90,116,39,124,2,48,115,31,94,44,82,20,72,83,127,1,7,117,101,85,47,104,110,57,...
    12,37,50,91,132,128,77,51,24,125,139,111,95,142,105,52,100,136,109,114,66,42,107,35,25,...
    87,144,119,43,15,65,141,54,13,56,27,126,93,40,62,69,28,75,73,10,133,121,41,26,74,4,84,68,...
    21,88,30,108,45,96,70,113,19,49,78,5,71,81,89,33,137,67,8,80,143,60,122,129,118,14,99,61,...
    18,134,140,106,29,17,138,97,16,120,130];

HueCombination = HueCombination(fixedseed,:);

ansIndex  = zeros(s_huecombination,1);
correct  = zeros(s_huecombination,1);
response  = zeros(s_huecombination,1);

%start trials loop
tic
for trialN = 1:s_huecombination
    
    O1_Hue = zeros(trialN_condition,1);O2_Hue = zeros(trialN_condition,1);
    O3_Hue = zeros(trialN_condition,1);O4_Hue = zeros(trialN_condition,1);

    cnt_History = cnt_History + 1;
    
    Target_Hue = HueCombination(trialN,1);
    Distractor_Hue = HueCombination(trialN,2);
    Target_Environment = HueCombination(trialN,3);
    
    seed = target_seed((session-1)*s_huecombination+trialN);
    
    % When the target object is placed under environment 1
    if Target_Environment == 1
        if seed == 1
            fileBG_En1 =  strcat(conditionname_BG,'e1_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat');
            fileNoBG_En1 =  strcat(conditionname_NoBG,'e1_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat');
            answer = 1;
            O2_Hue(trialN,1) = Distractor_Hue;O3_Hue(trialN,1) = Distractor_Hue;O4_Hue(trialN,1) = Distractor_Hue;
            O1_Hue(trialN,1) = Target_Hue;
        else
            fileBG_En1 =  strcat(conditionname_BG,'e1_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_mb_bayesian_scaled.mat');
            fileNoBG_En1 =  strcat(conditionname_NoBG,'e1_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_mb_bayesian_scaled.mat');
            answer = 2;
            O1_Hue(trialN,1) = Distractor_Hue;O3_Hue(trialN,1) = Distractor_Hue;O4_Hue(trialN,1) = Distractor_Hue;
            O2_Hue(trialN,1) = Target_Hue;
        end
        fileBG_En2 =  strcat(conditionname_BG,'e2_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat');
        fileNoBG_En2 =  strcat(conditionname_NoBG,'e2_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat');
    
    % When the target object is placed under environment 2
    elseif Target_Environment == 2
        if seed == 1
            fileBG_En2 =  strcat(conditionname_BG,'e2_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat');
            fileNoBG_En2 =  strcat(conditionname_NoBG,'e2_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat');
            answer = 3;
            O1_Hue(trialN,1) = Distractor_Hue;O2_Hue(trialN,1) = Distractor_Hue;O4_Hue(trialN,1) = Distractor_Hue;
            O3_Hue(trialN,1) = Target_Hue;
        else
            fileBG_En2 =  strcat(conditionname_BG,'e2_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_mb_bayesian_scaled.mat');
            fileNoBG_En2 =  strcat(conditionname_NoBG,'e2_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_mb_bayesian_scaled.mat');
            answer = 4;
            O1_Hue(trialN,1) = Distractor_Hue;O2_Hue(trialN,1) = Distractor_Hue;O3_Hue(trialN,1) = Distractor_Hue;
            O4_Hue(trialN,1) = Target_Hue;
        end
        fileBG_En1 =  [conditionname_BG,'e1_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat'];
        fileNoBG_En1 =  [conditionname_NoBG,'e1_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_mb_bayesian_scaled.mat'];
    end
    ansIndex(trialN) = answer;

    temp  = load(fullfile(stimuli_dir,fileNoBG_En1));MB_NoBG_En1 = temp.MB;
    temp = load(fullfile(stimuli_dir,fileNoBG_En2));MB_NoBG_En2 = temp.MB;
    
    LMS_NoBG_En1 = mb_image_to_lms_image(MB_NoBG_En1);
    LMS_NoBG_En2 = mb_image_to_lms_image(MB_NoBG_En2);
        
    O1_MB = MB_NoBG_En1(1:end/2,:,:);O2_MB = MB_NoBG_En1(end/2+1:end,:,:);
    O3_MB = MB_NoBG_En2(1:end/2,:,:);O4_MB = MB_NoBG_En2(end/2+1:end,:,:);
    
    O1_LMS = LMS_NoBG_En1(1:end/2,:,:);O2_LMS = LMS_NoBG_En1(end/2+1:end,:,:);
    O3_LMS = LMS_NoBG_En2(1:end/2,:,:);O4_LMS = LMS_NoBG_En2(end/2+1:end,:,:);
    
    if strcmp(background{1},'Context')
        temp = load(fullfile(stimuli_dir,fileBG_En1));MB_BG_En1 = temp.MB;
        temp = load(fullfile(stimuli_dir,fileBG_En2));MB_BG_En2 = temp.MB;

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

        Background_LMS_En1 = mb_image_to_lms_image(Background_MB_En1);
        Background_LMS_En2 = mb_image_to_lms_image(Background_MB_En2);

        LMS_BG_En1 = mb_image_to_lms_image(MB_BG_En1);
        LMS_BG_En2 = mb_image_to_lms_image(MB_BG_En2);
    end
    
    switch observer{1}
        case 'Mean_History'
            if strcmp(background{1},'Context')
                BG_MB_En1_Stats = [mean(nonzeros(Background_MB_En1(:,:,1))),mean(nonzeros(Background_MB_En1(:,:,2))),mean(nonzeros(Background_MB_En1(:,:,3)))];
                BG_MB_En2_Stats = [mean(nonzeros(Background_MB_En2(:,:,1))),mean(nonzeros(Background_MB_En2(:,:,2))),mean(nonzeros(Background_MB_En2(:,:,3)))];
                                
                % Add Noise and Store LMS values
                O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En1_Stats),NoiseStrength*NoiseScale_LMS_En1);
                O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En1_Stats),NoiseStrength*NoiseScale_LMS_En1);
                O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En2_Stats),NoiseStrength*NoiseScale_LMS_En2);
                O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En2_Stats),NoiseStrength*NoiseScale_LMS_En2);

            elseif strcmp(background{1},'NoContext')
                O1_LMS_Stats(cnt_History,:) = [0 0 0];
                O2_LMS_Stats(cnt_History,:) = [0 0 0];
                O3_LMS_Stats(cnt_History,:) = [0 0 0];
                O4_LMS_Stats(cnt_History,:) = [0 0 0];
            end

        case 'MeanAcrssObj_History'
            O1_MB_Stats = take_mean_nonzeros([O1_MB,O2_MB]);O2_MB_Stats = take_mean_nonzeros([O1_MB,O2_MB]);
            O3_MB_Stats = take_mean_nonzeros([O3_MB,O4_MB]);O4_MB_Stats = take_mean_nonzeros([O3_MB,O4_MB]);
            
            % Add Noise to LMS values and store values
            O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O1_MB_Stats),NoiseStrength*NoiseScale_LMS_En1);
            O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O2_MB_Stats),NoiseStrength*NoiseScale_LMS_En1);
            O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O3_MB_Stats),NoiseStrength*NoiseScale_LMS_En2);
            O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O4_MB_Stats),NoiseStrength*NoiseScale_LMS_En2);

        case 'Brightest_History'
            if strcmp(background{1},'Context')
                BG_MB_En1_Stats = take_brightest(Background_MB_En1,filter);
                BG_MB_En2_Stats = take_brightest(Background_MB_En2,filter);

                % Add Noise and store values
                O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En1_Stats),NoiseStrength*NoiseScale_LMS_En1);
                O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En1_Stats),NoiseStrength*NoiseScale_LMS_En1);
                O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En2_Stats),NoiseStrength*NoiseScale_LMS_En2);
                O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En2_Stats),NoiseStrength*NoiseScale_LMS_En2);
                
            elseif strcmp(background{1},'NoContext')
                O1_LMS_Stats(cnt_History,:) = [0 0 0];
                O2_LMS_Stats(cnt_History,:) = [0 0 0];
                O3_LMS_Stats(cnt_History,:) = [0 0 0];
                O4_LMS_Stats(cnt_History,:) = [0 0 0];
            end

        case 'BrightestAcrssObj_History'
            O1_MB_Stats = take_brightest([O1_MB,O2_MB],filter);O2_MB_Stats = take_brightest([O1_MB,O2_MB],filter);
            O3_MB_Stats = take_brightest([O3_MB,O4_MB],filter);O4_MB_Stats = take_brightest([O3_MB,O4_MB],filter);

            % Add Noise and store values
            O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O1_MB_Stats),NoiseStrength*NoiseScale_LMS_En1);
            O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O2_MB_Stats),NoiseStrength*NoiseScale_LMS_En1);
            O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O3_MB_Stats),NoiseStrength*NoiseScale_LMS_En2);
            O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O4_MB_Stats),NoiseStrength*NoiseScale_LMS_En2);
            
        case 'WMean_History'
            if strcmp(background{1},'Context')
                BG_MB_En1_Stats = take_weighted_mean(Background_MB_En1,w,filter);
                BG_MB_En2_Stats = take_weighted_mean(Background_MB_En2,w,filter);

                % Add noise and store values
                O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En1_Stats),NoiseStrength*NoiseScale_LMS_En1);
                O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En1_Stats),NoiseStrength*NoiseScale_LMS_En1);
                O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En2_Stats),NoiseStrength*NoiseScale_LMS_En2);
                O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En2_Stats),NoiseStrength*NoiseScale_LMS_En2);

            elseif strcmp(background{1},'NoContext')
                O1_LMS_Stats(cnt_History,:) = [0 0 0];
                O2_LMS_Stats(cnt_History,:) = [0 0 0];
                O3_LMS_Stats(cnt_History,:) = [0 0 0];
                O4_LMS_Stats(cnt_History,:) = [0 0 0];
                
            end
        case 'WMeanAcrssObj_History'
            O1_MB_Stats = take_weighted_mean([O1_MB,O2_MB],w,filter);O2_MB_Stats = take_weighted_mean([O1_MB,O2_MB],w,filter);
            O3_MB_Stats = take_weighted_mean([O3_MB,O4_MB],w,filter);O4_MB_Stats = take_weighted_mean([O3_MB,O4_MB],w,filter);

            % Add noise and store values
            O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O1_MB_Stats),NoiseStrength*NoiseScale_LMS_En1);
            O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O2_MB_Stats),NoiseStrength*NoiseScale_LMS_En1);
            O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O3_MB_Stats),NoiseStrength*NoiseScale_LMS_En2);
            O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O4_MB_Stats),NoiseStrength*NoiseScale_LMS_En2);
    end        
    
    % Estimate Surface Colour(SC) by taking mean LMS
    O1_LMS_SC = take_mean_nonzeros(O1_LMS);
    O2_LMS_SC = take_mean_nonzeros(O2_LMS);
    O3_LMS_SC = take_mean_nonzeros(O3_LMS);
    O4_LMS_SC = take_mean_nonzeros(O4_LMS);

    % add noise to surface color estimation
    O1_LMS_SC = add_noise_lms(O1_LMS_SC,NoiseStrength*NoiseScale_LMS_En1);
    O2_LMS_SC = add_noise_lms(O2_LMS_SC,NoiseStrength*NoiseScale_LMS_En1);
    O3_LMS_SC = add_noise_lms(O3_LMS_SC,NoiseStrength*NoiseScale_LMS_En2);
    O4_LMS_SC = add_noise_lms(O4_LMS_SC,NoiseStrength*NoiseScale_LMS_En2);
    
    O1_MB_SC = lms_to_mb(O1_LMS_SC);
    O2_MB_SC = lms_to_mb(O2_LMS_SC);
    O3_MB_SC = lms_to_mb(O3_LMS_SC);
    O4_MB_SC = lms_to_mb(O4_LMS_SC);
    
    % von Kries Scaling
    if ~strcmp(observer{1},'Null')
        weighting_temp = weighting(AllTrialN-cnt_History+1:end); 
        
        O1_LMS_Stats_temp = sum(O1_LMS_Stats(1:cnt_History,:).*weighting_temp,1)/sum(weighting_temp);
        O2_LMS_Stats_temp = sum(O2_LMS_Stats(1:cnt_History,:).*weighting_temp,1)/sum(weighting_temp);
        O3_LMS_Stats_temp = sum(O3_LMS_Stats(1:cnt_History,:).*weighting_temp,1)/sum(weighting_temp);
        O4_LMS_Stats_temp = sum(O4_LMS_Stats(1:cnt_History,:).*weighting_temp,1)/sum(weighting_temp);
        
        if sum(O1_LMS_Stats_temp+O2_LMS_Stats_temp+O3_LMS_Stats_temp+O4_LMS_Stats_temp) > 1
            if Target_Environment == 1
                O1_LMS_CSC = O1_LMS_SC.*((O3_LMS_Stats_temp+O4_LMS_Stats_temp)/2)./O1_LMS_Stats_temp;
                O2_LMS_CSC = O2_LMS_SC.*((O3_LMS_Stats_temp+O4_LMS_Stats_temp)/2)./O2_LMS_Stats_temp;
                O3_LMS_CSC = O3_LMS_SC;
                O4_LMS_CSC = O4_LMS_SC;
                
                LMS_En1_scaled = LMS_En1.*((O3_LMS_Stats_temp+O4_LMS_Stats_temp)/2)./((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2);
                LMS_threshold_En1 = std(vertcat(LMS_En1_scaled,LMS_En2));
                LMS_threshold_En2 = std(vertcat(LMS_En1_scaled,LMS_En2));
            
            elseif Target_Environment == 2
                O1_LMS_CSC = O1_LMS_SC;
                O2_LMS_CSC = O2_LMS_SC;
                O3_LMS_CSC = O3_LMS_SC.*((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2)./O3_LMS_Stats_temp;
                O4_LMS_CSC = O4_LMS_SC.*((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2)./O4_LMS_Stats_temp; 
                
                LMS_En2_scaled = LMS_En2.*((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2)./((O3_LMS_Stats_temp+O4_LMS_Stats_temp)/2);
                LMS_threshold_En1 = std(vertcat(LMS_En1,LMS_En2_scaled));
                LMS_threshold_En2 = std(vertcat(LMS_En1,LMS_En2_scaled));
            end
        else
            % If weightings are zero
            O1_LMS_CSC = O1_LMS_SC;O2_LMS_CSC = O2_LMS_SC;
            O3_LMS_CSC = O3_LMS_SC;O4_LMS_CSC = O4_LMS_SC;
            
            LMS_threshold_En1 = std(LMS_En1);
            LMS_threshold_En2 = std(LMS_En2);
        end
    else % if the model is 'Null'
        O1_LMS_CSC = O1_LMS_SC;O2_LMS_CSC = O2_LMS_SC;
        O3_LMS_CSC = O3_LMS_SC;O4_LMS_CSC = O4_LMS_SC;
        LMS_threshold_En1 = std(LMS_En1);
        LMS_threshold_En2 = std(LMS_En2);    
    end
    
    O1_MB_CSC = lms_to_mb(O1_LMS_CSC);
    O2_MB_CSC = lms_to_mb(O2_LMS_CSC);
    O3_MB_CSC = lms_to_mb(O3_LMS_CSC);
    O4_MB_CSC = lms_to_mb(O4_LMS_CSC);
    
    LMSw = [0.689903,0.348322,0.0371597/0.0192];
    
    %LMS_threshold_En1 = [1 1 1/20];
    %LMS_threshold_En2 = [1 1 1/20];

    % Find Odd-One
    response_LMS(trialN,1) = judge_odd_one_delta_lms(O1_LMS_CSC,O2_LMS_CSC,O3_LMS_CSC,O4_LMS_CSC,LMS_threshold_En1,LMS_threshold_En2);
    response_Chromaticity(trialN,1) = judge_odd_one_chromaticity(O1_MB_CSC,O2_MB_CSC,O3_MB_CSC,O4_MB_CSC,rg_threshold,yb_threshold);
    
%     if VisualizationFlag == 1
%         % Visalization of Trial
%         if strcmp(background{1},'Context') && ~(strcmp(observer{1},'GlobalMean')||strcmp(observer{1},'GlobalWMean')||strcmp(observer{1},'GlobalBrightest')||strcmp(observer{1},'MeanAcrssObj')||strcmp(observer{1},'WMeanAcrssObj')||strcmp(observer{1},'BrightestAcrssObj'))
%             legacy/functions/visualize_trial_estimate([MB_BG_En1,MB_BG_En2],[MB_NoBG_En1,MB_NoBG_En2],[Background_MB_En1,Background_MB_En2]...
%                 ,O1_MB_SC,O2_MB_SC,O3_MB_SC,O4_MB_SC,O1_LMS_Stats_temp,O2_LMS_Stats_temp,O3_LMS_Stats_temp,O4_LMS_Stats_temp,O1_MB_CSC,O2_MB_CSC,O3_MB_CSC,O4_MB_CSC,answer,response_Chromaticity(trialN,1),0);
%         end
%         pause(0.05)
%     end
    
    % Store if the answer was correct or not
    if response_LMS(trialN,1) == answer
        correct_LMS(trialN,1) = 1;
    elseif response_LMS(trialN,1) ~= answer
        correct_LMS(trialN,1) = 0;
    end
    
    if response_Chromaticity(trialN,1) == answer
        correct_Chromaticity(trialN,1) = 1;
    elseif response_Chromaticity(trialN,1) ~= answer
        correct_Chromaticity(trialN,1) = 0;
    end
end %of Trial

% Save the results. A surround-blind model was simulated only in the Context
% pass, so the same responses are written under both condition names.
if surroundBlind
    saveBackgrounds = lower(backgroundList);
else
    saveBackgrounds = {lower(background{1})};
end

result = struct('HueCombination','ansIndex','response_LMS','response_Chromaticity','correct_LMS','correct_Chromaticity');
result.HueCombination = HueCombination;
result.ansIndex = ansIndex;

result.response_LMS = response_LMS;
result.response_Chromaticity = response_Chromaticity;

result.correct_LMS = correct_LMS;
result.correct_Chromaticity = correct_Chromaticity;

for bgN = 1:numel(saveBackgrounds)
    if strcmp(observer{1},'WMean_History') || strcmp(observer{1},'GlobalWMean_History') || strcmp(observer{1},'WMeanAcrssObj_History')
        filename = strcat('model_',lower(specular{1}),'_',saveBackgrounds{bgN},'_session',num2str(session),'_',lower(observer),'_w',num2str(w),'_tau',num2str(tau),'_noise',num2str(NoiseStrength*100),'.mat');
    else
        filename = strcat('model_',lower(specular{1}),'_',saveBackgrounds{bgN},'_session',num2str(session),'_',lower(observer),'_tau',num2str(tau),'_noise',num2str(NoiseStrength*100),'.mat');
    end
    parsave(fullfile(model_dir,filename{1}), result);
end

toc
end
end
end
end
end
end
end
end

function parsave(fname,result)
save(fname, 'result')
end