% fig2_reflectance
% Figure 2: test reflectances used in the experiment.
%
% The script:
%   1. computes the chromaticity of 4,824 natural-object reflectances (plus
%      a flat one) in threshold-normalized MacLeod-Boynton (MB) space and,
%      for each of the eight hue directions around equal-energy white (EEW,
%      0:45:315 deg), selects the reflectance with the highest purity;
%   2. desaturates each selected reflectance toward EEW (by adding a flat
%      spectral offset) so that all eight share the same purity, then
%      equates their luminance -> the eight "basis" reflectances;
%   3. builds, for each hue, nor = 100 linear EEW-to-basis mixtures (the
%      reflectance spectra given to the renderer);
%   4. averages the discrimination thresholds of Morimoto et al. (2018)
%      (data/thresholds_morimoto2018.mat; sessions -> observers -> specular
%      conditions) to obtain, per environment and hue, the mixture level
%      used in the experiment;
%   5. plots per environment the chromaticities of the selected mixtures
%      (fig2a-c) and their spectra (fig2d-f). en = 3 is the E1/E2 average.

clearvars; close all;

%% Paths
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

data_dir = fullfile(project_root,'data');
figs_dir = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

figp = fig_parameters();   % shared figure sizing/typography

%% Parameters
% Equal-energy white (EEW) in MB chromaticity
ew_r = 0.7078;   % L/(L+M)
ew_b = 1;        % S/(L+M)

% Detection thresholds along the two cardinal color directions. Chromatic
% differences from EEW are divided by these, so distances ("purity") are in
% detection-threshold units and the hue directions are perceptually
% comparable.
rg_threshold = 0.0071;   % L/(L+M) direction
yb_threshold = 0.1325;   % S/(L+M) direction

noh = 8;     % number of hue directions (0:45:315 deg)
nor = 100;   % number of mixture levels per hue (n = 1 ... nor)

wavelengths = 400:10:700;   % sampling of all reflectance spectra [nm]

% Plotting
color_scale = 0.85;      % intensity scale for marker/line colors (lower = darker, more visible)
level = [2.5 2.5 2.5];   % per-environment multiplier on the raw threshold when choosing the plotted mixture level
env_names = {'en1','en2','en_mean'};   % en = 3 is the E1/E2 average

%% 1. Chromaticity of every candidate reflectance
% 4,824 natural-object reflectances (31 samples, 400:10:700 nm), plus a
% flat (spectrally uniform) reflectance appended as the last candidate.
load(fullfile(data_dir,'allsurfaces.mat'),'ALLSURFACES');
reflectances = [ALLSURFACES, ones(31,1)]';   % -> n_candidates x 31

MB = spectrum_to_mb_rgb(reflectances);

% Chromaticity relative to EEW, in threshold units
r_shifted = (MB(:,1)-ew_r)/rg_threshold;
b_shifted = (MB(:,2)-ew_b)/yb_threshold;

% Hue angle (0-360 deg around EEW) and purity (distance from EEW)
theta = atan2(b_shifted, r_shifted);
theta(theta < 0) = theta(theta < 0) + 2*pi;
theta(theta == 2*pi) = 0;
theta = theta/pi*180;
purity = hypot(r_shifted, b_shifted);

%% 2. Select the highest-purity reflectance on each hue direction
angle_tol = 0.5;   % accept candidates within +-0.5 deg of the target hue

basis = zeros(noh,31);
basis_purity = zeros(1,noh);
for i = 1:noh
    target = 360/noh*(i-1);
    candidates = find(abs(theta - target) < angle_tol);
    [basis_purity(i), k] = max(purity(candidates));
    basis(i,:) = reflectances(candidates(k),:);
end

% All eight will be desaturated to match the least saturated one
lowest_purity = min(basis_purity);

