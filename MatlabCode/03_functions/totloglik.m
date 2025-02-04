function [tll,grad,hessian] = totloglik(coef,calib,data,var)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Total Log-Likelihood of Life-Cycle Model  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% NOTES:
    % > total loglikelihood derivation of full life-cycle model


%%% INPUT:
%   - "coef": parameter vector
%   - "calib": model calibration-struct
%   - "var": variables-struct

%%% OUTPUT:
%   - "tll": total loglikelihood
%   - "grad": numerical gradient
%   - "hessian": BHHH hessian

%%% Calls to other scripts:
%   - probs_ls_ed_blim.m


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack Model Elements
% >>> extraction of some elements to make parfor-loop work

%%% unpack model calibration
N       = calib.N;
T       = calib.T;
M       = calib.M;
educyrs = calib.educyrs;

%%% unpack variables
ed      = var.ed;
ex      = var.ex;
h       = var.h;
choice  = var.choice;
choice_ed = var.choice_ed;
spell   = var.spell;
work    = var.work;
lw      = var.lw;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Setup Optimization:

%%% Numerical Gradient Derivation - Step Size
step = 1e-6;

%%% likelihood contributions
pm  = zeros(N,1,M  ,size(coef,1)+1);                % type probabilities
pw  = zeros(N,1,M  ,size(coef,1)+1);                % individual likelihood contributions wages
P   = zeros(N,T,M,3,size(coef,1)+1);                % choice probabilities
P_ed = zeros(N,size(educyrs,1),M,size(coef,1)+1);   % education choice prob

U_ed    = zeros(size(educyrs,1),M,size(coef,1)+1); %#ok<*NASGU>
Temp_ed = zeros(size(educyrs,1),M,size(coef,1)+1);
dV_ed   = zeros(size(educyrs,1),M,size(coef,1)+1);
V_ed    = zeros(size(educyrs,1),M,size(coef,1)+1);
dP_ed   = zeros(size(educyrs,1),M,size(coef,1)+1);

%%% generate coefficient matrices
    % parameters wage-equation
    theta_w_mat = zeros(size(coef(   1:M+ 9),1), size(coef,1)+1);

    % parameters utility function
    theta_u_mat = zeros(size(coef(M+10:M+14),1), size(coef,1)+1);

    % parameters job-offers
    phi_o_mat   = zeros(size(coef(M+15:M+20),1), size(coef,1)+1);

    % parameters type probabilities
    theta_m_mat = zeros(size(coef(M+21:M+22),1),size(coef,1)+1);

    % parameters educ-utility
    theta_ued_mat = zeros(size(coef(M+23:M+32),1),size(coef,1)+1);


%%% fill coefficient matrices
for z= 1:size(coef,1)+1
    if z==1

         theta_w_mat(:,z)    = coef(   1:M+ 9        ,1);        
         theta_u_mat(:,z)    = coef(M+10:M+14        ,1);
         phi_o_mat(:,z)      = coef(M+15:M+20        ,1);
         theta_m_mat(:,z)    = coef(M+21:M+22        ,1);     
         theta_ued_mat(:,z)  = coef(M+23:M+32        ,1);

    elseif z>1
        coef(z-1,1)=coef(z-1,1)+step;

        theta_w_mat(:,z)    = coef(   1:M+ 9        ,1);       
        theta_u_mat(:,z)    = coef(M+10:M+14        ,1);
        phi_o_mat(:,z)      = coef(M+15:M+20        ,1);
        theta_m_mat(:,z)    = coef(M+21:M+22        ,1);
        theta_ued_mat(:,z)  = coef(M+23:M+32        ,1);

        coef(z-1,1)=coef(z-1,1)-step;       % reset coef vector to pre-step

    end
end

    %%% display current iteration parameters if required:
    %disp(coef)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Derive Individual Likelihood Contributions - Parallel Computation
%%% NOTES:
%   Each instance of parfor-loop computes:
%       a) Loglik-contribution of wage-profiles
%       b) Solution and Loglik-contribution of life-cycle model via P()


