% fig7_human_performance_exp1
% Experiment 1 human colour-constancy performance (manuscript figure 7).
% Every panel is saved as an individual file.
%
%   fig7a_human_performance_exp1  the mean across observers with each
%       observer's data overlaid across the four conditions, plus the
%       no-correction (null) model.
%
%   fig7b_session_learning  percentage correct across the four sessions,
%       without and with the surrounding context (gloss averaged), with the
%       no-correction model scored session by session on the same trials.
%
%   fig7c<1-4>_<condition>_pairs  performance resolved by which pair of
%       reflectances was presented: one matrix per condition, averaged over
%       the seven observers. Rows/columns are the eight hue directions plus
%       the neutral reflectance (N), drawn as a separate block after a gap
%       because the hue circle does not continue into N. The lower-left and
%       upper-right triangles hold trials with the target under environment
%       1 and 2 respectively. Greyscale, black 40% to white 100%.
%       fig7c_colorbar is the shared color bar (with the no-data swatch).
%
%   fig7d_hue_separation  performance against the hue-angle separation of
%       the pair, which is what "difficulty" means in this experiment.
%
% The statistics reported in the paper are printed to the MATLAB window.

clearvars; close all;
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

matrix_dir = fullfile(project_root,'data','scores','exp1');
figs_dir   = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end
figp = fig_parameters();

observers = {'AKH','JH','LY','MS','SR','TD','TM'};
nObs = numel(observers);

% Four conditions in plotting order. NoContext = No Surrounding Context,
% Context = Surrounding Context (confirmed against the manuscript means).
conds = {'matte_nocontext','shiny_nocontext','matte_context','shiny_context'};
condLabels = {'Matte','Glossy','Matte','Glossy'};
groupLabels = {'No context','With context'};

% ---------------------------------------------------------------- load data
P = zeros(nObs, numel(conds));   % observers x conditions, proportion correct
C = zeros(9,9,nObs,numel(conds)); N = zeros(9,9,nObs,numel(conds));   % pair counts
Cs = zeros(9,9,4,nObs,numel(conds)); Ns = zeros(9,9,4,nObs,numel(conds));  % per session
for c = 1:numel(conds)
    for o = 1:nObs
        d = load(fullfile(matrix_dir, ['m_' conds{c} '_' lower(observers{o}) '_chromaticity.mat']));
        P(o,c) = d.OverallPercentageCorrect;
        C(:,:,o,c) = d.M.CorrectN_SessionSum;
        N(:,:,o,c) = d.M.TrialN_SessionSum;
        Cs(:,:,:,o,c) = d.M.CorrectN;
        Ns(:,:,:,o,c) = d.M.TrialN;
    end
end
Ppct = P*100;

% ---------------------------------------------------- report statistics
fprintf('\n================ Experiment 1: human performance ================\n');
fprintf('%-16s  %6s  %5s\n','Condition','Mean%','SE%');
for c = 1:numel(conds)
    fprintf('%-8s %-7s  %6.1f  %5.1f\n', condLabels{c}, ...
        ternary(c<=2,'(NoSC)','(SC)'), mean(Ppct(:,c)), sem(Ppct(:,c)));
end
noSC = mean(Ppct(:,1:2),2);  withSC = mean(Ppct(:,3:4),2);
matte = mean(Ppct(:,[1 3]),2); glossy = mean(Ppct(:,[2 4]),2);
fprintf('\nMain effect means (across observers):\n');
fprintf('  No context = %.1f%% (SE %.1f)   With context = %.1f%% (SE %.1f)\n', ...
    mean(noSC), sem(noSC), mean(withSC), sem(withSC));
fprintf('  Matte      = %.1f%% (SE %.1f)   Glossy       = %.1f%% (SE %.1f)\n', ...
    mean(matte), sem(matte), mean(glossy), sem(glossy));

