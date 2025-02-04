function [V_ed,U_ed,Temp_ed] = educ_choice(dV,o,theta_ued,calib,var,data)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EDUCATION CHOICE COMPONENTS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% INPUT:
%   - "dV": value function grid to derive continuation values
%   - "o": job offer probabilities (for labor market entry)
%   - "theta_ued": utility parameters (education-choice)
%   - "calib": model calibration-struct
%   - "data": observed data from estimation sample
%   - "var": variables-struct


%%% OUTPUT:
%   - "V_ed": value-function on education-grid
%   - "U_ed": systematic education cost components
%   - "Temp_ed": continuation values on education grid


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.a Unpack Model Elements:
% ---------------------------

ed_calib = {'fieldnames','S','E','H','M','J','L','D','K','rho', ...
                'educyrs','nwgrid','edgrid','exgrid','lwgrid','betta', 'weight','tau'};
ed_var   = {'fieldnames','l','sav'};

ed_data   = {'fieldnames','spbh','spgh'};


%%% unpack model parameters
v2struct(calib,ed_calib);

v2struct(var,ed_var);

v2struct(data,ed_data);

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.b Setup:
%  ---------  
%%% Matrices    
V_ed = zeros(size(educyrs,1),M);

%%% Wage-Shock Proabilitiy Weights
    wd=repmat(reshape(weight,1,1,1,1,D),[1 1 2 1 1 1 1 M 1]);

