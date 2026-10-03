% fig8_model_accuracy_exp1
% Experiment 1: how well do the computational observers SOLVE the task?
% (manuscript figure 8)
%
% This is the accuracy figure, and it is the one the paper leads with when it
% turns to models. Building any model that performs this task under
% environmental illumination is not straightforward: the light arriving at an
% object varies with direction, so there is no single illuminant to divide out,
% and the statistics used here were all proposed for flat Mondrian scenes under
% one light. Whether they transfer at all is the first question, and it is
% answered in absolute terms - percentage correct on the same trials the
% observers saw - rather than by any measure of agreement.
%
% Each panel is saved as an individual file (fig8a, fig8b). Both share one
% design: the observers of the matching condition are the leftmost column,
% and gloss is coded by the symbol (filled circle matte, open square glossy,
% as in figure 7).
%
%   (a) accuracy of each surround-based model with a surround, by gloss,
%       next to the observers in the same condition. Without a surround
%       these models have nothing to estimate and collapse onto the
%       no-correction column.
%   (b) the same models when the illuminant is estimated from the OBJECT
%       regions instead of the surround, split by whether the objects were
%       matte or glossy. This isolates what the specular image is worth: a
%       glossy object carries a specular reflection of the environment, so a
%       model that reads the illuminant off the object should improve with
%       gloss if that reflection is informative. The statistics that weight
%       the brightest part of the object - the brightest pixel, and the
%       luminance-weighted means at high powers - do improve, by 9 to 14
%       points, while those that average over the whole object get worse.
%       That is the signature of a specular highlight: the information is
%       carried by the few brightest pixels and is diluted by averaging.
%       The rightmost column, set off by a second divider because it is a
%       different class of model, is the temporal-integration account of
%       the no-context condition: the mean-chromaticity model integrating
%       surround statistics from previous trials with an exponential
%       kernel, at the time constant tau whose accuracy comes closest to
%       the observers' (chosen by sweeping tau below and printed to the
%       console).
%   (c) pair matrices, in the format of the observers' matrices in fig7c
%       and sharing their colour scale: the mean-chromaticity model with a
%       surround (with-context, matte and glossy) and the Mean tau = 10
%       temporal-integration model without one (no-context, matte and
%       glossy). A horizontal version of the shared colour bar is also
%       written, for layouts with the matrices in a row.
%
% All numbers are printed to the console.

clearvars; close all;
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));
matrix_dir = fullfile(project_root,'data','scores','exp1');
figs_dir   = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end
figp = fig_parameters();

observers = {'akh','jh','ly','ms','sr','td','tm'};
nObs = numel(observers);
conds   = {'matte_nocontext','shiny_nocontext','matte_context','shiny_context'};
noSC = [1 2]; withSC = [3 4];
matteC = [1 3]; glossyC = [2 4];

% Surround-based models and their object-based counterparts. The no-correction
% model has no counterpart: it never estimates an illuminant.
sur = {'null_tau0_noise25','mean_history_tau0_noise25', ...
       'brightest_history_tau0_noise25','wmean_history_w1_tau0_noise25', ...
       'wmean_history_w3_tau0_noise25','wmean_history_w5_tau0_noise25'};
obj = {'', 'meanacrssobj_history_tau0_noise25', ...
       'brightestacrssobj_history_tau0_noise25','wmeanacrssobj_history_w1_tau0_noise25', ...
       'wmeanacrssobj_history_w3_tau0_noise25','wmeanacrssobj_history_w5_tau0_noise25'};
lab = {'No correction','Mean','Brightest','wMean w_1','wMean w_3','wMean w_5'};
nModel = numel(sur);

% -------------------------------------------------------------------- humans
Phuman = zeros(nObs, numel(conds));
for c = 1:numel(conds)
    for o = 1:nObs
        d = load(fullfile(matrix_dir, ...
              sprintf('m_%s_%s_chromaticity.mat', conds{c}, observers{o})));
        Phuman(o,c) = d.OverallPercentageCorrect*100;
    end
end
hNo = mean(mean(Phuman(:,noSC),2));  hNoSE = sem(mean(Phuman(:,noSC),2));
hSC = mean(mean(Phuman(:,withSC),2)); hSCSE = sem(mean(Phuman(:,withSC),2));

% -------------------------------------------------------------------- models
% Models are deterministic given the stimulus, so there is one accuracy per
% model and condition, not a distribution over observers.
acc = @(tag,cc) mean(arrayfun(@(k) getfield(load(fullfile(matrix_dir, ...
        sprintf('m_%s_%s_chromaticity.mat', conds{k}, tag))), ...
        'OverallPercentageCorrect'), cc))*100;