% Two-way repeated-measures ANOVA: Specularity (matte/glossy) x Context (SC/NoSC)
T = array2table(Ppct, 'VariableNames', {'MatteNoSC','GlossyNoSC','MatteSC','GlossySC'});
within = table( categorical({'matte';'glossy';'matte';'glossy'}), ...
                categorical({'noSC';'noSC';'SC';'SC'}), ...
                'VariableNames', {'Specularity','Context'});
rm = fitrm(T, 'MatteNoSC-GlossySC ~ 1', 'WithinDesign', within);
ranovatbl = ranova(rm, 'WithinModel', 'Specularity*Context');
fprintf('\nTwo-way repeated-measures ANOVA (percentage correct):\n');
printRManova(ranovatbl);

% ------------------------------------------------------- cue-by-cue analysis
% The 2x2 design manipulates two potential sources of information about the
% illumination independently: the surrounding context, and the specular
% highlight on the object itself. Reporting each as a simple effect says
% directly which of them observers actually used.
fprintf('\nWhat each cue is worth (paired t-tests, n = %d):\n', nObs);
fprintf('  Adding the SURROUND:\n');
for s = 1:2   % 1 = matte, 2 = glossy
    a = Ppct(:,s); b = Ppct(:,s+2);            % columns 1-2 no context, 3-4 context
    [~,p,~,st] = ttest(b,a);
    fprintf('    %-7s %.1f -> %.1f (%+.1f pts)  t(%d) = %.2f, p = %.4g\n', ...
        condLabels{s}, mean(a), mean(b), mean(b)-mean(a), nObs-1, st.tstat, p);
end
fprintf('  Adding the SPECULAR highlight:\n');
for k = 0:1   % 0 = no context (cols 1,2), 1 = context (cols 3,4)
    a = Ppct(:,1+2*k); b = Ppct(:,2+2*k);
    [~,p,~,st] = ttest(b,a);
    fprintf('    %-11s %.1f -> %.1f (%+.1f pts)  t(%d) = %.2f, p = %.4g\n', ...
        ternary(k==0,'no context','context'), mean(a), mean(b), mean(b)-mean(a), ...
        nObs-1, st.tstat, p);
end

% Is there any illumination information available WITHOUT a surround? Compare
% observers with the null model, which applies no illuminant correction at all,
% in the same no-context conditions. Beating it means observers had information
% about the illumination from some source other than the surround - most
% plausibly knowledge of the two environments accumulated across trials, since
% each environment stayed on the same side throughout the experiment.
fprintf('\n  Without a surround, do observers still beat a no-correction model?\n');
for s = 1:2
    d = load(fullfile(matrix_dir,['m_' conds{s} '_null_tau0_noise25_chromaticity.mat']));
    nullPct = d.OverallPercentageCorrect*100;
    [~,p,~,st] = ttest(Ppct(:,s) - nullPct);
    fprintf('    %-7s human %.1f%% vs null model %.1f%% (%+.1f)  t(%d) = %.2f, p = %.4g\n', ...
        condLabels{s}, mean(Ppct(:,s)), nullPct, mean(Ppct(:,s))-nullPct, ...
        nObs-1, st.tstat, p);
end
fprintf('==================================================================\n\n');

% ------------------------------------------------------------------- figure
fig = figure; ax = gca; hold on;
fig.Units = 'centimeters'; fig.Color = figp.figurecolor; fig.InvertHardcopy = 'off';
fig.Position = [10 10 figp.onecolumn figp.onecolumn*0.85];   % one column wide
ax.Color = figp.axescolor;   % standard light-grey axes background

x = [1 2 4 5];   % gap between the two context groups
obsColor = [0.60 0.60 0.60];

% individual observers: points connected by lines within each context group
for o = 1:nObs
    plot(x(1:2), Ppct(o,1:2), '-', 'Color', [obsColor 0.5], 'LineWidth', 0.5, ...
        'Marker','o', 'MarkerSize', 3, 'MarkerFaceColor', obsColor, 'MarkerEdgeColor','none');
    plot(x(3:4), Ppct(o,3:4), '-', 'Color', [obsColor 0.5], 'LineWidth', 0.5, ...
        'Marker','o', 'MarkerSize', 3, 'MarkerFaceColor', obsColor, 'MarkerEdgeColor','none');
