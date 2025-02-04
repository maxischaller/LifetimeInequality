function [] = simcontrol_riskscen(calib,var,data,paramhat,draws)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Control Script: Simulation of life cycle paths - Risk Scenarios  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------

scen_calib = {'fieldnames','Adjust','Tau','Const','Const2','LSum1','LSum2', ...
                            'Nodis','Psi','Zeta','Xi','Omega','Ret60','Ret63', ...
                            'Ret65','MPplus','DeltaO','DeltaS','DeltaH1','DeltaH2','R','T'};
    v2struct(calib,scen_calib);


%%% Elements required for reshape of simulated data
    age = var.age;
    R   = calib.R;
    T   = calib.T;  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Simulate risk scenarios and save datasets:
% ----------------------------------------------

%%% Loop over scenarios
    for scen = 1:3  
        
        disp('--------------------------------')
        disp(['Running risk scenario:    ', num2str(scen)])

        % ---------------------------------------
        %%% Set adjusted values
            DeltaS  = 0;
            DeltaO  = 0;
            DeltaH2 = 0;
    
            % > A: Increase separation risk
            if scen == 1
                DeltaS = 1;         % double separation risk
            
            % > B: Decrease offer probabilities
            elseif scen == 2     
                DeltaO = -0.25;     % 3/4 offer probability
    
            % > C: Increase bad-health risk
            elseif scen == 3
                DeltaH2 = 2;        % double health risk
            
            end


        % ------------------------------
        %%% Overwrite Values in Structs
        %   > commented are not adjusted
            calib.DeltaO  = DeltaO;       
            calib.DeltaS  = DeltaS;
            calib.DeltaH2 = DeltaH2;


        % -------------------------------------------------------------
        %%% Simulate Life-Cycle Paths
            [sim_path_scen,~] = simpath_par(calib,var,data,paramhat,draws);

        % ----------------------------------
        %%% Simulate 'alive' indicator 
        [Alive_path,Cumsurv_path]       = alive(calib,data,sim_path_scen,draws);
            sim_path_scen.Alive_path    = Alive_path;
            sim_path_scen.Cumsurv_path  = Cumsurv_path;


        % ----------------------------------------------------------------
        %%% Save Simulated Data
        % > Unpack simulated paths
        simunpack = {'fieldnames','Type','Educ','C_path','Y_path','GCI_path','ITAX_path','CTAX_path','UINS_path', ...
                            'PINS_path','HINS_path','WAGE_path','WAGE2_path','WShock2_path','UIB_path','SAB_path', ...
                            'MPB_path','EPB_path','DPB_path','Empl_path','Reti_path','Health_path','Wealth_path', ...
                            'Sav_path','Exper_path'};
            v2struct(sim_path_scen,simunpack);


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
        
            Alive   = reshape(Alive_path(:,1:dT),R*dT,1);
        
            CalibDeltaS = EDUC;
                CalibDeltaS(:) = DeltaS;
            CalibDeltaO = EDUC;
                CalibDeltaO(:) = DeltaO;
            CalibDeltaH2 = EDUC;
                CalibDeltaH2(:) = DeltaH2;


        % ----------------------------------
        %%% Save to .txt File
            TAB = table(ID,Age,TYPE,EDUC,C,Y,GCI,ITAX,CTAX,UINS,PINS,HINS,WAGE,WAGE2,WShock,UIB,SAB,MPB,EPB,DPB,Empl,Reti,Health,Wealth,Sav,Exper,Alive,CalibDeltaS,CalibDeltaO,CalibDeltaH2);
            
            if scen == 1 
                %writetable(TAB,'MatlabCode/02_output/data_scenario_A.txt');
                writetable(TAB,join([calib.simdatadir,'data_scenario_A.txt']))
            elseif scen == 2
                %writetable(TAB,'MatlabCode/02_output/data_scenario_B.txt');
                writetable(TAB,join([calib.simdatadir,'data_scenario_B.txt']))
            elseif scen == 3
                %writetable(TAB,'MatlabCode/02_output/data_scenario_C.txt');
                writetable(TAB,join([calib.simdatadir,'data_scenario_C.txt']))
            end


        disp('...done.')
    end     % end scenario loop



end         % end function