Msur = nan(nModel,2); Mobj = nan(nModel,2);
for m = 1:nModel
    Msur(m,1) = acc(sur{m}, noSC);   Msur(m,2) = acc(sur{m}, withSC);
    if ~isempty(obj{m})
        % object-based models are split by specularity, not by surround
        Mobj(m,1) = acc(obj{m}, matteC); Mobj(m,2) = acc(obj{m}, glossyC);
    end
end

fprintf('\n============ Experiment 1: can the models solve the task? ============\n');
fprintf('Observers: %.1f%% without a surround (SE %.1f), %.1f%% with (SE %.1f)\n', ...
        hNo, hNoSE, hSC, hSCSE);
fprintf('\n%-14s %11s %11s   %11s %11s %8s\n','model', ...
        'surr:with','surr:without','obj:matte','obj:glossy','gloss');
for m = 1:nModel
    fprintf('%-14s %11.1f %11.1f   %11s %11s %8s\n', lab{m}, Msur(m,2), Msur(m,1), ...
        ternary(isnan(Mobj(m,1)),'-',sprintf('%.1f',Mobj(m,1))), ...
        ternary(isnan(Mobj(m,2)),'-',sprintf('%.1f',Mobj(m,2))), ...
        ternary(isnan(Mobj(m,1)),'-',sprintf('%+.1f',Mobj(m,2)-Mobj(m,1))));
end
fprintf(['\nThe last column is what gloss is worth to a model that reads the\n' ...
         'illuminant off the object itself. Statistics that weight the brightest\n' ...
         'part of the object gain; those that average over it lose. That is what\n' ...
         'a specular highlight should do, being carried by a few bright pixels.\n']);
fprintf('=====================================================================\n\n');

% ------------------------------------------------------------------- figures
% One file per panel. Both panels share the same design: the observers of
% the matching condition are the leftmost column, and gloss is coded by
% the symbol (matte filled circle, glossy open square, as in figure 7).

% ------------------- fig8a: surround-based models with a surround, by gloss
% The no-correction model is one of the columns; without a surround every
% surround-based model has nothing to estimate and collapses onto it (their
% measured values scatter around it only by redrawn internal noise).
MsurG = nan(nModel,2);                      % with surround: [matte glossy]
for m = 1:nModel
    MsurG(m,1) = acc(sur{m}, 3);            % matte_context
    MsurG(m,2) = acc(sur{m}, 4);            % shiny_context
end

fprintf('fig8a values (with surround), per gloss:\n');
fprintf('  %-8s', 'matte');  fprintf('%6.1f', MsurG(:,1)); fprintf('\n');
fprintf('  %-8s', 'glossy'); fprintf('%6.1f', MsurG(:,2)); fprintf('\n');

fig = figure; ax = gca; hold(ax,'on');
fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
fig.Position=[10 10 figp.onecolumn figp.onecolumn*0.68];
ax.Color = figp.axescolor;

xO = 1; xM = 2:nModel+1;                    % observers first, then the models
hMatteSC = Phuman(:,3); hGlossySC = Phuman(:,4);   % observers, with surround

% Category band behind the observers, drawn first so the data sit on top of
% it: the leftmost column is a different kind of decision maker from the
% models beside it. The tint is barely off the grey of figp.axescolor (the
% same pair of bands is used in figure 11).
xl = [0.4 nModel+1+0.6]; yl = [40 90];
bandYellow = [0.975 0.965 0.910];
patch(ax, [xl(1) 1.5 1.5 xl(1)], yl([1 1 2 2]), bandYellow, 'EdgeColor','none');

