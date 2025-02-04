function [tll,grad,hessian] = wageloglik(coef,calib,var)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Wage Equation: Log-Likelihood Function   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% NOTES:
%   - derivation of log-likelihood contribution of observed wage-sequences

%%% INPUT:
%   - "coef": parameter vector
%   - "calib": model calibration-struct
%   - "var": variables-struct

%%% OUTPUT:
%   - "tll": total loglikelihood
%   - "grad": numerical gradient
%   - "hessian": BHHH hessian


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack Model Elements

%%% unpack model calibration
N       = calib.N;
T       = calib.T;
M       = calib.M;

%%% unpack variables
ed      = var.ed;
ex      = var.ex;
h       = var.h;
lw      = var.lw;
work    = var.work;
spell   = var.spell;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Setup Optimization:
% Numerical Gradient Derivation - Step Size
step = 1e-6;

% Likelihood Contributions
pm = zeros(N,1,M,size(coef,1)+1);         % type probabilities
pw = zeros(N,1,M,size(coef,1)+1);         % individual likelihood contributions


% Generate Coefficient Matrices
%   > parfor loop extracts corresponding coef-vector
    
    % Parameters Wage-Equation
    theta_w_mat = zeros(size(coef(1:M+9),1),size(coef,1)+1);
    % Parameters Type Probabilities
    theta_m_mat = zeros(size(coef(M+10:M+11),1),size(coef,1)+1);


% Fill Coef-Matrices
for z = 1:size(coef,1)+1
    if z==1
        theta_w_mat(:,z)    =coef(   1:M+ 9,1);
        theta_m_mat(:,z)    =coef(M+10:M+11,1);

    elseif z>1
        % for derivation of numerical gradient parameter z
        coef(z-1,1)=coef(z-1,1)+step;

        theta_w_mat(:,z)    =coef(   1:M+ 9,1);
        theta_m_mat(:,z)    =coef(M+10:M+11,1);

        coef(z-1,1)=coef(z-1,1)-step;       % reset coef vector to pre-step

    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Derive Individual Likelihood Contributions - Parallel Computation
% Parallel computation available -> change loop below to 'parfor'
for z=1:size(coef,1)+1

    % Data-Param Matrix
    xb = zeros(N,T,M,1);

    % Coef-Vectors
    theta_w = theta_w_mat(:,z);
    theta_m = theta_m_mat(:,z);

    % --------------------------------------------------------------------
    % type probabilities cond. on education level (initial conditions)  
    pm(:,:,:,z) = repmat(reshape([theta_m(1:M-1,1)' 1-sum(theta_m(1:M-1,1),1)]',1,1,M), [N 1]);

    % fill param-data matrix of wage-equation:
        % > intercepts + educ + exp-terms + health
        % > does not contain measurement error and ar1-error process
    xb(:,:,:,1)=repmat(reshape(theta_w(1:M,1),1,1,M),[N T])+repmat(theta_w(M+2,1).*ed./10+(theta_w(M+3,1).*(ed<12)+theta_w(M+4,1).*(ed>=12)).*(ex/10)+ ...
            (theta_w(M+5,1).*(ed<12)+theta_w(M+6,1).*(ed>=12)).*((ex.^2)/1000)+theta_w(M+7,1).*h,[1 1 M]);    


    % --------------------------------------------------------------------
    % generic variance-covariance matrix AR(1)-process
    Omega=zeros(T,T);

    for t1=1:T
        for t2=1:T
    
            if     t1==t2           
                Omega(t1,t2) = ((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2))+(theta_w(M+9,1)^2);
            elseif abs(t1-t2)>0
                Omega(t1,t2) = ((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2))*(theta_w(M+1,1)^abs(t1-t2));
            end

        end
    end    


    % --------------------------------------------------------------------
    % derive individual-specific var-covar matrix
    for n=1:N
        % note: 5 max detected amount of spells in data
        %   > each spell generates square in var-covar matrix
        Omega_n=((spell(n,:)==1)'.*(spell(n,:)==1)+ ...
                (spell(n,:)==2)'.*(spell(n,:)==2)+ ...
                (spell(n,:)==3)'.*(spell(n,:)==3)+ ...
                (spell(n,:)==4)'.*(spell(n,:)==4)+ ...
                (spell(n,:)==5)'.*(spell(n,:)==5)).*Omega;
     
        % keep only section matching individual observed ages
        Omega_n = Omega_n(any(Omega_n~=0),any(Omega_n~=0));

        % derive inverse of individual var-covar matrix
        IOmega_n = inv(Omega_n);

        % derive individal likelihood contributions
        for m=1:M
            % (y-xb) for observed spells in employment
            arg = nonzeros(work(n,:).*(lw(n,:)-xb(n,:,m,1)))';
                % > transpose bc 'nonzeros' returns column vector

            % invidual likelihood contribution
            %   > multivariate gaussian density of wage-path
            pw(n,1,m,z) = max((1/(sqrt(det(Omega_n)*(2*pi)^(sum(work(n,:),2))))).*exp(-0.5.*(arg*IOmega_n*arg')),1e-5);
            
        end
    end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Derive Likelihood Function and Optimization Components
% total log-likelihood of wage-equation
tll     = -sum(log(sum(prod(pw(:,1,:,1).^repmat(max(work,[],2),[1 1 M]),2).*pm(:,:,:,1),3)),1);

% compute gradient
grad    = -squeeze(sum((log(sum(prod(reshape(pw(:,1,:,2:size(coef,1)+1).^repmat(max(work,[],2),[1 1 M size(coef,1)]),N,1,M,1,size(coef,1)),2).*reshape(pm(:,:,:,2:size(coef,1)+1),N,1,M,1,size(coef,1)),3))- ...
                repmat(log(sum(prod(        pw(:,1,:,1               ).^repmat(max(work,[],2),[1 1 M             ]                      ),2).*pm(:,:,:,1),3)),[1 1 1 1 size(coef,1)]))./step,1));

% compute scores
scores  = -squeeze(  (log(sum(prod(reshape(pw(:,1,:,2:size(coef,1)+1).^repmat(max(work,[],2),[1 1 M size(coef,1)]),N,1,M,1,size(coef,1)),2).*reshape(pm(:,:,:,2:size(coef,1)+1),N,1,M,1,size(coef,1)),3))- ...
                repmat(log(sum(prod(        pw(:,1,:,1               ).^repmat(max(work,[],2),[1 1 M             ]                      ),2).*pm(:,:,:,1),3)),[1 1 1 1 size(coef,1)]))./step);

% compute BHHH hessian
hessian=scores'*scores;


end