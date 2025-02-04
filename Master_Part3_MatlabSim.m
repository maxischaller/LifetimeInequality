close all; clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MASTER SCRIPT: LIFE-CYCLE SCENARIO SIMULATIONS                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Contents of Script: 
%   1. Setup project directory and model environment
%   2. Static microsimulation using estimation sample
%   3. Baseline scenario: simulation of life-cycle paths
%   4. Bseline scenario + invol. separations: simulation
%   5. Counterfactual risk scenarios: simulation of life-cycle paths
%   6. Counterfactual policy scenario: simulation & rev.-neutral search
%   7. Counterfactual policy scenario: computation welfare effects
%   8. Robustness to calibration: simulation of life-cycle paths


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0. Setup execution:
%%% Notes:
%   > Sections can be executed independently of each other
%   > Order of execution must be preserved!

%%% Execute static microsimulation on estimation sample
switch_esamplus     = 1;

%%% Simulate life-cycles with estimated model: Baseline scenario
switch_sim_baseline = 1;

%%% Simulation including involuntary separations
switch_sim_involsep = 1;

%%% Simulation: elevated risk scenarios
switch_sim_riskscen = 1;

%%% Simulation: lifetime tax policy reform
switch_sim_taxpol   = 1;

%%% Derivation welfare effects for lifetime tax reform scenario
switch_welfare_effects = 1;

%%% Robustness to preference parameter calibration - run simulation
switch_sim_robpref = 1;


% -------------------------------------------------------------------------
%%% Parallel pool settings
% Notes:
%   > Simulation procedures may be executed in parallel environment along
%   dimension of subsamples of individual life-cycles.
%   > Each scenario includes the simulation of 50,000 individual
%       life-cycles. The forward simulation of life-cycles may be
%       distributed to multiple workers, given the full-sample of
%       life-cycles can be split evenly across workers.
%   > !! Choice of number of workers: !!
%       Required condition: (No. lifecycles / No. workers) = IntegerValue
%       E.g. 50,000/8 = 6,250 (individ. life-cycles simulated per worker)


%%% Number of workers available in parallel environment
nmbrworkers = 8;

%%% Split simulations into Z subsamples (sent to workers)
Z = 8;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.1 Setup project directory:

%%% Set project directory paths
projectdir = pwd;
    SOEPdatadir = join([projectdir,'/Data/SOEP_confid/derived_confid/']);
    simdatadir  = join([projectdir,'/Data/SimData/']);
    figureout   = join([projectdir,'/StataCode/02_figures/']);
    tableout    = join([projectdir,'/StataCode/03_tables/']);


%%% Add directory containing Matlab functions
addpath('MatlabCode/03_functions');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.2 Setup Model: 
%   > model calibration, data and variables stored in structs

%%% Model calibration
[calib] = calibrate();
    
    % > write paths and control settings to struct
    calib.SOEPdatadir = SOEPdatadir;
    calib.simdatadir  = simdatadir;
    calib.figureout   = figureout;
    calib.tableout    = tableout;    
    calib.nmbrworkers = nmbrworkers;
    calib.Z           = Z;


%%% Data preparation
[data] = dataprep(calib);


