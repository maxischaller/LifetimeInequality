function [sim_path] = simpath_par_behfix(calib,var,data,base_sim_path)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation of life cycle paths - Behavior fixed to Baseline  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% NOTES:
% > behfix: behavior fixed to baseline simulations

%%% INPUT:
%   - "calib": model calibration-struct
%   - "data": observed data from estimation sample
%   - "var": variables-struct
%   - "base_sim_path": simulated baseline behavior

%%% OUTPUT:
%   - "sim_path": simulated life-cycle path variables


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------
sim_calib = {'fieldnames','R','T','Z'};
    v2struct(calib,sim_calib);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Prepare baseline life-cycle paths
% ---------------------------------------

%%% > correction to use path variables as index
% base_sim_path.Reti_path = base_sim_path.Reti_path + 1;
% base_sim_path.Empl_path = base_sim_path.Empl_path + 1;
% base_sim_path.Health_path = base_sim_path.Health_path + 1;

for z = 1:Z

    dEduc(:,:,z)   = base_sim_path.Educ((z-1)*R/Z+1:z*R/Z,:); %#ok<*AGROW>
    
    dType(:,:,z)   = base_sim_path.Type((z-1)*R/Z+1:z*R/Z,:);

    dReti(:,:,z)   = base_sim_path.Reti_path((z-1)*R/Z+1:z*R/Z,:);

    dEmpl(:,:,z)   = base_sim_path.Empl_path((z-1)*R/Z+1:z*R/Z,:);

    dExper(:,:,z)  = base_sim_path.Exper_path((z-1)*R/Z+1:z*R/Z,:);  % 1:T+1

    dHealth(:,:,z) = base_sim_path.Health_path((z-1)*R/Z+1:z*R/Z,:);    %1:T+1

    dWAGE(:,:,z)   = base_sim_path.WAGE_path((z-1)*R/Z+1:z*R/Z,:);  %1:T+1
    dWAGE2(:,:,z)  = base_sim_path.WAGE2_path((z-1)*R/Z+1:z*R/Z,:); %1:T+1

    dSavChoice(:,:,z) = base_sim_path.SavChoice_path((z-1)*R/Z+1:z*R/Z,:);  %1:T+1

    dWShock2(:,:,z) = base_sim_path.WShock2_path((z-1)*R/Z+1:z*R/Z,:);  %1:T+1

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Simulate Live Cycle Paths - Parallelized:
%  ----------------------------------------
%%% NOTES:
%   - dim3/pages implementation for z-Loop to make parfor work
%     (restrictions on valid index for slicing vars)


%%% Parallelized loop
%   > Note: using parfor not necessarily is of advantage because the most 
%       computationally intensive derivations (interpolation) is not
%       required when the behavior is fixed
for z = 1:Z

    %%% Extract correct baseline path-variables
    base            = [];       % required to make parfor work (ensure slicing)
    base.Educ       = dEduc(:,:,z);
    base.Type       = dType(:,:,z);
    base.Reti       = dReti(:,:,z);
    base.Empl       = dEmpl(:,:,z);
    base.Exper      = dExper(:,:,z);
    base.Health     = dHealth(:,:,z);
    base.WAGE       = dWAGE(:,:,z);
    base.WAGE2      = dWAGE2(:,:,z);
    base.WShock2    = dWShock2(:,:,z);
    base.SavChoice  = dSavChoice(:,:,z);


    %%% Execute Simulation of Subsample
    [sim_path] = parsim_behfix(calib,var,data,base);

   
    %%% Write Results to Summary Path Variables 
    pC_path(:,:,z)       = sim_path.C_path;
    pY_path(:,:,z)       = sim_path.Y_path;
    pGCI_path(:,:,z)     = sim_path.GCI_path;
    pCTAX_path(:,:,z)    = sim_path.CTAX_path;
    pITAX_path(:,:,z)    = sim_path.ITAX_path;
    pSSC_path(:,:,z)     = sim_path.SSC_path;
    pHINS_path(:,:,z)    = sim_path.HINS_path;
    pMPB_path(:,:,z)     = sim_path.MPB_path;
    pEPB_path(:,:,z)     = sim_path.EPB_path;
    pDPB_path(:,:,z)     = sim_path.DPB_path;
    pNPB_path(:,:,z)     = sim_path.NPB_path;
    pExper_path(:,:,z)   = sim_path.Exper_path;
    pSav_path(:,:,z)     = sim_path.Sav_path;
    pSavChoice_path(:,:,z) = sim_path.SavChoice_path;

    pFav_path(:,:,z)     = sim_path.Fav_path;

    pUINS_path(:,:,z)    = sim_path.UINS_path;
    pPINS_path(:,:,z)    = sim_path.PINS_path;
    pWAGE_path(:,:,z)    = sim_path.WAGE_path;
    pWAGE2_path(:,:,z)   = sim_path.WAGE2_path;
    pWShock2_path(:,:,z) = sim_path.WShock2_path;   % rename to match sizes
    pUIB_path(:,:,z)     = sim_path.UIB_path;
    pSAB_path(:,:,z)     = sim_path.SAB_path;
    pEmpl_path(:,:,z)    = sim_path.Empl_path;
    pReti_path(:,:,z)    = sim_path.Reti_path;    

    pHealth_path(:,:,z)  = sim_path.Health_path;
    pPov_path(:,:,z)     = sim_path.Pov_path;

    pType(:,:,z)         = sim_path.Type;
    pEduc(:,:,z)         = sim_path.Educ;

    pExpRatio_path(:,:,z) = sim_path.ExpRatio_path;

    pWealth_path(:,:,z) = sim_path.Wealth_path;

