% fig10_human_performance_exp2
% Experiment 2 human colour-constancy performance (manuscript figure 10),
% minimal style: one panel, mean across observers with each observer's data
% overlaid. The focal comparison of Experiment 2 is congruent vs
% incongruent, so the two congruency levels sit side by side within each of
% the four specularity x context groups, connected by a line per observer.
% The no-correction model is drawn in pink, as in fig7a, so the cost of the
% manipulation can be read against the floor of no correction at all.
%
% All statistics reported in the paper are printed to the MATLAB window.

clearvars; close all;
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

matrix_dir = fullfile(project_root,'data','scores','exp2');
figs_dir   = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end
figp = fig_parameters();

observers = {'AKH','JH','LY','MS','SR','TD','TM'};
nObs = numel(observers);

% 2 (specular) x 2 (context) x 2 (congruency). NoContext = No context,
% Context = With context. Min = congruent (mean cone signals matched),
% Max = incongruent (mismatched). Verified against the manuscript means.
spec = {'matte','shiny'};  specLab = {'Matte','Glossy'};
bg   = {'nocontext','context'};  bgLab = {'No context','With context'};
cong = {'min','max'};  congLab = {'Congruent','Incongruent'};

% P(observer, specularity, context, congruency)
P = zeros(nObs,2,2,2);
for o = 1:nObs
  for s = 1:2
    for b = 1:2
      for g = 1:2
        d = load(fullfile(matrix_dir, ...
            ['m_' spec{s} '_' bg{b} '_' lower(observers{o}) '_chromaticity_' cong{g} '.mat']));
        P(o,s,b,g) = d.OverallPercentageCorrect;
      end
    end
  end
end
Ppct = P*100;

% ---------------------------------------------------- report statistics
fprintf('\n================ Experiment 2: human performance ================\n');
fprintf('%-8s %-13s %-12s  %6s  %5s\n','Specular','Context','Congruency','Mean%','SE%');
for g = 1:2, for b = 1:2, for s = 1:2
    v = Ppct(:,s,b,g);
    fprintf('%-8s %-13s %-12s  %6.1f  %5.1f\n', specLab{s}, bgLab{b}, congLab{g}, mean(v), sem(v));
end, end, end
fprintf('\nMain-effect means (across observers):\n');
fprintf('  Matte = %.1f%%   Glossy = %.1f%%\n', mean(reshape(Ppct(:,1,:,:),nObs,[]),'all'), mean(reshape(Ppct(:,2,:,:),nObs,[]),'all'));
fprintf('  No context = %.1f%%   With context = %.1f%%\n', mean(reshape(Ppct(:,:,1,:),nObs,[]),'all'), mean(reshape(Ppct(:,:,2,:),nObs,[]),'all'));
fprintf('  Congruent = %.1f%%   Incongruent = %.1f%%\n', mean(reshape(Ppct(:,:,:,1),nObs,[]),'all'), mean(reshape(Ppct(:,:,:,2),nObs,[]),'all'));

% Three-way repeated-measures ANOVA: Specularity x Context x Congruency
flat = reshape(Ppct, nObs, 8);   % column order: s fastest, then b, then g
vn = cell(1,8); wSpec=cell(8,1); wCtx=cell(8,1); wCong=cell(8,1); col=0;
for g=1:2, for b=1:2, for s=1:2
    col=col+1; vn{col}=sprintf('c%d',col);
    wSpec{col}=specLab{s}; wCtx{col}=bgLab{b}; wCong{col}=congLab{g};
end, end, end
% reorder flat to match the (g,b,s) column construction above
flat2 = zeros(nObs,8); col=0;
for g=1:2, for b=1:2, for s=1:2
    col=col+1; flat2(:,col)=Ppct(:,s,b,g);
end, end, end
T = array2table(flat2,'VariableNames',vn);
within = table(categorical(wSpec),categorical(wCtx),categorical(wCong), ...
    'VariableNames',{'Specularity','Context','Congruency'});
rm = fitrm(T, sprintf('%s-%s ~ 1',vn{1},vn{8}), 'WithinDesign', within);
tbl = ranova(rm,'WithinModel','Specularity*Context*Congruency');
fprintf('\nThree-way repeated-measures ANOVA (percentage correct):\n');
printRManova(tbl);