%%% Generate variables
[var] = vargen(calib,data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Static Microsimulation using SOEP Estimation Sample: 

if switch_esamplus == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Execute static microsimulation on estimation sample:')
    disp(' ') 

    samplus(calib,var);

    disp('...done!')
    disp('        ')    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 3. Simulate life-cycle paths
%%% Notes:
%   - Section simulates life-cycle trajectories based on the estimated model
%   - Simulation is initialized via 'simcontrol_baseline.m' script


%%% OUTPUT 
%   - "sim_paths_baseline.mat": saves model solution and simulated life-cycles
%   - "data_baseline.txt": simulated dataset for baseline scenario


%%% OUTPUT - Results in Paper:
%   - "Figure SWA.7: Distributions of observed and predicted years of
%       education


if switch_sim_baseline == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running baseline scenario simulation:')
    disp(' ')

    % ----------------------------------
    %%% Load estimated Parameters
        load('MatlabCode/02_output/estim_params.mat','paramhat');
    
    % ----------------------------------
    %%% Generate draws:
    %   > identical across all scenarios
        [draws] = drawgen(calib,paramhat);   

    % ------------------------------------------------------------------
    %%% Parallel Pool Configuration      
        mypool = parpool("Processes", calib.nmbrworkers);
        disp(mypool)

    % ----------------------------------
    %%% Execute Simulation
    %tic
        simcontrol_baseline(calib,var,data,paramhat,draws);
    %toc
    

    % ----------------------------------    
    %%% Shut down parallel pool
        delete(mypool)      % delete(gpc) [general]  

    % ---------------------------------- 
    %%% Clean-up
        clearvars -EXCEPT calib data var switch*

    disp('...done!')
    disp('        ')
    % --------------------------------------------------------------------
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Baseline scenario simulation not executed..!')
    disp(' ')

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 4. Simulate life-cycle paths: including involuntary separations
%%% OUTPUT 
%   - "data_involsep.txt"

if switch_sim_involsep == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running baseline scenario simulation - invol. separations included:')
    disp(' ')

    % ----------------------------------
    %%% Load estimated Parameters
        load('MatlabCode/02_output/estim_params.mat','paramhat');

    % ----------------------------------
    %%% Generate draws:
    %   > identical across all scenarios
        [draws] = drawgen(calib,paramhat);   

    % ------------------------------------------------------------------
    %%% Parallel Pool Configuration     
        mypool = parpool("Processes", calib.nmbrworkers);
        disp(mypool)

    % ----------------------------------
    %%% Execute Simulation
    %tic
        simcontrol_sepsim(calib,var,data,paramhat,draws)
    %toc
    
    % ----------------------------------    
    %%% Shut down parallel pool
        delete(mypool)      % delete(gpc) [general]  

    % ----------------------------------
    %%% Clean-up
        clearvars -EXCEPT calib data var switch*

    disp('...done!')
    disp('        ')
    % --------------------------------------------------------------------
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Baseline + invol. separations simulation not executed..!')
    disp(' ')

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 5. Simulate counterfactual risk scenarios
%%% Notes:
%   > simulate scenarios with elevated employment and health risks

%%% Scenario specification:
%   A) Increased separation risk: x2
%       > *(1+DeltaS): setting DeltaS==1
%   B) Decreased offer risk: x(3/4)
%       > *(1+DeltaO): setting DeltaO==-0.25
%   C) Increase bad-health risk: x2
%       > DeltaH2==2

%%% OUTPUT 
%   - "data_scenario_A.txt", "data_scenario_B.txt", "data_scenario_C.txt"


if switch_sim_riskscen == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running risk scenario simulations:')
    disp(' ')

    % ----------------------------------
    %%% Load estimated Parameters
        load('MatlabCode/02_output/estim_params.mat','paramhat');

    % ----------------------------------
    %%% Generate draws:
    %   > identical across all scenarios
        [draws] = drawgen(calib,paramhat);

    % ------------------------------------------------------------------
    %%% Parallel Pool Configuration     
        mypool = parpool("Processes", calib.nmbrworkers);
        disp(mypool);

    % ----------------------------------
    %%% Execute Simulation
        simcontrol_riskscen(calib,var,data,paramhat,draws)
    
    % ----------------------------------    
    %%% Shut down parallel pool
        delete(mypool)      % delete(gpc) [general] 


    disp('        ')
    % --------------------------------------------------------------------
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Risk scenario simulations not executed..!')
    disp(' ')

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 6. Simulate counterfactual policy scenarios : Lifetime taxation reform

if switch_sim_taxpol == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running lifetime tax policy simulations:')
    disp(' ')

    % ----------------------------------
    %%% Load estimated Parameters
        load('MatlabCode/02_output/estim_params.mat','paramhat');

    % ----------------------------------
    %%% Generate draws:
    %   > identical across all scenarios
        [draws] = drawgen(calib,paramhat);

    % ------------------------------------
    %%% Load baseline scenario simulation 
        load('MatlabCode/02_output/sim_paths_baseline.mat','sim_path');
        base_sim_path = sim_path;
        clear sim_path

    % ------------------------------------------------------------------
    %%% Parallel Pool Configuration     
        mypool = parpool("Processes", calib.nmbrworkers);
        disp(mypool)

    % -------------------------------------------------------
    %%% Execute simulation & Revenue-neutral parameter search
        simcontrol_taxpol_bisec(calib,var,data,paramhat,base_sim_path,draws)
    
    % ----------------------------------    
    %%% Shut down parallel pool
        delete(mypool)      % delete(gpc) [general] 


    disp('...done!')
    disp('        ')
    % --------------------------------------------------------------------
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Tax policy scenario simulation not executed..!')
    disp(' ')

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 7. Compute welfare effects for policy reform scenarios

%%% OUTPUT:
%   - Table 12: Reform effects - Share of winners and welfare effects

