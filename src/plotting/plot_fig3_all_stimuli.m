% NOTE: The "%% Rendering" section of this script re-renders the stimuli and
% requires external tools that are NOT bundled with this repository:
% Mitsuba plus RenderToolbox4 (rtbMakeSceneFiles / MyrtbBatchRender), and the
% *_Figure_Stimuli_Mapping.json mapping files. The earlier sections
% (threshold analysis, spd/condition-file generation) run with bundled data.

clearvars; close all;
project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(genpath(fullfile(project_root,'src')));

config_dir = fullfile(project_root,'data','config');
thresholds_dir = fullfile(project_root,'data','thresholds_morimoto2018');
rendering_dir = fullfile(project_root,'data','rendering');
blend_dir = fullfile(rendering_dir,'blend_files');
spd_dir = fullfile(rendering_dir,'spd_files');
stimuli_dir = fullfile(project_root,'data','stimuli','all_hues');
figs_dir = fullfile(project_root,'figs');
if ~exist(spd_dir,'dir'); mkdir(spd_dir); end
if ~exist(stimuli_dir,'dir'); mkdir(stimuli_dir); end
if ~exist(figs_dir,'dir'); mkdir(figs_dir); end

load(fullfile(config_dir,'ChosenAngle.mat'))
rg_threshold = 0.0071;
yb_threshold = 0.1325;

ew_r = 0.7078;
ew_b = 1;

% figure counter
f = 1;

nor = 100;

% number of hue
noh = 8;

% load reflectances of 4825 natual objects
load(fullfile(config_dir,'ALLSURFACES.mat'));
load(fullfile(config_dir,'ChosenAngle.mat'));

% Add flat reflectance
ALLSURFACES_size = size(ALLSURFACES);
ALLSURFACES(:,ALLSURFACES_size(2)+1)=ones(31,1);
Reflectance = ALLSURFACES';
Ref_size = size(Reflectance);

MB = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(Reflectance);
r_shifted = (MB(:,1)-ew_r)/rg_threshold;
b_shifted = (MB(:,2)-ew_b)/yb_threshold;
RGB = MBtoRGBVector(MB,0.1);

for i = 1:Ref_size(1)
    RGB(i,:) = RGB(i,:)/max(RGB(i,:))*0.5;
end

RGB = power(RGB,1/2.2);
RGB = min(1,RGB);RGB = max(0,RGB);

for i = 1:Ref_size(1)
    t = atan2(b_shifted(i,1),r_shifted(i,1));
    if t < 0
        t = t + 2*pi;
    end
    if t == 2*pi
        t = 0;
    end
    theta(i,1) = t/pi*180;
    distance(i,1) = hypot(r_shifted(i,1),b_shifted(i,1));
end

error = 0.5;
for i = 1:noh
    find(abs(theta-360/noh*(i-1))< error)
    Index(1:length(find(abs(theta-360/noh*(i-1)) < error)),i) = find(abs(theta-360/noh*(i-1))< error);
    distance_index(1:length(find(abs(theta-360/noh*(i-1)) < error)),i) = distance(find(abs(theta-360/noh*(i-1))< error));
    [~,maxI] = max(distance_index(:,i));
    
    Index_highestpurity(1,i) = Index(maxI,i);
    distance_highestpurity(1,i) = distance_index(maxI,i);
end

LowestPurity = min(distance_highestpurity);

Index2 = Index(find(Index(:)>0));
Index_size = size(Index2);

for i = 1:noh
    basis_vector(i,:) = Reflectance(Index_highestpurity(i),:);
end

% Create vectors with the same distance from EEW
for i = 1:noh
    for j = 1:10000
        v(j,:) = (j-1)*0.001*ones(1,31) + basis_vector(i,:);
    end
    MB_v = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(v);

    r_v_shifted = (MB_v(:,1)-ew_r)/rg_threshold;
    b_v_shifted = (MB_v(:,2)-ew_b)/yb_threshold;
    
    distance_v = hypot(r_v_shifted,b_v_shifted);
    dif = abs(distance_v - LowestPurity);
    [~,minIndex] = min(dif);
    basis_v_out(i,:) = v(minIndex,:)/max(v(minIndex,:));
end

o=0;s=0;sp=0;en=0;
startsession = 1;
lastsession = 5;