% The Specularity x Congruency interaction is the informative one: the
% congruency cost is a matte phenomenon. Report it as simple effects, the
% congruency cost per gloss level (averaged over context), so the numbers
% behind the interaction can be quoted directly.
fprintf('\nCongruency cost by specularity (averaged over context, paired t):\n');
for s = 1:2
    a = squeeze(mean(Ppct(:,s,:,1),3));   % congruent
    b = squeeze(mean(Ppct(:,s,:,2),3));   % incongruent
    [~,p,~,st] = ttest(a,b);
    fprintf('  %-7s %.1f -> %.1f (%+.1f pts)  t(%d) = %.2f, p = %.4g\n', ...
        specLab{s}, mean(a), mean(b), mean(b)-mean(a), nObs-1, st.tstat, p);
end
fprintf('==================================================================\n\n');

% ------------------------------------------------------------------- figure
% x layout: four specularity x context groups, each holding the focal
% congruent-incongruent pair side by side:
% [Matte-NoSC Glossy-NoSC Matte-SC Glossy-SC] x [Congruent Incongruent]
fig = figure; ax = gca; hold on;
fig.Units='centimeters'; fig.Color=figp.figurecolor; fig.InvertHardcopy='off';
fig.Position=[10 10 figp.onecolumn figp.onecolumn*0.85*1.1];
ax.Color = figp.axescolor;

xg = [1 2; 4 5; 7 8; 10 11];     % group rows: [congruent incongruent]
obsColor=[0.6 0.6 0.6];
% (specularity, context) per group: M-noSC, G-noSC, M-SC, G-SC
sb = [1 1; 2 1; 1 2; 2 2];
groupLab = {'Matte, no context','Glossy, no context', ...
            'Matte, with context','Glossy, with context'};

for k = 1:4
    x = xg(k,:);
    D = squeeze(Ppct(:, sb(k,1), sb(k,2), :));   % observers x [cong incong]
    for o=1:nObs
        plot(x, D(o,:), '-', 'Color',[obsColor 0.45],'LineWidth',0.5, ...
            'Marker','o','MarkerSize',2.5,'MarkerFaceColor',obsColor, ...
            'MarkerEdgeColor','none');
    end
    m=mean(D); e=sem(D);
    plot(x, m,'k-','LineWidth',1.5);
    errorbar(x, m, e, 'k','LineStyle','none','LineWidth',1,'CapSize',3);
    plot(x, m, 'ko','MarkerSize',7,'MarkerFaceColor','k','MarkerEdgeColor','w','LineWidth',0.5);
end

% No-correction model, as in fig7a: the same task performed with no
% discounting of the illumination at all, one value per condition and
% congruency. The model never consults the surround, so the Context and
% NoContext conditions are the same condition for it; the two condition
% files were simulated separately and differ only by redrawn internal
% noise. The two files are therefore POOLED (averaged; equal trial
% counts), which halves that noise and gives one value per gloss level
% and congruency, drawn identically in both context groups.
% The min/max file tags of the null-model runs are reversed for the glossy
% objects, so the congruency index is flipped there (null_cong below).
nullColor = [0.85 0.4 0.55];
for k = 1:4
    nullPct = zeros(1,2);
    for g = 1:2
        gg = g; if sb(k,1) == 2; gg = 3-g; end     % glossy: tags reversed
        null_cong = cong{gg};
        v = 0;
        for bgi = 1:2
            d = load(fullfile(matrix_dir, ...
                ['m_' spec{sb(k,1)} '_' bg{bgi} '_null_tau0_noise25_chromaticity_' null_cong '.mat']));
            v = v + d.OverallPercentageCorrect*100/2;
        end
        nullPct(g) = v;
    end
    plot(xg(k,:), nullPct, '-', 'Color', nullColor, 'LineWidth', 1);
    plot(xg(k,:), nullPct, 's', 'MarkerSize', 7, 'MarkerFaceColor', nullColor, ...
         'MarkerEdgeColor', nullColor, 'LineWidth', 1);
end

yline(50, ':', 'Color',[0 0 0 0.4],'LineWidth',figp.axeslinewidth);