%tic
parfor z = 1:size(coef,1)+1        % parfor-implementation
%for z = 1:size(coef,1)+1        
    %tic
    %memoryForMac()

    %%%%%%%%%%%%%%
    %%% Setup  %%%
    %%%%%%%%%%%%%%
   
    %%% Data-Param Matrix
    xb  = zeros(N,T,M,1);

    %%% Coef-Vectors
    theta_w     = theta_w_mat(:,z);
    theta_m     = theta_m_mat(:,z);
    theta_u     = theta_u_mat(:,z);
    phi_o       = phi_o_mat(:,z);
    theta_ued   = theta_ued_mat(:,z);


    %%% type probabilities cond. on education level
    pm(:,:,:,z) = repmat(reshape([theta_m(1:M-1,1)' 1-sum(theta_m(1:M-1,1),1)]',1,1,M), [N 1]);


    %%% fill param-data matrix of wage-equation:
    xb(:,:,:,1)=      repmat(reshape(theta_w(1:M,1),1,1,M),[N T])+repmat(theta_w(M+2,1).*ed./10+(theta_w(M+3,1).*(ed<12)+theta_w(M+4,1).*(ed>=12)).*(ex/10)+ ...
            (theta_w(M+5,1).*(ed<12)+theta_w(M+6,1).*(ed>=12)).*((ex.^2)/1000)+theta_w(M+7,1).*h,[1 1 M]);    


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% 3.a) Wage Loglikelihood contributions  %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%% generic variance-covariance matrix AR(1)-process
    Omega=zeros(T,T);

    for t1=1:T
        for t2=1:T
    
            if     t1==t2           
                Omega(t1,t2)=((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2))+(theta_w(M+9,1)^2);
            elseif abs(t1-t2)>0
                Omega(t1,t2)=((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2))*(theta_w(M+1,1)^abs(t1-t2));
            end

        end
    end    

    % --------------------------------------------------------------------
    %%% derive individual-specific var-covar matrix and likelihood
    for n=1:N

        % note: 5 max detected amount of spells in data
        %   > each spell generates square in var-covar matrix
        Omega_n=((spell(n,:)==1)'.*(spell(n,:)==1)+ ...
                (spell(n,:)==2)'.*(spell(n,:)==2)+ ...
                (spell(n,:)==3)'.*(spell(n,:)==3)+ ...
                (spell(n,:)==4)'.*(spell(n,:)==4)+ ...
                (spell(n,:)==5)'.*(spell(n,:)==5)).*Omega; %#ok<*PFBNS>
     
        % keep only section matching individual observed ages
        Omega_n=Omega_n(any(Omega_n~=0),any(Omega_n~=0));

        % derive inverse of individual var-covar matrix
        IOmega_n=inv(Omega_n);

        % derive individal likelihood contributions
        for m=1:M
            % (y-xb) for observed spells in employment
            arg=nonzeros(work(n,:).*(lw(n,:)-xb(n,:,m,1)))';
                % > transpose bc 'nonzeros' returns column vector

            % invidual likelihood contribution
            %   > multivariate gaussian density of wage-path
            pw(n,1,m,z)=max((1/(sqrt(det(Omega_n)*(2*pi)^(sum(work(n,:),2))))).*exp(-0.5.*(arg*IOmega_n*arg')),1e-5);

        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% 3.b) Life-cycle Model Solution and Likelihood  %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%% recursive solution of life-cycle model & derivation of choice-prob
    %[P(:,:,:,:,z),P_ed(:,:,:,z),U_ed(:,:,z),Temp_ed(:,:,z),dV_ed(:,:,z),V_ed(:,:,z),dP_ed(:,:,z)] = probs_ls_ed_blim(theta_w,theta_u,phi_o,theta_ued,calib,data,var);
    [P(:,:,:,:,z),P_ed(:,:,:,z),~,~,~,~,~] = probs_ls_ed_blim(theta_w,theta_u,phi_o,theta_ued,calib,data,var);
    

    %toc
end
%toc



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Compute Likelihood Function and Optimization Components

%%% Life-cycle Model with Educational Choice
tll=-sum(log(sum(pw(:,:,:,1).^repmat(max(work,[],2),[1 1 M]).*prod(prod(P(:,:,:,:,1).^choice,4),2).*pm(:,:,:,1).*prod(P_ed(:,:,:,1).^choice_ed,2),3)),1);


%%% compute gradient
grad=-squeeze(sum((log(sum(  reshape(pw(:,:,:,  2:size(coef,1)+1).^repmat(max(work,[],2),[1 1 M size(coef,1)]),N,1,M,1,size(coef,1)).* ...
                           prod(prod( P(:,:,:,:,2:size(coef,1)+1).^repmat(choice,[1 1 1 1 size(coef,1)]),4),2).*reshape(pm(:,:,:,2:size(coef,1)+1),N,1,M,1,size(coef,1)) ...
                       .*reshape(prod(P_ed(:,:,:,2:size(coef,1)+1).^repmat(choice_ed,[1 1 1 size(coef,1)]),2),N,1,M,1,size(coef,1))         ,3))- ...
            repmat(log(sum(          pw(:,:,:,  1               ).^repmat(max(work,[],2),[1 1 M]).* ...
                           prod(prod( P(:,:,:,:,1               ).^choice,4),2).*pm(:,:,:,1).*prod(P_ed(:,:,:,1).^choice_ed,2),3)),[1 1 1 1 size(coef,1)]))./step,1));



%%% compute scores
scores=-squeeze(  (log(sum(  reshape(pw(:,:,:,  2:size(coef,1)+1).^repmat(max(work,[],2),[1 1 M size(coef,1)]),N,1,M,1,size(coef,1)).* ...
                           prod(prod( P(:,:,:,:,2:size(coef,1)+1).^repmat(choice,[1 1 1 1 size(coef,1)]),4),2).*reshape(pm(:,:,:,2:size(coef,1)+1),N,1,M,1,size(coef,1)) ...
                       .*reshape(prod(P_ed(:,:,:,2:size(coef,1)+1).^repmat(choice_ed,[1 1 1 size(coef,1)]),2),N,1,M,1,size(coef,1))    ,3))- ...
            repmat(log(sum(          pw(:,:,:,  1               ).^repmat(max(work,[],2),[1 1 M]).* ...
                           prod(prod( P(:,:,:,:,1               ).^choice,4),2).*pm(:,:,:,1).*prod(P_ed(:,:,:,1).^choice_ed,2),3)),[1 1 1 1 size(coef,1)]))./step);


%%% compute BHHH hessian
hessian=scores'*scores;



end         % function end