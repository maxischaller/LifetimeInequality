function [s_ste,o_ste] = osdelta(phi_o,hessian,calib)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute standard errors of job offer and separation rates %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unpack Parameters:
% ------------------
osdel_calib = {'fieldnames','phi_s','T','H','M','edgrid','DeltaS','DeltaO'};

%%% unpack model calibration and switches
v2struct(calib,osdel_calib);

%%% define step-size for gradient derivation
step=1e-6;

%%% define gradient matrix size
s_grad=zeros(H,2,M,T+1,size(phi_s,1));
o_grad=zeros(H,2,M,T+1,size(phi_o,1));

%%% define standard-error matrix size
s_ste=zeros(H,2,M,T+1);
o_ste=zeros(H,2,M,T+1);

%%% estimated inverse-hessian - separation parameters
ihsep = calib.ihess_sep;
    
%%% estimated hessian LC-model
ihess = inv(hessian);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GRADIENTS: Job Offer and Separation Rates:
% ------------------------------------------

phi = [phi_s; phi_o];

for z=1:size(phi,1)/2

    %%% Preparation: Numerical Gradient
    d_phi=phi;
    d_phi(z              ,1)=d_phi(z  ,1)            +step;
    d_phi(z+size(phi,1)/2,1)=d_phi(z+size(phi,1)/2,1)+step;

    %%% Job Separation Rates
    for t=1:T+1

        s_grad(:,1,:,t,z)=(min(max((1./((1./exp(d_phi( 1,1)+d_phi( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +d_phi( 4,1).*(t>30)+d_phi( 5,1).*(t>35)+d_phi( 6,1).*(t>40)))+1)).*(1+DeltaS),1e-10),1)- ...
            min(max((1./((1./exp(  phi( 1,1)+  phi( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +  phi( 4,1).*(t>30)+  phi( 5,1).*(t>35)+  phi( 6,1).*(t>40)))+1)).*(1+DeltaS),1e-10),1))./step;
        s_grad(:,2,:,t,z)=(min(max((1./((1./exp(d_phi( 1,1)+d_phi( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+d_phi( 3,1)+d_phi( 4,1).*(t>30)+d_phi( 5,1).*(t>35)+d_phi( 6,1).*(t>40)))+1)).*(1+DeltaS),1e-10),1)- ...
            min(max((1./((1./exp(  phi( 1,1)+  phi( 2,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+  phi( 3,1)+  phi( 4,1).*(t>30)+  phi( 5,1).*(t>35)+  phi( 6,1).*(t>40)))+1)).*(1+DeltaS),1e-10),1))./step;

    end

    %%% Job Offer Rates
    for t=1:T+1

        o_grad(:,1,:,t,z)=(min(max((1./((1./exp(d_phi( 7,1)+d_phi( 8,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +d_phi(10,1).*(t>30)+d_phi(11,1).*(t>35)+d_phi(12,1).*(t>40)))+1)).*(1+DeltaO),1e-10),1)- ...
            min(max((1./((1./exp(  phi( 7,1)+  phi( 8,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])            +  phi(10,1).*(t>30)+  phi(11,1).*(t>35)+  phi(12,1).*(t>40)))+1)).*(1+DeltaO),1e-10),1))./step;
        o_grad(:,2,:,t,z)=(min(max((1./((1./exp(d_phi( 7,1)+d_phi( 8,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+d_phi( 9,1)+d_phi(10,1).*(t>30)+d_phi(11,1).*(t>35)+d_phi(12,1).*(t>40)))+1)).*(1+DeltaO),1e-10),1)- ...
            min(max((1./((1./exp(  phi( 7,1)+  phi( 8,1).*repmat(1*(edgrid(:,1)>=12),[1 1 M])+  phi( 9,1)+  phi(10,1).*(t>30)+  phi(11,1).*(t>35)+  phi(12,1).*(t>40)))+1)).*(1+DeltaO),1e-10),1))./step;

    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STANDARD ERRORS: Job Offer and Separation Rates:
% ------------------------------------------------
for a=1:H
    for b=1:2
        for d=1:M
            for t=1:T

                s_ste(a,b,d,t)=sqrt(diag(squeeze(s_grad(a,b,d,t,:))'*ihsep                     *squeeze(s_grad(a,b,d,t,:))));
                o_ste(a,b,d,t)=sqrt(diag(squeeze(o_grad(a,b,d,t,:))'*ihess(M+15:M+20,M+15:M+20)*squeeze(o_grad(a,b,d,t,:))));

            end
        end
    end
end


end             % function end