allx = reshape(xg',1,[]);
ax.FontName=figp.fontname; ax.FontSize=figp.fontsize; ax.LineWidth=figp.axeslinewidth;
ax.TickDir='out'; box off; ax.XColor='k'; ax.YColor='k';
ax.XLim=[0.4 xg(end)+0.6]; ax.YLim=[40 100]; ax.YTick=40:10:100;
ax.XTick = allx; ax.XTickLabel = repmat({'Cong.','Incong.'},1,4);
ax.XTickLabelRotation = 45;
ylabel('Percentage correct [%]','FontSize',figp.fontsize_axis);
xn=@(xd)(xd-ax.XLim(1))/(ax.XLim(2)-ax.XLim(1));
% At one-column width the group labels are stacked: a Matte/Glossy row
% under the rotated tick labels, and a context row spanning group pairs.
specRow = {'Matte','Glossy','Matte','Glossy'};
for k=1:4
    text(xn(mean(xg(k,:))),-0.26,specRow{k},'Units','normalized', ...
        'HorizontalAlignment','center','FontName',figp.fontname, ...
        'FontSize',figp.fontsize);
end
text(xn(mean([xg(1,:) xg(2,:)])),-0.37,'No context','Units','normalized', ...
    'HorizontalAlignment','center','FontName',figp.fontname, ...
    'FontSize',figp.fontsize_axis,'FontWeight','bold');
text(xn(mean([xg(3,:) xg(4,:)])),-0.37,'With context','Units','normalized', ...
    'HorizontalAlignment','center','FontName',figp.fontname, ...
    'FontSize',figp.fontsize_axis,'FontWeight','bold');

grid minor
% Pin the minor grid to a uniform spacing despite the uneven major ticks.
ax.XAxis.MinorTickValues = 0.5:0.5:xg(end)+0.5;
ax.YAxis.MinorTickValues = 40:2.5:100;

% Expand the axes to fill the canvas (exportgraphics crops to content), with
% extra bottom room for the two stacked label rows.
drawnow;
ti = ax.TightInset;
bottom = ti(2) + 0.20;
left = ti(1) + 0.02;
ax.Position = [left, bottom, 1-left-ti(3)-0.02, 1-bottom-ti(4)];

drawnow;
exportgraphics(fig, fullfile(figs_dir,'fig10_human_performance_exp2.pdf'),'ContentType','vector');
exportgraphics(fig, fullfile(figs_dir,'fig10_human_performance_exp2.png'), 'Resolution',600);
fprintf('Saved %s (+ 600-dpi png)\n', fullfile(figs_dir,'fig10_human_performance_exp2.pdf'));

%% -------------- fig10b: pair matrices, context x congruency
% Performance resolved by reflectance pair, pooled over the seven
% observers AND over the two gloss levels (112 trials per cell), in the
% format of the Experiment 1 matrices (fig7c): the four hue directions
% (0, 90, 180, 270 deg) as a block, the neutral reflectance (N) as a
% separate strip beyond a gap, the same greyscale (black 40% to white
% 100%) and the same below-chance test (one-tailed binomial on the pooled
% counts, BH-FDR q = 0.05 within the pair cells; survivors get a white
% asterisk).
congFile = {'congruent','incongruent'};
pnl = 0;
for b = 1:2
    for g = 1:2
        pnl = pnl + 1;
        Ch = zeros(5,5); Nh = zeros(5,5);
        for s = 1:2
            for o = 1:nObs
                d = load(fullfile(matrix_dir, ...
                    ['m_' spec{s} '_' bg{b} '_' lower(observers{o}) ...
                     '_chromaticity_' cong{g} '.mat']));
                Ch = Ch + d.M.CorrectN_SessionSum; Nh = Nh + d.M.TrialN_SessionSum;
            end
        end
        panel = sprintf('fig10b%d_%s_%s', pnl, bg{b}, congFile{g});
        draw_pair_matrix_exp2(Ch, Nh, figp, figs_dir, panel);
    end
end

% ------------------------------------------------------------- local helpers
function draw_pair_matrix_exp2(Cm, Nm, figp, figs_dir, panel)
% One 5 x 5 pair matrix (4 hues + N) in the fig7c format, from pooled
% correct/trial counts. Saves <panel>.png (600 dpi) into figs_dir.
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

function s = sem(x)
    s = std(x,[],1)./sqrt(size(x,1));
end
function printRManova(tbl)
    rows = tbl.Properties.RowNames;
    for i = 1:numel(rows)
        r = rows{i};
        if startsWith(r,'(Intercept):')
            eff = strrep(r,'(Intercept):','');
            F=tbl.F(i); p=tbl.pValue(i); df1=tbl.DF(i); df2=tbl.DF(i+1);
            fprintf('  %-30s F(%d,%d) = %.2f, p = %.4g\n', eff, df1, df2, F, p);
        end
    end
end
