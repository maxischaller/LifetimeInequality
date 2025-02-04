%%%%%%%%%%%%%%%%%%%%
% Utility function %
%%%%%%%%%%%%%%%%%%%%

function [u] = utility(c,l,theta_u,calib,var)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Unpack Parameters:
% ------------------
u_calib = {'fieldnames','S','E','H','M','J','L','D','rho'};
u_var   = {'fieldnames','l'};

%%% unpack model parameters
v2struct(calib,u_calib);

v2struct(var,u_var);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Utility Function Derivation:
% ----------------------------
u=zeros(S,E,H,L,D,2,2,M,J);

%%% Utility function
for j=1:J
    % bad health
    u(:,:,:,:,:,1,:,:,j)=theta_u(1,1).*(1./(1-rho)).*(((max(c(:,:,:,:,:,1,:,:,j),1e-3).*(1+theta_u(2,1).*(1-l(j))+theta_u(4,1).*l(j).*(j<J))).^((1-rho)))-1);
    % good health
    u(:,:,:,:,:,2,:,:,j)=theta_u(1,1).*(1./(1-rho)).*(((max(c(:,:,:,:,:,2,:,:,j),1e-3).*(1+theta_u(3,1).*(1-l(j))+theta_u(5,1).*l(j).*(j<J))).^((1-rho)))-1);

end
    % note for J (retirement) condition (j<J) excludes second term.


end