end
% mean +/- SE within each context group. Condition symbols as in fig7b and
% fig7d: grey for no context, black for with context; matte a filled circle,
% glossy an open square.
mP = mean(Ppct); eP = sem(Ppct);
humCol = {[0.55 0.55 0.55],[0.55 0.55 0.55],[0 0 0],[0 0 0]};
humMrk = {'o','s','o','s'};
humFil = {'flat','none','flat','none'};
humMsz = [6 7 6 7];
for g = [1 3]
    plot(x(g:g+1), mP(g:g+1), '-', 'Color', humCol{g}, 'LineWidth', 1.5);
end
errorbar(x, mP, eP, 'k', 'LineStyle','none', 'LineWidth', 0.5, 'CapSize', 1);
for c = 1:numel(conds)
    plot(x(c), mP(c), humMrk{c}, 'Color', humCol{c}, ...
        'MarkerFaceColor', ternary(strcmp(humFil{c},'flat'), humCol{c}, 'w'), ...
        'MarkerSize', humMsz(c), 'LineWidth', figp.linewidth);
end

% No-correction model: the same task performed with no discounting of the
% illumination at all. Drawn here so that the observers' advantage over it -
% the evidence that they had illumination information even with no surround -
% can be read straight off the figure instead of only from the text.
nullPct = zeros(1, numel(conds));
for c = 1:numel(conds)
    d = load(fullfile(matrix_dir, ...
             ['m_' conds{c} '_null_tau0_noise25_chromaticity.mat']));
    nullPct(c) = d.OverallPercentageCorrect*100;
end
nullColor = [0.85 0.4 0.55];
for g = [1 3]
    plot(x(g:g+1), nullPct(g:g+1), '-', 'Color', nullColor, 'LineWidth', 1);
end
plot(x, nullPct, 's', 'MarkerSize', 7, 'MarkerFaceColor', nullColor, ...
     'MarkerEdgeColor', nullColor, 'LineWidth', 1);

yline(50, ':', 'Color', [0 0 0 0.4], 'LineWidth', figp.axeslinewidth);   % chance level

ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
ax.XColor = 'k'; ax.YColor = 'k';
ax.XLim = [0.4 5.6]; ax.YLim = [45 100];
ax.XTick = x; ax.XTickLabel = condLabels;
ax.YTick = 50:10:100;
ylabel('Percentage correct [%]', 'FontSize', figp.fontsize_axis);
% context group labels on a second row, below the Matte/Glossy tick labels
xn = @(xd) (xd-ax.XLim(1))/(ax.XLim(2)-ax.XLim(1));
text(xn(1.5), -0.11, groupLabels{1}, 'Units','normalized', 'HorizontalAlignment','center', 'FontName',figp.fontname, 'FontSize',figp.fontsize_axis, 'FontWeight','bold');
text(xn(4.5), -0.11, groupLabels{2}, 'Units','normalized', 'HorizontalAlignment','center', 'FontName',figp.fontname, 'FontSize',figp.fontsize_axis, 'FontWeight','bold');

grid minor
% The uneven major ticks (x = [1 2 4 5]) make MATLAB's automatic minor grid
% uneven; pin the minor grid lines to a uniform spacing on both axes.
ax.XAxis.MinorTickValues = 0.5:0.5:5.5;
ax.YAxis.MinorTickValues = 45:2.5:100;

% Expand the axes to fill the canvas: exportgraphics crops to the drawn
% content, so with default margins the exported figure ends up smaller than
% figp.onecolumn. TightInset covers tick/axis labels; the extra bottom room
% keeps the second-row context group labels inside the export.
drawnow;
ti = ax.TightInset;
bottom = ti(2) + 0.10;
% TightInset underestimates the side margins slightly, so pad both sides a
% little to keep the y-label and the axes inside the figure.
left = ti(1) + 0.03;
ax.Position = [left, bottom, 1-left-ti(3)-0.03, 1-bottom-ti(4)];

