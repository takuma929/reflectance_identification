function result_vertcat = vertcat_sessions(s1,s2,s3,s4)
    HueCombination = vertcat(s1.HueCombination,s2.HueCombination,s3.HueCombination,s4.HueCombination);
    %ansIndex = vertcat(s1.ansIndex,s2.ansIndex,s3.ansIndex,s4.ansIndex);
    %response = vertcat(s1.response,s2.response,s3.response,s4.response);
    correct_Human = vertcat(s1.correct_Human,s2.correct_Human,s3.correct_Human,s4.correct_Human);
    correct_Model = vertcat(s1.correct_Model,s2.correct_Model,s3.correct_Model,s4.correct_Model);

    result_vertcat.HueCombination = HueCombination;
    %result_vertcat.ansIndex = ansIndex;
    %result_vertcat.response = response;
    result_vertcat.correct_Human = correct_Human;
    result_vertcat.correct_Model = correct_Model;
end