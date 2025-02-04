function [welfare_diff] = welfare_effects(calib,theta_u,theta_educ,consump_scal,sim_path_base,lt_util_scen)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute welfare effects %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Compute welfare for baseline simulation:
% --------------------------------------------
    %%% Compute expected lifetime utilites given consump_scal at current
    %    iteration
    [lt_util_base] = expctd_lifeutil(calib,theta_u,theta_educ,consump_scal,sim_path_base);

    %%% Unpack required arrays
    % R                    = calib.R;
    Educ_base            = sim_path_base.Educ;
    Type_base            = sim_path_base.Type;
    flagID_LTpoor50_base = sim_path_base.flagID_LTpoor50;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Derive welfare difference between scenarios:
% --------------------------------------------------------------------

    %%% Total welfare
    if calib.switch_totalwelfare == 1
        welfare_diff = (mean(lt_util_base) - mean(lt_util_scen));

    %%% Split by groups
    elseif calib.switch_totalwelfare == 0

        %%% Educ-specific
        if calib.switch_educwelfare == 1
            welfare_diff = mean(lt_util_base(Educ_base>=12)) - mean(lt_util_scen(Educ_base>=12));
        elseif calib.switch_educwelfare == 2
            welfare_diff = mean(lt_util_base(Educ_base<=11)) - mean(lt_util_scen(Educ_base<=11));
        end

        %%% Type-specific
        if calib.switch_typewelfare == 1
            welfare_diff = mean(lt_util_base(Type_base==1)) - mean(lt_util_scen(Type_base==1));
        elseif calib.switch_typewelfare == 2
            welfare_diff = mean(lt_util_base(Type_base==2)) - mean(lt_util_scen(Type_base==2));
        elseif calib.switch_typewelfare == 3
            welfare_diff = mean(lt_util_base(Type_base==3)) - mean(lt_util_scen(Type_base==3));       
        end

        %%% Lifetime poor/rich classes
        if calib.switch_LTPoorWelfare == 1
            welfare_diff = mean(lt_util_base(flagID_LTpoor50_base==0)) - mean(lt_util_scen(flagID_LTpoor50_base==0));           
        elseif calib.switch_LTPoorWelfare == 2
            welfare_diff = mean(lt_util_base(flagID_LTpoor50_base==1)) - mean(lt_util_scen(flagID_LTpoor50_base==1));            
        end

    end

     
end