% TightInset is not always reliable about the y-label, so measure where the
% label actually rendered and, if it pokes past the left figure edge, shift
% the axes right by the overhang.
drawnow;
ax.YLabel.Units = 'normalized';
ylabel_left = ax.Position(1) + ax.YLabel.Extent(1)*ax.Position(3);
if ylabel_left < 0.01
    shift = 0.01 - ylabel_left;
    ax.Position(1) = ax.Position(1) + shift;
    ax.Position(3) = ax.Position(3) - shift;
end
fig7a_axpos = ax.Position;   % reused by fig7b so the two plot boxes align

drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig7a_human_performance_exp1.pdf'), 'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig7a_human_performance_exp1.png'), 'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig7a_human_performance_exp1.pdf'));

%% ===================== fig7b: learning across the four sessions
% Percentage correct per session, for each of the four conditions. Symbols
% follow fig7d: matte filled circles, glossy open squares; grey without a
% surround, black with one.
nSes = size(Cs,3);
Pses = nan(nObs, nSes, numel(conds));
for c = 1:numel(conds)
    for o = 1:nObs
        for s = 1:nSes
            cc = Cs(:,:,s,o,c); nn = Ns(:,:,s,o,c);
            Pses(o,s,c) = sum(cc(:))/sum(nn(:))*100;
        end
    end
end

fprintf('Per-session %% correct:\n');
fprintf('  %-22s', 'session'); fprintf('%8d', 1:nSes); fprintf('\n');
sesLab = {'matte, no context','glossy, no context','matte, context','glossy, context'};
for c = 1:numel(conds)
    fprintf('  %-22s', sesLab{c}); fprintf('%8.1f', mean(Pses(:,:,c),1)); fprintf('\n');
end

% Condition styling, as in fig7d
sesCol = {[0.55 0.55 0.55],[0.55 0.55 0.55],[0 0 0],[0 0 0]};
sesMrk = {'o','s','o','s'};
sesFil = {'flat','none','flat','none'};
sesMsz = [6 7 6 7];
sesLabFull = {'Matte, no context','Glossy, no context', ...
              'Matte, with context','Glossy, with context'};

fig = figure; ax = gca; hold(ax,'on');
fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
fig.Position=[10 10 figp.onecolumn figp.onecolumn*0.85];   % same height as fig7a
ax.Color = figp.axescolor;

for c = 1:numel(conds)
    m = mean(Pses(:,:,c),1); e = std(Pses(:,:,c),0,1)/sqrt(nObs);
    errorbar(ax, 1:nSes, m, e, ['-' sesMrk{c}], 'Color', sesCol{c}, ...
        'MarkerFaceColor', ternary(strcmp(sesFil{c},'flat'), sesCol{c}, 'w'), ...
        'MarkerSize', sesMsz(c), 'LineWidth', figp.linewidth, 'CapSize', 2);
end
yline(ax, 50, ':', 'Color', 'k', 'LineWidth', 1);   % chance level

ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
ax.XColor = 'k'; ax.YColor = 'k';
ax.XLim = [0.6 nSes+0.4]; ax.XTick = 1:nSes;
ax.YLim = [45 100]; ax.YTick = 50:10:100;
ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on';
xlabel(ax,'Session','FontSize',figp.fontsize_axis);
ylabel(ax,'Correct [%]','FontSize',figp.fontsize_axis);

% Legend, top left: symbols only (dummy line-less handles), as in fig7d
hleg = gobjects(1,numel(conds));
for c = 1:numel(conds)
    hleg(c) = plot(ax, nan, nan, sesMrk{c}, 'Color', sesCol{c}, ...
        'MarkerFaceColor', ternary(strcmp(sesFil{c},'flat'), sesCol{c}, 'w'), ...
        'MarkerSize', sesMsz(c), 'LineStyle','none');
