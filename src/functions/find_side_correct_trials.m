function result_SC = find_side_correct_trials(result)
% Extract trials where observers/model chose correct side
Aside(find((result.ansIndex == 1)|(result.ansIndex == 2)),1) = 1;
Aside(find((result.ansIndex == 3)|(result.ansIndex == 4)),1) = 2;
Rside(find((result.response == 1)|(result.response == 2)),1) = 1;
Rside(find((result.response == 3)|(result.response == 4)),1) = 2;
result.SC = zeros(length(result.response),1);
SC_Id = find(Aside == Rside);
result.SC(SC_Id) = 1;

result_SC.HueCombination = result.HueCombination(SC_Id,:);
result_SC.ansIndex = result.ansIndex(SC_Id);
result_SC.correct = result.correct(SC_Id);
result_SC.response = result.response(SC_Id);
end