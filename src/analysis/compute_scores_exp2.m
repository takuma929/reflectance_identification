% compute_scores_exp2
% -----------------------------------------------------------------------------
% Experiment 2 counterpart of COMPUTE_SCORES_EXP1. Scores every model observer
% against every human observer, separately for congruent and incongruent trials
% (file tags "min" and "max"), and writes:
%
%   results/scores/exp2/matrix/      percentage correct per reflectance pair
%   results/scores/exp2/all_scores/  per-observer agreement counts (see
%                                    CALC_ALL_SCORES_EXP2)
%
% Five reflectances were used here rather than nine, so the performance
% matrices are 5 x 5 and the diagonal (identical target and distractor) is
% excluded.
% -----------------------------------------------------------------------------

clearvars; close all;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(project_root,'src')));

excludeIndex = 1:6:25; % exclude diagonal cells

includeIndex = 1:25; 
includeIndex(excludeIndex)=0; % include other cells

ExtIndex = nonzeros(includeIndex);

weightingList = [1 3 5]; % Number of Weighting

%NoiseLevel = [0 25 50 100]; % level 100%
NoiseLevel = [25]; % level 100%

tauList = [0 1 10 100 1000 inf];

%SignalType = {'Chromaticity','LMS'};
SignalType = {'Chromaticity'};

human_dir         = fullfile(project_root,'data','human','exp2');
model_dir         = fullfile(project_root,'results','model','exp2');
matdir            = fullfile(project_root,'results','scores','exp2','matrix');
AllScoresdir      = fullfile(project_root,'results','scores','exp2','all_scores');
matrix_images_dir = fullfile(project_root,'results','matrix_images','exp2');

if ~exist(matdir,'dir'); mkdir(matdir); end
if ~exist(AllScoresdir,'dir'); mkdir(AllScoresdir); end
if ~exist(matrix_images_dir,'dir'); mkdir(matrix_images_dir); end

load(fullfile(project_root,'data','config','threshold.mat'));

rg_threshold = 0.0071;
yb_threshold = 0.1325;
Threshold_STD(:,1,:) = (Threshold(:,1,:)-0.7078)/rg_threshold;
Threshold_STD(:,2,:) = (Threshold(:,2,:)-1)/yb_threshold;

% Chance level was 50% once the trial InCorrect condition was excluded
chancelevel = 0.5;

cnt = ones(4,1);

firstsession = 1;
finalsession = 4;

%% Creating ComputationalModelList
Model_Basis = {'Mean_History','Brightest_History','MeanAcrssObj_History','BrightestAcrssObj_History'};
WeightingModel_Basis = {'WMean_History','WMeanAcrssObj_History'};

% Basic Models
cnt_Model = 1;
for ii = 1:length(Model_Basis)  
    for tau = tauList
        for Noise = NoiseLevel
            if tau == Inf
                Model{cnt_Model} = [Model_Basis{ii},'_tauInf_Noise',num2str(Noise)];
            else
                Model{cnt_Model} = [Model_Basis{ii},'_tau',num2str(tau),'_Noise',num2str(Noise)];
            end
            cnt_Model = cnt_Model + 1;
        end
    end
end

% Weighting Models
cnt_Model = 1;
for ii = 1:length(WeightingModel_Basis)  
    for w = weightingList
        for tau = tauList
            for Noise = NoiseLevel
                WeightingModel{cnt_Model} = [WeightingModel_Basis{ii},'_w',num2str(w),'_tau',num2str(tau),'_Noise',num2str(Noise)];
                cnt_Model = cnt_Model + 1;
            end
        end
    end
end

% Null Model
cnt_Model = 1;
for Noise = NoiseLevel
    for tau = 0
        NullModel{cnt_Model} = ['Null_tau',num2str(tau),'_Noise',num2str(Noise)];
        cnt_Model = cnt_Model + 1;
    end
end

ComputationalModelList = [Model,WeightingModel,NullModel,'Congruent100_tau0_Noise25','Congruent0_tau0_Noise25'];
%ComputationalModelList = [Model,WeightingModel];
%ComputationalModelList = [NullModel];
%ComputationalModelList = {'Congruent100_tau0_Noise25','Congruent0_tau0_Noise25'};

%% Creating Matrix
disp('Creating Matrix....');

o = 0;sp = 0;bg = 0;
noh = 4;