end
lgd = legend(ax, hleg, sesLabFull, 'Location','northwest', 'FontSize', 7);
lgd.Color = figp.axescolor; lgd.EdgeColor = 'none';   % opaque, as in fig7d
ax.Position = fig7a_axpos;   % same plot box as fig7a, so the panels align

drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig7b_session_learning.pdf'),'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig7b_session_learning.png'),'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig7b_session_learning.pdf'));

%% ============================ fig7c: one pair matrix per condition
side = figp.twocolumn/4*0.9;   % panel size: a quarter of the two-column width, 10% reduced
nHue = 8; hueStep = 360/nHue;

% Rows/columns 1-8 are the hue directions; the neutral reflectance (N) is
% drawn as a separate strip, offset by `gap` cells so the matrix visibly
% breaks between 315 deg and N (the hue circle does not continue into N).
gap = 0.5;                            % gap between hue matrix and N strips [cells]
n_center = nHue + 0.5 + gap + 0.5;    % centre coordinate of the N row/column
lab = arrayfun(@(k)sprintf('%d',(k-1)*hueStep), 1:nHue, 'UniformOutput', false);
lab{end+1} = 'N';

for c = 1:numel(conds)
    % Pool trials over observers before taking the ratio, so that cells with
    % missing trials for one observer are not given undue weight. The diagonal
    % is not a reflectance pair and is left blank rather than plotted as zero.
    pc = sum(C(:,:,:,c),3)./sum(N(:,:,:,c),3)*100;
    pc(logical(eye(9))) = NaN;

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
    ax.XLim = [0.4 n_center+0.6]; ax.YLim = [0.4 n_center+0.6];   % frames unclipped
    % exportgraphics rebuilds the axis rulers on export, which restores the
    % spine lines even if they were hidden. The rulers are therefore turned
    % off entirely and every tick/axis label is drawn as a text object.
    ax.XColor = 'none'; ax.YColor = 'none';
    ax.Color = figp.figurecolor;            % the gap reads as empty page

    % Pale tint on the blank diagonal (same-reflectance) cells
    for k = 1:nHue
        rectangle(ax,'Position',[k-0.5 k-0.5 1 1], ...
            'FaceColor',[0.55 0.75 0.80],'EdgeColor','none');
    end

    % Close the 8 x 8 hue-pair matrix with its own black frame and frame the
    % N row/column separately beyond the gap, so the hue circle and the
    % neutral reflectance read as distinct blocks.
    rectangle(ax,'Position',[0.5 0.5 nHue nHue],'EdgeColor','k','LineWidth',0.5);
    rectangle(ax,'Position',[n_center-0.5 0.5 1 nHue],'EdgeColor','k','LineWidth',0.5);
    rectangle(ax,'Position',[0.5 n_center-0.5 nHue 1],'EdgeColor','k','LineWidth',0.5);

    % White asterisk on cells SIGNIFICANTLY below chance: one-tailed
    % binomial test on the pooled counts (7 observers x 8 trials = 56 per
    % cell), corrected for multiple comparisons by Benjamini-Hochberg FDR
    % at q = 0.05 within the 72 pair cells of the condition - the same
    % correction as the above-chance analysis reported in the manuscript.
    plow = binocdf(sum(C(:,:,:,c),3), sum(N(:,:,:,c),3), 0.5);
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
    fprintf('%s: %d of %d pair cells below chance after BH-FDR (q = 0.05)\n', ...
        conds{c}, nnz(sig), nnz(~eye(9)));

    % Tick labels. The hue labels sit left of / below the full matrix; each
    % N label sits right next to its own block (the x-axis 'N' would
    % otherwise end up far below its column, beyond the gap and the N row).
    for k = 1:nHue
        text(ax, 0.25, k, lab{k}, 'HorizontalAlignment','right', ...
            'VerticalAlignment','middle', ...
            'FontName',figp.fontname, 'FontSize',figp.fontsize-2);
        text(ax, k, n_center+0.75, lab{k}, 'Rotation',90, ...
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
    text(ax, 4.5, n_center+2.3, 'Distractor hue [deg]', 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontName',figp.fontname, 'FontSize',figp.fontsize-1);
    text(ax, -1.5, 4.5, 'Target hue [deg]', 'Rotation',90, ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'FontName',figp.fontname, 'FontSize',figp.fontsize-1);

    drawnow;
    panel = sprintf('fig7c%d_%s_pairs', c, conds{c});
    exportgraphics(fig, fullfile(figs_dir,[panel '.pdf']),'ContentType','vector');
    exportgraphics(fig, fullfile(figs_dir,[panel '.png']),'Resolution',600);
    fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,[panel '.pdf']));
