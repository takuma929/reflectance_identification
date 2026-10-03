clearvars; close all;
project_root = fileparts(mfilename('fullpath'));
addpath(fullfile(project_root,'utils'));

figs_dir = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

cmap = brewermap(1024,'*Blues');
G = custom_gauss([1001 1001], 200, 200, 0, 0, 1, [0 0]);
imagesc(G);colormap(cmap)
axis square;

imwrite(G,fullfile(figs_dir,'fig5_gaussian_noise.tif'))