%% 3. Equate purity, then luminance
% Adding a flat offset to a reflectance moves its chromaticity toward EEW
% without changing its hue. For each basis, search offsets 0:0.001:9.999
% for the one whose purity best matches lowest_purity, then normalize the
% peak to 1.
n_offsets = 10000;
v = zeros(n_offsets,31);
for i = 1:noh
    for j = 1:n_offsets
        v(j,:) = (j-1)*0.001*ones(1,31) + basis(i,:);
    end
    MB_v = spectrum_to_mb_rgb(v);
    purity_v = hypot((MB_v(:,1)-ew_r)/rg_threshold, (MB_v(:,2)-ew_b)/yb_threshold);
    [~,best] = min(abs(purity_v - lowest_purity));
    basis(i,:) = v(best,:)/max(v(best,:));
end

% Append EEW (flat reflectance) as row noh+1, scale every spectrum to the
% luminance of the dimmest one, then normalize the set by its global max.
basis(noh+1,:) = ones(1,31);
MB_basis = spectrum_to_mb_rgb(basis);
basis = basis./MB_basis(:,3)*min(MB_basis(:,3));
basis = basis/max(basis(:));

eew_spectrum = basis(noh+1,:);   % flat spectrum after the scaling above

%% 4. Mixture spectra
% For each hue, nor linear mixtures between EEW (n = 1) and the full basis
% reflectance (n = nor): mixtures(:,h,n). These were written as .spd files
% for the renderer, rounded to five decimals, so the same rounding is kept.
mixtures = zeros(numel(wavelengths),noh,nor);
for i = 1:noh
    for n = 0:nor-1
        spectrum = n*basis(i,:)/(nor-1) + (nor-1-n)*eew_spectrum/(nor-1);
        mixtures(:,i,n+1) = round(spectrum,5)';
    end
end

%% 5. Mixture levels from the Morimoto et al. (2018) thresholds
% Threshold at the final staircase trial (in mixture-level units), per
% observer x specularity x environment x session x hue.
T = load(fullfile(data_dir,'thresholds_morimoto2018.mat'));
thr = T.threshold;

% Hierarchical average: sessions -> observers -> specular conditions,
% giving one threshold (in mixture-level units) per environment and hue.
thr = mean(thr,4);   % over sessions
thr = mean(thr,1);   % over observers
thr = mean(thr,2);   % over specular conditions
threshold_hue = squeeze(thr);                                    % -> 2 x noh
threshold_hue(3,:) = (threshold_hue(1,:)+threshold_hue(2,:))/2;  % E1/E2 average

%% 6. Figure 2a-c: chromaticities of the selected reflectances
side = figp.twocolumn/3;   % panel size: a third of the two-column width, square

