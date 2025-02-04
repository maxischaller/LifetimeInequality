close all; clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MASTER SCRIPT: ESTIMATION STRUCTURAL LIFE-CYCLE MODEL         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Contents of Script:
%   1. Setup project directory and model environment
%   2. Main estimation procedures:
%       > Initialize estimation: Calibration and starting values of parameters
%       > Stage 1 - Maximum Likelihood estimation: Wage equation
%       > Stage 2 - Maximum Likelihood estimation: Life-cycle model
%   3. Separate display and export of estimated parameters
%   4. Robustness of estimation results to preference parameter calibration



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0. Setup execution:
% Notes:
%   > Sections indicated by switches below can be executed independently of
%       each other, given the order of execution is preserved!

%%% Execute estimation procedures (main calibration)?
switch_estim_exec   = 1;

%%% Review parameter estimates separately? (Tables: 1, 3, SWA.3)
switch_disp_param   = 1;
    % > only available after completion of the main estimation procedure

%%% Execute estimation procedures (robustness to preference calibration)?
switch_estim_exec_rob = 1;


% -------------------------------------------------------------------------
%%% Parallel pool settings
% Notes:
%   > Estimation procedures include computationally expensive derivation of
%       numerical gradients over 35 structural parameters. 
%   > Numerical gradients may be computed in parallel environment (see
%       totloglik.m, line 117)
%   > Specify below the available number of workers. To optimize runtime 
%       please choose and efficient allocation of workers given the required 
%       35+1 computations of the loop. (e.g. 36, 18, 12, ...)
%   > Parallel pool is created before start-up of the estimation procedure
%       using the default profile.

%%% Number of workers available in parallel environment
nmbrworkers = 18;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.1 Setup project directory:

%%% Set project directory paths
projectdir = pwd;
    SOEPdatadir = join([projectdir,'/Data/SOEP_confid/derived_confid/']);
    simdatadir  = join([projectdir,'/Data/SimData/']);
    figureout   = join([projectdir,'/StataCode/02_figures/']);
    tableout    = join([projectdir,'/StataCode/03_tables/']);

    disp('---------------------------------')
    disp('Project directory:')
    disp(projectdir)

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
    
    % unpack parameters required in master script:
    M   = calib.M;


%%% Data preparation
[data] = dataprep(calib);


