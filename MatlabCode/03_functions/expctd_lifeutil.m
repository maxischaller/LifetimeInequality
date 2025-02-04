function [lt_util] = expctd_lifeutil(calib,theta_u,theta_educ,consump_scal,sim_path)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute welfare measure: Expected lifetime utilities %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.a Unpack model elements:
% ---------------------------

    v2struct(sim_path)

    R       = calib.R;
    T       = calib.T;
    rho     = calib.rho;
    betta   = calib.betta;


%%% Generate indicator variables:
    UEmpl_path      = -(Empl_path - 1);         % 1==unemployment
    nonReti_path    = -(Reti_path - 1);         % 1==non-retired           
    BadHealth_path  = -(Health_path - 1);       %#ok<NODEF> % 1==bad-health 


%%% Extend health-path variable:
    Health_path     = [Health_path 999*ones(R,100-(T+20))];
    BadHealth_path  = [BadHealth_path 999*ones(R,100-(T+20))];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Compute per-period utilities:
% ---------------------------------

%%% Scale consumption profile
    C_path_scal = C_path.*(1+consump_scal)./10000;

%%% Compute utilities dep. on state trajectories and estimated parameters  
    % >>> non-retired
    x = nonReti_path .*  (C_path_scal.*(1+theta_u(4,1)).*BadHealth_path.*UEmpl_path ...
                        + C_path_scal.*(1+theta_u(5,1)).*Health_path.*UEmpl_path ...
                        + C_path_scal.*(1+theta_u(2,1)).*BadHealth_path.*Empl_path ...
                        + C_path_scal.*(1+theta_u(3,1)).*Health_path.*Empl_path);

    % >>> retired
    y = Reti_path .* C_path_scal.*(1);


    % >>> compute utilities
    periodutil = theta_u(1,1).*(1./(1-rho)).*(((x+y).^(1-rho)-1));
        % > years in education have value -Inf due to zeros in C_path

        % > C_path only zero while in Education
        periodutil(C_path_scal==0) = 0;
            


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Compute expected lifetime values:
% ---------------------------------------

% --------------------------
%%% Prepare discount factors

    %%% In labor market - discount to labor market entry:
    discon1 = betta.^(max(cumsum(periodutil~=0,2)-1,0));
        % > multiplication with periodutil returns zeros for periods in
        %     education bc periodutil==0
        
    %%% Education continuation value:
    % -> discounts expected lifetime utilities from labor market entry to
    %       age 15 (education decision age)
    discon2 = betta.^(max(Educ+8,20) - 15);


% ----------------------------------------------------
%%% Expected lifetime utility after labor market entry    
    periodutil = Cumsurv_path.*discon1.*periodutil;
    cycle_util = sum(periodutil,2);


% ----------------------------------------------------
%%% Expected lifetime utility incl. education at age 15    

    %%% Education alternative-specific utility components
    educ_const = zeros(R,1);
    for x = 1:length(theta_educ)
        educ_const(Educ==x+7) = theta_educ(x);
    end

   %%% Combinded expected lifetime utility
   lt_util = educ_const + discon2.*cycle_util; 


end