for en = 1:3
    % Spectra at the mixture level used in the experiment (raw threshold
    % scaled by level(en)) and at the raw threshold itself.
    ref_used = zeros(31,noh);
    ref_raw  = zeros(31,noh);
    for h = 1:noh
        n_used = min(round(threshold_hue(en,h)*level(en)), nor);
        n_raw  = min(round(threshold_hue(en,h)), nor);
        ref_used(:,h) = mixtures(:,h,n_used);
        ref_raw(:,h)  = mixtures(:,h,n_raw);
    end

    [MB_used,RGB_used] = spectrum_to_mb_rgb(ref_used');
    [MB_raw, RGB_raw ] = spectrum_to_mb_rgb(ref_raw');
    RGB_used = RGB_used'/max(RGB_used(:))*color_scale;
    RGB_raw  = RGB_raw'/max(RGB_raw(:))*color_scale;

    fig = figure(en); ax = gca; hold on;
    fig.Units = 'centimeters'; fig.Color = figp.figurecolor; fig.InvertHardcopy = 'off';
    fig.Position = [10 10 side side];
    ax.Color = figp.axescolor;   % standard light-grey axes background

    % Filled circles: levels used in the experiment; crosses: raw thresholds
    scatter(MB_used(:,1),MB_used(:,2),50,RGB_used,'o','filled','MarkerEdgeColor',[0 0 0],'LineWidth',0.5);
    scatter(MB_raw(:,1), MB_raw(:,2), 25,RGB_raw,'x','MarkerEdgeColor',[0 0 0],'LineWidth',0.75);
    scatter(ew_r,ew_b,50,[0.7 0.7 0.7],'o','filled','MarkerEdgeColor',[0 0 0],'LineWidth',0.5);   % EEW

    ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
    ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
    ax.XColor = 'k'; ax.YColor = 'k';
    ax.XLim = [0.69 0.73]; ax.YLim = [0.6 1.4];
    ax.XTick = [0.69 0.71 0.73]; ax.XTickLabel = {'0.69','0.71','0.73'};
    ax.YTick = [0.6 1.0 1.4];    ax.YTickLabel = {'0.6','1.0','1.4'};
    ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on';
    xlabel('L/(L+M)', 'FontSize', figp.fontsize_axis);
    ylabel('S/(L+M)', 'FontSize', figp.fontsize_axis);
    axis square;

    % Expand the axes to fill the canvas, keeping them square and centred.
    drawnow;
    ti = ax.TightInset;
    w = min(1-ti(1)-ti(3), 1-ti(2)-ti(4));
    ax.Position = [ti(1)+(1-ti(1)-ti(3)-w)/2, ti(2)+(1-ti(2)-ti(4)-w)/2, w, w];

    % print exports the full canvas, so every panel is exactly side x side.
    drawnow;
    fig.PaperPositionMode = 'auto';
    panel = ['fig2',char('a'+en-1),'_',env_names{en},'_chromaticity.png'];
    print(fig, fullfile(figs_dir,panel), '-dpng', ['-r' num2str(figp.dpi)]);
    fprintf('Saved %s (%d dpi)\n', fullfile(figs_dir,panel), figp.dpi);
end

%% 7. Figure 2d-f: spectra of the selected reflectances
for en = 1:3
    ref_used = zeros(31,noh);
    for h = 1:noh
        n_used = min(round(threshold_hue(en,h)*level(en)), nor);
        ref_used(:,h) = mixtures(:,h,n_used);
    end

    % Line colors are computed from max-normalized spectra (so hue is
    % comparable across lines); the plotted curves are the raw values.
    [~,RGB_lines] = spectrum_to_mb_rgb((ref_used./max(ref_used,[],1))');
    RGB_lines = RGB_lines';
    RGB_lines = RGB_lines/max(RGB_lines(:))*color_scale;

    fig = figure(en+3); ax = gca; hold on;
    fig.Units = 'centimeters'; fig.Color = figp.figurecolor; fig.InvertHardcopy = 'off';
    fig.Position = [10 10 side side];
    ax.Color = figp.axescolor;   % standard light-grey axes background

    for h = 1:noh
        plot(wavelengths, ref_used(:,h), '-','LineWidth',1,'Color',RGB_lines(h,:));
    end
    plot(wavelengths, eew_spectrum,'-','LineWidth',1,'Color',[0.7 0.7 0.7]);   % EEW reference

    ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
    ax.LineWidth = figp.axeslinewidth; ax.TickDir = 'out'; box off;
    ax.XColor = 'k'; ax.YColor = 'k';
    ax.XLim = [400 700]; ax.YLim = [0.20 0.60];
    ax.XTick = [400 550 700]; ax.XTickLabel = {'400','550','700'};
    ax.YTick = [0.2 0.4 0.6]; ax.YTickLabel = {'0.20','0.40','0.60'};
    ax.XMinorGrid = 'on'; ax.YMinorGrid = 'on';
    xlabel('Wavelength [nm]', 'FontSize', figp.fontsize_axis);
    ylabel('Reflectance', 'FontSize', figp.fontsize_axis);
    axis square;

    % Expand the axes to fill the canvas, keeping them square and centred.
    drawnow;
    ti = ax.TightInset;
    w = min(1-ti(1)-ti(3), 1-ti(2)-ti(4));
    ax.Position = [ti(1)+(1-ti(1)-ti(3)-w)/2, ti(2)+(1-ti(2)-ti(4)-w)/2, w, w];

    % print exports the full canvas, so every panel is exactly side x side.
    drawnow;
    fig.PaperPositionMode = 'auto';
    panel = ['fig2',char('d'+en-1),'_',env_names{en},'_reflectance.png'];
    print(fig, fullfile(figs_dir,panel), '-dpng', ['-r' num2str(figp.dpi)]);
    fprintf('Saved %s (%d dpi)\n', fullfile(figs_dir,panel), figp.dpi);
end
