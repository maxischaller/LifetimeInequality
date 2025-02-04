function [] = simcontrol_taxpol_bisec(calib,var,data,paramhat,base_sim_path,draws)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Control Script: Simulation of lifetime tax policy reform  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------
scen_calib = {'fieldnames','DeltaO','DeltaS','DeltaH1','DeltaH2', ...
                            'R','T','TaxLT','BehFix'};        
    v2struct(calib,scen_calib);


%%% Elements required for reshape of simulated data
    age = var.age;
    R   = calib.R;
    T   = calib.T; 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Reference values from baseline scenario:
% -------------------------------------------

%%% Run baseline scenario simulation for fixed behavior simulations
%   > run baseline scenario again with switch BehFix=1: removes
%       transformation of path variables at the end
        
    if isfile('MatlabCode/02_output/sim_paths_BehFix.mat')
        % File exists.
        load('MatlabCode/02_output/sim_paths_BehFix.mat','BehFix_sim_path')

    else
        % File does not exist.
        BehFix = 1;
            calib.BehFix = BehFix;
        
        [BehFix_sim_path,~] = simpath_par(calib,var,data,paramhat,draws);    
        
            calib.BehFix = 0;

        save('MatlabCode/02_output/sim_paths_BehFix.mat','BehFix_sim_path')
    end    


%%% Test equivalence to original baseline scenario simulation    
    d1 = zeros(9,1);
        d1(1) = isequal(BehFix_sim_path.ExpRatio_path, base_sim_path.ExpRatio_path); 
        d1(2) = isequal(BehFix_sim_path.Educ, base_sim_path.Educ); 
        d1(3) = isequal(BehFix_sim_path.ITAX_path, base_sim_path.ITAX_path);
        d1(4) = isequal(BehFix_sim_path.CTAX_path, base_sim_path.CTAX_path);
        d1(5) = isequal(BehFix_sim_path.UINS_path, base_sim_path.UINS_path);
        d1(6) = isequal(BehFix_sim_path.HINS_path, base_sim_path.HINS_path);
        d1(7) = isequal(BehFix_sim_path.SAB_path, base_sim_path.SAB_path);
        d1(8) = isequal(BehFix_sim_path.DPB_path, base_sim_path.DPB_path);
        d1(9) = isequal(BehFix_sim_path.UIB_path, base_sim_path.UIB_path); 
    assert(mean(d1)==1)

%%% Flag for entry into labor market
    Entry = zeros(R,81);
    for r = 1:R
        if base_sim_path.Educ(r)<13
            Entry(r,:) = ones(1,81);
        else
            Entry(r,:) = [zeros(1,(base_sim_path.Educ(r)-12)) ones(1,(81-(base_sim_path.Educ(r)-12)))];
        end
    end    

%%% Derive baseline experience ratio   
    ExpRatio_extract = base_sim_path.ExpRatio_path;

    ExpRatio_extract(find(Entry==0)) = NaN;  %#ok<FNDSB>
    MeanExpRatio = mean(ExpRatio_extract,"omitnan");
    calib.MeanExpRatio = MeanExpRatio;


%%% Save baseline-education to calib-struct
    calib.Educ_b = base_sim_path.Educ;

%%% Simulate alive indicator on baseline scenario    
    [Alive_path_base,~] = alive(calib,data,base_sim_path,draws);
        % > requires base_sim_path (original BehFix=0 simulation with transformation
        %       on health_path)

%%% Derive Revenue-Neutrality criterium for baseline:
    simunpack = {'fieldnames','ITAX_path','CTAX_path','UINS_path',...
                        'HINS_path','UIB_path','SAB_path','DPB_path'};
        v2struct(BehFix_sim_path,simunpack);

    val_base = UIB_path(:,1:40) + SAB_path(:,1:40) + DPB_path(:,1:40) - ITAX_path(:,1:40) - CTAX_path(:,1:40) - UINS_path(:,1:40) - HINS_path(:,1:40); 
    
    val_base = val_base.*Alive_path_base(:,1:40);

    crit_base = sum(val_base,'all');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Simulate lifetime tax policy scenarios and save datasets:
% -------------------------------------------------------------
%%% Notes:
%   - Simple bisection root finding procedure to calibrate parameters of 
%       lifetime tax reform to ensure revenue-neutrality
%   - Search for value of parameter pi1: modulates the extent to which the
%       tax reform increases taxes for individuals who have worked above
%       average years for their age group.

