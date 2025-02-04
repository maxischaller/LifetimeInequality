function [] = control_taxpol_analysis(calib,theta_u,theta_educ,sim_path_base,sim_path_scen)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Control Script: Lifetime tax policy reform -- Analysis %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------
    tax_scen = calib.tax_scen;

    %%% Extract baseline trajectories
    Educ_base  = sim_path_base.Educ;
    Type_base  = sim_path_base.Type;
    flagID_LTpoor50 = sim_path_base.flagID_LTpoor50;
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Compute individual expected lifetime utilities:
% ---------------------------------------------------
       
    %%% Consumption scaling: (1+consump_scal) [as simulated]
    consump_scal = 0;

    %%% Baseline simulation
    [lt_util_base] = expctd_lifeutil(calib,theta_u,theta_educ,consump_scal,sim_path_base);  

    %%% Scenario simulation: lifetime tax reform
    [lt_util_scen] = expctd_lifeutil(calib,theta_u,theta_educ,consump_scal,sim_path_scen);
  
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Compute share of individuals 'better off' under reform:
% -----------------------------------------------------------

    %%% Prepare 'winners': individ. expected lifetime utility differences
    lt_util_diff    = lt_util_scen - lt_util_base;    
    lt_util_winflag = lt_util_diff>0;

    %%% Overall share
    lt_util_winshare = mean(lt_util_winflag);

    %%% By productivity type
    lt_util_winshare(2) = sum(lt_util_winflag(Type_base==1))/length(lt_util_diff(Type_base==1));
    lt_util_winshare(3) = sum(lt_util_winflag(Type_base==2))/length(lt_util_diff(Type_base==2));
    lt_util_winshare(4) = sum(lt_util_winflag(Type_base==3))/length(lt_util_diff(Type_base==3));
        assert(length(lt_util_winflag(Type_base==1))+length(lt_util_winflag(Type_base==2))+length(lt_util_winflag(Type_base==3)) == calib.R)

    %%% By education level
    lt_util_winshare(5) = sum(lt_util_winflag(Educ_base>=12))/length(lt_util_diff(Educ_base>=12));
    lt_util_winshare(6) = sum(lt_util_winflag(Educ_base<=11))/length(lt_util_diff(Educ_base<=11));
        assert(length(lt_util_winflag(Educ_base>=12)) + length(lt_util_winflag(Educ_base<=11)) == calib.R )

    %%% Lifetime poor/rich based on work history
    lt_util_winshare(7) = sum(lt_util_winflag(flagID_LTpoor50==0))/length(lt_util_winflag(flagID_LTpoor50==0));
    lt_util_winshare(8) = sum(lt_util_winflag(flagID_LTpoor50==1))/length(lt_util_winflag(flagID_LTpoor50==1));              
        assert(length(lt_util_winflag(flagID_LTpoor50==0))+ length(lt_util_winflag(flagID_LTpoor50==1)) == calib.R)

    
    %%% Table 12: Share of winners under reform - Export to CollectedResults
    if tax_scen == 1
        writetable(table(100*lt_util_winshare),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_12_Welfare','Range','B7','WriteVariableNames',false,'AutoFitWidth',false);
    elseif tax_scen == 2
        writetable(table(100*lt_util_winshare),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_12_Welfare','Range','B13','WriteVariableNames',false,'AutoFitWidth',false);
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Compute welfare effects:
% ----------------------------

    % ---------------------------------
    %%% Set options        
        options = optimoptions('fsolve','Display','iter-detailed','Diagnostics','on');

    % ---------------------------------
    %%% Utilitarian welfare function 
        calib.switch_totalwelfare = 1; % = 1 if total sample welfare effects; = 0 if group-splits
        calib.switch_educwelfare  = 0; % = 1 if educ-group specific welfare effects
        calib.switch_typewelfare  = 0; % = 1 if productivity type specific welfare effects
        calib.switch_LTPoorWelfare = 0;

    %%% Welfare effects solution array
        sol_welfare  = zeros(1,8); 

    % ---------------------------------
    %%% Standard welfare function specification
    
        % >>> Total welfare:
        welfarediff = @(consump_scal) welfare_effects(calib,theta_u,theta_educ,consump_scal,sim_path_base,lt_util_scen);
        startval = -0.02;
        [sol_scal,~] = fsolve(welfarediff,startval,options);
        sol_welfare(1) = sol_scal;

            calib.switch_totalwelfare = 0;

        % >>> Productive ability type: High, med, low
        for i = 1:3
            calib.switch_typewelfare = i;
            welfarediff = @(consump_scal) welfare_effects(calib,theta_u,theta_educ,consump_scal,sim_path_base,lt_util_scen);
            startval = -0.02;
            [sol_scal,~] = fsolve(welfarediff,startval,options);
            sol_welfare(1+i) = sol_scal;
        end
            calib.switch_typewelfare = 0;                

        % >>> Education level (1: high / 2: low)
        for i = 1:2
            calib.switch_educwelfare = i;
            welfarediff = @(consump_scal) welfare_effects(calib,theta_u,theta_educ,consump_scal,sim_path_base,lt_util_scen);
            startval = -0.02;
            [sol_scal,~] = fsolve(welfarediff,startval,options);
            sol_welfare(4+i) = sol_scal;
        end
            calib.switch_educwelfare = 0;

        % >>> Lifetime poor/rich classes:
        for i = 1:2
            calib.switch_LTPoorWelfare = i; 
            welfarediff = @(consump_scal) welfare_effects(calib,theta_u,theta_educ,consump_scal,sim_path_base,lt_util_scen);
            startval = -0.02;
            [sol_scal,~] = fsolve(welfarediff,startval,options);
            sol_welfare(6+i) = sol_scal;
        end
            calib.switch_LTPoorWelfare = 0;
    
    %%% Table 12: Welfare effects - Export to CollectedResults
    if tax_scen == 1
        writetable(table(100*sol_welfare),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_12_Welfare','Range','B6','WriteVariableNames',false,'AutoFitWidth',false);
    elseif tax_scen == 2
        writetable(table(100*sol_welfare),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_12_Welfare','Range','B12','WriteVariableNames',false,'AutoFitWidth',false);
    end




end