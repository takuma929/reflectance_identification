% plot_fig11_model_accuracy_exp2
% Experiment 2 (manuscript figure 11): what happens to observers, and to the
% models, when the surround is made uninformative about the light falling on
% the objects?
%
% This is the figure the paper's argument rests on, and it is an accuracy
% comparison rather than an agreement measure. Congruent and incongruent trials
% were interleaved, and the drop from one to the other is what each decision
% maker loses when the surround stops predicting the light on the object.
%
% Two things are needed to read that drop correctly.
%
% First, the analysis is restricted to the two conditions that actually HAVE a
% surround. In the two no-surround conditions every surround-based model
% returns exactly the no-correction model's responses, because the estimate it
% depends on does not exist, so pooling those conditions in would dilute every
% model's cost by half with a number that is not about the manipulation.
%
% Second, the congruent and incongruent sets differ in viewing angle and hence
% in intrinsic difficulty, so part of any drop is the stimulus change rather
% than the loss of the cue. The no-correction model measures exactly that part:
% it never consults the surround, so whatever it loses is what the change of
% stimulus costs on its own. It is not drawn in the figure, but its cost is
% printed to the console as the baseline against which the other drops
% should be read.
%
% A model that estimates one illuminant from the surround and divides it out
% must lose far more than that baseline, because on incongruent trials its
% estimate is wrong by construction. Observers need not, and do not.
%
% The last two columns are fixed-estimate models: instead of reading the
% surround of the current trial, they hold the surround estimate of one
% trial type and divide it out on EVERY trial - the congruent-estimate
% model keeps the congruent surround (which does match the light on the
% objects), the incongruent-estimate model keeps the incongruent one.
%
% Numbers are printed to the console.

clearvars; close all;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(project_root,'src')));
matrix_dir = fullfile(project_root,'results','scores','exp2','matrix');
figs_dir   = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end
figp = fig_parameters();

observers = {'akh','jh','ly','ms','sr','td','tm'};
nObs  = numel(observers);
conds = {'matte_context','shiny_context'};   % conditions that have a surround
cong  = {'min','max'};                       % dif-min = congruent, dif-max = not
tags  = {'mean_history_tau0_noise25', ...
         'brightest_history_tau0_noise25','wmean_history_w1_tau0_noise25', ...
         'wmean_history_w3_tau0_noise25','wmean_history_w5_tau0_noise25', ...
         'congruent100_tau0_noise25','congruent0_tau0_noise25'};
lab   = {'Mean','Brightest','WMean w1','WMean w3','WMean w5', ...
         'Congruent estimate','Incongruent estimate'};    % console
labTeX = {'Mean','Brightest','wMean w_1','wMean w_3','wMean w_5', ...
         'Cong. est.','Incong. est.'};    % axis
nModel = numel(tags);

% ------------------------------------------------------- observers and models
% The figure shows the average over the two with-surround conditions
% (matte and glossy); the per-gloss numbers are printed below it in the
% console, because the observers' congruency cost differs between the
% gloss levels (Specularity x Congruency interaction, see
% plot_fig10_human_performance_exp2).
H = zeros(nObs,2,2);                        % observer x congruency x gloss
M = zeros(nModel,2,2);                      % model x congruency x gloss
for c = 1:numel(conds)
    for g = 1:2
        for o = 1:nObs
            d = load(fullfile(matrix_dir, sprintf('m_%s_%s_chromaticity_%s.mat', ...
                     conds{c}, observers{o}, cong{g})));
            H(o,g,c) = d.OverallPercentageCorrect*100;
        end
        for t = 1:nModel
            d = load(fullfile(matrix_dir, sprintf('m_%s_%s_chromaticity_%s.mat', ...
                     conds{c}, tags{t}, cong{g})));
            M(t,g,c) = d.OverallPercentageCorrect*100;
        end
    end
end

Hm = mean(H,3);                             % gloss-averaged, as in the figure
Mm = mean(M,3);