if switch_welfare_effects == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Compute welfare effects:')
    disp(' ')

    % ----------------------------------
    %%% Load estimated Parameters
        load('MatlabCode/02_output/estim_params.mat','paramhat');

        theta_u    = paramhat(calib.M+10:calib.M+14,1);
        theta_educ = [0; paramhat(calib.M+23:calib.M+32,1)];

    % ----------------------------------
    %%% Load baseline simulation      
        load('MatlabCode/02_output/sim_paths_baseline.mat','sim_path')

        sim_path_base = sim_path; 
            clear sim_path

        %%% Generate lifetime poor/rich measure
        MeanExpRatio = mean(sim_path_base.ExpRatio_path(:,1:40));
        flag_LTpoor = double(sim_path_base.ExpRatio_path(:,1:40)<repmat(MeanExpRatio(1:40),[calib.R,1]));
        flagID_LTpoor50 = double((sum(flag_LTpoor,2)./size(flag_LTpoor,2) > 0.50));
            sim_path_base.flagID_LTpoor50 = flagID_LTpoor50;            
            % mean(flagID_LTpoor50)
        
        sim_path_base.flagID_LTpoor50;


    % -------------------------------------------------------------------
    %%% Loop over reform scenarios 1 & 2:
    
    for tax_scen = 1:2
        calib.tax_scen = tax_scen;

        %%% Load simulated life-cycle paths  
        if tax_scen == 1   
            load('MatlabCode/02_output/TaxPolSol_ScenD.mat','sim_path_taxpol')
            sim_path_scen = sim_path_taxpol;
            clear sim_path_taxpol
        elseif tax_scen == 2
            load('MatlabCode/02_output/TaxPolSol_ScenE.mat','sim_path_taxpol')
            sim_path_scen = sim_path_taxpol;
            clear sim_path_taxpol            
        end


        % -------------------------
        %%% Run analysis:
        control_taxpol_analysis(calib,theta_u,theta_educ,sim_path_base,sim_path_scen);

    end     % end loop over scenarios


    disp('...done!')
    disp('        ')    
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Welfare effects derivation not executed..!')
    disp(' ')

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 8. Simulate life-cycle paths for robustness scenarios
%%% NOTES:
%   - simulates life-cycle paths for parameters estimates using alternative
%       calibration of the preference parameters of the structural model


if switch_sim_robpref == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running robustness scenario simulation - Preference parameters:')
    disp(' ')

    % ----------------------------------
    %%% Loop over alternative calibrations
    for robscen_pref = 1:8
        disp('-----------------------------')
        disp(['Robustness scenario:    ' num2str(robscen_pref)]);

        % ----------------------------------
        %%% Load estimated Parameters
        if robscen_pref == 1
            load('MatlabCode/02_output/estim_params_b98g50.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==2
            load('MatlabCode/02_output/estim_params_b97g50.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==3
            load('MatlabCode/02_output/estim_params_b99g25.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==4
            load('MatlabCode/02_output/estim_params_b99g75.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==5
            load('MatlabCode/02_output/estim_params_b98g25.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==6
            load('MatlabCode/02_output/estim_params_b98g75.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==7
            load('MatlabCode/02_output/estim_params_b97g25.mat','paramhat','betta_rob','rho_rob');
        elseif robscen_pref==8
            load('MatlabCode/02_output/estim_params_b97g75.mat','paramhat','betta_rob','rho_rob');
        end
        disp('Calibration:')
        disp(['beta: ' num2str(betta_rob) '    gamma:  ' num2str(rho_rob)]);
    
        calib.robscen_pref = robscen_pref;
        
        %%% Set model calibration
        calib.betta = betta_rob;
        calib.rho   = rho_rob;
        
        % ----------------------------------
        %%% Generate draws:
        %   > identical across all scenarios
        [draws] = drawgen(calib,paramhat);   
    
        % ------------------------------------------------------------------
        %%% Parallel Pool Configuration      
            mypool = parpool("Processes", calib.nmbrworkers);
    
    
        % ----------------------------------
        %%% Execute Simulation
        %tic
            simcontrol_robprefparam(calib,var,data,paramhat,draws);
        %toc
        
    
        % ----------------------------------    
        %%% Shut down parallel pool
            delete(mypool)      % delete(gpc) [general]  
    
        % ---------------------------------- 
        %%% Clean-up
        clearvars -EXCEPT calib data var switch*


        disp('...done!')
        disp('        ')        
    end

    % --------------------------------------------------------------------
else
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Robustness scenario simulation not executed..!')
    disp(' ')

end