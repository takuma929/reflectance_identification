function A = agreement_from_counts(tp, tn, fp, fn)
% AGREEMENT_FROM_COUNTS  Model-human agreement on which trials succeed and fail.
%
% Counts follow the convention of calc_all_scores_exp1/exp2, where each trial
% is classified by whether each decision maker was CORRECT on that trial:
%   tp = Hit              human correct   & model correct
%   tn = CorrectRejection human incorrect & model incorrect
%   fp = FalseAlarm       human incorrect & model correct
%   fn = Miss             human correct   & model incorrect
%
% Returns a struct with three views of the same 2x2 table:
%
%   A.success       P(model correct | human correct) = tp/(tp+fn)
%                   Taking the trials the observer got right as 100%, the
%                   fraction the model also got right.
%   A.successChance P(model correct) = (tp+fp)/N
%                   Chance level for A.success: the value it would take if
%                   the model's responses were independent of the observer's.
%
%   A.error         P(model wrong | human wrong) = tn/(tn+fp)
%   A.errorChance   P(model wrong) = (tn+fn)/N
%                   Chance level for A.error, defined the same way.
%
%   A.kappa         error consistency [Geirhos 2020]
%                   (cObs - cExp)/(1 - cExp), where cObs is the fraction of
%                   trials on which model and observer agreed (both right or
%                   both wrong) and cExp is the agreement expected from their
%                   two accuracies alone, p_h*p_m + (1-p_h)*(1-p_m). It is 0
%                   when the two agree exactly as often as independent
%                   decision makers of those accuracies would, and 1 when
%                   they agree on every trial. This is Cohen's kappa on the
%                   correct/incorrect coding, and is reported because it is
%                   the standard measure in the human-versus-machine
%                   literature. Note that it removes the agreement forced by
%                   accuracy but NOT the agreement produced by both parties
%                   finding the same stimuli hard - that is what
%                   DIFFICULTY_CONTROLLED_AGREEMENT is for.
%   A.cObs, A.cExp  the two terms above, kept for reporting.
%
%   A.dprime        z(A.success) - z(P(model correct | human wrong))
%                   Signal-detection summary that combines the two: it is 0
%                   when the model's successes and failures carry no
%                   information about the observer's, and grows as the model
%                   both succeeds where the observer succeeds and fails where
%                   the observer fails. Unlike the two conditional
%                   probabilities, it needs no separate chance baseline.
%
% The log-linear correction (0.5 added to each count, 1 to each total) is
% applied to the two rates entering d' [Hautus 1995]. It is applied uniformly
% rather than only to extreme cells, which is the recommended practice; a
% small number of observer x condition cells would otherwise give an infinite
% d' because the model agreed with the observer on every trial of one kind.

    N = tp + tn + fp + fn;

    if (tp + fn) == 0; A.success = NaN; else; A.success = tp/(tp + fn); end
    if (tn + fp) == 0; A.error   = NaN; else; A.error   = tn/(tn + fp); end
    if N == 0
        A.successChance = NaN; A.errorChance = NaN;
    else
        A.successChance = (tp + fp)/N;
        A.errorChance   = (tn + fn)/N;
    end

    % Error consistency: observed agreement against the agreement two
    % independent decision makers of these accuracies would already reach.
    if N == 0
        A.cObs = NaN; A.cExp = NaN; A.kappa = NaN;
    else
        pHuman = (tp + fn)/N;          % observer's accuracy on these trials
        pModel = (tp + fp)/N;          % model's accuracy on the same trials
        A.cObs = (tp + tn)/N;
        A.cExp = pHuman*pModel + (1 - pHuman)*(1 - pModel);
        if abs(1 - A.cExp) < eps
            A.kappa = NaN;             % accuracies at ceiling: kappa undefined
        else
            A.kappa = (A.cObs - A.cExp)/(1 - A.cExp);
        end
    end

    % d' from the hit rate P(model correct | human correct) and the false-alarm
    % rate P(model correct | human wrong), both log-linear corrected.
    hitRate   = (tp + 0.5)/(tp + fn + 1);
    falseRate = (fp + 0.5)/(fp + tn + 1);
    A.dprime  = norminv(hitRate) - norminv(falseRate);
end