end



%%% Convert Dimension Back
for z = 1:Z
    if z == 1
        C_path      = pC_path(:,:,z);
        Y_path      = pY_path(:,:,z);
        GCI_path    = pGCI_path(:,:,z);
        CTAX_path   = pCTAX_path(:,:,z);
        ITAX_path   = pITAX_path(:,:,z);
        SSC_path    = pSSC_path(:,:,z);
        HINS_path   = pHINS_path(:,:,z);
        MPB_path    = pMPB_path(:,:,z);
        EPB_path    = pEPB_path(:,:,z);
        DPB_path    = pDPB_path(:,:,z);
        NPB_path    = pNPB_path(:,:,z);
        Exper_path  = pExper_path(:,:,z);
        Sav_path    = pSav_path(:,:,z);
        SavChoice_path = pSavChoice_path(:,:,z);

        Fav_path    = pFav_path(:,:,z);

        UINS_path   = pUINS_path(:,:,z);
        PINS_path   = pPINS_path(:,:,z);
        WAGE_path   = pWAGE_path(:,:,z);
        WAGE2_path  = pWAGE2_path(:,:,z);
        p2WShock2_path = pWShock2_path(:,:,z);
        UIB_path    = pUIB_path(:,:,z);
        SAB_path    = pSAB_path(:,:,z);
        Empl_path   = pEmpl_path(:,:,z);
        Reti_path   = pReti_path(:,:,z);

        Health_path = pHealth_path(:,:,z);
        Pov_path    = pPov_path(:,:,z);
        
        Type        = pType(:,:,z);
        Educ        = pEduc(:,:,z);

        ExpRatio_path = pExpRatio_path(:,:,z);

        Wealth_path = pWealth_path(:,:,z);

    else
        C_path      = [C_path;pC_path(:,:,z)];
        Y_path      = [Y_path;pY_path(:,:,z)];
        GCI_path    = [GCI_path;pGCI_path(:,:,z)];
        CTAX_path   = [CTAX_path;pCTAX_path(:,:,z)];
        ITAX_path   = [ITAX_path;pITAX_path(:,:,z)];
        SSC_path    = [SSC_path;pSSC_path(:,:,z)];
        HINS_path   = [HINS_path;pHINS_path(:,:,z)];
        MPB_path    = [MPB_path;pMPB_path(:,:,z)];
        EPB_path    = [EPB_path;pEPB_path(:,:,z)];
        DPB_path    = [DPB_path;pDPB_path(:,:,z)];
        NPB_path    = [NPB_path;pNPB_path(:,:,z)];
        Exper_path  = [Exper_path;pExper_path(:,:,z)];
        Sav_path    = [Sav_path;pSav_path(:,:,z)];
        SavChoice_path    = [SavChoice_path;pSavChoice_path(:,:,z)];

        Fav_path    = [Fav_path;pFav_path(:,:,z)];

        UINS_path   = [UINS_path;pUINS_path(:,:,z)];
        PINS_path   = [PINS_path;pPINS_path(:,:,z)];
        WAGE_path   = [WAGE_path;pWAGE_path(:,:,z)];
        WAGE2_path  = [WAGE2_path;pWAGE2_path(:,:,z)];
        p2WShock2_path = [p2WShock2_path;pWShock2_path(:,:,z)];
        UIB_path    = [UIB_path;pUIB_path(:,:,z)];
        SAB_path    = [SAB_path;pSAB_path(:,:,z)];
        Empl_path   = [Empl_path;pEmpl_path(:,:,z)];
        Reti_path   = [Reti_path;pReti_path(:,:,z)];

        Health_path = [Health_path;pHealth_path(:,:,z)];
        Pov_path    = [Pov_path;pPov_path(:,:,z)];

        Type        = [Type;pType(:,:,z)];
        Educ        = [Educ;pEduc(:,:,z)];

        ExpRatio_path    = [ExpRatio_path;pExpRatio_path(:,:,z)];

        Wealth_path = [Wealth_path;pWealth_path(:,:,z)];
    end
    
    

end


    WShock2_path = p2WShock2_path;

%%% Write Path Variables to Struct
sim_path = v2struct(C_path,Y_path,GCI_path,ITAX_path,CTAX_path,SSC_path,UINS_path,PINS_path, ...
                   HINS_path,WAGE_path,WAGE2_path,WShock2_path,UIB_path,SAB_path,MPB_path, ...
                   EPB_path,DPB_path,NPB_path,Type,Educ,Empl_path,Reti_path,Health_path, ...
                   Wealth_path,Sav_path,Exper_path,Pov_path,Fav_path,ExpRatio_path);




end