% Analyze the result from the previous experiment for scaling of each hue
for Environment = {'E1','E2'}
    en = en + 1;
    for shape = {'Sphere'}
        s = s + 1;
        for specular = {'Shiny','Matte'}
            sp = sp + 1;
            for observer = {'JH','TM','SR'}
                o = o + 1;
                for session = startsession:lastsession
                    resultFile = strcat(shape{1},'_',specular{1},'_',Environment{1},'_session',num2str(session),'_',observer{1},'.mat');
                    load(fullfile(thresholds_dir,resultFile));
                    Threshold(o,s,sp,en,session,:,:) = result.threshold(:,1:2);
                    for h = 1:noh
                        Threshold_Raw(o,s,sp,en,session,h) = PMOut(h).threshold(length(PMOut(h).threshold));
                    end
                end
                for h = 1:noh
                    Ave_Threshold_Raw(o,s,sp,en,h) = mean(Threshold_Raw(o,s,sp,en,:,h));
                    SE_Threshold_Raw(o,s,sp,en,h) = std(Threshold_Raw(o,s,sp,en,:,h))/sqrt(lastsession-startsession+1);
                    % i = 1:redness, i = 2:blueness
                    for i = 1:2
                        Ave_Threshold(o,s,sp,en,h,i) = mean(Threshold(o,s,sp,en,:,h,i));
                        SE_Threshold(o,s,sp,en,h,i) = std(Threshold(o,s,sp,en,:,h,i))/sqrt(lastsession-startsession+1);
                    end
                end
            end
            for h = 1:noh
                MaxAcrossObserver_Threshold_Raw(s,sp,en,h) = mean(Ave_Threshold_Raw(:,s,sp,en,h));
            end
            o = 0;
            for h = 1:noh
                MaxAcrossObserverandShape_Threshold_Raw(sp,en,h) = mean(MaxAcrossObserver_Threshold_Raw(:,sp,en,h));
            end
        end
        sp = 0;
    end
    s = 0;
end

% add EEW to basis_v_out
basis_v_out(noh+1,:) = ones(1,31);

MB_v = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(basis_v_out);

minLum = min(MB_v(:,3));

for i = 1:noh+1
    basis_v_out(i,:) = basis_v_out(i,:)/MB_v(i,3)*minLum;
end

Threshold_Raw_Exp3_2 = MaxAcrossObserverandShape_Threshold_Raw(:,2,:);

MB_v_new = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(basis_v_out);

basis_v_out = basis_v_out/max(max(basis_v_out));

%MB_v(:,3) = ones(noh,1)*10;

RGB_v = MBtoRGBVector(MB_v_new,5);
RGB_v = RGB_v/max(RGB_v(:))*0.7;
RGB_v = power(RGB_v,1/2.2);

x= 400:10:700;
EEW = basis_v_out(noh+1,:);

% Write spd files
for i = 1:noh
    degree = (i-1)*360/noh;
    for n = 0:nor-1
        v_out = n*basis_v_out(i,:)/(nor-1)+(nor-1-n)*EEW/(nor-1);
        
        Obj(i,n+1,:) = v_out;
        Obj2((i-1)*nor+n+1,:) = v_out;
        
        %v_out_normalize = v_out/sum(v_out)*Sum_Ref(i);
        A = [x;v_out];
        fname = strcat('Ref_',num2str(degree),'deg_n',num2str(n+1),'.spd');
        fileID = fopen(fullfile(spd_dir,fname),'w');
        fprintf(fileID,'%3d %1.5f\n',A);
        fclose(fileID);
    end
end

MB_Obj2 = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(Obj2);

for i = 1:noh
    temp = squeeze(Obj(i,:,:));
	MB_AllHue_AcrossIll(i,:,:) = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(temp);
end

ALL = reshape(Obj,[noh*nor,31]);

MB_ALL = HSLightProbe_MultiSpectralVectortoMBandRGB_400to700(ALL);
MB_ALL(:,3) = ones(noh*nor,1)*10;

RGB_ALL = MBtoRGBVector(MB_ALL,5);
RGB_ALL = RGB_ALL/max(RGB_ALL(:));
RGB_ALL = power(RGB_ALL,1/2.2);

noh = 8;

