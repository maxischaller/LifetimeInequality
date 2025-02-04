function [P,P_ed,U_ed,Temp_ed,dV_ed,V_ed,dP_ed] = probs_ls_ed_blim(theta_w,theta_u,phi_o,theta_ued,calib,data,var)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute Choice Probabilites for DCDP Model %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% INPUT:
%   - "theta_w,theta_u,phi_o,theta_ued": model parameters
%   - "calib": model calibration-struct
%   - "data": observed data from estimation sample
%   - "var": variables-struct


%%% OUTPUT:
%   - "P": choice probabilities - labor supply choices
%   - "P_ed": choice probabilities - education decision
%   - "U_ed": systematic component - education decision
%   - "Temp_ed,dV_ed,dP_ed": track derivation steps for education utility
%   - "V_ed": value function on education grid


%%% Functions called:
%   - "offsep.m"
%   - "taxtrans.m"
%   - "utility.m"
%   - "transit.m"
%   - "educ_choice.m"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.a Unpack Model Elements:
%  -----------------------------------
prob_calib  = {'fieldnames','N','T','D','M','J','S','E','H','L','K', ...
                'wdbase','nwgrid','edgrid','exgrid','bingrid','lwgrid' ...
                'educyrs','betta','tau','DeltaO','DeltaS','wdbase','weight','blim'};

prob_var    = {'fieldnames','ic','ed','ex','h','wl','work','spell', ...
                'choice','l','sav','ob','nw','noret','nolab', ...
                'wagel'};

prob_data   = {'fieldnames','spbh','spgh'};


%%% unpack model calibration
v2struct(calib,prob_calib);

v2struct(var,prob_var);

v2struct(data,prob_data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.b Setup:
%  ---------

P    = zeros(N,T,D,M,3);                % choice probabilities: labor supply
V    = zeros(N,T,D,M,J);                % choice-specific value functions
dV   = zeros(S,E,H,L,D,2,2,M,J,T);
P_ed = zeros(size(educyrs,1),M);        % choice probabilities: education

k    = zeros(S,E,H,L,D,2,2,M,T);        % constant for rescaling 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Predict Gross Wages:
%  -----------------------

%%% transform standard-normal support of wage-shock
wdgrid1 = wdbase.*sqrt((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2));  % stst-distribution ar1
wdgrid2 = wdbase.*      theta_w(M+8,1);                           % only transitory shock s.d.


% ------------------------------------------------------------------------
%%% gross log-wages
logw = zeros(E,H,L,D,2,2,M);

% low-education / unemploymed t-1 / wage-shock from stst–distribution
logw(:,1:2,:,:,:,1,:)=                    repmat(reshape(theta_w(1:M,1),1,1,1,1,1,1,M),[E 2 L D 2    ]) + ...
                         theta_w(M+2,1) .*repmat(        edgrid(1:2,1)'./10           ,[E 1 L D 2 1 M]) + ...
                         theta_w(M+3,1) .*repmat(        exgrid        ./10           ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+5,1) .*repmat(       (exgrid.^2)    ./1000          ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]) +repmat(reshape(wdgrid1,1,1,1,D),[E 2 L 1 2 1 M]);
    % logw -> 6th-dim=1 unemployed in t-1

% low-education / employed t-1 / wage-shock from ar1-distribution
logw(:,1:2,:,:,:,2,:)=(1-theta_w(M+1,1)).*repmat(reshape(theta_w(1:M,1),1,1,1,1,1,1,M),[E 2 L D 2    ]) + ...
                         theta_w(M+1,1) .*repmat(reshape(lwgrid        ,1,1,L        ),[E 2 1 D 2 1 M]) + ...
                         theta_w(M+2,1) .*repmat(        edgrid(1:2,1)'./10           ,[E 1 L D 2 1 M]) + ...
                         theta_w(M+3,1) .*repmat(       (exgrid        ./10)          ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+5,1) .*repmat(      ((exgrid.^2)    ./1000)         ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]) -theta_w(M+1,1).*( ...
                         theta_w(M+2,1) .*repmat(        edgrid(1:2,1)' ./10          ,[E 1 L D 2 1 M]) + ...
                         theta_w(M+3,1) .*repmat(    max(exgrid-1,0)    ./10          ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+5,1) .*repmat(   (max(exgrid-1,0).^2)./1000         ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]))+repmat(reshape(wdgrid2,1,1,1,D),[E 2 L 1 2 1 M]);

% high-education / unemployed t-1 / wage-shock from ar1-distribution
logw(:,3:4,:,:,:,1,:)=                    repmat(reshape(theta_w(1:M,1),1,1,1,1,1,1,M),[E 2 L D 2    ]) + ...
                         theta_w(M+2,1) .*repmat(        edgrid(3:4,1)'./10           ,[E 1 L D 2 1 M]) + ...
                         theta_w(M+4,1) .*repmat(        exgrid        ./10           ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+6,1) .*repmat(       (exgrid.^2)    ./1000          ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]) +repmat(reshape(wdgrid1,1,1,1,D),[E 2 L 1 2 1 M]);

% high-education / employed t-1 / wage-shock from ar1-distribution
logw(:,3:4,:,:,:,2,:)=(1-theta_w(M+1,1)).*repmat(reshape(theta_w(1:M,1),1,1,1,1,1,1,M),[E 2 L D 2    ]) + ...
                         theta_w(M+1,1) .*repmat(reshape(lwgrid        ,1,1,L        ),[E 2 1 D 2 1 M]) + ...
                         theta_w(M+2,1) .*repmat(        edgrid(3:4,1)'./10           ,[E 1 L D 2 1 M]) + ...
                         theta_w(M+4,1) .*repmat(       (exgrid        ./10)          ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+6,1) .*repmat(      ((exgrid.^2)    ./1000)         ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]) -theta_w(M+1,1).*( ...
                         theta_w(M+2,1) .*repmat(        edgrid(3:4,1)' ./10          ,[E 1 L D 2 1 M]) + ...
                         theta_w(M+4,1) .*repmat(    max(exgrid-1,0)    ./10          ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+6,1) .*repmat(   (max(exgrid-1,0).^2)./1000         ,[1 2 L D 2 1 M]) + ...
                         theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]))+repmat(reshape(wdgrid2,1,1,1,D),[E 2 L 1 2 1 M]);


