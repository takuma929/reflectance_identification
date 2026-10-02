function main(RERUN_SIMULATION, RERUN_SCORES)
% MAIN  One-click regeneration of the analysis results and all paper figures.
%
%   >> main                 recompute scores, then redraw every figure
%   >> main(true)           also rerun the model simulations (slow, parfor)
%   >> main(false, false)   reuse existing results, only redraw figures
%
%   Stages
%     (1) run_simulation_exp1 / run_simulation_exp2 - computational observer
%         models over all trials (optional; hours with parfor, writes
%         results/model/).
%     (2) compute_scores_exp1 / compute_scores_exp2 - performance matrices
%         and trial-by-trial scores of humans vs models (writes
%         results/scores/ and results/matrix_images/).
%     (3) plotting - one script per manuscript figure, plot_fig<N>_*.m,
%         redrawn into figs/. Each results figure also prints the statistics
%         quoted in the manuscript to the console.
%
%   Requirements
%     - MATLAB (developed with R2016b, verified with R2025b)
%     - Statistics and Machine Learning Toolbox (fitrm / ranova)
%     - data/ as bundled with this repository; brewermap and the other
%       third-party helpers are in src/functions/vendor/
%
%   Notes
%     - plot_fig6_viewing_angles additionally needs the camera-angle renders
%       in data/external/E3E4_AllAnglewithMirrorMB (not bundled; see README).
%       It draws Figure 6 and the viewing-angle panels of Figure 9.
%     - plot_fig3_all_stimuli re-renders the stimuli and needs Mitsuba +
%       RenderToolbox4; it is skipped here.
%     - Analysis/plotting files are scripts that clear the workspace, so
%       they are launched with evalin('base', ...).

% ---------------------------------------------------------------- configuration
if nargin < 1 || isempty(RERUN_SIMULATION), RERUN_SIMULATION = false; end
if nargin < 2 || isempty(RERUN_SCORES),     RERUN_SCORES     = true;  end

% ------------------------------------------------------------------------- paths
project_root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(project_root, 'src')));

% -------------------------------------------------------------- 1. simulations
if RERUN_SIMULATION
    fprintf('\n=== [1/3] Running model simulations (slow) ===\n');
    evalin('base', 'run_simulation_exp1');
    evalin('base', 'run_simulation_exp2');
end

% -------------------------------------------------------------------- 2. scores
if RERUN_SCORES
    fprintf('\n=== [2/3] Computing scores (humans vs models) ===\n');
    evalin('base', 'compute_scores_exp1');
    evalin('base', 'compute_scores_exp2');
end

% ------------------------------------------------------------------- 3. figures
fprintf('\n=== [3/3] Redrawing figures ===\n');
figure_scripts = { ...
    'plot_fig1_environment', ...              % environments / chromatic distributions
    'plot_fig2_reflectance', ...              % surface reflectances
    'plot_fig4_procedure', ...                % trial-procedure panels
    'plot_fig5_gaussian_noise', ...           % internal-noise inset of the model schematic
    'plot_fig7_human_performance_exp1', ...   % Exp 1 human performance + ANOVA
    'plot_fig8_model_accuracy_exp1', ...      % Exp 1 model accuracy vs observers
    'plot_fig9_exp2_stimuli', ...             % Exp 2 example presentations
    'plot_fig10_human_performance_exp2', ...  % Exp 2 human performance + ANOVA
    'plot_fig11_model_accuracy_exp2'};        % Exp 2 cost of an uninformative surround
for k = 1:numel(figure_scripts)
    fprintf('--- %s\n', figure_scripts{k});
    try
        evalin('base', figure_scripts{k});
    catch err
        warning('%s failed: %s', figure_scripts{k}, err.message);
    end
end

% plot_fig6_viewing_angles (Figure 6 and the angle panels of Figure 9) needs
% data/external - run it if the folder is present.
if exist(fullfile(project_root, 'data', 'external', 'E3E4_AllAnglewithMirrorMB'), 'dir')
    fprintf('--- plot_fig6_viewing_angles\n');
    evalin('base', 'plot_fig6_viewing_angles');
else
    fprintf(['--- plot_fig6_viewing_angles skipped ', ...
             '(data/external/E3E4_AllAnglewithMirrorMB not found)\n']);
end

% Figure 3 (plot_fig3_all_stimuli) re-renders every stimulus and needs Mitsuba
% and RenderToolbox4, so it is not part of the default run; call it directly
% when those are installed.

fprintf('\nDone. Figures are in figs/.\n');
end
