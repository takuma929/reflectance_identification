function run_all()
%RUN_ALL Regenerate every figure of the paper.
%   Make this repository the current folder in MATLAB (or add it to the
%   path) and call RUN_ALL. Each figure script resolves its own paths, reads
%   the data in data/ and writes its panels into figs/. The statistics
%   quoted in the paper are printed to the Command Window as each figure is
%   drawn.
%
%   Each script is run in the base workspace inside try/catch, so one
%   failing figure does not stop the others.

figure_scripts = { ...
    'fig1_environment', ...
    'fig2_reflectance', ...
    'fig4_procedure', ...
    'fig5_gaussian_noise', ...
    'fig7_human_performance_exp1', ...
    'fig8_model_accuracy_exp1', ...
    'fig9_exp2_stimuli', ...
    'fig10_human_performance_exp2', ...
    'fig11_model_accuracy_exp2'};

for k = 1:numel(figure_scripts)
    name = figure_scripts{k};
    fprintf('\n===== %s (%d/%d) =====\n', name, k, numel(figure_scripts));
    try
        evalin('base', name);
    catch err
        fprintf(2, 'Skipped %s: %s\n', name, err.message);
    end
end

fprintf('\nDone. Figures written to %s\n', ...
    fullfile(fileparts(mfilename('fullpath')), 'figs'));
end
