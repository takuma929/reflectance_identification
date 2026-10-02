% run_simulation_exp2
% -----------------------------------------------------------------------------
% Experiment 2 counterpart of RUN_SIMULATION_EXP1: the same model observers,
% run on the Experiment 2 stimuli.
%
% The design differs in one important way. Viewing angles were chosen so that
% the mean cone signals of the surround either matched the light falling on the
% object (congruent, file tag "difmin") or differed from it as much as possible
% (incongruent, "difmax"). Because a surround-based illuminant estimate is
% deliberately misleading on incongruent trials, comparing the two conditions
% asks whether observers rely on that estimate at all -- they largely do not,
% losing only about 3 percentage points, whereas every model collapses.
%
% Output: results/model/exp2/model_<condition>_dif<min|max>_session<n>_<model>.mat
%
% SLOW: see RUN_SIMULATION_EXP1.
% -----------------------------------------------------------------------------

clearvars; close all;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(project_root,'src')));

stimuli_dir  = fullfile(project_root,'data','stimuli','exp2');
config_dir   = fullfile(project_root,'data','config');
hue_comb_dir = fullfile(project_root,'data','config','hue_combination_exp2');
env_dir      = fullfile(project_root,'data','environments');
model_dir    = fullfile(project_root,'results','model','exp2');

if ~exist(model_dir,'dir'); mkdir(model_dir); end

% Extract Congruent and Incongruent condition
load(fullfile(stimuli_dir,'potato_matte_context_e3_hueupper1_huelower1_difmax_mb_exp3_2_scaled.mat'));MB_Incongruent_BG_En3 = MB;
load(fullfile(stimuli_dir,'potato_matte_context_e3_hueupper1_huelower1_difmin_mb_exp3_2_scaled.mat'));MB_Congruent_BG_En3 = MB;
load(fullfile(stimuli_dir,'potato_matte_context_e4_hueupper1_huelower1_difmax_mb_exp3_2_scaled.mat'));MB_Incongruent_BG_En4 = MB;
load(fullfile(stimuli_dir,'potato_matte_context_e4_hueupper1_huelower1_difmin_mb_exp3_2_scaled.mat'));MB_Congruent_BG_En4 = MB;
load(fullfile(stimuli_dir,'potato_matte_nocontext_e3_hueupper1_huelower1_difmax_mb_exp3_2_scaled.mat'));MB_Incongruent_NoBG_En3 = MB;
load(fullfile(stimuli_dir,'potato_matte_nocontext_e3_hueupper1_huelower1_difmin_mb_exp3_2_scaled.mat'));MB_Congruent_NoBG_En3 = MB;
load(fullfile(stimuli_dir,'potato_matte_nocontext_e4_hueupper1_huelower1_difmax_mb_exp3_2_scaled.mat'));MB_Incongruent_NoBG_En4 = MB;
load(fullfile(stimuli_dir,'potato_matte_nocontext_e4_hueupper1_huelower1_difmin_mb_exp3_2_scaled.mat'));MB_Congruent_NoBG_En4 = MB;

% Make Mask
ObjMaskEn3_Incongruent = ~boolean(MB_Incongruent_NoBG_En3);
ObjMaskEn4_Incongruent = ~boolean(MB_Incongruent_NoBG_En4);
ObjMaskEn3_Congruent = ~boolean(MB_Congruent_NoBG_En3);
ObjMaskEn4_Congruent = ~boolean(MB_Congruent_NoBG_En4);

% Extract the Background
Background_Incongruent_MB_En3 = ObjMaskEn3_Incongruent.*MB_Incongruent_BG_En3;
Background_Incongruent_MB_En4 = ObjMaskEn4_Incongruent.*MB_Incongruent_BG_En4;
Background_Congruent_MB_En3 = ObjMaskEn3_Congruent.*MB_Congruent_BG_En3;
Background_Congruent_MB_En4 = ObjMaskEn4_Congruent.*MB_Congruent_BG_En4;

Background_Incongruent_LMS_En3 = mb_image_to_lms_image(Background_Incongruent_MB_En3);
Background_Incongruent_LMS_En4 = mb_image_to_lms_image(Background_Incongruent_MB_En4);
Background_Congruent_LMS_En3 = mb_image_to_lms_image(Background_Congruent_MB_En3);
Background_Congruent_LMS_En4 = mb_image_to_lms_image(Background_Congruent_MB_En4);
       