condLab = {'matte','glossy'};
fprintf('\n==== Experiment 2: cost of making the surround uninformative ====\n');
fprintf('\n--- average of the two with-surround conditions (as plotted) ---\n');
fprintf('%-14s %11s %11s %10s\n','', 'congruent','incongruent','cost');
[~,p,~,st] = ttest(Hm(:,1), Hm(:,2));
fprintf('%-14s %11.1f %11.1f %10.1f   t(%d) = %.2f, p = %.4g\n', 'Observers', ...
        mean(Hm(:,1)), mean(Hm(:,2)), mean(Hm(:,1)-Hm(:,2)), nObs-1, st.tstat, p);
for t = 1:nModel
    fprintf('%-14s %11.1f %11.1f %10.1f\n', lab{t}, Mm(t,1), Mm(t,2), Mm(t,1)-Mm(t,2));
end

for c = 1:2
    fprintf('\n--- %s, with surround ---\n', condLab{c});
    fprintf('%-14s %11s %11s %10s\n','', 'congruent','incongruent','cost');
    [~,p,~,st] = ttest(H(:,1,c), H(:,2,c));
    fprintf('%-14s %11.1f %11.1f %10.1f   t(%d) = %.2f, p = %.4g\n', 'Observers', ...
            mean(H(:,1,c)), mean(H(:,2,c)), mean(H(:,1,c)-H(:,2,c)), nObs-1, st.tstat, p);
    for t = 1:nModel
        fprintf('%-14s %11.1f %11.1f %10.1f\n', lab{t}, M(t,1,c), M(t,2,c), ...
                M(t,1,c)-M(t,2,c));
    end
    % No-correction baseline: not drawn in this figure (it is the pink
    % model of fig10a), but its cost is what the change of stimulus costs
    % on its own, so it is reported here. As in fig10a, the context and
    % no-context runs are pooled - the model never consults the surround,
    % so the two runs differ only by redrawn internal noise.
    specName = strrep(conds{c}, '_context', '');
    bgs = {'context','nocontext'};
    % The min/max file tags of the null-model runs are reversed for the
    % glossy objects, so the congruency index is flipped there.
    nullPct = zeros(1,2);
    for g = 1:2
        gg = g; if strcmp(specName,'shiny'); gg = 3-g; end
        v = 0;
        for bgi = 1:2
            d = load(fullfile(matrix_dir, sprintf('m_%s_%s_null_tau0_noise25_chromaticity_%s.mat', ...
                     specName, bgs{bgi}, cong{gg})));
            v = v + d.OverallPercentageCorrect*100/2;
        end
        nullPct(g) = v;
    end
    fprintf('%-14s %11.1f %11.1f %10.1f   (fig10a; not in this figure)\n', ...
            'No correction', nullPct(1), nullPct(2), nullPct(1)-nullPct(2));
end
fprintf(['\nRestricted to the two conditions that have a surround. The no-correction\n' ...
         'model never consults the surround, so its cost is what the change of\n' ...
         'stimulus costs on its own, and is the baseline against which the other\n' ...
         'costs should be read.\n']);
fprintf('=================================================================\n\n');

% -------------------------------------------------------------------- figure
% One panel, averaged over the two with-surround conditions.
fig = figure; fig.Units='centimeters'; fig.Color=figp.figurecolor;
fig.InvertHardcopy='off';
fig.Position=[10 10 figp.onecolumn figp.onecolumn*0.68*1.32];   % fig8a/b height + 32%
ax = gca; hold(ax,'on'); ax.Color = figp.axescolor;

x = 1:nModel+1;                          % observers occupy position 1
allC = [mean(Hm(:,1)); Mm(:,1)];
allI = [mean(Hm(:,2)); Mm(:,2)];