%%% Generate variables
[var] = vargen(calib,data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 2. Main estimation procedures

if switch_estim_exec == 1 
    tic

    % -----------------------------------------------
    %%% Parallel pool configuration
    mypool = parpool("Processes",calib.nmbrworkers);
    disp(mypool)


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    %%% 2.a Initialize Estimation: Calibration and Starting Values of Parameters
    % -------------------------------------------------------------------------

    %%% Wage equation parameters (to be estimated / starting values)
        theta_w = [1.9 1.6 1.3 0.9 0.6 0.2 0.3 -0.025 -0.05 0.01 0.05 0.1]';
    
    %%% Utility function parameters (to be estimated / starting values)
        theta_u = [1.5 -0.25 -0.25 -0.25 -0.25]';
        
    %%% Job separation model parameters -> reduced form estimates
        % importet via paramdem.m into "calib"-struct
    
    %%% Job offers (to be estimated / starting values)
        phi_o = [-1.5 -0.25 1 -0.5 0.25 -0.1]';
        
    %%% Ability type probabilities (to be estimated / starting values)
        theta_m = [0.4 0.4]';
       
    %%% Years of education Intercepts
        inter      = zeros(10,1);
        inter(:,1) = 0.1;

        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    %%% 2.b Log-Likelihood Maximization - Wage Equation
    % -------------------------------------------------
    %%% Notes:
    %   > Separate ML-estimation of wage-equation to improve starting values for
    %       full model estimation procedure
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running first-stage Wage-equation estimation procedure:')
    disp(' ')

    %%% Set Options
        options = optimset('Display','iter','GradObj','on','Hessian','on','Algorithm','trust-region-reflective', ...
                     'TolFun',1e-5,'DerivativeCheck','off');
    
    %%% Starting Values Optimization
        startval = [theta_w' theta_m']';
    
    
    % -------------------------------------
    % Parallelized Estimation Procedure
    %   -> Note: parallel execution can be added inside wageloglik.m 
    
        wagellfun = @(coef) wageloglik(coef,calib,var);
     
        [paramhat,~,~,~,~,~] = fminunc(wagellfun,startval,options);
    
        theta_w     = paramhat(   1:M+9,1);
        theta_m     = paramhat(M+10:M+11,1);
    
        % >>> Inverse Hessian and standard errors if required
            %wage_ihess = inv(hessian);
            %wage_ste = sqrt(diag(wage_ihess));



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    %%% 3.c Total Log-Likelihood Maximization - Full Model   
    % ----------------------------------------------------
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Running FIML estimation procedure:')
    disp(' ')

    %%% Starting values:
    startval=[theta_w' theta_u' phi_o' theta_m' inter']';      

    %%% Setup and run Optimization
    options=optimoptions('fminunc','Display','iter-detailed','GradObj','on','Hessian','on','Algorithm','trust-region', ...
                 'StepTolerance',1e-6,'TolFun',1e-6,'DerivativeCheck','off');    

    tllfun = @(coef) totloglik(coef,calib,data,var);
   
    [paramhat,fval,exitflag,output,~,~] = fminunc(tllfun,startval,options);


    %%% Estimated parameters
    coef = paramhat;

    %%% Derive model solution for estimated parameters
    [tll,grad,hessian] = totloglik(coef,calib,data,var);

    %%% Standard errors
    ihess   = inv(hessian);
    ste     = sqrt(diag(ihess));

    %%% Save estimated parameters
    savefile = "MatlabCode/02_output/estim_params.mat";
    save(savefile,'startval','paramhat','grad','hessian','ihess','ste');

    toc

    % -----------------------------------------------
    %%% Delete parallel pool
    delete(mypool)

elseif switch_estim_exec == 0
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Main model estimation not executed..!')
    disp(' ')

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 3. Review and export parameter estimates
%%% Notes:
%   - Review parameter estimates separately from estimation procedure. Only
%       available after running main estimation procedure.

%%% OUTPUT:
%   - Table 1: Parameters of the utility function, wage equation and type
%       probabilities 
%   - Table SWA.3 Parameters estimates: employment risk 
%       // Panel I: Job offers
%   - Table 3: Job offer and involuntary job separation probabilities

if switch_disp_param == 1
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Display estimated parameters:')
    disp(' ')

    % ----------------------------------
    %%% Load estimated parameters
        load('MatlabCode/02_output/estim_params.mat','paramhat','hessian');
    
    % ---------------------------------
    %%% Run script to display results in command window
        % > disable export of estimation results
        calib.switch_estimexport = 1;

    paramdisp(paramhat,hessian,calib)

    % --------------------------------- 
    %%% Export estimated parameters for use in StataAnalysis
    writematrix(paramhat,'MatlabCode/02_output/paramhat.txt');


else 
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Estimated parameters not displayed..!')
    disp(' ')

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 4. Robustness of Estimation Results to Preference Parameter Calibration

if switch_estim_exec_rob == 1 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    %%% 4.a Initialize Estimation: Calibration and Starting Values of Parameters
    % -------------------------------------------------------------------------

    %%% Wage equation parameters (to be estimated / starting values)
        theta_w = [1.9 1.6 1.3 0.9 0.6 0.2 0.3 -0.025 -0.05 0.01 0.05 0.1]';

    %%% Utility function parameters (to be estimated / starting values)
        theta_u = [1.5 -0.25 -0.25 -0.25 -0.25]';


    %%% Job separation model parameters -> reduced form estimates
        % importet via paramdef.m into "calib"-struct


    %%% Job Offers (to be estimated / starting values)
        phi_o = [-1.5 -0.25 1 -0.5 0.25 -0.1]';


    %%% Ability Type Probabilities (to be estimated / starting values)
        theta_m = [0.4 0.4]';


    %%% Years of education Intercepts
        inter      = zeros(10,1);
        inter(:,1) = 0.1;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    %%% 4.b Log-Likelihood Maximization - Wage Equation
    % -------------------------------------------------
    %%% Notes:
    %   > Separate ML-estimation of wage-equation to improve starting values for
    %       full model estimation procedure
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Robustness to calibration: Running first-stage Wage-equation estimation procedure:')
    disp(' ')

    %%% Set Options
        options = optimset('Display','iter','GradObj','on','Hessian','on','Algorithm','trust-region-reflective', ...
                     'TolFun',1e-5,'DerivativeCheck','off');

    %%% Starting Values Optimization
        startval = [theta_w' theta_m']';


    % -------------------------------------
    % Estimation Procedure
        wagellfun = @(coef) wageloglik(coef,calib,var);

        [paramhat,~,~,~,~,~] = fminunc(wagellfun,startval,options);

        theta_w     = paramhat(   1:M+9,1);
        theta_m     = paramhat(M+10:M+11,1);

        % >>> Inverse Hessian and standard errors if required
            %wage_ihess = inv(hessian);
            %wage_ste = sqrt(diag(wage_ihess));



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    %%% 4.c Full Model Estimation for varying preference parameters   
    % -------------------------------------------------------------
        % > disable export of estimation results
        calib.switch_estimexport = 0;
    
    %%% Starting Values:
        startval=[theta_w' theta_u' phi_o' theta_m' inter']';              

    for robscen_pref = 1:8
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
        disp('Robustness to calibration: Running FIML estimation procedure:')
        disp(' ')

        %%% Set preference parameters
        if robscen_pref == 1
            calib.betta = 0.98;
            calib.rho = 1.50;
        elseif robscen_pref==2
            calib.betta = 0.97;
            calib.rho = 1.50;
        elseif robscen_pref==3
            calib.betta = 0.99;
            calib.rho = 1.25;
        elseif robscen_pref==4
            calib.betta = 0.99;
            calib.rho = 1.75;
        elseif robscen_pref==5
            calib.betta = 0.98;
            calib.rho = 1.25;
        elseif robscen_pref==6
            calib.betta = 0.98;
            calib.rho = 1.75;
        elseif robscen_pref==7
            calib.betta = 0.97;
            calib.rho = 1.25;
        elseif robscen_pref==8
            calib.betta = 0.97;
            calib.rho = 1.75;
        end
        disp('Betta:') 
        disp(calib.betta)
        disp('Gamma:')
        disp(calib.rho)

 
        %%% Parallel pool configuration
        mypool = parpool("Processes",calib.nmbrworkers);
        disp(mypool)

        %%% Set-Up Optimization
        options=optimoptions('fminunc','Display','iter-detailed','GradObj','on','Hessian','on','Algorithm','trust-region', ...
                     'StepTolerance',1e-6,'TolFun',1e-6,'DerivativeCheck','off');    

        tllfun = @(coef) totloglik(coef,calib,data,var);               
        tic
        [paramhat,fval,exitflag,output,~,~] = fminunc(tllfun,startval,options);
        toc

        %%% Estimated parameters
        coef = paramhat;

        %%% Derive model solution for estimated parameters
        [tll,grad,hessian] = totloglik(coef,calib,data,var);

        %%% Standard errors
        ihess   = inv(hessian);
        ste     = sqrt(diag(ihess));

        %%% Save estimated parameters
        if robscen_pref == 1
            savefile = "MatlabCode/02_output/estim_params_b98g50.mat";
        elseif robscen_pref == 2
            savefile = "MatlabCode/02_output/estim_params_b97g50.mat";
        elseif robscen_pref == 3
            savefile = "MatlabCode/02_output/estim_params_b99g25.mat";
        elseif robscen_pref == 4
            savefile = "MatlabCode/02_output/estim_params_b99g75.mat";
        elseif robscen_pref == 5
            savefile = "MatlabCode/02_output/estim_params_b98g25.mat";
        elseif robscen_pref == 6
            savefile = "MatlabCode/02_output/estim_params_b98g75.mat";    
        elseif robscen_pref == 7
            savefile = "MatlabCode/02_output/estim_params_b97g25.mat";
        elseif robscen_pref == 8
            savefile = "MatlabCode/02_output/estim_params_b97g75.mat";              
        end
        betta_rob = calib.betta;
        rho_rob = calib.rho;
        save(savefile,'startval','paramhat','grad','hessian','ihess','ste','betta_rob','rho_rob');


        %%% Display estimated parameters
        paramdisp(paramhat,hessian,calib)

        
        %%% Delete parallel pool
        delete(mypool)


    end % end loop over preference parameter calibrations

    % > reset preference parameters
    calib.betta = 0.99;
    calib.rho = 1.50;

    
elseif switch_estim_exec_rob == 0
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
    disp('Robustness to calibration: No estimation executed..!')
    disp(' ')

end