function [data] = dataprep(calib)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Prepare Variables containing Data   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% INPUT DATA:
%   - Estimation sample: data.txt
%   - Health transition profiles: hbg.txt, hgg.txt
%   - Mortality profiles: spbh_e0.txt, spgh_e0.txt, spbh_e1.txt, spgh_e1.txt

%%% OUTPUTS:
%   Figure 3(c): Mortality Risk

%%% STRUCTURE:
%   1. Unpack required calibration
%   2. Load main estimation dataset
%   3. Load health transition profiles
%   4. Load heterogenous survival profiles
%   5. Write data to structure: "data"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 1. Unpack Parameters/Switches
Mort    = calib.Mort;
N       = calib.N;
W       = calib.W;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 2. Main Estimation Dataset
rawdata = load(join([calib.SOEPdatadir,'estim_sample.txt']));
X       = zeros(N,size(rawdata,2),W);
for n=1:N
    for w=1:W
        X(n,:,w) = rawdata((n-1)*W+w,:);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 3. Health Transition Profiles
hbg = load('MatlabCode/01_input/hbg.txt');        % transition prob from bad to good health
hgg = load('MatlabCode/01_input/hgg.txt');        % transition prob from good to good health


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 4. Heterogeneous Mortality Profiles
if     Mort == 0
    % No mortality
    spgh=repmat([ones(80,58) zeros(80,22)]',[1 1 2]);
    spbh=repmat([ones(80,58) zeros(80,22)]',[1 1 2]);

elseif Mort == 1
    %%% Heterogeneous mortality 
    spbh_e0 = load('MatlabCode/01_input/spbh_e0.txt');
    spbh_e1 = load('MatlabCode/01_input/spbh_e1.txt');
    spgh_e0 = load('MatlabCode/01_input/spgh_e0.txt');
    spgh_e1 = load('MatlabCode/01_input/spgh_e1.txt');

    % > bad-health
    spbh = ones(80,80,2);
    spbh(:,:,1) = tril(repmat(spbh_e0(1:80,1),[1 80]));
    spbh(:,:,2) = tril(repmat(spbh_e1(1:80,1),[1 80]));

    % > good-health
    spgh = ones(80,80,2);
    spgh(:,:,1) = tril(repmat(spgh_e0(1:80,1),[1 80]));
    spgh(:,:,2) = tril(repmat(spgh_e1(1:80,1),[1 80]));

    % > lifetable reference
     lifetable = load('MatlabCode/01_input/lifetable.txt');

end


% -------------------------------------------------------------
%%% Plot: Figure_3c_MortalityRisk
    sup = 20:99;

    f1 = figure;
    set(0,'DefaultLineLineWidth',1.2)

    plot(sup,cumprod(diag(spbh(:,:,1))),'LineStyle','--','Color',[0.4 0.4 0.4])
    hold on
    plot(sup,cumprod(diag(spbh(:,:,2))),'LineStyle','-.','Color',[0.4 0.4 0.4])
    hold on
    plot(sup,cumprod(diag(spgh(:,:,1))),'LineStyle','--','Color',[0.7 0.7 0.7])
    hold on
    plot(sup, cumprod(diag(spgh(:,:,2))),'LineStyle','-.','Color',[0.7 0.7 0.7])
    hold on
    plot(sup, cumprod(lifetable(1:80)),'k-')

    hold on
    plot(sup, repmat(0.5,[80 1]),'k-','LineWidth',0.7)
    legend('Bad health and low education','Bad health and high education','Good health and low education','Good health and high education','Baseline (HMD)','Location','southwest')
    xlabel('Age (years)','FontSize',14)
    ylabel('Survival probability','FontSize',14)
    ax = gca;
    ax.FontSize = 13; 
    ax.YGrid = 'on';
    ax.FontName = 'Linux Libertine O' ;
    pbaspect([1.5 1 1]);
    
    %exportgraphics(ax,'Figure_3c_MortalityRisk.pdf')
    %   > does not work with latex-font export
    %   > instead: save graphic as (svg) and convert as pdf e.g. using
    %   inkscape

    %saveas(f1,'MatlabCode/02_output/Figure_3c_MortalityRisk.svg');
    saveas(f1,join([calib.figureout,'Figure_3c_MortalityRisk.svg']));
    close(f1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 5. Write to Data-Struct

data = v2struct(X,hbg,hgg,spgh,spbh);


end