% Category bands, drawn first so everything else sits on top of them: the
% observers (pale yellow) and the two fixed-estimate models (pale blue) are
% different kinds of decision maker from the surround-based models between
% them, which keep the plain axes background. The tints are barely off the
% grey of figp.axescolor, so they group without competing with the data.
xl = [0.4 nModel+1.6]; yl = [40 100];
bandYellow = [0.975 0.965 0.910];
bandBlue   = [0.920 0.945 0.968];
patch(ax, [xl(1) 1.5 1.5 xl(1)], yl([1 1 2 2]), bandYellow, 'EdgeColor','none');
patch(ax, [6.5 xl(2) xl(2) 6.5], yl([1 1 2 2]), bandBlue,   'EdgeColor','none');

for k = 1:numel(x)
    plot(ax, [x(k) x(k)], [allC(k) allI(k)], '-', 'Color', [0.75 0.75 0.75], ...
         'LineWidth', 0.5);
end
plot(ax, x(2:end), allC(2:end), 'o', 'Color','k','MarkerFaceColor','k','MarkerSize',5);
plot(ax, x(2:end), allI(2:end), 's', 'Color',[0.45 0.45 0.45], ...
     'MarkerFaceColor','w','MarkerSize',5.5,'LineWidth',figp.linewidth);
errorbar(ax, x(1), allC(1), std(Hm(:,1))/sqrt(nObs), 'o', 'Color','k', ...
     'MarkerFaceColor','k','MarkerSize',5,'CapSize',2, ...
     'LineWidth',figp.linewidth);
errorbar(ax, x(1), allI(1), std(Hm(:,2))/sqrt(nObs), 's', 'Color','k', ...
     'MarkerFaceColor','w','MarkerSize',5.5,'CapSize',2,'LineWidth',figp.linewidth);

yline(ax, 50, ':', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.75);
% Two dividers, drawn identically: observers | surround-based models | the
% two models that hold a fixed estimate instead of reading the current
% surround.
for xdiv = [1.5 6.5]                       % same style as the fig8 dividers
    xline(ax, xdiv, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);
end
ax.XLim = xl; ax.XTick = x;
ax.XTickLabel = [{'Observers'} labTeX]; ax.XTickLabelRotation = 45;
ax.YLim = yl; ax.YTick = 40:10:100;
ax.YMinorGrid = 'on';
ax.Layer = 'top';                      % grid drawn over the category bands too
ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
ax.XColor = 'k'; ax.YColor = 'k';
ylabel(ax,'Correct [%]','FontSize',figp.fontsize_axis);

ax.Position = [0.15 0.26 0.81 0.71];   % as fig8a/b (room for rotated labels)
drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig11_model_accuracy_exp2.pdf'),'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig11_model_accuracy_exp2.png'),'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig11_model_accuracy_exp2.pdf'));

%% ------- fig11c: pair matrices of the congruent-estimate model
% Where does the survival come from, pair by pair? The fixed
% congruent-estimate model (93.3% congruent, 85.6% incongruent), on
% congruent and on incongruent trials, with counts pooled over the two
% conditions that have a surround - the same restriction as the panels
% above. Format, colour scale and below-chance test as in the Experiment 1
% matrices.
congFile = {'congruent','incongruent'};
offdiag = ~eye(5);
fprintf(['\nfig11c: Spearman rho, congruent-estimate model vs pooled observer\n' ...
         'matrix (off-diagonal pair cells, same pooling as the panels):\n']);