%[c,num,typ] = brewermap(256,'PuBu');
c_Ext = brewermap(32,'*Greys');

HumanObserverList = {'AKH','JH','LY','MS','SR','TD','TM'};

for type = SignalType
    for congruency = {'Min','Max'}
        for observer = [HumanObserverList,'HumanAverage',ComputationalModelList]
            o = o + 1;
            for specular = {'Matte','Shiny'}
                sp = sp + 1;
                for background = {'NoContext','Context'}
                    bg = bg + 1;   
                    CorrectN = zeros(noh+1,noh+1,finalsession-firstsession+1);
                    TrialN = zeros(noh+1,noh+1,finalsession-firstsession+1);

                    if ~strcmp(observer{1},'HumanAverage')
                        for session = firstsession:finalsession
                            if sum(strcmp(observer{1},HumanObserverList))
                                filename = fullfile(human_dir,['potato_',lower(specular{1}),'_',lower(background{1}),'_dif',lower(congruency{1}),'_session',num2str(session),'_',lower(observer{1}),'_exp3_2']);
                            else
                                filename = fullfile(model_dir,['model_',lower(specular{1}),'_',lower(background{1}),'_dif',lower(congruency{1}),'_session',num2str(session),'_',lower(observer{1})]);
                            end
                            load(filename);
                            
                            session_trialN = length(result.HueCombination);
                            
                            if ~sum(strcmp(observer{1},HumanObserverList))
                                switch type{1}
                                    case 'LMS'
                                        result.correct = result.correct_LMS(1:session_trialN);
                                        result.response = result.response_LMS(1:session_trialN);
                                    case 'Chromaticity'
                                        result.correct = result.correct_Chromaticity(1:session_trialN);
                                        result.response = result.response_Chromaticity(1:session_trialN);
                                end
                            end

                            Aside = zeros(session_trialN,1);
                            Rside = zeros(session_trialN,1);

                            % Number of InCorrect Side
                            % Answer side
                            Aside((result.ansIndex == 1)|(result.ansIndex == 2),1) = 1;
                            Aside((result.ansIndex == 3)|(result.ansIndex == 4),1) = 2;

                            % Response side
                            Rside((result.response == 1)|(result.response == 2),1) = 1;
                            Rside((result.response == 3)|(result.response == 4),1) = 2;

                            result.SC = zeros(length(result.response),1);
                            result.SC(Aside == Rside) = 1;

                            HueCombination_SC = result.HueCombination(Aside == Rside,:);
                            ansIndex_SC = result.ansIndex(Aside == Rside);
                            correct_SC = result.correct(Aside == Rside);
                            response_SC = result.response(Aside == Rside);

                            for i = 1:length(response_SC)
                                if HueCombination_SC(i,3) == 1
                                    Target = max(HueCombination_SC(i,1),HueCombination_SC(i,2)); % Target Hue
                                    Distracter = min(HueCombination_SC(i,1),HueCombination_SC(i,2)); % Distractor Hue
                                elseif HueCombination_SC(i,3) == 2
                                    Target = min(HueCombination_SC(i,1),HueCombination_SC(i,2)); % Target Hue
                                    Distracter = max(HueCombination_SC(i,1),HueCombination_SC(i,2)); % Distractor Hue
                                end                        
                                CorrectN(Target,Distracter,session) = CorrectN(Target,Distracter,session)+correct_SC(i);
                                TrialN(Target,Distracter,session) = TrialN(Target,Distracter,session)+1;
                            end
                        end

                        M.CorrectN = CorrectN; % The number of correct Trial
                        M.TrialN = TrialN;  % The number of side-correct Trial
                        M.CorrectN_SessionSum = sum(CorrectN,3); % The session sum of correct Trial
                        M.TrialN_SessionSum = sum(TrialN,3); % The session sum of side-correct Trial

                        % Number of Trials where observers chose Incorrect side
                        mask = repmat(~diag(ones(1,noh+1)),1,1,finalsession-firstsession+1);
                        M.InCorrectN = 2*ones(noh+1,noh+1,finalsession-firstsession+1).*mask-M.TrialN; 
                        M.InCorrectN_SessionSum = sum(M.InCorrectN,3);

                        M.PercentageCorrect = M.CorrectN_SessionSum./M.TrialN_SessionSum;
                        M.PercentageInCorrect = M.InCorrectN_SessionSum/8;

                        % Replace Nan with Zero
                        M.PercentageCorrect(isnan(M.PercentageCorrect))=0;
                        M.PercentageInCorrect(isnan(M.PercentageInCorrect))=0;

                        OverallPercentageCorrect = sum(M.CorrectN(:))/sum(M.TrialN_SessionSum(:));

                        save(fullfile(matdir,['m_',lower(specular{1}),'_',lower(background{1}),'_',lower(observer{1}),'_',lower(type{1}),'_',lower(congruency{1})]),...
                        'M','OverallPercentageCorrect')

                    elseif strcmp(observer{1},'HumanAverage') % Write a Matrix for Human Average
                        o2 = 0;
                        M_HumanAverage = zeros(5,5,length(HumanObserverList));
                        for observer2 = HumanObserverList
                            o2 = o2 + 1;
                            load(fullfile(matdir,['m_',lower(specular{1}),'_',lower(background{1}),'_',lower(observer2{1}),'_',lower(type{1}),'_',lower(congruency{1})]))
                            M_HumanAverage(:,:,o2) = M.PercentageCorrect;
                        end
                        MatrixPlot = draw_performance_matrix_exp2(mean(M_HumanAverage,3));
                        imwrite(MatrixPlot,fullfile(matrix_images_dir,['p_matrix_',lower(specular{1}),'_',lower(background{1}),'_',lower(observer{1}),'_',lower(type{1}),'_',lower(congruency{1}),'.png']));
                    end

                    MatrixPlot = draw_performance_matrix_exp2(M.PercentageCorrect);

                    imwrite(MatrixPlot,fullfile(matrix_images_dir,['p_matrix_',lower(specular{1}),'_',lower(background{1}),'_',lower(observer{1}),'_',lower(type{1}),'_',lower(congruency{1}),'.png']));

                    % if the model is human observer, write an InCorrectMatrix
                    if sum(strcmp(observer{1},HumanObserverList))
                        %InCorrectMatrixPlot = draw_incorrect_matrix(M.InCorrectN_SessionSum);
                        %imwrite(InCorrectMatrixPlot,fullfile(matrix_images_dir,['IC_Matrix_',specular{1},'_',background{1},'_',observer{1},'_',type{1},'_',congruency{1},'.png']));
                    end

                end
                bg = 0;
            end
            sp = 0;
        end
        o = 0;
    end