% Create Condition Files
HueCombination = combnk(1:noh+1,2);
s_huecomibination = size(HueCombination);
s_huecomibination = s_huecomibination(1);

level(1:2) = 3;
level(3:4) = 2;
% Created Condiiton file
en = 0;
for Environment = {'E1','E2','E3','E4'}
    en = en + 1;
    fname = strcat('Figure_Stimuli_',Environment{1},'_Condition.txt');
    fileID = fopen(fullfile(rendering_dir,fname),'w');
    A1 = 'ReflectanceUpper';
    A2 = 'cameraYRot';
    A3 = 'cameraX';
    A4 = 'cameraY';
    A5 = 'cameraZ';

    fprintf(fileID,'%s\t%s\t%s\t%s\t%s\n',A1,A2,A3,A4,A5);
    
    for HueUpper = 1:9
        % Dealing with Equal Energy White
        if HueUpper == 9
            DegreeUpper = 0;
            HueUpper_n = 1;
        else 
            if strcmp(Environment{1},'E1') || strcmp(Environment{1},'E2')
                HueUpper_n = min(round(MaxAcrossObserverandShape_Threshold_Raw(1,en,HueUpper)*level(en)),100);
            elseif strcmp(Environment{1},'E3') || strcmp(Environment{1},'E4')
                HueUpper_n = min(round(Threshold_Raw_Exp3_2(1,HueUpper)*level(en)),100);
            end
            DegreeUpper= (HueUpper-1)*360/noh;
        end

        RefnameUpper = strcat('Ref_',num2str(DegreeUpper),'deg_n',num2str(HueUpper_n),'.spd');

        if strcmp(Environment{1},'E4')
           %cameraYRot = 200;
           cameraYRot = 0;
        elseif strcmp(Environment{1},'E3')
           %cameraYRot = 70;
           cameraYRot = 0;
        else
            cameraYRot = 0;
        end
        
        AngleUpper = 0;        
        if strcmp(Environment{1},'E1') || strcmp(Environment{1},'E2')
            d_CameraObject = 5.2;
        else
            d_CameraObject = 5;
        end
        cameraZ = d_CameraObject*sin(deg2rad(90+cameraYRot));
        cameraY = 0;
        cameraX = -d_CameraObject*cos(deg2rad(90+cameraYRot));

        fprintf(fileID,'%s\t%d\t%f\t%f\t%f\n',RefnameUpper,cameraYRot,cameraX,cameraY,cameraZ);                
    end
    fclose(fileID);
end

%% Rendering
% Shape(blenderfile), Specular(Mapping),ReflectanceStep(Condition),Hue(Condition), BackGround(Mapping),
% Environment(Condition)
% Requires Mitsuba + RenderToolbox4 (rtbMakeSceneFiles / MyrtbBatchRender)
% and the *_Figure_Stimuli_Mapping.json files, which are not bundled.
% (assert used instead of error() because "error" is a variable above)
assert(exist('rtbMakeSceneFiles','file')>0, ...
    ['Rendering requires Mitsuba and RenderToolbox4 (rtbMakeSceneFiles/', ...
    'MyrtbBatchRender), which are not bundled with this repository.']);
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 600*0.3;
hints.imageHeight = 600*0.3;
hints.recipeName = 'AllStimuli';
hints.renderer = 'Mitsuba';

