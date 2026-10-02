function figp = fig_parameters()
% FIG_PARAMETERS  Shared figure sizing/styling constants for paper figures.
%   figp = fig_parameters() returns a struct used by the plot_* scripts so
%   every figure shares one consistent size and typography. Widths follow the
%   Optica / JOSA A author guidelines.
%
%   Usage in a plotting script (units in centimetres):
%       figp = fig_parameters();
%       fig = figure; ax = gca;
%       fig.Units = 'centimeters'; fig.Color = 'w';
%       fig.Position = [10 10 figp.onecolumn figp.onecolumn*0.8];
%       ax.FontName = figp.fontname; ax.FontSize = figp.fontsize;
%       exportgraphics(fig, fullfile(figs_dir,'figX.pdf'), 'ContentType','vector');

% Column widths in centimetres
figp.twocolumn = 17.8;              % full (two-column) figure width [cm]
figp.onecolumn = figp.twocolumn/2; % single-column figure width [cm]
figp.medcolumn = figp.twocolumn*2/3; % 1.5-column width [cm]

% Typography
figp.fontname      = 'Helvetica';  % Optica figures use a sans-serif face
figp.fontsize      = 8;            % general text / tick labels [pt]
figp.fontsize_axis = 9;           % axis labels [pt]
figp.fontsize_title = 10;         % panel titles [pt]

% Line / marker defaults
figp.linewidth = 0.75;            % data line width [pt]
figp.axeslinewidth = 0.5;         % axis line width [pt]

% Backgrounds
figp.axescolor = ones(1,3)*0.97;  % standard light-grey axes background
figp.figurecolor = 'w';           % figure (page) background

% Export helper defaults
figp.dpi = 600;                   % raster resolution for -dpng exports
end
