function [] = simcontrol_sepsim(calib,var,data,paramhat,draws)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Control Script: Simulation of life cycle paths + Invol.Separations %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------

%%% Elements required for reshape of simulated data
    age = var.age;
    R   = calib.R;
    T   = calib.T;  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Execute simulation procedure:
% ---------------------------------
% ---------------------------------
%%% Run simulation
    [sim_path,~] = simpath_par_sepsim(calib,var,data,paramhat,draws);


% ----------------------------------
%%% Simulate Alive Indicator
    [Alive_path,Cumsurv_path] = alive(calib,data,sim_path,draws);
        sim_path.Alive_path   = Alive_path;
        sim_path.Cumsurv_path = Cumsurv_path;

% ----------------------------------
%%% Save simulated life-cycles and model solution 
    %savefile = 'MatlabCode/02_output/sim_paths_sepsim.mat';     
    %save(savefile,'sim_path','sim_sol');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Save simulated life-cycles for Stata Analysis
% --------------------------------------------------
%%% Unpack simulated paths
    simunpack = {'fieldnames','Type','Educ','C_path','Y_path','GCI_path','ITAX_path','CTAX_path','UINS_path', ...
                        'PINS_path','HINS_path','WAGE_path','WAGE2_path','WShock2_path','UIB_path','SAB_path', ...
                        'MPB_path','EPB_path','DPB_path','Empl_path','Reti_path','Health_path','Wealth_path', ...
                        'Sav_path','Exper_path','SepShock_path'};
        v2struct(sim_path,simunpack);

% ----------------------------------
%%% Restructure simulated outcomes
    dT = 81;
    
    %%% Generate ID
    ID      = (1:1:R)';
    ID      = reshape(repmat(ID,[1 dT]),R*dT,1);
    
    %%% Reshape
    Age     = reshape(repmat(age(1:dT,1)',[R 1]),R*dT,1);
    TYPE    = reshape(repmat(Type,[1 dT]),R*dT,1);
    EDUC    = reshape(repmat(Educ,[1 dT]),R*dT,1);
    C       = reshape(C_path(:,1:dT),R*dT,1); %#ok<*USENS>
    Y       = reshape(Y_path(:,1:dT),R*dT,1);
    GCI     = reshape(GCI_path(:,1:dT),R*dT,1);
    ITAX    = reshape(ITAX_path(:,1:dT),R*dT,1);
    CTAX    = reshape(CTAX_path(:,1:dT),R*dT,1);
    UINS    = reshape(UINS_path(:,1:dT),R*dT,1);
    PINS    = reshape(PINS_path(:,1:dT),R*dT,1);
    HINS    = reshape(HINS_path(:,1:dT),R*dT,1);
    WAGE    = reshape(WAGE_path(:,1:dT),R*dT,1);
    WAGE2   = reshape(WAGE2_path(:,1:dT),R*dT,1);       % with measurement error added
    WShock  = reshape(WShock2_path(:,1:dT),R*dT,1);
    UIB     = reshape(UIB_path(:,1:dT),R*dT,1);
    SAB     = reshape(SAB_path(:,1:dT),R*dT,1);
    MPB     = reshape(MPB_path(:,1:dT),R*dT,1);
    EPB     = reshape(EPB_path(:,1:dT),R*dT,1);
    DPB     = reshape(DPB_path(:,1:dT),R*dT,1);
    Empl    = reshape(Empl_path(:,1:dT),R*dT,1);
    Reti    = reshape(Reti_path(:,1:dT),R*dT,1);
    Health  = reshape([Health_path repmat(999,[R dT-(T+1)])],R*dT,1);
    Wealth  = reshape([Wealth_path repmat(999,[R dT-(T+1)])],R*dT,1);
    Sav     = reshape(Sav_path(:,1:dT),R*dT,1);
    Exper   = reshape(Exper_path(:,1:dT),R*dT,1);
    SepShock= reshape(SepShock_path(:,1:dT),R*dT,1);
    Alive   = reshape(Alive_path(:,1:dT),R*dT,1);

    %%% Save to .txt File
    TAB = table(ID,Age,TYPE,EDUC,C,Y,GCI,ITAX,CTAX,UINS,PINS,HINS,WAGE,WAGE2,WShock,UIB,SAB,MPB,EPB,DPB,Empl,Reti,Health,Wealth,Sav,Exper,Alive,SepShock);
    %writetable(TAB,'MatlabCode/02_output/data_involsep.txt');
    writetable(TAB,join([calib.simdatadir,'data_involsep.txt']))


end