for g = 1:2
    Cm = zeros(5,5); Nm = zeros(5,5);          % model counts
    Ch = zeros(5,5); Nh = zeros(5,5);          % pooled observer counts
    CoH = zeros(5,5,nObs); NoH = zeros(5,5,nObs);  % per-observer counts
    for c = 1:numel(conds)
        d = load(fullfile(matrix_dir, sprintf('m_%s_congruent100_tau0_noise25_chromaticity_%s.mat', ...
                 conds{c}, cong{g})));
        Cm = Cm + d.M.CorrectN_SessionSum; Nm = Nm + d.M.TrialN_SessionSum;
        for o = 1:nObs
            d = load(fullfile(matrix_dir, sprintf('m_%s_%s_chromaticity_%s.mat', ...
                     conds{c}, observers{o}, cong{g})));
            Ch = Ch + d.M.CorrectN_SessionSum; Nh = Nh + d.M.TrialN_SessionSum;
            CoH(:,:,o) = CoH(:,:,o) + d.M.CorrectN_SessionSum;
            NoH(:,:,o) = NoH(:,:,o) + d.M.TrialN_SessionSum;
        end
    end

    pcM = Cm./Nm*100; pcH = Ch./Nh*100;
    msk = offdiag & Nm > 0 & Nh > 0;
    [rho, pval] = corr(pcM(msk), pcH(msk), 'Type','Spearman');
    fprintf('  %-12s trials: rho = %.2f, n = %d, p = %.4g\n', ...
            congFile{g}, rho, nnz(msk), pval);

    % Inter-observer upper limit for that value: each observer's matrix
    % against the pooled matrix of the remaining six, averaged.
    rhos = zeros(1,nObs);
    for o = 1:nObs
        rest = setdiff(1:nObs,o);
        pcO = CoH(:,:,o)./NoH(:,:,o)*100;
        pcR = sum(CoH(:,:,rest),3)./sum(NoH(:,:,rest),3)*100;
        mskO = offdiag & NoH(:,:,o) > 0 & sum(NoH(:,:,rest),3) > 0;
        rhos(o) = corr(pcO(mskO), pcR(mskO), 'Type','Spearman');
    end
    fprintf('  %-12s inter-observer ceiling: mean rho = %.2f (leave-one-out)\n', ...
            congFile{g}, mean(rhos));

    panel = sprintf('fig11c%d_congruentest_%s', g, congFile{g});
    draw_pair_matrix_exp2(Cm, Nm, figp, figs_dir, panel);
end