%%% Extract Intercepts
inter = [0 theta_ued']';
    % > for alternative 1 (8 yrs of education): normalized to zero


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Continuation Values Computation:
% --------------------------------

for i = 1:7

    %%% Initialize matrices
    dv_ed = zeros(1,1,2,1,1,1,1,M);
    f     = zeros(1,1,2,1,D,1,1,M,2);

    %%% Evaluation only at subset of t+1 states
        % > nw=exp=0; gh; lagged-unemployed
        % > no interpolation step required; cont. vars unchanged at
        %   boundary
    x = dV(1,1,:,1,:,2,1,:,:,i);
    
        % > early retirement excluded
        x(:,:,:,:,:,:,:,:,J) = -inf;

        % > employment choice restrictions
        x1 = x;
        x2 = x;
        x2(:,:,:,:,:,:,:,:,1:K) = -inf;


    %%% Preparation for Bellman Eq.
    temp1=zeros(1,1,H,1,D,1,1,M,3);
    temp2=zeros(1,1,H,1,D,1,1,M,3);

    temp1(:,:,:,:,:,:,:,:,1)=max(x1(:,:,:,:,:,:,:,:,  1:K  ),[],9);
    temp1(:,:,:,:,:,:,:,:,2)=max(x1(:,:,:,:,:,:,:,:,K+1:J-1),[],9);
    temp1(:,:,:,:,:,:,:,:,3)=max(x1(:,:,:,:,:,:,:,:,    J  ),[],9);
    temp2(:,:,:,:,:,:,:,:,1)=max(x2(:,:,:,:,:,:,:,:,  1:K  ),[],9); 
    temp2(:,:,:,:,:,:,:,:,2)=max(x2(:,:,:,:,:,:,:,:,K+1:J-1),[],9);
    temp2(:,:,:,:,:,:,:,:,3)=max(x2(:,:,:,:,:,:,:,:,    J  ),[],9);            


    t = i-1;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Conditional on Education Choice:
    % -----------------------------------
    if i == 1        % low-education k = 8,9,10,11 and high-ed 12
        % > start life-cycle V20 (age-20 value function)
        
        % -----------------------------------------
        %%% LOW EDUCATION
        
        %%% Derive Transition Probability
        f(:,:,:,:,:,:,:,:,1) =    repmat(reshape(o(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[1 1 1 1 D 1 1 1 1])  .* wd;
        f(:,:,:,:,:,:,:,:,2) = (1-repmat(reshape(o(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[1 1 1 1 D 1 1 1 1])) .* wd;
  

        %%% Expected Value for V20 (as t+1)
        dv_ed(:,:,:,:,:,:,:,:) = sum( ...
                            log(sum(exp(temp1(:,:,1:2,:,:,:,:,:,:)),9)).*f(:,:,1:2,:,:,:,:,:,1) ...
                          + log(sum(exp(temp2(:,:,1:2,:,:,:,:,:,:)),9)).*f(:,:,1:2,:,:,:,:,:,2) ,5);
            % > t+1: Pr(badhealth)==0
        
        dv_ed = squeeze(dv_ed);


        %%% Evaluation of Education Choice State (Low-Education)
        for z = 1:4    
            for m = 1:M
    
                % only low-education grid
                ledgrid = [8 11]';
    
                [E1]      = ndgrid(ledgrid);
                F         = griddedInterpolant(E1,dv_ed(:,m),'linear');
                V_ed(z,m) = F(educyrs(z));
    
            end
        end


        % -----------------------------------------
        %%% HIGH EDUCATION        
        %%% Derive Transition Probability High Educ
        f     = zeros(1,1,2,1,D,1,1,M,2); 

        f(:,:,:,:,:,:,:,:,1) =    repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[1 1 1 1 D 1 1 1 1])  .* wd;
        f(:,:,:,:,:,:,:,:,2) = (1-repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[1 1 1 1 D 1 1 1 1])) .* wd;  

        %%% Expected Value for V20 (t+1)
        dv_ed = zeros(1,1,2,1,1,1,1,M);
        dv_ed(:,:,:,:,:,:,:,:) = sum( ...
                            log(sum(exp(temp1(:,:,3:4,:,:,:,:,:,:)),9)).*f(:,:,1:2,:,:,:,:,:,1) ...
                          + log(sum(exp(temp2(:,:,3:4,:,:,:,:,:,:)),9)).*f(:,:,1:2,:,:,:,:,:,2) ,5);        

        dv_ed = squeeze(dv_ed);

        %%% Evaluation of Education Choice State (High-Education)
        for m = 1:M
            hedgrid = [12 18]';         
            [E1] = ndgrid(hedgrid);
            F = griddedInterpolant(E1,dv_ed(:,m),'linear');
            V_ed(5,m) = F(educyrs(5));
            % > no interpolation needed, bc grid point k=12 is evaluated
        end


    % --------------------------------------------------------------------
    else        % HIGH EDUCATION
        % > start life-cycle cond. on education choice V21-V27

        % high-education, offer
        f(:,:,:,:,:,:,:,:,1) =    repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[1 1 1 1 D 1 1 1 1])  .* wd;
        f(:,:,:,:,:,:,:,:,2) = (1-repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[1 1 1 1 D 1 1 1 1])) .* wd;
        
        %%% Expected Valuation
        dv_ed(:,:,:,:,:,:,:,:) = sum( ...
                             log(sum(exp(temp1(:,:,3:4,:,:,:,:,:,:)),9)).*f(:,:,:,:,:,:,:,:,1) ...
                           + log(sum(exp(temp2(:,:,3:4,:,:,:,:,:,:)),9)).*f(:,:,:,:,:,:,:,:,2) ,5);

        dv_ed = squeeze(dv_ed);

        %%% Evaluation of Education Choice
        for m = 1:M

            % only high-educ grid
            hedgrid = [12 18]';

            [E1] = ndgrid(hedgrid);
            F = griddedInterpolant(E1,dv_ed(:,m),'linear');
            V_ed(4+i,m) = F(educyrs(4+i));
               
        end


    end         % if-condition


end         % i=1:7



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Education utility derivation:
% ---------------------------------

% ------------------------------
%%% Derive discounting factors
    % > for continuation value expectation
    discon2 = betta.^([1:1:size(educyrs,1)]');      %#ok<NBRAK1>
    discon2(1:5,:) = repmat(discon2(5,:),[5,1]);


% ------------------------------
%%% Systematic component
U_ed = repmat(inter,[1 3]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Combine Educ-Utility and Continuation Values:
% -------------------------------------------------

Temp_ed = repmat(discon2,[1 3]).*V_ed;

V_ed    = U_ed + Temp_ed;



end