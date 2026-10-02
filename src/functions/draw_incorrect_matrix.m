function Out = draw_incorrect_matrix(M)
% Function to write Performance Matrix

Lessthan50 = brewermap(8,'Reds');
Lessthan50 = Lessthan50(4:8,:);
c = brewermap(8,'Reds');
c(2:length(c)+1,:) = c;c(1,:) = 1;
chancelevel = 0.5;

c_blank = [124 215 220]/255*0.95; % Color for blank pixels

Basisvector_RGB = [0.805397554745334,0.578851979681344,0.711879895735292;...
    0.787293540963976,0.569845356351199,0.813575434882833;...
    0.711955852905546,0.605882049887387,0.850334927702030;...
    0.610787406253394,0.660407717453200,0.811089134802130;...
    0.544613126955130,0.701317857457000,0.707390134496488;...
    0.572051896488103,0.708578776972239,0.582039716631771;...
    0.667580573428483,0.678788811224770,0.520956911240964;...
    0.758990980401772,0.626848656843467,0.583837527813780;...
    0.689256543793169,0.643916752593870,0.709533095176641];

s = 50;
edge = s*0.1;

for i = 1:9
    for k = 1:3
        BasisVColor((i-1)*s+1:i*s,1:s,k) = vertcat(ones(edge,s),[ones(s-edge*2,edge),repmat(Basisvector_RGB(i,k),s-edge*2),ones(s-edge*2,edge)],ones(edge,s));
    end
end

BasisVColor_T(:,:,1) = BasisVColor(:,:,1)';
BasisVColor_T(:,:,2) = BasisVColor(:,:,2)';
BasisVColor_T(:,:,3) = BasisVColor(:,:,3)';

UpperLabel = [ones(s,s,3),BasisVColor_T,ones(s,s,3)];
    
for i = 1:9
    for j = 1:9

        N_M = M(i,j);

        for k = 1:3
            if i == j
                M_Out((i-1)*s+1:i*s,(j-1)*s+1:j*s,k) = ones(s,s)*c_blank(k);
            else
                M_Out((i-1)*s+1:i*s,(j-1)*s+1:j*s,k) = repmat(c(M(i,j)+1,k),s);
            end
        end
    end
end
noh = 8;
Out = vertcat(UpperLabel,[BasisVColor,M_Out,ones(s*(noh+1),s,3)]);
end