% ------------------------------------------------------------------------
%%% annual labor earnings:
wage = 52*40.*repmat(reshape(max(exp(logw),8.5),1,E,H,L,D,2,2,M),[S 1]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Job-Offer/Separation Rates:
%  ------------------------------

[s,o] = offsep(phi_o,calib);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Define Grid of Value Function:
%  -----------------------------

%%% rectangular grid 
[G1,G2,G3,G4] = ndgrid(nwgrid,exgrid,edgrid,lwgrid);
    % for discretized grids of variables



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. Recursive Computation of Value Function and Choice Probabilities:
%  ----------------------------------------------------------------

%%% recursive over all ages of life-cycle
for t = T:(-1):1


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Assign consumption levels to choices %    (t) (standard grid)
    % --------------------------------------

    %%% calculate path variables / tax-transfer and pension system
    %[y,gci,dis,itax,ctax,ssc,health,pins,unempl,uib,sab,mpb,npb]=taxtrans(t,wage,calib,data);
    [y,~,dis,~,~,~,~,~,~,~,~,~,~] = taxtrans(t,wage,calib,data);


    %%% Consumption = y - positive savings + dissavings
    c = max((y-max(repmat(reshape(sav,1,1,1,1,1,1,1,1,J),[S E H L D 2 2 M]),-repmat(nwgrid - blim,[1 E H L D 2 2 M J]))+dis)./10000,0);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute flow utility and transition probabilities %
    % ---------------------------------------------------
    
    %%% utility function
    u = utility(c,l,theta_u,calib,var); 


    %%% transition probabilities
    q = transit(t,s,o,calib,data);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Period T - Last Period of Labor Market Participation %
    % ------------------------------------------------------

    if t==T

        %%% reassignment of age T flow utility (get matrix size)
        v  = u;
        x  = u;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Calculate Path Variables T+1 (compulsory retirement)
        % ------------------------------------------------------

        %%% tax-transfer system
        %[y,gci,dis,itax,ctax,ssc,health,pins,unempl,uib,sab,mpb,npb] = taxtrans(t+1,wage,calib,data);
        [y,~,dis,~,~,~,~,~,~,~,~,~,~] = taxtrans(t+1,wage,calib,data);

        %%% consumption
        c = max((y-max(repmat(reshape(sav,1,1,1,1,1,1,1,1,J),[S E H L D 2 2 M]),-repmat(nwgrid - blim,[1 E H L D 2 2 M J]))+dis)./10000,0);

        %%% flow utility T+1
        u = utility(c,l,theta_u,calib,var);

        %%% compulsory retirement at age T+1
        %   > replicate derived pension utility on all choices
        x(:,:,:,:,:,:,:,:,1:J-1) = repmat(u(:,:,:,:,:,:,:,:,J),[1 1 1 1 1 1 1 1 J-1]);

        %%% w: T+1 pension flow utility
        w = x;      % get matrix size


            % ---------------------------------
            %%% Derive Continuation Values T+1
                % note: loop over j excludes retirement dimension!
              
            for j = 1:J-1                     % savings choice

                for a = 1:2                   % lagged employment status
                    
                    for d = 1:2               % health status
                        
                        for e = 1:D           % wage shock grid (not t-dependent, already evaluated)

                            %%% Path variables:
                            % Net Wealth Transition                            
                            nwbar = nwgrid*(1+tau)-max(nwgrid*tau-801,0)*0.25*1.055+max(sav(j),-(nwgrid-blim));

                            % Experience:
                            if j<=K
                                exbar = exgrid+1;
                            else
                                exbar = exgrid;
                            end

                            % combined T+1 grid: netwealth, exp, educ, lag-wage
                            [B1,B2,B3,B4] = ndgrid(nwbar,exbar,edgrid,lwgrid);

                            for m=1:M
                                
                                F = griddedInterpolant(G1,G2,G3,G4,w(:,:,:,:,e,d,a,m,j),'linear');
                                
                                x(:,:,:,:,e,d,a,m,j) = F(B1,B2,B3,B4);   % continuation values T+1     

                            end

                        end
                    end
                end
            end
        

            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Compute Expected Utility of remaining lifetime in T
        % ------------------------------------------------------
        
        for i = 1:(80-t+1)
            v(:,:,1:2,:,:,1,:,:,:) = v(:,:,1:2,:,:,1,:,:,:)+betta^i.*prod(spbh(t:t+i-1,t,1),1).*(x(:,:,1:2,:,:,1,:,:,:));
            v(:,:,1:2,:,:,2,:,:,:) = v(:,:,1:2,:,:,2,:,:,:)+betta^i.*prod(spgh(t:t+i-1,t,1),1).*(x(:,:,1:2,:,:,2,:,:,:));
            v(:,:,3:4,:,:,1,:,:,:) = v(:,:,3:4,:,:,1,:,:,:)+betta^i.*prod(spbh(t:t+i-1,t,2),1).*(x(:,:,3:4,:,:,1,:,:,:));
            v(:,:,3:4,:,:,2,:,:,:) = v(:,:,3:4,:,:,2,:,:,:)+betta^i.*prod(spgh(t:t+i-1,t,2),1).*(x(:,:,3:4,:,:,2,:,:,:));
        end


    %%%%%%%%%%%%%%%
    % Period t<T %
    % ------------- 
    
    elseif t<T
          
        w = v;

        %%% Evaluate t+1 value function (standard grid) at t+1 grid
        for j=1:J-1     % time t choice
            % - for any choice in period t(!) (except retirement - evaluation separate)

            % - note this loop does not end after first t+1 interpolation
            for a = 1:2
                for d = 1:2
                    for e = 1:D

                        nwbar = nwgrid*(1+tau)-max(nwgrid*tau-801,0)*0.25*1.055+max(sav(j),-(nwgrid-blim));

                        if j<=K
                            exbar = exgrid+1;
                        else
                            exbar = exgrid;
                        end

                        [B1,B2,B3,B4] = ndgrid(nwbar,exbar,edgrid,lwgrid);

                        for z1 = 1:J          
                            for m = 1:M
                                F = griddedInterpolant(G1,G2,G3,G4,w(:,:,:,:,e,d,a,m,z1),'linear');
                                x(:,:,:,:,e,d,a,m,z1) = F(B1,B2,B3,B4);
                            end
                        end

                    end
                end
            end



            %%% early retirement restricted %%%
            if t <= 43                       
                x(:,:,:,:,:,2,:,:,J)   = -inf;
            end

            if t <= 10
                x(:,:,:,:,:,1,:,:,J)   = -inf;
            end


            %%% employment restricted in t+1 %%%
            x1=x;                            
            x2=x;
            x2(:,:,:,:,:,:,:,:,1:K)    = -inf;

            
            % -------------------------------------------------
            %%% Bellman equation
                % - derivation of alternative-specific value functions in t
                %   using log-sum-exp form to derive expected value of
                %   continuation values (integrated Bellman eq.)

            temp1 = zeros(S,E,H,L,D,2,2,M,3);
            temp2 = zeros(S,E,H,L,D,2,2,M,3);

            temp1(:,:,:,:,:,:,:,:,1) = max(x1(:,:,:,:,:,:,:,:,  1:K  ),[],9);
            temp1(:,:,:,:,:,:,:,:,2) = max(x1(:,:,:,:,:,:,:,:,K+1:J-1),[],9);
            temp1(:,:,:,:,:,:,:,:,3) = max(x1(:,:,:,:,:,:,:,:,    J  ),[],9);
            temp2(:,:,:,:,:,:,:,:,1) = max(x2(:,:,:,:,:,:,:,:,  1:K  ),[],9); 
            temp2(:,:,:,:,:,:,:,:,2) = max(x2(:,:,:,:,:,:,:,:,K+1:J-1),[],9);
            temp2(:,:,:,:,:,:,:,:,3) = max(x2(:,:,:,:,:,:,:,:,    J  ),[],9);
            

            %%% alternative-specific value functions:
                % > separate derivation to heterogen. mortality profiles by health and educ
                % > model with rescaling and shift-adjustment
    
            % > v(t) at age t, low-educ, bad-health
            v(:,:,1:2,:,:,1,:,:,j)=                u(:,:,1:2,:,:,1,:,:,j)+betta.*spbh(t,t,1).*repmat(sum(sum(sum( ...
                (log(sum(exp(temp1(:,:,1:2,:,:,:,:,:,:)-repmat(k(:,:,1:2,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,1:2,:,:,:,:,:,t+1)).*q(:,:,1:2,:,:,:,:,:,1,j)+ ...
                (log(sum(exp(temp2(:,:,1:2,:,:,:,:,:,:)-repmat(k(:,:,1:2,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,1:2,:,:,:,:,:,t+1)).*q(:,:,1:2,:,:,:,:,:,2,j)  ,5),6),7),[1 1 1 1 D 1 2]);
                
            % > v(t) at age t, low-educ, good-health
            v(:,:,1:2,:,:,2,:,:,j)=                u(:,:,1:2,:,:,2,:,:,j)+betta.*spgh(t,t,1).*repmat(sum(sum(sum( ...
                (log(sum(exp(temp1(:,:,1:2,:,:,:,:,:,:)-repmat(k(:,:,1:2,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,1:2,:,:,:,:,:,t+1)).*q(:,:,1:2,:,:,:,:,:,3,j)+ ...
                (log(sum(exp(temp2(:,:,1:2,:,:,:,:,:,:)-repmat(k(:,:,1:2,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,1:2,:,:,:,:,:,t+1)).*q(:,:,1:2,:,:,:,:,:,4,j)  ,5),6),7),[1 1 1 1 D 1 2]);

            % > v(t) at age t, high-educ, bad-health
            v(:,:,3:4,:,:,1,:,:,j)=                u(:,:,3:4,:,:,1,:,:,j)+betta.*spbh(t,t,2).*repmat(sum(sum(sum( ...
                (log(sum(exp(temp1(:,:,3:4,:,:,:,:,:,:)-repmat(k(:,:,3:4,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,3:4,:,:,:,:,:,t+1)).*q(:,:,3:4,:,:,:,:,:,1,j)+ ...
                (log(sum(exp(temp2(:,:,3:4,:,:,:,:,:,:)-repmat(k(:,:,3:4,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,3:4,:,:,:,:,:,t+1)).*q(:,:,3:4,:,:,:,:,:,2,j)  ,5),6),7),[1 1 1 1 D 1 2]);

            % > v(t) at age t, high-educ, good-health
            v(:,:,3:4,:,:,2,:,:,j)=                u(:,:,3:4,:,:,2,:,:,j)+betta.*spgh(t,t,2).*repmat(sum(sum(sum( ...
                (log(sum(exp(temp1(:,:,3:4,:,:,:,:,:,:)-repmat(k(:,:,3:4,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,3:4,:,:,:,:,:,t+1)).*q(:,:,3:4,:,:,:,:,:,3,j)+ ...
                (log(sum(exp(temp2(:,:,3:4,:,:,:,:,:,:)-repmat(k(:,:,3:4,:,:,:,:,:,t+1),[1 1 1 1 1 1 1 1 3])),9))+k(:,:,3:4,:,:,:,:,:,t+1)).*q(:,:,3:4,:,:,:,:,:,4,j)  ,5),6),7),[1 1 1 1 D 1 2]);

        end     % over choices J-1 at age t


        %%% Early retirement
        v(:,:,:,:,:,:,:,:,J)=u(:,:,:,:,:,:,:,:,J); 
        
        % early retirement years up to 64
        for i=1:T-t
            v(:,:,1:2,:,:,1,:,:,J)=v(:,:,1:2,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,1,:,:,J));
            v(:,:,1:2,:,:,2,:,:,J)=v(:,:,1:2,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,2,:,:,J));
            v(:,:,3:4,:,:,1,:,:,J)=v(:,:,3:4,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,1,:,:,J));
            v(:,:,3:4,:,:,2,:,:,J)=v(:,:,3:4,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,2,:,:,J));
        end

        for i=T-t+1:(80-t+1)
            v(:,:,1:2,:,:,1,:,:,J)=v(:,:,1:2,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,1,:,:,J));
            v(:,:,1:2,:,:,2,:,:,J)=v(:,:,1:2,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,2,:,:,J));
            v(:,:,3:4,:,:,1,:,:,J)=v(:,:,3:4,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,1,:,:,J));
            v(:,:,3:4,:,:,2,:,:,J)=v(:,:,3:4,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,2,:,:,J));
        end


    end     % loop 'if t=T, elseif t<T'
    


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute Constant for Rescaling %
    % --------------------------------

    k(:,:,:,:,:,:,:,:,t) = repmat(min(min(min(min(min(min(min(min(v,[],1),[],2),[],3),[],4),[],5),[],6),[],7),[],9),[S E H L D 2 2]);   
        % - no sum along dim-8 : prod. types (keeps 3 layers)

 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Evaluation of Observed States %
    % -------------------------------

    for j = 1:J                           % savings choice
        for m = 1:M                       % prod. ability type
            for a = 1:2                   % lagged employment status
                for d = 1:2               % health status
                    for e = 1:D           % wage shock

                        F = griddedInterpolant(G1,G2,G3,G4,v(:,:,:,:,e,d,a,m,j),'linear');

                        for n=1:N
                            if ob(n,t)==1 && h(n,t)==d-1 && wl(n,t)==a-1        %#ok<USENS>
                                % note: binary h(health) and wl(lagemplst)
                                
                                V(n,t,e,m,j) = F(nw(n,t),ex(n,t),ed(n,t),max(log(wagel(n,t)),2));                                
                            end    
                        end
                    end
                end
            end
        end
    end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Save Age t Value Function
    dV(:,:,:,:,:,:,:,:,:,t) = v;    

end     % recursive loop end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6. Compute individuals' Job Offer and Separation Rates:
%  -------------------------------------------------------

Off = zeros(N,T,M);
Sep = zeros(N,T,M);

for t = 1:T
    for m = 1:M
        for a = 1:2
            for n = 1:N

                if ob(n,t)==1 && h(n,t)==a-1

                    Off(n,t,m) = o(1+((ed(n,t)>=12)*2),a,m,t);
                    Sep(n,t,m) = s(1+((ed(n,t)>=12)*2),a,m,t);

                    % > o(1:2,..) rows 1&2, 3%4 contain same values
                    % > differentiation only b/w low/high educ (not grid)
                end
            end
        end
    end
end

Off = repmat(reshape(Off,N,T,1,M),[1 1 D]);
Sep = repmat(reshape(Sep,N,T,1,M),[1 1 D]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7. Rescale value function 
% --------------------------
    % - see multinomial choice model parameter location identification

V=V-repmat(max(V,[],5),[1 1 1 1 J]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine Value of Optimal Savings Choice:
%  -----------------------------------------

Temp = V;
V=zeros(N,T,D,M,3);

V(:,:,:,:,1)=max(Temp(:,:,:,:,  1:K  ),[],5);
V(:,:,:,:,2)=max(Temp(:,:,:,:,K+1:J-1),[],5);
V(:,:,:,:,3)=max(Temp(:,:,:,:,    J  ),[],5);       % unique dim-5 J=27 retirement


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8. Compute LS Choice Probabilites:
%  ----------------------------------

for t = 1:T                   % labor market participation
    for j = 1:3               % labor supply status / retirement

        P(:,t,:,:,j)=max( ...
            repmat(   wl(:,t) ,[1 1 D M]).*(   Sep(:,t,:,:) .*(exp(V(:,t,:,:,j)).*noret(:,t,:,:,j).*nolab(:,t,:,:,j))./(sum(exp(V(:,t,:,:,:)).*noret(:,t,:,:,:).*nolab(:,t,:,:,:),5))+ ...
                                            (1-Sep(:,t,:,:)).*(exp(V(:,t,:,:,j)).*noret(:,t,:,:,j))                  ./(sum(exp(V(:,t,:,:,:)).*noret(:,t,:,:,:),5)))+ ...
            repmat((1-wl(:,t)),[1 1 D M]).*(   Off(:,t,:,:) .*(exp(V(:,t,:,:,j)).*noret(:,t,:,:,j))                  ./(sum(exp(V(:,t,:,:,:)).*noret(:,t,:,:,:),5)) + ...
                                            (1-Off(:,t,:,:)).*(exp(V(:,t,:,:,j)).*noret(:,t,:,:,j).*nolab(:,t,:,:,j))./(sum(exp(V(:,t,:,:,:)).*noret(:,t,:,:,:).*nolab(:,t,:,:,:),5))),1e-10); %#ok<USENS>

        % 'max': numerical optimization requirement
    end
end


%%% Integrate Wage-Shock
P = squeeze(sum(P.*repmat(reshape(weight,1,1,D),[N T 1 M 3]),3));
    % (N,T,M,3)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 9. Compute Education Choice Probabilites:
%  ----------------------------------------

%%% Computation Valuations of Choice Alternatives    
[V_ed,U_ed,Temp_ed] = educ_choice(dV,o,theta_ued,calib,var,data);
    dV_ed = V_ed;

%%% Rescale Education Value Function
V_ed  = V_ed - repmat(max(V_ed,[],1),[size(educyrs,1) 1]);


%%% Compute Education Choice Probabilities
for j = 1:size(educyrs,1)
    P_ed(j,:) = max( exp(V_ed(j,:))./(sum(exp(V_ed(:,:)),1))  ,1e-10);
end

dP_ed = P_ed;

%%% resize:
P_ed = repmat(reshape(P_ed,1,size(educyrs,1),M),[N 1 1]);



end     % function end