end

%% =================== fig7c colorbar (shared by fig7c1-4), as its own file
fig = figure; fig.Units='centimeters'; fig.Color=figp.figurecolor;
fig.InvertHardcopy='off';
fig.Position = [10 10 side*0.7 side];

ax = axes(fig); ax.Visible = 'off';         % only the color bar is exported
ax.Position = [0.05 0.22 0.25 0.73];        % room for the label + no-data swatch
colormap(ax, pair_colormap()); clim(ax, [40 100]);
cb = colorbar(ax);
cb.Label.String = 'Correct [%]';
cb.FontName = figp.fontname; cb.FontSize = figp.fontsize-2;
cb.Label.FontSize = figp.fontsize-1; cb.Ticks = [40 50 70 100];

% Widen the bar, then add a swatch for the blank (no data) cells below it.
% The swatch is a SQUARE with side equal to the bar width; the figure is
% taller than it is wide, so the normalized height is scaled by the aspect
% ratio.
drawnow;
cb.Position(3) = cb.Position(3)*1.8;
p = cb.Position;
sh = p(3) * fig.Position(3)/fig.Position(4);   % square side, normalized height
annotation(fig,'rectangle',[p(1) p(2)-0.09-sh p(3) sh], ...
    'FaceColor',[0.55 0.75 0.80], 'Color','k', 'LineWidth',0.5);
annotation(fig,'textbox',[p(1)+p(3)+0.01 p(2)-0.09-sh 0.5 sh], ...
    'String',{'No','data'}, 'EdgeColor','none', 'FontName',figp.fontname, ...
    'FontSize',figp.fontsize-1, 'VerticalAlignment','middle');

drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig7c_colorbar.pdf'),'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig7c_colorbar.png'),'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig7c_colorbar.pdf'));

%% ============================== fig7d: effect of hue separation
% Performance against the hue-angle separation of the pair, the systematic
% difficulty effect visible in the fig7c matrices.
sep = nan(9,9);
for i = 1:nHue
    for j = 1:nHue
        if i ~= j; k = abs(i-j); sep(i,j) = min(k, nHue-k)*hueStep; end
    end
end
sepLevels = unique(sep(~isnan(sep)))';
Psep = nan(nObs, numel(sepLevels), numel(conds));
for c = 1:numel(conds)
    for s = 1:numel(sepLevels)
        msk = (sep == sepLevels(s));
        for o = 1:nObs
            cc = C(:,:,o,c); nn = N(:,:,o,c);
            Psep(o,s,c) = sum(cc(msk))/sum(nn(msk))*100;
        end
    end
end

% Same width as fig7a before it was widened (80% of one column); 40% taller
panel_w = figp.onecolumn; panel_h = 10;   % one column wide, 10 cm tall
condLabFull = {'Matte, no context','Glossy, no context', ...
               'Matte, with context','Glossy, with context'};

% Grey for the two no-surround conditions, black for the two with a surround;
% matte solid, glossy open, so the surround effect reads at a glance.
col = {[0.55 0.55 0.55],[0.55 0.55 0.55],[0 0 0],[0 0 0]};
mrk = {'o','s','o','s'};
fil = {'flat','none','flat','none'};
msz = [6 7 6 7];   % squares read optically smaller than circles, so draw them larger

