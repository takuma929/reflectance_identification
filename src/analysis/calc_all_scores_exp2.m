function [Matrix,P] = calc_all_scores_exp2(resultHuman,resultModel,noh,NoS,modelname,observername)
% CALC_ALL_SCORES_EXP2  Cross-tabulate one model's responses against one observer's.
%
% Builds the 2 x 2 table that every agreement measure in the paper is computed
% from. The signal-detection labels are used with the OBSERVER'S OUTCOME as the
% signal, not the physical truth, so the names do not mean what they usually do:
%
%     Hit              observer correct   AND model correct
%     Miss             observer correct   BUT model wrong
%     FalseAlarm       observer wrong     BUT model correct
%     CorrectRejection observer wrong     AND model wrong
%
% Read that way, the hit rate is P(model correct | observer correct) and one
% minus the false-alarm rate is P(model wrong | observer wrong) -- the two
% quantities plotted in the model figures, combined into d' by
% AGREEMENT_FROM_COUNTS.
%
% Only trials on which the decision maker chose the correct SIDE are counted
% (FIND_SIDE_CORRECT_TRIALS), because choosing the wrong side reflects failed
% discrimination within an environment rather than failed constancy across
% environments. Human and model trials are then matched on their hue
% combination, which uniquely identifies a trial within a session.
%
% INPUTS
%   resultHuman, resultModel  1 x NoS structs of per-session trial records
%   noh                       number of hue angles (five in this experiment)
%   NoS                       number of sessions
%   modelname, observername   labels stored in the output for bookkeeping
%
% OUTPUTS
%   Matrix  counts and rates resolved by reflectance pair, indexed
%           (target hue, distractor hue). The table is deliberately NOT
%           symmetric: reflectances were scaled by the discrimination
%           thresholds of the environment holding the target, so the same pair
%           of hues is a different discrimination depending on which side the
%           target was on.
%   P       the same counts pooled over all pairs, plus the derived measures
%           (hit rate, d', and the agreement struct P.Agreement).
%
% See also AGREEMENT_FROM_COUNTS, DIFFICULTY_CONTROLLED_AGREEMENT.
Matrix.Hit = zeros(noh+1,noh+1);
Matrix.Miss = zeros(noh+1,noh+1);
Matrix.CorrectRejection = zeros(noh+1,noh+1);
Matrix.FalseAlarm = zeros(noh+1,noh+1);
Matrix.TrialN = zeros(noh+1,noh+1);
Matrix.Signal_TrialN = zeros(noh+1,noh+1);
Matrix.Noise_TrialN = zeros(noh+1,noh+1);
Matrix.HitRate = zeros(noh+1,noh+1);
Matrix.CorrectRejectionRate = zeros(noh+1,noh+1);
Matrix.FalseAlarmRate = zeros(noh+1,noh+1);
Matrix.MissRate = zeros(noh+1,noh+1);
Matrix.pN = zeros(noh+1,noh+1);
Matrix.pSN = zeros(noh+1,noh+1);
Matrix.ZN= zeros(noh+1,noh+1);
Matrix.dprime = zeros(noh+1,noh+1);
Matrix.F1 = zeros(noh+1,noh+1);
Matrix.Beta = zeros(noh+1,noh+1);
Matrix.Log10Beta = zeros(noh+1,noh+1);
Matrix.C = zeros(noh+1,noh+1);
Matrix.ModelName = modelname;
Matrix.ObserverName = observername;

P.Hit = 0;
P.Miss = 0;
P.CorrectRejection = 0;
P.FalseAlarm = 0;
P.TrialN = 0;
P.Signal_TrialN = 0;
P.Noise_TrialN = 0;
P.HitRate = 0;
P.CorrectRejectionRate = 0;
P.FalseAlarmRate = 0;
P.MissRate = 0;
P.pN = 0;
P.pSN = 0;
P.ZN= 0;
P.dprime = 0;
P.F1 = 0;
P.MCC = 0;
P.Sensitivity = 0;
P.Specificity = 0;
P.Beta = 0;
P.Log10Beta = 0;
P.C = 0;
P.ModelName = modelname;
P.ObserverName = observername;

for session = 1:NoS
    % Extract trials where observers chose correct side
    resultHuman_SC = find_side_correct_trials(resultHuman(session));
    resultModel_SC = find_side_correct_trials(resultModel(session));
    result_session(session)  = equate_hue_combination_exp2(resultHuman_SC,resultModel_SC);
end

% Combine all sessions, result will have contains 576 trials
result = vertcat_sessions(result_session(1),result_session(2),result_session(3),result_session(4));

for i = 1:length(result.HueCombination)
    if result.HueCombination(i,3) == 1
        Target = max(result.HueCombination(i,1),result.HueCombination(i,2)); % Target Hue
        Distracter = min(result.HueCombination(i,1),result.HueCombination(i,2)); % Distractor Hue
    elseif result.HueCombination(i,3) == 2
        Distracter = max(result.HueCombination(i,1),result.HueCombination(i,2)); % Target Hue
        Target = min(result.HueCombination(i,1),result.HueCombination(i,2)); % Distractor Hue
    end

    % Classify Trial into Hit, Correct Rejection, False Alarm, Miss
    if result.correct_Model(i) == result.correct_Human(i)
        if result.correct_Model(i) == 1
            % Hit
            Matrix.Hit(Target,Distracter) = Matrix.Hit(Target,Distracter)+1;
            P.Hit = P.Hit+1;
            Matrix.Signal_TrialN(Target,Distracter) = Matrix.Signal_TrialN(Target,Distracter)+1;
            P.Signal_TrialN = P.Signal_TrialN+1;
        else
            % Correct Rejection
            Matrix.CorrectRejection(Target,Distracter) = Matrix.CorrectRejection(Target,Distracter)+1;
            P.CorrectRejection = P.CorrectRejection+1;
            Matrix.Noise_TrialN(Target,Distracter) = Matrix.Noise_TrialN(Target,Distracter)+1;
            P.Noise_TrialN = P.Noise_TrialN+1;
        end
    else
        if result.correct_Model(i) == 1
            % False Alarm
            Matrix.FalseAlarm(Target,Distracter) = Matrix.FalseAlarm(Target,Distracter)+1;
            P.FalseAlarm = P.FalseAlarm+1;
            Matrix.Noise_TrialN(Target,Distracter) = Matrix.Noise_TrialN(Target,Distracter)+1;
            P.Noise_TrialN = P.Noise_TrialN+1;
        else
            % Miss
            Matrix.Miss(Target,Distracter) = Matrix.Miss(Target,Distracter)+1;
            P.Miss = P.Miss+1;
            Matrix.Signal_TrialN(Target,Distracter) = Matrix.Signal_TrialN(Target,Distracter)+1;
            P.Signal_TrialN = P.Signal_TrialN+1;
        end           
    end
    Matrix.TrialN(Target,Distracter) = Matrix.TrialN(Target,Distracter)+1;
    P.TrialN = P.TrialN+1;
end

Matrix.HitRate = Matrix.Hit./Matrix.Signal_TrialN;
Matrix.CorrectRejectionRate = Matrix.CorrectRejection./Matrix.Noise_TrialN;
Matrix.FalseAlarmRate = Matrix.FalseAlarm./Matrix.Noise_TrialN;
Matrix.MissRate = Matrix.Miss./Matrix.Signal_TrialN;

Matrix.pN = 1-Matrix.FalseAlarmRate;
Matrix.pSN = 1-Matrix.HitRate;

Matrix.ZN = norminv(Matrix.pN);Matrix.ZSN = norminv(Matrix.pSN);

Matrix.dprime = Matrix.ZN-Matrix.ZSN;
Matrix.Beta = normpdf(Matrix.ZSN)./normpdf(Matrix.ZN);
Matrix.Log10Beta = log10(Matrix.Beta);
Matrix.C = 0.5*(Matrix.ZSN+Matrix.ZN);

P.HitRate = P.Hit./P.Signal_TrialN;
P.CorrectRejectionRate = P.CorrectRejection./P.Noise_TrialN;
P.FalseAlarmRate = P.FalseAlarm./P.Noise_TrialN;
P.MissRate = P.Miss./P.Signal_TrialN;

% Calculate F1 Score here
P.Precision = P.Hit/(P.Hit+P.FalseAlarm);
P.Recall = P.Hit/(P.Hit+P.Miss);
P.F1 = 2*P.Recall*P.Precision/(P.Recall+P.Precision);

% Calculate Sensitivity, Specificity and MCC
P.Sensitivity = P.Recall;
P.Specificity = P.CorrectRejection/(P.CorrectRejection+P.FalseAlarm);
P.MCC = (P.Hit*P.CorrectRejection-P.FalseAlarm*P.Miss)/sqrt((P.Hit+P.FalseAlarm)*(P.Hit+P.Miss)*(P.CorrectRejection+P.FalseAlarm)*(P.CorrectRejection+P.Miss));

% Success- and error-pattern agreement (reported in the main figures): of the
% trials the observer got right/wrong, the fraction the model also got
% right/wrong, each with its chance baseline, plus the d' that combines them.
P.Agreement = agreement_from_counts(P.Hit,P.CorrectRejection,P.FalseAlarm,P.Miss);

P.pN = 1-P.FalseAlarmRate;
P.pSN = 1-P.HitRate;
P.ZN = norminv(P.pN);P.ZSN = norminv(P.pSN);

P.dprime = P.ZN-P.ZSN;
P.Beta = normpdf(P.ZSN)./normpdf(P.ZN);
P.Log10Beta = log10(P.Beta);
P.C = 0.5*(P.ZSN+P.ZN);
end