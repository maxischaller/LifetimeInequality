function [draws] = drawgen(calib,paramhat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate draws for Simulation Exercises %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% NOTES:
%   - (Pseudo-)random draws are the same across all simulation scenarios
%   - 'seed' specified in 'calibrate.m' line 88
%   - draws are saved to struct 'draws.[...]'


%%% OUTPUT: 'draws.[...]' struct


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------
    % >>> unpack model calibration
    draw_calib = {'fieldnames','M','T','R','seed'};
        v2struct(calib,draw_calib)

    % >>> extract wage-equation parameters
    theta_w    = paramhat(   1:M+ 9,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Generate draws:
% -------------------------

%%% Seed
    rng(seed);

%%% Productive type probabilities
    random1      = rand(R,1);

%%% Education choice
    random_ed    = rand(R,1);

%%% Employment choice
    random2      = rand(R,T+1);

%%% Health trajectories
    random3      = rand(R,T+1);

%%% Wage shock paths (from standard normal)
    WShock1_path = randn(R,T).*sqrt((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2)); % steady-state
    WShock2_path = randn(R,T).*      theta_w(M+8,1);                          % transitory
   
%%% Measurement error
    MError       = randn(R,T+1).*theta_w(M+9,1);

%%% Survival trajectories
    random_surv  = rand(R,1);

%%% Involuntary separations    
    random4      = rand(R,T+1); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 3. Write to Draws-Struct

    draws = v2struct(random1,random_ed,random2,random3,WShock1_path,WShock2_path,MError,random_surv,random4);

end