NoS = 4; % Number of Session

%NoiseLevel = [0:0.2:1,2:10];
NoiseLevel = [0 0.25 0.5 1.0];
%NoiseLevel = 0:0.5:2;

VisualizationFlag = 0;
% n
% 1 3
% 2 4

specularList = {'Matte','Shiny'};
backgroundList = {'Context','NoContext'};
typeList = {'DifMax','DifMin'};

% Caluclation
% P: overall performance
% P_HueDif: Performance as a function of hue difference
% P_SC : Percentage of Side Correct
load(fullfile(config_dir,'variance_environment.mat'));
load(fullfile(config_dir,'threshold.mat'));

rg_threshold_PreExp = max(max(abs(0.7078-Threshold(:,1,:))));
yb_threshold_PreExp = max(max(abs(1-Threshold(:,2,:))));

rg_threshold = 0.0071;
yb_threshold = 0.1325;
Threshold_STD(:,1,:) = (Threshold(:,1,:)-0.7078)/rg_threshold;
Threshold_STD(:,2,:) = (Threshold(:,2,:)-1)/yb_threshold;

load(fullfile(env_dir,'mbandrgb_en1to4.mat'))
LMS_En3 = reshape(mb_image_to_lms_image(MB_En3),size(MB_En3,1)*size(MB_En3,2),size(MB_En3,3));
LMS_En4 = reshape(mb_image_to_lms_image(MB_En4),size(MB_En4,1)*size(MB_En4,2),size(MB_En4,3));

% Noise Scale based on sd in each environment
NoiseScale_LMS_En3 = std(LMS_En3(sum(LMS_En3,2)>0,:));
NoiseScale_LMS_En4 = std(LMS_En4(sum(LMS_En4,2)>0,:));

% Trial to Trial Anaylysis
o = 0;sh = 0;sp = 0;bg = 0;

wsize = 3;
filter = ones(wsize,wsize)/wsize^2;

shape = {'Potato'};

%Full List of Models
%Models = {'Mean_History','Brightest_History','WMean_History',...
%        'MeanAcrssObj_History','BrightestAcrssObj_History','WMeanAcrssObj_History',...
%        'Congruent100','Congruent75','Congruent50','Congruent25','Congruent0','Null'};
%Models = {'Null'};
%Models = {'WMean_History','GlobalWMean_History','WMeanAcrssObj_History'};
%Models = {'Congruent100','Congruent0','Null'};

Models = {'Mean_History','Brightest_History','WMean_History',...
        'MeanAcrssObj_History','BrightestAcrssObj_History','WMeanAcrssObj_History',...
        'Congruent100','Congruent0','Null'};

AllTrialN = 1280;
cnt_History = 0;

for observerN = 1:length(Models)
observer = Models(observerN);
if strcmp(observer{1},'Congruent100') || strcmp(observer{1},'Congruent0')|| strcmp(observer{1},'Null')
    tauList = 0;
else
    tauList = [0 1 10 100 1000 Inf];
end

parfor tauN = 1:length(tauList)
tau = tauList(tauN); 

if tau == 0
    weighting = zeros(AllTrialN,1);
    weighting(end) = 1;
