function [Alive_path,Cumsurv_path] = alive(calib,data,sim_path,draws)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulate Individual Surivival %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% NOTES:
%   > simulate indicator of individual survival paths based on education
%   levels and health paths
%
%%% INPUT: 
%   - estimated heterogeneous mortality profiles 
%   - simulated education levels and health trajectories
%   - draws for survival trajectories

%  ----------------------------------
%% Unpack Sim-path and Calib

    simunpack = {'fieldnames','Health_path','Educ'};
        v2struct(sim_path,simunpack);

    simunpack_data   = {'fieldnames','spbh','spgh'};
        v2struct(data,simunpack_data);

    scen_calib = {'fieldnames','T','R'};        
        v2struct(calib,scen_calib);

    random_surv = draws.random_surv;

%  ----------------------------------
%% Simulate Alive Indicator
         
    sp = zeros(R,80);

    for r=1:R
        for t=1:T
            sp(r,t)=spbh(t,t  ,1+1*(Educ(r,1)>=12)).*(Health_path(r,t  )==0)+spgh(t,t,1+1*(Educ(r,1)>=12)).*(Health_path(r,t  )==1);
        end
        for t=T+1:80
            sp(r,t)=spbh(t,T+1,1+1*(Educ(r,1)>=12)).*(Health_path(r,T+1)==0)+spgh(t,T+1,1+(Educ(r,1)>=12)).*(Health_path(r,T+1)==1);
        end
    end
    
    %%% Adjust for certain survival in education
    for r = 1:R
        sp(r,1:1+1*(Educ(r,1)>12)*Educ(r,1)-12) = 1;
    end

    %%% LifeCycle Survival
    % > cum. dying
    px = [zeros(R,1) cumprod(sp(:,1:80),2).*[(1-sp(:,2:80)) ones(R,1)] ];
    
    % > cum surv.
    Cumsurv_path = [ones(R,1) cumprod(sp(:,1:80),2)];

    
    %%% Derive Indicator
    Alive_path = 1.*(repmat(random_surv,[1 81]) > cumsum(px,2));
    % > correction for certain death at age 100
    Alive_path(:,81) = 0;



end