fig = figure; ax = gca; hold(ax,'on');
fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
fig.Position=[10 10 panel_w panel_h];
ax.Color = figp.axescolor;

for c = 1:numel(conds)
    mS = mean(Psep(:,:,c),1); eS = std(Psep(:,:,c),0,1)/sqrt(nObs);
    errorbar(ax, sepLevels, mS, eS, ['-' mrk{c}], 'Color', col{c}, ...
        'MarkerFaceColor', ternary(strcmp(fil{c},'flat'), col{c}, 'w'), ...
        'MarkerSize', msz(c), 'LineWidth', figp.linewidth, 'CapSize', 2);
end
yline(ax, 50, ':', 'Color', 'k', 'LineWidth', 1);   % chance level

ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
ax.XColor = 'k'; ax.YColor = 'k';
ax.XLim = [30 195]; ax.XTick = sepLevels; ax.YLim = [45 100]; ax.YTick = 50:10:100;
ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on';
xlabel(ax,'Hue separation of the pair [deg]','FontSize',figp.fontsize_axis);
ylabel(ax,'Correct [%]','FontSize',figp.fontsize_axis);

% Legend, bottom right: symbols only (dummy line-less handles)
hleg = gobjects(1,numel(conds));
for c = 1:numel(conds)
    hleg(c) = plot(ax, nan, nan, mrk{c}, 'Color', col{c}, ...
        'MarkerFaceColor', ternary(strcmp(fil{c},'flat'), col{c}, 'w'), ...
        'MarkerSize', msz(c), 'LineStyle','none');
end
lgd = legend(ax, hleg, condLabFull, 'Location','southeast', 'FontSize', 7);
lgd.Color = figp.axescolor; lgd.EdgeColor = 'none';   % opaque, hides the chance line behind the text

ax.Position = [0.14 0.20 0.80 0.76];   % shift the plot up within the canvas
drawnow;
lgd.Position(2) = lgd.Position(2) + 0.05;   % nudge the legend up, off the chance line

drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig7d_hue_separation.pdf'),'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig7d_hue_separation.png'),'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig7d_hue_separation.pdf'));

% ------------------------------------------------------------- local helpers
function cm = pair_colormap()
% Linear greyscale: black at the 40% floor of the colour scale, white at
% 100%. An earlier version drew cells below the 50% chance level in red,
% but no cell falls significantly below chance once the per-cell test is
% corrected across the 72 pairs (BH-FDR, q = 0.05), so a colour break at
% 50% singled out what is only trial-count noise.
    cm = repmat(linspace(0,1,256)', 1, 3);
end

function s = sem(x)
    s = std(x,[],1)./sqrt(size(x,1));
end
function sig = bh_fdr_mask(p, mask, q)
% Benjamini-Hochberg FDR over the p-values selected by the logical mask;
% returns a logical array (same size as p) of the cells that survive.
    pv = p(mask); ps = sort(pv(:)); m = numel(ps);
    k = find(ps <= (1:m)'/m*q, 1, 'last');
    if isempty(k); thr = -1; else; thr = ps(k); end
    sig = false(size(p)); sig(mask) = pv <= thr;
end

function out = ternary(cond,a,b)
    if cond; out = a; else; out = b; end
end
function printRManova(tbl)
    rows = tbl.Properties.RowNames;
    for i = 1:numel(rows)
        r = rows{i};
        if startsWith(r,'(Intercept):') || strcmp(r,'(Intercept)')
            eff = strrep(r,'(Intercept):','');
            if strcmp(eff,'(Intercept)'); continue; end
            F = tbl.F(i); p = tbl.pValue(i);
            df1 = tbl.DF(i); df2 = tbl.DF(i+1);
            fprintf('  %-22s F(%d,%d) = %.2f, p = %.4g\n', eff, df1, df2, F, p);
        end
    end
end
