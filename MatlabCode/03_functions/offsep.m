%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute job offer and separation rates %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [s,o] = offsep(phi_o,calib)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unpack Model Elements:
% ----------------------
offsep_calib = {'fieldnames','phi_s','T','H','M','edgrid','DeltaS','DeltaO'};

%%% unpack model calibration and switches
v2struct(calib,offsep_calib);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute Separation and Offer Probabilities:
% -------------------------------------------

s = zeros(H,2,M,T+1);
o = zeros(H,2,M,T+1);


%%% job separation rates
for t = 1:T+1

    s(:,1,:,t) = min(max((1./((1./exp(phi_s( 1,1)+phi_s( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +phi_s( 4,1).*(t>30)+phi_s( 5,1).*(t>35)+phi_s( 6,1).*(t>40)))+1)).*(1+DeltaS),1e-10),1); %#ok<USENS>
    s(:,2,:,t) = min(max((1./((1./exp(phi_s( 1,1)+phi_s( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+phi_s( 3,1)+phi_s( 4,1).*(t>30)+phi_s( 5,1).*(t>35)+phi_s( 6,1).*(t>40)))+1)).*(1+DeltaS),1e-10),1);

end



%%% job offer rates
for t = 1:T+1
    % > DeltaO relative changes to offer rates 
    o(:,1,:,t) = min(max((1./((1./exp(phi_o( 1,1)+phi_o( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +phi_o(4,1).*(t>30)+phi_o(5,1).*(t>35)+phi_o(6,1).*(t>40)))+1)).*(1+DeltaO),1e-10),1);
    o(:,2,:,t) = min(max((1./((1./exp(phi_o( 1,1)+phi_o( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+phi_o( 3,1)+phi_o(4,1).*(t>30)+phi_o(5,1).*(t>35)+phi_o(6,1).*(t>40)))+1)).*(1+DeltaO),1e-10),1);

    % > DeltaO absolute changes to offer rates 
%     o(:,1,:,t) = min(max((1./((1./exp(phi_o( 1,1)+phi_o( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +phi_o(4,1).*(t>30)+phi_o(5,1).*(t>35)+phi_o(6,1).*(t>40)))+1))+DeltaO,1e-10),1);
%     o(:,2,:,t) = min(max((1./((1./exp(phi_o( 1,1)+phi_o( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+phi_o( 3,1)+phi_o(4,1).*(t>30)+phi_o(5,1).*(t>35)+phi_o(6,1).*(t>40)))+1))+DeltaO,1e-10),1);

end


end
