clearvars; close all;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(project_root,'src')));

external_dir = fullfile(project_root,'data','external','E3E4_AllAnglewithMirrorMB');
if ~exist(external_dir,'dir'); error('Camera-angle data not bundled. Copy E3E4_AllAnglewithMirrorMB from the archive repo into data/external/.'); end
figs_dir = fullfile(project_root,'figs');
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

c(1,:) = [0 1 1];
c(2,:) = [1 0 1];

rg_threshold = 0.0071;
yb_threshold = 0.1325;

ew_r = 0.7078;ew_b = 1;

for En = 3:4
    fig = figure;
    for Angle = 0:10:350
        load(fullfile(external_dir,['En',num2str(En),'_cameraYRot',num2str(Angle),'_Context_MB_CameraAngleDependencewithMirror']));MB_All = MB;
        load(fullfile(external_dir,['En',num2str(En),'_cameraYRot',num2str(Angle),'_NoContext_MB_CameraAngleDependencewithMirror']));MB_Obj = MB;
        MB_BG = MB_All - MB_Obj;
        
        MeanMB_BG((Angle+10)/10,:) = [sum(nonzeros(MB_BG(:,:,1).*MB_BG(:,:,3)))/sum(sum(MB_BG(:,:,3))),sum(nonzeros(MB_BG(:,:,2).*MB_BG(:,:,3)))/sum(sum(MB_BG(:,:,3)))];
        MeanMB_Obj((Angle+10)/10,:) = [sum(nonzeros(MB_Obj(:,:,1).*MB_Obj(:,:,3)))/sum(sum(MB_Obj(:,:,3))),sum(nonzeros(MB_Obj(:,:,2).*MB_Obj(:,:,3)))/sum(sum(MB_Obj(:,:,3)))];
    end
    
    RMSE = sqrt(((MeanMB_BG(:,1)-MeanMB_Obj(:,1))/rg_threshold).^2 + ((MeanMB_BG(:,2)-MeanMB_Obj(:,2))/yb_threshold).^2);
    [~,maxid] = max(RMSE);[~,minid] = min(RMSE);
    id = [maxid,minid];
    for n = 1:2
        scatter(MeanMB_BG(id(n),1),MeanMB_BG(id(n),2),400,c(n,:),'o','filled','MarkerEdgeColor','k','MarkerFaceAlpha',.5);hold on;
        scatter(MeanMB_Obj(id(n),1),MeanMB_Obj(id(n),2),400,c(n,:),'d','filled','MarkerEdgeColor','k','MarkerFaceAlpha',.5)
    end
    scatter(0.7078,1,250,'k+','LineWidth',2)

    hold on

    ax = gca;
    ax.Color = 'w';ax.XColor = 'k';ax.YColor = 'k';
    ax.LineWidth = 2;
    xlabel('L/(L+M)');
    ylabel('S/(L+M)')
    
    ax.XLim = [0.66 0.74];
    ax.YLim = [0.5 1.50];
    
    set(gca, 'XTick', [0.66 0.70 0.74]);   
    set(gca, 'XTickLabel', {'0.66','0.70','0.74'}); 
    set(gca, 'TickDir', 'out');   

    set(gca, 'YTick', [0.5 1.0 1.5]);       
    set(gca, 'YTickLabel', {'0.5','1.0','1.5'}); 

    set(gca, 'FontName','Arial');     

    f = gcf;
    axis square;

    figsize = [10,7.5]; % h*w

    fig.PaperType       = 'a4';
    fig.PaperUnits      = 'centimeters';
    fig.PaperPosition   = [0,20,figsize(1),figsize(2)];
    fig.Units           = 'centimeters';
    fig.Position        = [0,200,figsize(1),figsize(2)];
    fig.Color           = 'w';
    fig.InvertHardcopy  = 'off';

    box off
    ax.LineWidth = 2;
    ax.FontSize = 16;

    ax.LineWidth = 2;
    ax.Units = 'centimeters';
    ticklengthcm(ax,0.2)
    %ax.Position = [2.0 1.7 5.2 5.2];

    print('-r600',fullfile(figs_dir,['WeighteMean_En',num2str(En),'.png']),'-dpng')
end