% ------------------------------------------------------------- local helpers
function draw_pair_matrix_exp2(Cm, Nm, figp, figs_dir, panel)
% One 5 x 5 pair matrix (4 hues + N) in the fig7c format, from pooled
% correct/trial counts. Identical to the helper of the same name in
% plot_fig10_human_performance_exp2. Saves <panel>.png (600 dpi).
    nHue = 4; gap = 0.5; n_center = nHue + 0.5 + gap + 0.5;
    mlab = {'0','90','180','270'};
    side = figp.twocolumn/4*0.9;

    pc = Cm./Nm*100;
    pc(logical(eye(5))) = NaN;            % the diagonal is not a pair

    fig = figure; ax = gca; hold(ax,'on');
    fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
    fig.Position=[10 10 side side];
    ax.Position = [0.22 0.18 0.72 0.72];

    im = image(ax, 'XData',1:nHue, 'YData',1:nHue, ...
        'CData',pc(1:nHue,1:nHue), 'CDataMapping','scaled');
    im.AlphaData = ~isnan(pc(1:nHue,1:nHue));
    imN1 = image(ax, 'XData',n_center, 'YData',1:nHue, ...
        'CData',pc(1:nHue,nHue+1), 'CDataMapping','scaled');
    imN1.AlphaData = ~isnan(pc(1:nHue,nHue+1));
    imN2 = image(ax, 'XData',1:nHue, 'YData',n_center, ...
        'CData',pc(nHue+1,1:nHue), 'CDataMapping','scaled');
    imN2.AlphaData = ~isnan(pc(nHue+1,1:nHue));
    clim(ax, [40 100]); colormap(ax, pair_colormap());
    ax.YDir = 'reverse'; axis(ax,'square');
    ax.XLim = [0.4 n_center+0.6]; ax.YLim = [0.4 n_center+0.6];
    ax.XColor = 'none'; ax.YColor = 'none';
    ax.Color = figp.figurecolor;

    % Pale tint on every cell without data (the diagonal, plus any
    % untested pair)
    nodata = [0.55 0.75 0.80];
    for i = 1:5
        for j = 1:5
            if ~isnan(pc(i,j)); continue; end
            xx = j; yy = i;
            if j == 5; xx = n_center; end
            if i == 5; yy = n_center; end
            if i == 5 && j == 5; continue; end   % N-N corner is not drawn
            rectangle(ax,'Position',[xx-0.5 yy-0.5 1 1], ...
                'FaceColor',nodata,'EdgeColor','none');
        end
    end

    % Frames: hue block and the two N strips
    rectangle(ax,'Position',[0.5 0.5 nHue nHue],'EdgeColor','k','LineWidth',0.5);
    rectangle(ax,'Position',[n_center-0.5 0.5 1 nHue],'EdgeColor','k','LineWidth',0.5);
    rectangle(ax,'Position',[0.5 n_center-0.5 nHue 1],'EdgeColor','k','LineWidth',0.5);

    % White asterisk on cells significantly below chance (one-tailed
    % binomial per cell, BH-FDR q = 0.05 within the off-diagonal cells)
    plow = binocdf(Cm, Nm, 0.5);
    sig  = bh_fdr_mask(plow, ~eye(5) & Nm > 0, 0.05);
    for i = 1:5
        for j = 1:5
            if ~sig(i,j); continue; end
            xx = j; yy = i;
            if j == 5; xx = n_center; end
            if i == 5; yy = n_center; end
            text(ax, xx, yy+0.08, '*', 'Color','w', ...
                'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
                'FontName',figp.fontname, 'FontSize',figp.fontsize+1, ...
                'FontWeight','bold');
        end
    end
    fprintf('%s: %d of %d pair cells below chance after BH-FDR (q = 0.05)\n', ...
        panel, nnz(sig), nnz(~eye(5)));

    % Tick labels as text objects (the rulers are off)
    for k = 1:nHue
        text(ax, 0.30, k, mlab{k}, 'HorizontalAlignment','right', ...
            'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
        text(ax, k, n_center+0.55, mlab{k}, 'Rotation',90, ...
            'HorizontalAlignment','right', 'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
    end
    text(ax, 0.30, n_center, 'N', 'HorizontalAlignment','right', ...
        'VerticalAlignment','middle', ...
        'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
    text(ax, n_center, nHue+0.60, 'N', ...
        'HorizontalAlignment','center', 'VerticalAlignment','top', ...
        'FontName',figp.fontname, 'FontSize',figp.fontsize-2);

    % Axis labels, centred on the hue block
    text(ax, (nHue+1)/2, n_center+1.55, 'Distractor hue [deg]', ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'FontName',figp.fontname, 'FontSize',figp.fontsize-1);
    text(ax, -0.95, (nHue+1)/2, 'Target hue [deg]', 'Rotation',90, ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'FontName',figp.fontname, 'FontSize',figp.fontsize-1);

    drawnow;
    exportgraphics(fig, fullfile(figs_dir,[panel '.png']),'Resolution',600);
    fprintf('Saved %s\n', fullfile(figs_dir,[panel '.png']));
end

function cm = pair_colormap()
% Identical to the pair matrices of Experiment 1: linear greyscale, black
% at the 40% floor of the colour scale, white at 100%.
    cm = repmat(linspace(0,1,256)', 1, 3);
end

function sig = bh_fdr_mask(p, mask, q)
% Benjamini-Hochberg FDR over the p-values selected by the logical mask;
% returns a logical array (same size as p) of the cells that survive.
    pv = p(mask); ps = sort(pv(:)); m = numel(ps);
    k = find(ps <= (1:m)'/m*q, 1, 'last');
    if isempty(k); thr = -1; else; thr = ps(k); end
    sig = false(size(p)); sig(mask) = pv <= thr;
end
