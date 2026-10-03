% fig1_environment
% Figure 1: chromatic distributions of the four light-probe environments.
%
% For each environment (En1-En4) the script:
%   1. loads the precomputed MacLeod-Boynton (MB) coordinates of every pixel
%      of the light-probe image (data/environments_mb.mat),
%   2. normalizes pixel luminance so that the brightest non-highlight pixel
%      maps to 1 (the top p_highlight fraction of pixels is treated as
%      specular highlights and clipped), and discards very dark pixels,
%   3. plots the pixel chromaticities (L/(L+M) vs S/(L+M)) together with the
%      blackbody locus, the mean chromaticity of the environment (x) and the
%      equal-energy white point (+),
%   4. saves each panel as figs/fig1<a-d>_en<n>_chromatic_distribution.png.

clearvars; close all;

%% Paths
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

data_dir = fullfile(project_root,'data');
figs_dir         = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

figp = fig_parameters();   % shared figure sizing/typography

%% Parameters
% Equal-energy white (EEW) in MB chromaticity
ew_r = 0.7078;   % L/(L+M)
ew_b = 1;        % S/(L+M)

% Fraction of pixels treated as specular highlights, per environment:
% luminance is rescaled so that the (1 - p_highlight) quantile maps to 1,
% and anything brighter is clipped to 1.
p_highlight = [0.1 0.05 0.05 0.05];

% Pixels with normalized luminance below this are discarded (their
% chromaticity estimates are dominated by noise).
L_min = 0.01;

%% Load data
% MB chromaticities of blackbody radiators, 100 K to 1,000,000 K -> bbl
load(fullfile(data_dir,'blackbody_locus.mat'),'bbl');

% Per-pixel MB coordinates, rows x cols x [L/(L+M), S/(L+M), luminance]
env = load(fullfile(data_dir,'environments_mb.mat'));
MB_all = {env.MB_En1, env.MB_En2, env.MB_En3, env.MB_En4};

% Number of highlight pixels to clip per environment (the pixel count is
% taken from En1; all four light probes share the same resolution).
n_highlight = round(p_highlight * size(MB_all{1},1) * size(MB_all{1},2));

%% One chromaticity panel per environment
side = figp.twocolumn/4;   % panel size: a quarter of the two-column width, square

for i = 1:numel(MB_all)
    % --- Per-pixel chromaticity and luminance ---------------------------
    MB = MB_all{i};
    r = reshape(MB(:,:,1),[],1);   % L/(L+M)
    b = reshape(MB(:,:,2),[],1);   % S/(L+M)
    L = reshape(MB(:,:,3),[],1);
    L = L/max(L);                  % normalize to the brightest pixel

    % --- Luminance normalization and dark-pixel exclusion ---------------
    [L,order] = sort(L);           % ascending luminance
    r = r(order);
    b = b(order);
    L = min(L/L(end-n_highlight(i)), 1);   % highlights clip to 1
    keep = L > L_min;
    r = r(keep);
    b = b(keep);

    % --- Plot -----------------------------------------------------------
    fig = figure; ax = gca; hold on;
    fig.Units = 'centimeters'; fig.Color = figp.figurecolor; fig.InvertHardcopy = 'off';
    fig.Position = [10 10 side side];
    ax.Color = figp.axescolor;   % standard light-grey axes background

    scatter(r,b,2,[0.7 0.7 0.7],'o','filled');                     % pixel chromaticities
    plot(bbl(:,1),bbl(:,2),'k-','LineWidth',figp.linewidth);       % blackbody locus
    scatter(mean(r),mean(b),70,'kx','LineWidth',figp.linewidth);   % mean chromaticity
    scatter(ew_r,ew_b,70,'k+','LineWidth',figp.linewidth);         % equal-energy white

    ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
    ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
    ax.XColor = 'k'; ax.YColor = 'k';
    ax.XLim = [0.62 0.88]; ax.YLim = [0 3];
    ax.XTick = [0.62 0.75 0.88]; ax.XTickLabel = {'0.62','0.75','0.88'};
    ax.YTick = [0 1.5 3.0];      ax.YTickLabel = {'0.0','1.5','3.0'};
    ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on';
    xlabel('L/(L+M)', 'FontSize', figp.fontsize_axis);
    ylabel('S/(L+M)', 'FontSize', figp.fontsize_axis);
    axis square;

    % Expand the axes to fill the canvas, keeping the axes square and the
    % content centred in whichever direction has slack.
    drawnow;
    ti = ax.TightInset;
    w = min(1-ti(1)-ti(3), 1-ti(2)-ti(4));
    ax.Position = [ti(1)+(1-ti(1)-ti(3)-w)/2, ti(2)+(1-ti(2)-ti(4)-w)/2, w, w];

    % --- Export ---------------------------------------------------------
    % PNG only (the scatter has ~1e5 points per panel, which would make a
    % vector PDF tens of MB). print exports the full canvas rather than
    % tight-cropping, so every panel comes out exactly side x side (square).
    drawnow;
    fig.PaperPositionMode = 'auto';
    panel = ['fig1',char('a'+i-1),'_en',num2str(i),'_chromatic_distribution.png'];
    print(fig, fullfile(figs_dir,panel), '-dpng', ['-r' num2str(figp.dpi)]);
    fprintf('Saved %s (%d dpi)\n', fullfile(figs_dir,panel), figp.dpi);
end