end

%% Calculating - All scores Human, Computational Model vs. Human Observer
disp('Caculating All scores....');
m = 0;sp = 0;bg = 0;o = 0;
for type = SignalType
    for congruency = {'Min','Max'}
        for model = ComputationalModelList
            m = m + 1;
            for specular = {'Matte','Shiny'}
                sp = sp + 1;
                for background = {'NoContext','Context'}
                    bg = bg + 1; 
                    clear resultModel resultHuman Matrix P
                    for observer = HumanObserverList
                        o = o + 1;

                        for session = firstsession:finalsession
                            load(fullfile(model_dir,['model_',lower(specular{1}),'_',lower(background{1}),'_dif',lower(congruency{1}),'_session',num2str(session),'_',lower(model{1})]));

                            switch type{1}
                                case 'LMS'
                                    result.correct = result.correct_LMS(1:session_trialN);
                                    result.response = result.response_LMS(1:session_trialN);
                                case 'Chromaticity'
                                    result.correct = result.correct_Chromaticity(1:session_trialN);
                                    result.response = result.response_Chromaticity(1:session_trialN);
                            end
                            resultModel(session) = result;
                            
                            load(fullfile(human_dir,['potato_',lower(specular{1}),'_',lower(background{1}),'_dif',lower(congruency{1}),'_session',num2str(session),'_',lower(observer{1}),'_exp3_2']));
                            resultHuman(session) = result;                    
                        end

                        [Matrix(o),P(o)] = calc_all_scores_exp2(resultHuman,resultModel,noh,finalsession-firstsession+1,model,observer);
                    end
                    save(fullfile(AllScoresdir,['allscores_',lower(specular{1}),'_',lower(background{1}),'_',lower(model{1}),'_',lower(type{1}),'_',lower(congruency{1})]),...
                    'Matrix','P')
                    o = 0;
                end
                bg = 0;
            end
            sp = 0;
        end
        m = 0;
    end
end