else
    weighting = flipud(exp(-(0:AllTrialN-1)/tau)');
end

if strcmp(observer{1},'Congruent100') || strcmp(observer{1},'Congruent0') || strcmp(observer{1},'Null')
    weightingList = 1;
else
    weightingList = [1 3 5]; % Number of Weighting
end

for w = weightingList
if w == 1 || strcmp(observer{1},'WMean_History')||strcmp(observer{1},'WMeanAcrssObj_History')...
         || strcmp(observer{1},'Congruent100')||strcmp(observer{1},'Congruent75')||strcmp(observer{1},'Congruent50')...
          || strcmp(observer{1},'Congruent25')||strcmp(observer{1},'Congruent0')
for NoiseStrength = NoiseLevel
cnt_History = 0;
O1_LMS_Stats = zeros(AllTrialN,3);O2_LMS_Stats = zeros(AllTrialN,3);
O3_LMS_Stats = zeros(AllTrialN,3);O4_LMS_Stats = zeros(AllTrialN,3);

for session = 1:NoS
if session <=2 
    sessionn = 1;
elseif session > 2
    sessionn = 2;
end

for specularN =  1:2
specular = specularList(specularN);
for backgroundN =  1:2
background = backgroundList(backgroundN);
% Note: run_simulation_exp1 simulates the surround-blind models (Null and the
% AcrssObj family) only once and writes the responses to both surround
% conditions, because there they are handed the identical trials. That
% shortcut does not apply here: Experiment 2 drew a separate trial sequence
% for each surround condition (see the huecombination file loaded below), so
% even a model that ignores the surround is answering different questions in
% the two conditions and has to be run in each.

for typen = 1:2
type = typeList(typen);

disp(['    Session',num2str(session),' Simulating...'])
disp(['Model:',observer{1},' Condition:',specular{1},background{1}])
disp(['NoiseLevel:',num2str(NoiseStrength*100),'%',' Weighting:',num2str(w)])
disp(['tau:',num2str(tau)])

conditionname_BG = strcat(lower(shape),'_',lower(specular),'_context_');
conditionname_NoBG = strcat(lower(shape),'_',lower(specular),'_nocontext_');

%number of hues tested
noh = 4;

% HueCombination(1:Target Hue,2:Distractor Hue,3:Environment that has the Target,
% 4:Pattern,5:Type(DifMax or DifMin)),6:session
temp  = load(fullfile(hue_comb_dir,['huecombination_',lower(specular{1}),'_',lower(background{1}),'_session',num2str(sessionn),'_exp3_2.mat']));
HueCombination = temp.HueCombination;
Id = find(HueCombination(:,6) == session & HueCombination(:,5) == typen);

HueCombination = HueCombination(Id,:);
s_huecombination = length(HueCombination);
ansIndex  = zeros(s_huecombination,1);
correct  = zeros(s_huecombination,1);
response  = zeros(s_huecombination,1);

trialN_condition = s_huecombination;

%start trials loop
tic
response_LMS = zeros(trialN_condition,1);correct_LMS = zeros(trialN_condition,1); 
response_Chromaticity = zeros(trialN_condition,1);correct_Chromaticity = zeros(trialN_condition,1); 

for trialN = 1:s_huecombination
    cnt_History = cnt_History + 1;
    
    O1_Hue = zeros(trialN_condition,1);O2_Hue = zeros(trialN_condition,1);
    O3_Hue = zeros(trialN_condition,1);O4_Hue = zeros(trialN_condition,1);

    Target_Hue = HueCombination(trialN,1);
    Distractor_Hue = HueCombination(trialN,2);
    Target_Environment = HueCombination(trialN,3);
    Pattern = HueCombination(trialN,4);
    
    if Target_Environment == 1
        if Pattern == 1
            fileBG_En3 =  strcat(conditionname_BG,'e3_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            fileNoBG_En3 =  strcat(conditionname_NoBG,'e3_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            answer = 1;
            O2_Hue(trialN,1) = Distractor_Hue;O3_Hue(trialN,1) = Distractor_Hue;O4_Hue(trialN,1) = Distractor_Hue;
            O1_Hue(trialN,1) = Target_Hue;
        else
            fileBG_En3 =  strcat(conditionname_BG,'e3_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            fileNoBG_En3 =  strcat(conditionname_NoBG,'e3_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            answer = 2;
            O1_Hue(trialN,1) = Distractor_Hue;O3_Hue(trialN,1) = Distractor_Hue;O4_Hue(trialN,1) = Distractor_Hue;
            O2_Hue(trialN,1) = Target_Hue;
        end
        fileBG_En4 =  strcat(conditionname_BG,'e4_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
        fileNoBG_En4 =  strcat(conditionname_NoBG,'e4_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
    elseif Target_Environment == 2
        if Pattern == 1
            fileBG_En4 =  strcat(conditionname_BG,'e4_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            fileNoBG_En4 =  strcat(conditionname_NoBG,'e4_hueupper',num2str(Target_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            answer = 3;
            O1_Hue(trialN,1) = Distractor_Hue;O2_Hue(trialN,1) = Distractor_Hue;O4_Hue(trialN,1) = Distractor_Hue;
            O3_Hue(trialN,1) = Target_Hue;
        else
            fileBG_En4 =  strcat(conditionname_BG,'e4_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            fileNoBG_En4 =  strcat(conditionname_NoBG,'e4_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Target_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
            answer = 4;
            O1_Hue(trialN,1) = Distractor_Hue;O2_Hue(trialN,1) = Distractor_Hue;O3_Hue(trialN,1) = Distractor_Hue;
            O4_Hue(trialN,1) = Target_Hue;
        end
        fileBG_En3 =  strcat(conditionname_BG,'e3_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
        fileNoBG_En3 =  strcat(conditionname_NoBG,'e3_hueupper',num2str(Distractor_Hue),'_huelower',num2str(Distractor_Hue),'_',lower(type{1}),'_mb_exp3_2_scaled.mat');
    end
    ansIndex(trialN) = answer;

    temp = load(fullfile(stimuli_dir,fileNoBG_En3{1}));MB_NoBG_En3 = temp.MB;
    temp = load(fullfile(stimuli_dir,fileNoBG_En4{1}));MB_NoBG_En4 = temp.MB;
    
    LMS_NoBG_En3 = mb_image_to_lms_image(MB_NoBG_En3);
    LMS_NoBG_En4 = mb_image_to_lms_image(MB_NoBG_En4);
        
    O1_MB = MB_NoBG_En3(1:end/2,:,:);O2_MB = MB_NoBG_En3(end/2+1:end,:,:);
    O3_MB = MB_NoBG_En4(1:end/2,:,:);O4_MB = MB_NoBG_En4(end/2+1:end,:,:);
    
    O1_LMS = LMS_NoBG_En3(1:end/2,:,:);O2_LMS = LMS_NoBG_En3(end/2+1:end,:,:);
    O3_LMS = LMS_NoBG_En4(1:end/2,:,:);O4_LMS = LMS_NoBG_En4(end/2+1:end,:,:);
    
    if strcmp(background{1},'Context')&&~strcmp(observer{1},'Null')
        temp = load(fullfile(stimuli_dir,fileBG_En3{1}));MB_BG_En3 = temp.MB;
        temp = load(fullfile(stimuli_dir,fileBG_En4{1}));MB_BG_En4 = temp.MB;

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

        Background_LMS_En3 = mb_image_to_lms_image(Background_MB_En3);
        Background_LMS_En4 = mb_image_to_lms_image(Background_MB_En4);

        LMS_BG_En3 = mb_image_to_lms_image(MB_BG_En3);
        LMS_BG_En4 = mb_image_to_lms_image(MB_BG_En4);
    end
    
    switch observer{1}
        case 'Mean_History'
            if strcmp(background{1},'Context')
                BG_MB_En3_Stats = [mean(nonzeros(Background_MB_En3(:,:,1))),mean(nonzeros(Background_MB_En3(:,:,2))),mean(nonzeros(Background_MB_En3(:,:,3)))];
                BG_MB_En4_Stats = [mean(nonzeros(Background_MB_En4(:,:,1))),mean(nonzeros(Background_MB_En4(:,:,2))),mean(nonzeros(Background_MB_En4(:,:,3)))];

                % Add Noise and Store LMS values
                O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En3_Stats),NoiseStrength*NoiseScale_LMS_En3);
                O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En3_Stats),NoiseStrength*NoiseScale_LMS_En3);
                O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En4_Stats),NoiseStrength*NoiseScale_LMS_En4);
                O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En4_Stats),NoiseStrength*NoiseScale_LMS_En4);
                
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
            O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O1_MB_Stats),NoiseStrength*NoiseScale_LMS_En3);
            O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O2_MB_Stats),NoiseStrength*NoiseScale_LMS_En3);
            O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O3_MB_Stats),NoiseStrength*NoiseScale_LMS_En4);
            O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O4_MB_Stats),NoiseStrength*NoiseScale_LMS_En4);
        
        case 'Brightest_History'
            if strcmp(background{1},'Context')
                BG_MB_En3_Stats = take_brightest(Background_MB_En3,filter);
                BG_MB_En4_Stats = take_brightest(Background_MB_En4,filter);

                % Add Noise and store values
                O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En3_Stats),NoiseStrength*NoiseScale_LMS_En3);
                O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En3_Stats),NoiseStrength*NoiseScale_LMS_En3);
                O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En4_Stats),NoiseStrength*NoiseScale_LMS_En4);
                O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En4_Stats),NoiseStrength*NoiseScale_LMS_En4);

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
            O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O1_MB_Stats),NoiseStrength*NoiseScale_LMS_En3);
            O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O2_MB_Stats),NoiseStrength*NoiseScale_LMS_En3);
            O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O3_MB_Stats),NoiseStrength*NoiseScale_LMS_En4);
            O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O4_MB_Stats),NoiseStrength*NoiseScale_LMS_En4);

        case 'WMean_History'
            if strcmp(background{1},'Context')
                BG_MB_En3_Stats = take_weighted_mean(Background_MB_En3,w,filter);
                BG_MB_En4_Stats = take_weighted_mean(Background_MB_En4,w,filter);
                
                % Add noise and store values
                O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En3_Stats),NoiseStrength*NoiseScale_LMS_En3);
                O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En3_Stats),NoiseStrength*NoiseScale_LMS_En3);
                O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En4_Stats),NoiseStrength*NoiseScale_LMS_En4);
                O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(BG_MB_En4_Stats),NoiseStrength*NoiseScale_LMS_En4);

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
            O1_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O1_MB_Stats),NoiseStrength*NoiseScale_LMS_En3);
            O2_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O2_MB_Stats),NoiseStrength*NoiseScale_LMS_En3);
            O3_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O3_MB_Stats),NoiseStrength*NoiseScale_LMS_En4);
            O4_LMS_Stats(cnt_History,:) = add_noise_lms(mb_to_lms(O4_MB_Stats),NoiseStrength*NoiseScale_LMS_En4);

        case {'Congruent100','Congruent75','Congruent50','Congruent25','Congruent0'}
            
            switch observer{1}
                case 'Congruent100'
                    w_congruent = 1;w_incongruent = 0;
                case 'Congruent75'
                    w_congruent = 0.75;w_incongruent = 0.25;
                case 'Congruent50'
                    w_congruent = 0.50;w_incongruent = 0.50;
                case 'Congruent25'
                    w_congruent = 0.25;w_incongruent = 0.75;
                case 'Congruent0'
                    w_congruent = 0;w_incongruent = 1;
            end
            
            Background_Combined_En3 = w_incongruent*Background_Incongruent_LMS_En3...
               +w_congruent*Background_Congruent_LMS_En3;
            Background_Combined_En4 = w_incongruent*Background_Incongruent_LMS_En4...
               +w_congruent*Background_Congruent_LMS_En4;   
            
            BG_LMS_En3_Stats = [mean2(Background_Combined_En3(:,:,1)),mean2(Background_Combined_En3(:,:,2)),mean2(Background_Combined_En3(:,:,3))];
            BG_LMS_En4_Stats = [mean2(Background_Combined_En4(:,:,1)),mean2(Background_Combined_En4(:,:,2)),mean2(Background_Combined_En4(:,:,3))];

            % MB to LMS
            O1_LMS_Stats(cnt_History,:) = BG_LMS_En3_Stats;
            O2_LMS_Stats(cnt_History,:) = BG_LMS_En3_Stats;
            O3_LMS_Stats(cnt_History,:) = BG_LMS_En4_Stats;
            O4_LMS_Stats(cnt_History,:) = BG_LMS_En4_Stats;
    end        
    
    % Estimate Surface Colour(SC) by taking mean LMS
    O1_LMS_SC = take_mean_nonzeros(O1_LMS);
    O2_LMS_SC = take_mean_nonzeros(O2_LMS);
    O3_LMS_SC = take_mean_nonzeros(O3_LMS);
    O4_LMS_SC = take_mean_nonzeros(O4_LMS);

    O1_MB_SC = lms_to_mb(O1_LMS_SC);
    O2_MB_SC = lms_to_mb(O2_LMS_SC);
    O3_MB_SC = lms_to_mb(O3_LMS_SC);
    O4_MB_SC = lms_to_mb(O4_LMS_SC);
    
    % add noise to surface color estimation
    O1_MB_SC = add_noise_lms(O1_MB_SC,NoiseStrength*NoiseScale_LMS_En3);
    O2_MB_SC = add_noise_lms(O2_MB_SC,NoiseStrength*NoiseScale_LMS_En3);
    O3_MB_SC = add_noise_lms(O3_MB_SC,NoiseStrength*NoiseScale_LMS_En4);
    O4_MB_SC = add_noise_lms(O4_MB_SC,NoiseStrength*NoiseScale_LMS_En4);

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
                
                LMS_En3_scaled = LMS_En3.*((O3_LMS_Stats_temp+O4_LMS_Stats_temp)/2)./((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2);
                LMS_threshold_En3 = std(vertcat(LMS_En3_scaled,LMS_En4));
                LMS_threshold_En4 = std(vertcat(LMS_En3_scaled,LMS_En4));

            elseif Target_Environment == 2
                O1_LMS_CSC = O1_LMS_SC;
                O2_LMS_CSC = O2_LMS_SC;
                O3_LMS_CSC = O3_LMS_SC.*((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2)./O3_LMS_Stats_temp;
                O4_LMS_CSC = O4_LMS_SC.*((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2)./O4_LMS_Stats_temp;       
                
                LMS_En4_scaled = LMS_En4.*((O1_LMS_Stats_temp+O2_LMS_Stats_temp)/2)./((O3_LMS_Stats_temp+O4_LMS_Stats_temp)/2);
                LMS_threshold_En3 = std(vertcat(LMS_En3,LMS_En4_scaled));
                LMS_threshold_En4 = std(vertcat(LMS_En3,LMS_En4_scaled));
            end
        else
            O1_LMS_CSC = O1_LMS_SC;O2_LMS_CSC = O2_LMS_SC;
            O3_LMS_CSC = O3_LMS_SC;O4_LMS_CSC = O4_LMS_SC;
            
            LMS_threshold_En3 = std(LMS_En3);
            LMS_threshold_En4 = std(LMS_En4);
        end
    else % if the model is 'Null'
        O1_LMS_CSC = O1_LMS_SC;O2_LMS_CSC = O2_LMS_SC;
        O3_LMS_CSC = O3_LMS_SC;O4_LMS_CSC = O4_LMS_SC;
        LMS_threshold_En3 = std(LMS_En3);
        LMS_threshold_En4 = std(LMS_En4);    
    end
    
    O1_MB_CSC = lms_to_mb(O1_LMS_CSC);
    O2_MB_CSC = lms_to_mb(O2_LMS_CSC);
    O3_MB_CSC = lms_to_mb(O3_LMS_CSC);
    O4_MB_CSC = lms_to_mb(O4_LMS_CSC);
    
    % Find Odd-One
    response_LMS(trialN) = judge_odd_one_delta_lms(O1_LMS_CSC,O2_LMS_CSC,O3_LMS_CSC,O4_LMS_CSC,LMS_threshold_En3,LMS_threshold_En4);
    response_Chromaticity(trialN) = judge_odd_one_chromaticity(O1_MB_CSC,O2_MB_CSC,O3_MB_CSC,O4_MB_CSC,rg_threshold,yb_threshold);
        
    % Store if the answer was correct or not
    if response_LMS(trialN) == answer
        correct_LMS(trialN) = 1;
    elseif response_LMS(trialN) ~= answer
        correct_LMS(trialN) = 0;
    end
    
    if response_Chromaticity(trialN) == answer
        correct_Chromaticity(trialN) = 1;
    elseif response_Chromaticity(trialN) ~= answer
        correct_Chromaticity(trialN) = 0;
    end
    
end %of Trial

% Save the results
if strcmp(observer{1},'WMean_History') || strcmp(observer{1},'GlobalWMean_History') || strcmp(observer{1},'WMeanAcrssObj_History')
    filename = strcat('model_',lower(specular{1}),'_',lower(background{1}),'_',lower(type{1}),'_session',num2str(session),'_',lower(observer),'_w',num2str(w),'_tau',num2str(tau),'_noise',num2str(NoiseStrength*100),'.mat');
else
    filename = strcat('model_',lower(specular{1}),'_',lower(background{1}),'_',lower(type{1}),'_session',num2str(session),'_',lower(observer),'_tau',num2str(tau),'_noise',num2str(NoiseStrength*100),'.mat');
end

result = struct('HueCombination','ansIndex','response_LMS','response_Chromaticity','correct_LMS','correct_Chromaticity');
result.HueCombination = HueCombination;
result.ansIndex = ansIndex;

result.response_LMS = response_LMS;
result.response_Chromaticity = response_Chromaticity;

result.correct_LMS = correct_LMS;
result.correct_Chromaticity = correct_Chromaticity;

parsave(fullfile(model_dir,filename{1}), result);

toc
end
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