% observers: same glossy/matte symbols as the models, +/- 1 SE error bars
plot(ax, [xO xO], [mean(hMatteSC) mean(hGlossySC)], '-', ...
     'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
errorbar(ax, xO, mean(hMatteSC), sem(hMatteSC), 'o', 'Color','k', ...
    'MarkerFaceColor','k', 'MarkerSize',5, 'LineWidth', 0.5, 'CapSize', 2);
errorbar(ax, xO, mean(hGlossySC), sem(hGlossySC), 's', 'Color','k', ...
    'MarkerFaceColor','w', 'MarkerSize',5.5, 'LineWidth', figp.linewidth, ...
    'CapSize', 2);

% Markers only: the x axis is a list of models, not a continuous variable,
% so a connecting line would imply a trend that does not exist. A thin
% vertical stem joins the two gloss levels of each model instead.
for k = 1:nModel
    plot(ax, xM(k)*[1 1], MsurG(k,:), '-', 'Color', [0.75 0.75 0.75], ...
         'LineWidth', 0.5);
end
plot(ax, xM, MsurG(:,1), 'o', 'Color','k', 'MarkerFaceColor','k', 'MarkerSize',5);
plot(ax, xM, MsurG(:,2), 's', 'Color','k', 'MarkerFaceColor','w', ...
     'MarkerSize',5.5, 'LineWidth', figp.linewidth);

yline(ax, 50, ':', 'Color', 'k', 'LineWidth', 0.75);   % chance level
xline(ax, 1.5, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);   % observers | models
ax.XLim = xl; ax.XTick = 1:nModel+1;
ax.XTickLabel = [{'Observers'}, lab];
ax.XTickLabelRotation = 45; ax.YLim = yl; ax.YTick = 40:10:90;
ax.YMinorGrid = 'on';
ax.Layer = 'top';                      % grid drawn over the category band too
ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
ax.XColor = 'k'; ax.YColor = 'k';
ylabel(ax,'Correct [%]','FontSize',figp.fontsize_axis);

ax.Position = [0.15 0.26 0.81 0.71];   % room for the rotated tick labels
drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig8a_model_accuracy_surround.pdf'),'ContentType','vector');
fprintf('Saved %s\n', fullfile(figs_dir,'fig8a_model_accuracy_surround.pdf'));

% --------------------------------------- fig8b: object-based models, by gloss
% Everything in this panel is the NO-CONTEXT condition: the object-based
% models never use the surround, and the observers are shown for the same
% condition, as the leftmost column rather than as a horizontal line. The
% no-correction model has no object-based counterpart and is omitted.
fig = figure; ax = gca; hold(ax,'on');
fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
fig.Position=[10 10 figp.onecolumn figp.onecolumn*0.68];
ax.Color = figp.axescolor;

MobjN = nan(nModel,2);                       % no-context: [matte glossy]
for m = 2:nModel
    MobjN(m,1) = acc(obj{m}, 1);             % matte_nocontext
    MobjN(m,2) = acc(obj{m}, 2);             % shiny_nocontext
end
hMatte = Phuman(:,1); hGlossy = Phuman(:,2); % observers, no context

% The rightmost column is the other route to above-chance performance
% without a surround: the mean-chromaticity model that integrates surround
% statistics from PREVIOUS trials with an exponential kernel of time
% constant tau (each environment stayed on the same side throughout the
% experiment, so its statistics could be accumulated). Sweep tau and show
% the one whose no-context accuracy comes closest to the observers'.
tauList = {'0','1','10','100','1000','10000','inf'};
Mtau = nan(numel(tauList),2);                % no-context: [matte glossy]
for t = 1:numel(tauList)
    tag = sprintf('mean_history_tau%s_noise25', tauList{t});
    Mtau(t,1) = acc(tag, 1);                 % matte_nocontext
    Mtau(t,2) = acc(tag, 2);                 % shiny_nocontext
end
hNoG = [mean(hMatte) mean(hGlossy)];         % observers, per gloss
[~,tBest] = min(mean(abs(Mtau - hNoG),2));
tauLab = ['Mean \tau=' tauList{tBest}];

fprintf('fig8b temporal integration (mean model, no context):\n');
fprintf('  %-8s %8s %8s\n','tau','matte','glossy');
for t = 1:numel(tauList)
    fprintf('  %-8s %8.1f %8.1f%s\n', tauList{t}, Mtau(t,1), Mtau(t,2), ...
        ternary(t==tBest,'   <- closest to observers',''));
end
fprintf('  observers %7.1f %8.1f\n\n', hNoG(1), hNoG(2));

xO = 1; xM = 2:nModel; xT = nModel+1;        % observers, models, tau model

% Category bands, drawn first so the data sit on top of them: the observers
% (pale yellow) and the temporal-integration model (pale orange) are
% different kinds of decision maker from the object-based models between
% them, which keep the plain axes background.
xl = [0.4 xT+0.6]; yl = [40 90];
bandYellow = [0.975 0.965 0.910];
bandOrange = [0.980 0.945 0.905];
patch(ax, [xl(1) 1.5 1.5 xl(1)], yl([1 1 2 2]), bandYellow, 'EdgeColor','none');
patch(ax, [nModel+0.5 xl(2) xl(2) nModel+0.5], yl([1 1 2 2]), bandOrange, ...
      'EdgeColor','none');

% observers: same glossy/matte symbols as the models, +/- 1 SE error bars
plot(ax, [xO xO], [mean(hMatte) mean(hGlossy)], '-', ...
     'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
errorbar(ax, xO, mean(hMatte), sem(hMatte), 'o', 'Color','k', ...
    'MarkerFaceColor','k', 'MarkerSize',5, 'LineWidth', 0.5, 'CapSize', 2);
errorbar(ax, xO, mean(hGlossy), sem(hGlossy), 's', 'Color','k', ...
    'MarkerFaceColor','w', 'MarkerSize',5.5, 'LineWidth', figp.linewidth, ...
    'CapSize', 2);

% Markers only: the x axis is a list of models, not a continuous variable,
% so a connecting line would imply a trend that does not exist. A thin
% vertical stem joins the two levels of each model instead.
for k = xM
    plot(ax, [k k], MobjN(k,:), '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
end
plot(ax, xM, MobjN(2:end,1), 'o', 'Color','k', 'MarkerFaceColor','k', 'MarkerSize',5);
plot(ax, xM, MobjN(2:end,2), 's', 'Color','k', 'MarkerFaceColor','w', ...
     'MarkerSize',5.5, 'LineWidth', figp.linewidth);

% temporal-integration column, rightmost
plot(ax, [xT xT], Mtau(tBest,:), '-', 'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
plot(ax, xT, Mtau(tBest,1), 'o', 'Color','k', 'MarkerFaceColor','k', 'MarkerSize',5);
plot(ax, xT, Mtau(tBest,2), 's', 'Color','k', 'MarkerFaceColor','w', ...
     'MarkerSize',5.5, 'LineWidth', figp.linewidth);

yline(ax, 50, ':', 'Color', 'k', 'LineWidth', 0.75);   % chance level
xline(ax, 1.5, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);   % observers | models
xline(ax, nModel+0.5, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);   % object-based | temporal
ax.XLim = xl; ax.XTick = 1:xT;
ax.XTickLabel = [{'Observers'}, lab(2:end), {tauLab}];
ax.XTickLabelRotation = 45; ax.YLim = yl; ax.YTick = 40:10:90;
ax.YMinorGrid = 'on';
ax.Layer = 'top';                      % grid drawn over the category bands too
ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
ax.XColor = 'k'; ax.YColor = 'k';
ylabel(ax,'Correct [%]','FontSize',figp.fontsize_axis);

ax.Position = [0.15 0.26 0.81 0.71];   % room for the rotated tick labels
drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig8b_model_accuracy_objects.pdf'),'ContentType','vector');
fprintf('Saved %s\n', fullfile(figs_dir,'fig8b_model_accuracy_objects.pdf'));

%% ---------------- fig8c: pair matrices of the two best surround models
% These matrices show WHERE a model's accuracy comes from, pair by pair,
% in the same format (and with the same colour scale and colour bar) as
% the observers' matrices in fig7c. Two model observers, two panels each:
% the mean-chromaticity model with a surround (with-context condition,
% matte and glossy), and the temporal-integration model of fig8b (Mean,
% tau = 10) in the condition it accounts for, no context.
cPanels = { ...  % {model tag, model slug, condition}
    {'mean_history_tau0_noise25',  'mean',      'matte_context'}, ...
    {'mean_history_tau0_noise25',  'mean',      'shiny_context'}, ...
    {'mean_history_tau10_noise25', 'meantau10', 'matte_nocontext'}, ...
    {'mean_history_tau10_noise25', 'meantau10', 'shiny_nocontext'}};

side = figp.twocolumn/4*0.9;   % panel size, as in fig7c
nHue = 8; hueStep = 360/nHue;
gap = 0.5;                            % gap between hue matrix and N strips [cells]
n_center = nHue + 0.5 + gap + 0.5;    % centre coordinate of the N row/column
mlab = arrayfun(@(k)sprintf('%d',(k-1)*hueStep), 1:nHue, 'UniformOutput', false);
mlab{end+1} = 'N';

for pnl = 1:numel(cPanels)
        [cModel, cSlug, cCond] = deal(cPanels{pnl}{:});
        d = load(fullfile(matrix_dir, ...
              sprintf('m_%s_%s_chromaticity.mat', cCond, cModel)));
        pc = d.M.CorrectN_SessionSum ./ d.M.TrialN_SessionSum * 100;
        pc(logical(eye(9))) = NaN;    % the diagonal is not a reflectance pair

        fig = figure; ax = gca; hold(ax,'on');
        fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
        fig.Position=[10 10 side side];
        ax.Position = [0.18 0.18 0.76 0.76];   % room for the manual labels

        % The hue block and the two N strips are separate images, so the gap
        % between them can be narrower than one cell.
        im = image(ax, 'XData',1:nHue, 'YData',1:nHue, ...
            'CData',pc(1:nHue,1:nHue), 'CDataMapping','scaled');
        im.AlphaData = ~isnan(pc(1:nHue,1:nHue));   % blank diagonal cells
        image(ax, 'XData',n_center, 'YData',1:nHue, ...
            'CData',pc(1:nHue,nHue+1), 'CDataMapping','scaled');
        image(ax, 'XData',1:nHue, 'YData',n_center, ...
            'CData',pc(nHue+1,1:nHue), 'CDataMapping','scaled');
        clim(ax, [40 100]); colormap(ax, pair_colormap());
        ax.YDir = 'reverse'; axis(ax,'square');
        ax.XLim = [0.4 n_center+0.6]; ax.YLim = [0.4 n_center+0.6];
        ax.XColor = 'none'; ax.YColor = 'none';
        ax.Color = figp.figurecolor;            % the gap reads as empty page

        % Pale tint on the blank diagonal (same-reflectance) cells
        for k = 1:nHue
            rectangle(ax,'Position',[k-0.5 k-0.5 1 1], ...
                'FaceColor',[0.55 0.75 0.80],'EdgeColor','none');
        end

        % Frames: the 8 x 8 hue block and the two N strips
        rectangle(ax,'Position',[0.5 0.5 nHue nHue],'EdgeColor','k','LineWidth',0.5);
        rectangle(ax,'Position',[n_center-0.5 0.5 1 nHue],'EdgeColor','k','LineWidth',0.5);
        rectangle(ax,'Position',[0.5 n_center-0.5 nHue 1],'EdgeColor','k','LineWidth',0.5);

        % White asterisk on cells SIGNIFICANTLY below chance: one-tailed
        % binomial test per cell, P(X <= k | n, 0.5), corrected for multiple
        % comparisons by Benjamini-Hochberg FDR at q = 0.05 within the 72
        % pair cells of the condition - the same correction as the
        % above-chance analysis reported in the manuscript. Note that with
        % 8 trials per cell the smallest attainable p is (1/2)^8 = 0.0039,
        % so a lone below-chance cell cannot survive the correction.
        plow = binocdf(d.M.CorrectN_SessionSum, d.M.TrialN_SessionSum, 0.5);
        sig  = bh_fdr_mask(plow, ~eye(9), 0.05);
        star = @(x,y) text(ax, x, y+0.12, '*', 'Color','w', ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize+1, ...
            'FontWeight','bold');
        for i = 1:nHue
            for j = 1:nHue
                if sig(i,j); star(j, i); end
            end
            if sig(i,nHue+1); star(n_center, i); end   % N column
            if sig(nHue+1,i); star(i, n_center); end   % N row
        end
        fprintf('%s %s: %d of %d pair cells below chance after BH-FDR (q = 0.05)\n', ...
            cSlug, cCond, nnz(sig), nnz(~eye(9)));

        % Tick labels, drawn as text objects (the rulers are off)
        for k = 1:nHue
            text(ax, 0.25, k, mlab{k}, 'HorizontalAlignment','right', ...
                'VerticalAlignment','middle', ...
                'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
            text(ax, k, n_center+0.75, mlab{k}, 'Rotation',90, ...
                'HorizontalAlignment','right', 'VerticalAlignment','middle', ...
                'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
        end
        text(ax, 0.25, n_center, 'N', 'HorizontalAlignment','right', ...
            'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
        text(ax, n_center, nHue+0.75, 'N', ...
            'HorizontalAlignment','center', 'VerticalAlignment','top', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-2);

        % Axis labels; both are centred on the 8 x 8 hue matrix
        text(ax, 4.5, n_center+2.3, 'Distractor hue [deg]', ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-1);
        text(ax, -1.5, 4.5, 'Target hue [deg]', 'Rotation',90, ...
            'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-1);

        drawnow;
        panel = sprintf('fig8c%d_%s_%s', pnl, cSlug, cCond);
        exportgraphics(fig, fullfile(figs_dir,[panel '.png']),'Resolution',600);
        fprintf('Saved %s\n', fullfile(figs_dir,[panel '.png']));
end

% ---- how similar are these model matrices to the observers'? Spearman
% rank correlation over the 72 off-diagonal pair cells, model matrix vs
% the observers' pooled matrix of the same condition.
offdiag = ~eye(9);
fprintf('\nfig8c: Spearman rho, model vs pooled observer matrix (72 pair cells):\n');
for pnl = 1:numel(cPanels)
    [cModel, cSlug, cCond] = deal(cPanels{pnl}{:});
    Ch = zeros(9,9); Nh = zeros(9,9);
    for o = 1:nObs
        d = load(fullfile(matrix_dir, ...
              sprintf('m_%s_%s_chromaticity.mat', cCond, observers{o})));
        Ch = Ch + d.M.CorrectN_SessionSum; Nh = Nh + d.M.TrialN_SessionSum;
    end
    pcH = Ch./Nh*100;
    d = load(fullfile(matrix_dir, ...
          sprintf('m_%s_%s_chromaticity.mat', cCond, cModel)));
    pcM = d.M.CorrectN_SessionSum./d.M.TrialN_SessionSum*100;
    msk = offdiag & ~isnan(pcM) & ~isnan(pcH);
    [rho, pval] = corr(pcM(msk), pcH(msk), 'Type','Spearman');
    fprintf('  %-10s vs observers, %-16s rho = %.2f, n = %d, p = %.4g\n', ...
            cSlug, cCond, rho, nnz(msk), pval);
end
fprintf('\n');

% ------------- horizontal colour bar, same scale as fig7c_colorbar
% The vertical bar drawn by plot_fig7_human_performance_exp1 is shared by
% every pair matrix; this is the same bar laid out horizontally, for
% layouts where the matrices sit in a row and the bar goes beneath them.
fig = figure; fig.Units='centimeters'; fig.Color=figp.figurecolor;
fig.InvertHardcopy='off';
fig.Position = [10 10 side side*0.4];

ax = axes(fig); ax.Visible = 'off';         % only the color bar is exported
ax.Position = [0.06 0.62 0.70 0.30];
colormap(ax, pair_colormap()); clim(ax, [40 100]);
cb = colorbar(ax, 'Location','southoutside');
cb.Label.String = 'Correct [%]';
cb.FontName = figp.fontname; cb.FontSize = figp.fontsize-2;
cb.Label.FontSize = figp.fontsize-1; cb.Ticks = [40 50 70 100];

% Match the bar thickness of the vertical version, then add the swatch for
% the blank (no data) cells to its right. The swatch is a SQUARE with side
% equal to the bar thickness; the figure is wider than it is tall, so the
% normalized width is scaled by the aspect ratio.
drawnow;
cb.Position = [0.06 0.52 0.70 0.18];
p = cb.Position;
sw = p(4) * fig.Position(4)/fig.Position(3);   % square side, normalized width
swx = p(1) + p(3) + 0.08;                      % swatch left edge
annotation(fig,'rectangle',[swx p(2) sw p(4)], ...
    'FaceColor',[0.55 0.75 0.80], 'Color','k', 'LineWidth',0.5);
annotation(fig,'textbox',[swx+sw/2-0.11 p(2)-0.42 0.22 0.3], ...
    'String','No data', 'EdgeColor','none', 'FontName',figp.fontname, ...
    'FontSize',figp.fontsize-1, 'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig8c_colorbar_horizontal.pdf'),'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig8c_colorbar_horizontal.png'),'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig8c_colorbar_horizontal.pdf'));

function out = ternary(c,a,b); if c; out = a; else; out = b; end; end

function sig = bh_fdr_mask(p, mask, q)
% Benjamini-Hochberg FDR over the p-values selected by the logical mask;
% returns a logical array (same size as p) of the cells that survive.
    pv = p(mask); [ps, ~] = sort(pv(:)); m = numel(ps);
    k = find(ps <= (1:m)'/m*q, 1, 'last');
    if isempty(k); thr = -1; else; thr = ps(k); end
    sig = false(size(p)); sig(mask) = pv <= thr;
end

function s = sem(x); s = std(x)/sqrt(numel(x)); end

function cm = pair_colormap()
% Identical to the colormap of the observers' pair matrices in
% plot_fig7_human_performance_exp1, so the model and human matrices can be
% compared directly and share one colour bar: a linear greyscale, black at
% the 40% floor of the colour scale, white at 100%. (An earlier version
% drew below-chance cells in red, but no cell falls significantly below
% chance after BH-FDR correction, so the break at 50% was dropped.)
    cm = repmat(linspace(0,1,256)', 1, 3);
end