en = 0;bg = 0;
for Environment = {'E1','E2','E3','E4'}
    if strcmp(Environment{1},'E1') || strcmp(Environment{1},'E2')
        shape = {'Bumpy'};
    elseif strcmp(Environment{1},'E3') || strcmp(Environment{1},'E4')
        shape = {'Potato'};
    end
    en = en + 1;
    %% Choose example files.
    fname = strcat('Figure_Stimuli_',Environment{1},'_Condition_Exp1.txt');
    parentSceneFile = fullfile(blend_dir,strcat(shape{1},'_Figure.blend'));
    mappingsFile = strcat(Environment{1},'_Figure_Stimuli_Mapping.json'); % not bundled with this repository
    conditionsFile = fullfile(rendering_dir,strcat('Figure_Stimuli_',Environment{1},'_Condition.txt'));
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'conditionsFile', conditionsFile, ...
        'mappingsFile', mappingsFile, ...
        'hints', hints);
    
    [~,MultiSpectralImage] = MyrtbBatchRender(nativeSceneFiles, 'hints', hints);   
    nameMulti = strcat(shape{1},'_',Environment{1},'_MultiSpectralImage');
    str = strcat(nameMulti,'=MultiSpectralImage;');eval(str);
    %M = MultiSpectralImage(:,:,2:32,1);
    %MB = MultiSpectralImagetoMB_Optimized(M);
    %RGB = mb_image_to_rgb_image(MB);

    for MultiIndex = 1:9
        %if strcmp(Environment{1},'E4')
            strMultiSpectraltoMB = strcat('MB=MultiSpectralImagetoMB_Optimized(',nameMulti,'(:,:,2:32,MultiIndex));');
        %else
            %strMultiSpectraltoMB = strcat('MB=MultiSpectralImagetoMB_Optimized(',nameMulti,'(:,:,1:31,MultiIndex));');
        %end
        %strMultiSpectraltoMB = strcat('[MB,RGB]= HSLightProbe_MultiSpectralImagetoMBandRGB_400to700(',nameMulti,'(:,:,1:31,MultiIndex));');
        eval(strMultiSpectraltoMB);

        strMultiSpectraltoAlpha = strcat('Alpha=',nameMulti,'(:,:,1,MultiIndex);');
        eval(strMultiSpectraltoAlpha);
        
        nameMB = strcat(shape{1},'_',Environment{1},'_Hue',num2str(MultiIndex),'_MB');
        nameRGB = strcat(shape{1},'_',Environment{1},'_Hue',num2str(MultiIndex),'_RGB');
        strMB = strcat(nameMB,'=MB;');
        eval(strMB);
        RGB = mb_image_to_rgb_image(MB);
        save(fullfile(stimuli_dir,nameMB),'MB');
        save(fullfile(stimuli_dir,nameRGB),'RGB','Alpha');
    end
end

for Environment = {'E1','E2','E3','E4'}
    if strcmp(Environment{1},'E1') || strcmp(Environment{1},'E2')
        shape = {'Bumpy'};
    elseif strcmp(Environment{1},'E3') || strcmp(Environment{1},'E4')
        shape = {'Potato'};
    end
    for hue = 1:9
        nameRGB = strcat(shape{1},'_',Environment{1},'_Hue',num2str(hue),'_RGB');

        load(fullfile(stimuli_dir,nameRGB))
        eval([Environment{1},'_',num2str(hue),' = RGB;'])
        eval([Environment{1},'_',num2str(hue),'_Alpha',' = Alpha;'])
    end
end

Image = vertcat([E1_1,E1_2,E1_3,E1_4,E1_5,E1_6,E1_7,E1_8,E1_9]*1.2,...
    [E2_1,E2_2,E2_3,E2_4,E2_5,E2_6,E2_7,E2_8,E2_9]*1.2,...
    [E3_1,E3_2,E3_3,E3_4,E3_5,E3_6,E3_7,E3_8,E3_9]*6,...
    [E4_1,E4_2,E4_3,E4_4,E4_5,E4_6,E4_7,E4_8,E4_9]*3);

AlphaImage = vertcat([E1_1_Alpha,E1_2_Alpha,E1_3_Alpha,E1_4_Alpha,E1_5_Alpha,E1_6_Alpha,E1_7_Alpha,E1_8_Alpha,E1_9_Alpha]*255*3,...
    [E2_1_Alpha*2,E2_2_Alpha*2,E2_3_Alpha*2,E2_4_Alpha*4,E2_5_Alpha*4,E2_6_Alpha*4,E2_7_Alpha*2,E2_8_Alpha*2,E2_9_Alpha*2]*255*3,...
    [E3_1_Alpha,E3_2_Alpha,E3_3_Alpha,E3_4_Alpha,E3_5_Alpha,E3_6_Alpha,E3_7_Alpha,E3_8_Alpha,E3_9_Alpha]*255*3,...
    [E4_1_Alpha,E4_2_Alpha,E4_3_Alpha,E4_4_Alpha,E4_5_Alpha,E4_6_Alpha,E4_7_Alpha,E4_8_Alpha,E4_9_Alpha]*255*48);

imshow(Image)
imwrite(Image,fullfile(figs_dir,'Figure_AllShape.png'),'Alpha',AlphaImage)