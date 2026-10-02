function result = equate_hue_combination_exp1(resultHuman,resultModel)
    [C,iHuman,iModel] = intersect(resultHuman.HueCombination,resultModel.HueCombination,'rows');
    
    result.HueCombination = resultHuman.HueCombination(iHuman,:);
    %result.HueCombination_Human = resultHuman.HueCombination(iHuman,:);
    %result.ansIndex_Human = resultHuman.ansIndex(iHuman,:);
    result.correct_Human = resultHuman.correct(iHuman,:);
    %result.response_Human = resultHuman.response(iHuman,:);
    
    %result.HueCombination_Model = resultModel.HueCombination(iModel,:);
    %result.ansIndex_Model = resultModel.ansIndex(iModel,:);
    result.correct_Model = resultModel.correct(iModel,:);
    %result.response_Model = resultModel.response(iModel,:);
end