%%% Init bounds for reform scenario (scenarios in columns)
RevNeutral_init = [0.4 0.7; ...
                   0.7 1.0];

%%% Set convergence tolerance
ConvTol = 500000;


% -------------------------------------------------------------------------
%%% Loop over scenarios
    for scen = 1:2

        %%% Solution to revenue neutral parameter calibration
        RevNeutral_sol = zeros(1,4); % [a, c, b], f(c)
            % Evaluated intervals: [a,b] and midpoint c=(a+b)/2
            % Function values f(c): revenue-difference to baseline scenario at
            % midpoint

        if scen == 1
            disp('1) Lifetime tax policy reform: simulation with fixed behavior')
            disp('-------------------------------------------------------------')
            disp('Bisection search: revenue-neutral parameter calibration:')
            disp('Iteration   Diff-Criterion        a          c          b  ')
            disp('--------    --------------       ---        ---        --- ')
 
        else
            disp('2) Lifetime tax policy reform: simulation with behavioral adjustments')
            disp('---------------------------------------------------------------------')
            disp('Bisection search: revenue-neutral parameter calibration:')
            disp('Iteration   Diff-Criterion        a          c          b  ')
            disp('--------    --------------       ---        ---        --- ')
        end

        % ---------------------------------------
        %%% Reset adjusted values
        TaxLT   = 0; 
        EdFix   = 0; %#ok<*NASGU>

        %%% retrieve inital bounds
        a    = RevNeutral_init(1,scen);
        b    = RevNeutral_init(2,scen);
        c    = (a+b)/2;
       
        iter = 0;

        critmin = ConvTol+100000;        


        % ----------------------------------------------------------------
        while abs(critmin) > ConvTol
            %tic

            % >>> track iterations
            iter = iter + 1;

            % ----------------------------------
            %%% Evaluate current grid points
            if iter == 1
                % >>> at first iteration evaluate all points
                xgrid = [a c b];

                for i = 1:3             
                    % -----------------------------------
                    %%% Lifetime taxation: fixed behavior
                    if scen == 1                              
                        TaxLT = 1;

                        calib.LTalpha = xgrid(i);          
                        calib.TaxLT = TaxLT;
            
                        % -----------------------------
                        %%% Simulate Life-Cycle Paths            
                        [sim_path_tax] = simpath_par_behfix(calib,var,data,BehFix_sim_path);
                        
                    % -------------------------------------------------
                    %%% Lifetime taxation: incl. behavioral adjustments
                    elseif scen == 2
                        TaxLT = 1;
                        EdFix = 0;

                        calib.TaxLT = TaxLT; 
                        calib.EdFix = EdFix;
                        calib.LTalpha = xgrid(i);
    
                        % -----------------------------
                        %%% Simulate Life-Cycle Paths                          
                        [sim_path_tax,~] = simpath_par(calib,var,data,paramhat,draws);
    
                    end
            
            
                    % -----------------------------
                    %%% Derive critical value
                    [Alive_path,~] = alive(calib,data,sim_path_tax,draws);
                    
                    simunpack = {'fieldnames','ITAX_path','CTAX_path','UINS_path','HINS_path','UIB_path','SAB_path','DPB_path'};
                        v2struct(sim_path_tax,simunpack);

                    val = UIB_path(:,1:40) + SAB_path(:,1:40) + DPB_path(:,1:40) - ITAX_path(:,1:40) - CTAX_path(:,1:40) - UINS_path(:,1:40) - HINS_path(:,1:40); 

                    val = val.*Alive_path(:,1:40);
            
                    crit_scen(i) = sum(val,'all'); %#ok<AGROW>
             
                end 


            %%% -----------------------------------------------------------    
            else
                % >>> for iter>1 only midpoint is updated
                i = 2;          
                    % -----------------------------------
                    %%% Lifetime taxation: fixed behavior
                    if scen == 1                              
                        TaxLT = 1;

                        calib.LTalpha = xgrid(i);          
                        calib.TaxLT = TaxLT;
            
                        % -----------------------------
                        %%% Simulate Life-Cycle Paths            
                        [sim_path_tax] = simpath_par_behfix(calib,var,data,BehFix_sim_path);

                        
                    % -------------------------------------------------
                    %%% Lifetime taxation: incl. behavioral adjustments
                    elseif scen == 2
                        TaxLT = 1;
                        EdFix = 0;

                        calib.TaxLT = TaxLT; 
                        calib.EdFix = EdFix;
                        calib.LTalpha = xgrid(i);
    
                        % -----------------------------
                        %%% Simulate Life-Cycle Paths                          
                        [sim_path_tax,~] = simpath_par(calib,var,data,paramhat,draws);
    
                    end
            
            
                    % -----------------------------
                    %%% Derive critical value
                    [Alive_path,~] = alive(calib,data,sim_path_tax,draws);
                    
                    simunpack = {'fieldnames','ITAX_path','CTAX_path','UINS_path','HINS_path','UIB_path','SAB_path','DPB_path'};
                        v2struct(sim_path_tax,simunpack);

                    val = UIB_path(:,1:40) + SAB_path(:,1:40) + DPB_path(:,1:40) - ITAX_path(:,1:40) - CTAX_path(:,1:40) - UINS_path(:,1:40) - HINS_path(:,1:40); 

                    val = val.*Alive_path(:,1:40);
            
                    crit_scen(i) = sum(val,'all');
              

            end    


            %%% compare to baseline
            critval = crit_scen - crit_base;
                %disp('Difference Criterion')

            %%% write current iteration values to solution tracker
            RevNeutral_sol(iter,1:4) = [xgrid(1) xgrid(2) xgrid(3) critval(2)];

            %%% position of sign-change
            idx_signchng = find(diff(sign(critval))) + 1;
                %disp(idx_signchng)
            
            critmin = critval(2);
                % xgrid(2) is solution

            disp([' ',num2str(iter),'         ',num2str(critval(2)),'        ',num2str(xgrid)])

            %%% update search interval
            if abs(critmin) > ConvTol
                if  idx_signchng == 2
                    xgrid(1) = xgrid(1);   % just for exposition
                    xgrid(3) = xgrid(2);
                    xgrid(2) = (xgrid(1)+xgrid(3))/2;
    
                    critval(3) = critval(2);            
    
                elseif idx_signchng == 3
                    xgrid(3) = xgrid(3);
                    xgrid(1) = xgrid(2);
                    xgrid(2) = (xgrid(1)+xgrid(3))/2;
    
                    critval(1) = critval(2);            
    
                end
            

            else
                disp('-------------')
                disp(['Convergence at iteration:          ', num2str(iter)])
                disp(['Solution value - Parameter pi:     ', num2str(xgrid(2))])
                disp(['Criterion tolerance at solution:   ', num2str(critmin)])
            
            end
                   
            
            %toc
        end     % end while loop

        % -------------------------------------------------------------
        %%% Save Simulated Data
        % compute revenue-neutral set of paths
         if scen == 1                                     
            TaxLT = 1; 
            calib.TaxLT = TaxLT;
            calib.LTalpha = RevNeutral_sol(end,2);
            
            [sim_path_taxpol] = simpath_par_behfix(calib,var,data,BehFix_sim_path);
            [Alive_path,Cumsurv_path] = alive(calib,data,sim_path_taxpol,draws);
                sim_path_taxpol.Alive_path = Alive_path;
                sim_path_taxpol.Cumsurv_path = Cumsurv_path;            
           
            %%% Save specs of procedure and solution to struct
            TaxPolSol_ScenD.InitBounds        = [RevNeutral_init(1,1) RevNeutral_init(2,1)];
            TaxPolSol_ScenD.FinIter           = iter;
            TaxPolSol_ScenD.FinIterBounds     = [RevNeutral_sol(end,1) RevNeutral_sol(end,3)];
            TaxPolSol_ScenD.ParamSolPi1       = [RevNeutral_sol(end,2)];
            TaxPolSol_ScenD.RevNeutralCritVal = [RevNeutral_sol(end,4)];
            TaxPolSol_ScenD.BiSecTracker      = RevNeutral_sol;
            save('MatlabCode/02_output/TaxPolSol_ScenD.mat','TaxPolSol_ScenD','sim_path_taxpol');
                % > save simulated paths for welfare effects analysis
            % Export calibrated parameter to CollectedResults
            writetable(table(TaxPolSol_ScenD.ParamSolPi1),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_11_PolSim','Range','F20','WriteVariableNames',false,'AutoFitWidth',false);
            
        elseif scen == 2
            TaxLT = 1;
            EdFix = 0;
            calib.TaxLT = TaxLT;
            calib.EdFix = EdFix;
            calib.LTalpha = RevNeutral_sol(1,scen);
            
            [sim_path_taxpol,~] = simpath_par(calib,var,data,paramhat,draws);
            [Alive_path,Cumsurv_path] = alive(calib,data,sim_path_taxpol,draws);
                sim_path_taxpol.Alive_path = Alive_path;
                sim_path_taxpol.Cumsurv_path = Cumsurv_path;

            %%% Save specs of procedure and solution to struct
            TaxPolSol_ScenE.InitBounds        = [RevNeutral_init(1,2) RevNeutral_init(2,2)];
            TaxPolSol_ScenE.FinIter           = iter;
            TaxPolSol_ScenE.FinIterBounds     = [RevNeutral_sol(end,1) RevNeutral_sol(end,3)];
            TaxPolSol_ScenE.ParamSolPi1       = [RevNeutral_sol(end,2)];
            TaxPolSol_ScenE.RevNeutralCritVal = [RevNeutral_sol(end,4)];
            TaxPolSol_ScenE.BiSecTracker      = RevNeutral_sol;
            save('MatlabCode/02_output/TaxPolSol_ScenE.mat','TaxPolSol_ScenE','sim_path_taxpol'); 
                % > save simulated paths for welfare effects analysis
            % Export calibrated parameter to CollectedResults
            writetable(table(TaxPolSol_ScenE.ParamSolPi1),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_11_PolSim','Range','F33','WriteVariableNames',false,'AutoFitWidth',false);    

        end

        % > Unpack simulated paths
        simunpack = {'fieldnames','Type','Educ','C_path','Y_path','GCI_path','ITAX_path','CTAX_path','UINS_path', ...
                            'PINS_path','HINS_path','WAGE_path','WAGE2_path','WShock2_path','UIB_path','SAB_path', ...
                            'MPB_path','EPB_path','DPB_path','Empl_path','Reti_path','Health_path','Wealth_path', ...
                            'Sav_path','Exper_path','ExpRatio_path'};
            v2struct(sim_path_taxpol,simunpack);
        
        simunpack_data   = {'fieldnames','spbh','spgh'};
            v2struct(data, simunpack_data);



        %  ----------------------------------
        %%% Baseline Experience Ratio
        %   > to investigate lifetime taxation reform effects in Figure SWA.10
        MeanExpRatioCut = MeanExpRatio(1:40);
        flag_LTpoor = double(base_sim_path.ExpRatio_path(:,1:40)<repmat(MeanExpRatioCut(1:40),[calib.R,1]));
        flagID_LTpoor50 = double((sum(flag_LTpoor,2)./size(flag_LTpoor,2) > 0.50));         
        

        %  ----------------------------------
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

            ExpRatio = reshape(ExpRatio_path(:,1:dT),R*dT,1);
        
            Alive   = reshape(Alive_path(:,1:dT),R*dT,1);

            flag_LTpoor     = reshape([flag_LTpoor repmat(999,[R dT-(T-5)])],R*dT,1);
            flagID_LTpoor50 = reshape(repmat(flagID_LTpoor50,[1 dT]),R*dT,1);  
        
            TaxPolParamSolPi1 = EDUC;
                TaxPolParamSolPi1(:) = RevNeutral_sol(end,2);

        % ----------------------------------
        %%% Save to .txt File
            TAB = table(ID,Age,TYPE,EDUC,C,Y,GCI,ITAX,CTAX,UINS,PINS,HINS,WAGE,WAGE2,WShock,UIB,SAB,MPB,EPB,DPB,Empl,Reti,Health,Wealth,Sav,Exper,Alive,ExpRatio,flagID_LTpoor50,flag_LTpoor,TaxPolParamSolPi1);
            
            if scen == 1                
                %writetable(TAB,'MatlabCode/02_output/data_scenario_D.txt');
                writetable(TAB,join([calib.simdatadir,'data_scenario_D.txt']))
            elseif scen == 2
                %writetable(TAB,'MatlabCode/02_output/data_scenario_E.txt');
                writetable(TAB,join([calib.simdatadir,'data_scenario_E.txt']))
            end

    end         % end scenario loop
  
end         % end function