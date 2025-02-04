function [sim_path,sim_sol] = simpath_par(calib,var,data,paramhat,draws)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation of life cycle paths %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% INPUT:
%   - "calib": model calibration-struct
%   - "data": observed data from estimation sample
%   - "var": variables-struct
%   - "paramhat": estimated parameters
%   - "draws": struct of (pseudo-)random draws for simulation


%%% OUTPUT:
%   - "sim_path": simulated life-cycle path variables
%   - "sim_sol": model solution given parameters


%%% Functions called:
%   - "offsep.m"
%   - "taxtrans.m"
%   - "utility.m"
%   - "transit.m"
%   - "educ_choice.m"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.a Unpack model elements:
% -------------------------
sim_calib = {'fieldnames','N','T','D','M','J','S','E','H','L','K','R', ...
                'wdbase','nwgrid','edgrid','exgrid','bingrid','lwgrid', ...
                'educyrs','betta','tau','DeltaO','DeltaS','wdbase','weight', ...
                'Tau','NWTest','LSum1','LSum2','Nodis','MPplus','Psi','Omega',...
                'DeltaH1','DeltaH2','Zeta','Xi','Adjust','D_INC'};

sim_var   = {'fieldnames','ic','ed','ex','h','wl','work','spell', ...
                'choice','l','sav','ob','nw','noret','nolab', ...
                'wagel'};

sim_data   = {'fieldnames','spbh','spgh','hbg','hgg'};


%%% unpack model calibration
    v2struct(calib,sim_calib);
    
    v2struct(var,sim_var);
    
    v2struct(data,sim_data);

    v2struct(draws);


%%% Explicit initialization to make parfor-loop work
    nwgrid = calib.nwgrid;
    edgrid = calib.edgrid;
    exgrid = calib.exgrid;
    lwgrid = calib.lwgrid;
    
    Const  = calib.Const;
    
    betta = calib.betta;
    tau = calib.tau;
    D = calib.D; M = calib.M; J = calib.J; S = calib.S; E = calib.E; 
    H = calib.H; R = calib.R; K = calib.K; L = calib.L; Z = calib.Z;
    sav = var.sav;
    
    spbh = data.spbh;
    spgh = data.spgh;
    
    blim  = calib.blim;
    NoWT  = calib.NoWT;
    scWT  = calib.scWT;
    EdFix = calib.EdFix;



%%% Estimated Parameters
    theta_w    = paramhat(   1:M+ 9,1);
    theta_u    = paramhat(M+10:M+14,1);
    phi_o      = paramhat(M+15:M+20,1);
    theta_m    = paramhat(M+21:M+22,1);
    theta_ued  = paramhat(M+23:M+32,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1.b Prepare Simulation
% -----------------------

%%% Path Variables
dV     =zeros(S,E,H,L,D,2,2,M,J,T  );               % value function
C      =zeros(S,E,H,L,D,2,2,M,J,T+1);               % consumption
Y      =zeros(S,E,H,L,D,2,2,M,J,T+1);               % income
GCI    =zeros(S,E,H,L,D,2,2,M,J,T+1);               % gross capital income pre-retirement
ITAX   =zeros(S,E,H,L,D,2,2,M,J,T+1);               % income tax
CTAX   =zeros(S,E,H,L,D,2,2,M,J,T+1);               % capital income tax
SSC    =zeros(S,E,H,L,D,2,2,M,J,T+1);               % social secu contributions
UINS   =zeros(S,E,H,L,D,2,2,M,J,T+1);               % unempl. insurance 
PINS   =zeros(S,E,H,L,D,2,2,M,J,T+1);               % pension insurance
HINS   =zeros(S,E,H,L,D,2,2,M,J,T+1);               % health insurance
UIB    =zeros(S,E,H,L,D,2,2,M,J,T+1);               % unemployment insurance benefits
SAB    =zeros(S,E,H,L,D,2,2,M,J,T+1);               % social assistance benefits
MPB    =zeros(S,E,H,L,D,2,2,M,J,T+1);               % minimum pension benefits
NPB    =zeros(S,E,H,L,D,2,2,M,J,T+1);               % net pension benefits

k      =zeros(S,E,H,L,D,2,2,M,T);                   % rescaling path

P_ed   =zeros(size(educyrs,1),M);                   % empty matrix educ-choice probabilities

%%% Set Type Probabilities
pm      = zeros(M,1);
pm(:,1) = cumsum([theta_m(1:   M-1 ,1)' 1-sum(theta_m(1:   M-1 ,1))],2)';




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Predict Gross Wages and Earnings:
% -------------------------------------

%%% Wage Grids
    % > transform standard-normal support of wage-shock
wdgrid1=wdbase.*sqrt((theta_w(M+8,1)^2)/(1-theta_w(M+1,1)^2));  % stst-distrib. ar1
wdgrid2=wdbase.*      theta_w(M+8,1);                           % only transitory s.d.


% ------------------------------------------------------------------------
%%% gross log-wages
logw=zeros(E,H,L,D,2,2,M);

%%% low-educ / unemployed t-1 / wage-shock from stst-distribution
logw(:,1:2,:,:,:,1,:)=                    repmat(reshape(theta_w(1:M,1),1,1,1,1,1,1,M),[E 2 L D 2    ]) + ...
    theta_w(M+2,1) .*repmat(        edgrid(1:2,1)'./10           ,[E 1 L D 2 1 M]) + ...
    theta_w(M+3,1) .*repmat(        exgrid        ./10           ,[1 2 L D 2 1 M]) + ...
    theta_w(M+5,1) .*repmat(       (exgrid.^2)    ./1000          ,[1 2 L D 2 1 M]) + ...
    theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]) +repmat(reshape(wdgrid1,1,1,1,D),[E 2 L 1 2 1 M]);

%%% low-educ / employed t-1 / wage-shock from ar1-distribution (transitory)
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

%%% high_educ / unemployed t-1
logw(:,3:4,:,:,:,1,:)=                    repmat(reshape(theta_w(1:M,1),1,1,1,1,1,1,M),[E 2 L D 2    ]) + ...
    theta_w(M+2,1) .*repmat(        edgrid(3:4,1)'./10           ,[E 1 L D 2 1 M]) + ...
    theta_w(M+4,1) .*repmat(        exgrid        ./10           ,[1 2 L D 2 1 M]) + ...
    theta_w(M+6,1) .*repmat(       (exgrid.^2)    ./1000          ,[1 2 L D 2 1 M]) + ...
    theta_w(M+7,1) .*repmat(reshape(bingrid       ,1,1,1,1,2    ),[E 2 L D 1 1 M]) +repmat(reshape(wdgrid1,1,1,1,D),[E 2 L 1 2 1 M]);

%%% high-educ / employed t-1
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
wage=52*40.*repmat(reshape(max(exp(logw),8.5),1,E,H,L,D,2,2,M),[S 1]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Job-Offer/Separation Rates:
%  ------------------------------
if Const == 0

    [s,o]=offsep(phi_o,calib);

elseif Const == 1
    a1 = DeltaO;
    a2 = DeltaS;

    % > overwrite in struct
    calib.DeltaO = 0;
    calib.DeltaS = 0;
    
    % > execute derivation
    [s,o]=offsep(phi_o,calib);

    % > re-set in struct
    calib.DeltaO = a1;
    calib.DeltaS = a2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Define Grid of Value Function:
%  ---------------------------------
%%% rectangular grid dim(8,6,4,5) 
[G1,G2,G3,G4]=ndgrid(nwgrid,exgrid,edgrid,lwgrid);
    % for discretized grids of variables


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. Recursive computation of value function and choice probabilities 
%  -------------------------------------------------------------------

for t = T:(-1):1
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Assign consumption levels to choices %    (t) (standard grid)
    % --------------------------------------

    %%% calculate path variables / tax-transfer and pension system
    [y,gci,dis,itax,ctax,ssc,health,pins,unempl,uib,sab,mpb,npb]=taxtrans(t,wage,calib,data);

    %%% Consumption = y - positive savings + dissavings
    c = max((y-max(repmat(reshape(sav,1,1,1,1,1,1,1,1,J),[S E H L D 2 2 M]),-repmat(nwgrid - blim,[1 E H L D 2 2 M J]))+dis)./10000,0);

        % -----------------------------------------------
        % > Keeping Behavior Constant:
        if Const == 1
            z1 = Adjust;
            z2 = Nodis;
            z3 = Omega;
            z4 = Xi;
            z5 = Psi;
            z6 = Zeta;
            z7 = MPplus;

            calib.Adjust    = 0;
            calib.Nodis     = 0;
            calib.Omega     = 0;
            calib.Xi        = 0;
            calib.Psi       = 0;
            calib.Zeta      = 0;
            calib.MPplus    = 0;

            [y,gci,dis,itax,ctax,ssc,health,pins,unempl,uib,sab,mpb,npb]=taxtrans(t,wage,calib,data);
        
            c = max((y-max(repmat(reshape(sav,1,1,1,1,1,1,1,1,J),[S E H L D 2 2 M]),-repmat(nwgrid - blim,[1 E H L D 2 2 M J]))+dis)./10000,0);

            calib.Adjust    = z1;
            calib.Nodis     = z2;
            calib.Omega     = z3;
            calib.Xi        = z4;
            calib.Psi       = z5;
            calib.Zeta      = z6;
            calib.MPplus    = z7;
        end

    %%% Save Path Variables
    C(:,:,:,:,:,:,:,:,:,t)      = c*10000;
    Y(:,:,:,:,:,:,:,:,:,t)      = y;
    GCI(:,:,:,:,:,:,:,:,:,t)    = gci;
    ITAX(:,:,:,:,:,:,:,:,:,t)   = itax;
    CTAX(:,:,:,:,:,:,:,:,:,t)   = ctax;
    SSC(:,:,:,:,:,:,:,:,:,t)    = ssc;
    UINS(:,:,:,:,:,:,:,:,:,t)   = unempl;
    PINS(:,:,:,:,:,:,:,:,:,t)   = pins;
    HINS(:,:,:,:,:,:,:,:,:,t)   = health;
    UIB(:,:,:,:,:,:,:,:,:,t)    = uib;
    SAB(:,:,:,:,:,:,:,:,:,t)    = sab;
    MPB(:,:,:,:,:,:,:,:,:,t)    = mpb;
    NPB(:,:,:,:,:,:,:,:,:,t)    = npb;    


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

        %%% reassignment of age T flow utility 
        v = u;
        x = u;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Calculate Path Variables T+1 (compulsory retirement)
        % ------------------------------------------------------
        %%% tax-transfer system
        [y,gci,dis,itax,ctax,ssc,health,pins,unempl,uib,sab,mpb,npb] = taxtrans(t+1,wage,calib,data);

        %%% consumption
        c = max((y-max(repmat(reshape(sav,1,1,1,1,1,1,1,1,J),[S E H L D 2 2 M]),-repmat(nwgrid - blim,[1 E H L D 2 2 M J]))+dis)./10000,0);

            % -----------------------------------------------
            % > Keeping Behavior Constant:
            if Const == 1
                z1 = Adjust;
                z2 = Nodis;
                z3 = Omega;
                z4 = Xi;
                z5 = Psi;
                z6 = Zeta;
                z7 = MPplus;
    
                calib.Adjust    = 0;
                calib.Nodis     = 0;
                calib.Omega     = 0;
                calib.Xi        = 0;
                calib.Psi       = 0;
                calib.Zeta      = 0;
                calib.MPplus    = 0;
    
                [y,gci,dis,itax,ctax,ssc,health,pins,unempl,uib,sab,mpb,npb]=taxtrans(t+1,wage,calib,data);
            
                c=max((y-max(repmat(reshape(sav,1,1,1,1,1,1,1,1,J),[S E H L D 2 2 M]),-repmat(nwgrid - blim,[1 E H L D 2 2 M J]))+dis)./10000,0);
    
                calib.Adjust    = z1;
                calib.Nodis     = z2;
                calib.Omega     = z3;
                calib.Xi        = z4;
                calib.Psi       = z5;
                calib.Zeta      = z6;
                calib.MPplus    = z7;
            end


        %%% save path variables
        C(:,:,:,:,:,:,:,:,:,t+1)    = c*10000;
        Y(:,:,:,:,:,:,:,:,:,t+1)    = y;
        GCI(:,:,:,:,:,:,:,:,:,t+1)  = gci;
        ITAX(:,:,:,:,:,:,:,:,:,t+1) = itax;
        CTAX(:,:,:,:,:,:,:,:,:,t+1) = ctax;
        SSC(:,:,:,:,:,:,:,:,:,t+1)  = ssc;
        UINS(:,:,:,:,:,:,:,:,:,t+1) = unempl;
        PINS(:,:,:,:,:,:,:,:,:,t+1) = pins;
        HINS(:,:,:,:,:,:,:,:,:,t+1) = health;
        UIB(:,:,:,:,:,:,:,:,:,t+1)  = uib;
        SAB(:,:,:,:,:,:,:,:,:,t+1)  = sab;
        MPB(:,:,:,:,:,:,:,:,:,t+1)  = mpb;
        NPB(:,:,:,:,:,:,:,:,:,t+1)  = npb;      


        %%% flow utility T+1
        u = utility(c,l,theta_u,calib,var);

        %%% compulsory retirement at age T+1
        %   > replicate derived pension utility on all choices
        x(:,:,:,:,:,:,:,:,1:J-1) = repmat(u(:,:,:,:,:,:,:,:,J),[1 1 1 1 1 1 1 1 J-1]);

        w = x;

        
        % --------------------------------------------
        %%% Derive Continuation Values T+1
            % > loop over time T choices (without retirement)

            for j = 1:J-1                     % savings choice
                for a = 1:2                   % lagged employment status
                    for d = 1:2               % health status
                        for e = 1:D           % wage shock grid (not t-dependent, already evaluated)
                            %%% Path variables:
                            % Net Wealth Transition
                            if NoWT == 0
                                nwbar = nwgrid*(1+tau)-max(nwgrid*tau-801,0)*0.25*1.055+max(sav(j),-(nwgrid-blim));
                            elseif NoWT == 1
                                nwbar = nwgrid*(1+tau)-max(nwgrid*tau-801,0)*0.25*scWT+max(sav(j),-(nwgrid-blim));
                            end

                            % Experience:
                            if j<=K
                                exbar=exgrid+1;
                            else
                                exbar=exgrid;
                            end

                            % combined T+1 grid: netwealth, exp, educ, lag-wage
                            [B1,B2,B3,B4] = ndgrid(nwbar,exbar,edgrid,lwgrid);

                            for m=1:M
                                F = griddedInterpolant(G1,G2,G3,G4,w(:,:,:,:,e,d,a,m,j),'linear');
                                x(:,:,:,:,e,d,a,m,j)=F(B1,B2,B3,B4);   % continuation values T+1
                            end

                        end
                    end
                end
            end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Compute Expected Utility of remaining lifetime in T
        % ------------------------------------------------------   
        for i=1:(80-t+1)
            v(:,:,1:2,:,:,1,:,:,:)=v(:,:,1:2,:,:,1,:,:,:)+betta^i.*prod(spbh(t:t+i-1,t,1),1).*(x(:,:,1:2,:,:,1,:,:,:));
            v(:,:,1:2,:,:,2,:,:,:)=v(:,:,1:2,:,:,2,:,:,:)+betta^i.*prod(spgh(t:t+i-1,t,1),1).*(x(:,:,1:2,:,:,2,:,:,:));
            v(:,:,3:4,:,:,1,:,:,:)=v(:,:,3:4,:,:,1,:,:,:)+betta^i.*prod(spbh(t:t+i-1,t,2),1).*(x(:,:,3:4,:,:,1,:,:,:));
            v(:,:,3:4,:,:,2,:,:,:)=v(:,:,3:4,:,:,2,:,:,:)+betta^i.*prod(spgh(t:t+i-1,t,2),1).*(x(:,:,3:4,:,:,2,:,:,:));
        end            


    %%%%%%%%%%%%%%%%%%%%%%%%
    % Period t<T %
    % ------------- 
    
    elseif t<T

        %%% reassign value function to derive continuation values           
        w = v;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Compute Expected Utility of remaining LifeTime in t
        % ------------------------------------------------------ 
        
        %%% Labor-Supply Choice (non-early ret)
        for j = 1:J-1
            
            x = u; % required to run parfor loop

            %%% Interpolation to t+1 Grid
            for a = 1:2
                for d = 1:2
                    for e = 1:D

                        if NoWT == 0
                            nwbar = nwgrid*(1+tau)-max(nwgrid*tau-801,0)*0.25*1.055+max(sav(j),-(nwgrid-blim));
                        elseif NoWT == 1
                            nwbar = nwgrid*(1+tau)-max(nwgrid*tau-801,0)*0.25*scWT+max(sav(j),-(nwgrid-blim));
                        end

                        if j<=K
                            exbar = exgrid+1;
                        else
                            exbar = exgrid;
                        end

                        [B1,B2,B3,B4] = ndgrid(nwbar,exbar,edgrid,lwgrid);

                        for z=1:J          
                            for m=1:M
                                F = griddedInterpolant(G1,G2,G3,G4,w(:,:,:,:,e,d,a,m,z),'linear');
                                x(:,:,:,:,e,d,a,m,z) = F(B1,B2,B3,B4);
                            end
                        end

                    end
                end
            end


            %%% early retirement restricted %%%
            if t <= 43                       
                x(:,:,:,:,:,2,:,:,J)   =-inf;
            end

            if t <= 10
                x(:,:,:,:,:,1,:,:,J)   =-inf;
            end


            %%% employment restricted in t+1 %%%
            x1=x;                            
            x2=x;
            x2(:,:,:,:,:,:,:,:,1:K)    =-inf;


            % -------------------------------------------------
            %%% Bellman-Equation
            temp1=zeros(S,E,H,L,D,2,2,M,3);
            temp2=zeros(S,E,H,L,D,2,2,M,3);

            temp1(:,:,:,:,:,:,:,:,1)=max(x1(:,:,:,:,:,:,:,:,  1:K  ),[],9);
            temp1(:,:,:,:,:,:,:,:,2)=max(x1(:,:,:,:,:,:,:,:,K+1:J-1),[],9);
            temp1(:,:,:,:,:,:,:,:,3)=max(x1(:,:,:,:,:,:,:,:,    J  ),[],9);
            temp2(:,:,:,:,:,:,:,:,1)=max(x2(:,:,:,:,:,:,:,:,  1:K  ),[],9); % all -inf !!
            temp2(:,:,:,:,:,:,:,:,2)=max(x2(:,:,:,:,:,:,:,:,K+1:J-1),[],9);
            temp2(:,:,:,:,:,:,:,:,3)=max(x2(:,:,:,:,:,:,:,:,    J  ),[],9);


            %%% alternative-specific value functions
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

        end     % j-loop
    
    

        %%% Early Retirement
        v(:,:,:,:,:,:,:,:,J)=u(:,:,:,:,:,:,:,:,J); 
        
        % > early retirement years up to 64; 
        for i=1:T-t
            v(:,:,1:2,:,:,1,:,:,J)=v(:,:,1:2,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,1,:,:,J));
            v(:,:,1:2,:,:,2,:,:,J)=v(:,:,1:2,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,2,:,:,J));
            v(:,:,3:4,:,:,1,:,:,J)=v(:,:,3:4,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,1,:,:,J));
            v(:,:,3:4,:,:,2,:,:,J)=v(:,:,3:4,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,2,:,:,J));
        end

        % > retirement post age 65    
        for i=T-t+1:(80-t+1)
            v(:,:,1:2,:,:,1,:,:,J)=v(:,:,1:2,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,1,:,:,J));
            v(:,:,1:2,:,:,2,:,:,J)=v(:,:,1:2,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,1),1).*(u(:,:,1:2,:,:,2,:,:,J));
            v(:,:,3:4,:,:,1,:,:,J)=v(:,:,3:4,:,:,1,:,:,J)+betta^i.*prod(spbh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,1,:,:,J));
            v(:,:,3:4,:,:,2,:,:,J)=v(:,:,3:4,:,:,2,:,:,J)+betta^i.*prod(spgh(t:t+i-1,t,2),1).*(u(:,:,3:4,:,:,2,:,:,J));
        end

    end     % if t=/<T


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compute Constant for Rescaling %
    % --------------------------------
    k(:,:,:,:,:,:,:,:,t) = repmat(min(min(min(min(min(min(min(min(v,[],1),[],2),[],3),[],4),[],5),[],6),[],7),[],9),[S E H L D 2 2]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Save Age-t Value Function %
    % ---------------------
    dV(:,:,:,:,:,:,:,:,:,t)=v;


end     % recursive loop



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6. Education Choice  %
% ------------------------
[V_ed,U_ed,Temp_ed] = educ_choice(dV,o,theta_ued,calib,var,data);
    dV_ed = V_ed;

%%% Rescale Education Value Function
V_ed = V_ed - repmat(max(V_ed,[],1),[size(educyrs,1) 1]);


%%% Compute Education Choice Probabilities
for j = 1:size(educyrs,1)
    P_ed(j,:) = max( exp(V_ed(j,:))./(sum(exp(V_ed(:,:)),1))  ,1e-10);
end

%%% Prepare for Simulation
P_edsum = cumsum(P_ed,1);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7. Rescale value function %
% ------------------------
V = dV - repmat(max(dV,[],9),[1 1 1 1 1 1 1 1 J]);
    % > along time t choices J



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8.Simulation Preparation: Model Solution

%%% write to struct
    sim_sol.V       = V;
    sim_sol.U_ed    = U_ed;
    sim_sol.Temp_ed = Temp_ed;
    sim_sol.dV_ed   = dV_ed;
    sim_sol.V_ed    = V_ed;
    sim_sol.P_ed    = P_ed;
    sim_sol.pm      = pm;
    sim_sol.P_edsum = P_edsum;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 9. Preparation of Life-Cycle Paths:
%%% NOTES:
%   - simulation procedure allows for parallel computation of individual
%       life-cycle paths
%   - Current Implementation: R=50000 individual paths simulated split on Z=8
%       cores

% -----------------------------------------------------
%%% Prepare Random Components (use generated randoms)

        drandom1 = zeros(R/Z,1,Z);
        drandom2 = zeros(R/Z,T+1,Z);
        drandom3 = zeros(R/Z,T+1,Z);
        drandom_ed = zeros(R/Z,1,Z);
        dWShock1_path = zeros(R/Z,T,Z);
        dWShock2_path = zeros(R/Z,T,Z);
        dMError = zeros(R/Z,T+1,Z);

        dEduc_b = zeros(1,1,Z);

        for z = 1:Z
            drandom1(:,:,z)     = random1((z-1)*R/Z+1:z*R/Z,:); %#ok<*NODEF>
            drandom2(:,:,z)     = random2((z-1)*R/Z+1:z*R/Z,:);
            drandom3(:,:,z)     = random3((z-1)*R/Z+1:z*R/Z,:);
            drandom_ed(:,:,z)   = random_ed((z-1)*R/Z+1:z*R/Z,:);

            dWShock1_path(:,:,z) = WShock1_path((z-1)*R/Z+1:z*R/Z,:);
            dWShock2_path(:,:,z) = WShock2_path((z-1)*R/Z+1:z*R/Z,:);

            dMError(:,:,z)      = MError((z-1)*R/Z+1:z*R/Z,:);
            
            if EdFix == 0
                dEduc_b(:,:,z) = nan(1);
            elseif EdFix == 1
                dEduc_b(:,:,z)   = calib.Educ_b((z-1)*R/Z+1:z*R/Z,:);
            end

        end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 11. Simulate Live Cycle Paths - Parallelized:
%  ---------------------------------------
%%% NOTES:
%   - dim3/pages implementation for z-Loop to make parfor work
%     (restrictions on valid index for slicing vars)

% T_parsim = tic;
%ticBytes(gcp);
parfor z = 1:Z          % parallel loop is optional
%for z = 1:Z

    %%% Extract correct section of randoms for parloop iteration
    random1     = drandom1(:,:,z);
    random2     = drandom2(:,:,z);
    random3     = drandom3(:,:,z);
    random_ed   = drandom_ed(:,:,z);

    WShock1_path = dWShock1_path(:,:,z);
    WShock2_path = dWShock2_path(:,:,z); 
    MError       = dMError(:,:,z);        
    
    Educ_b = dEduc_b(:,:,z);


    %%% Execute Simulation of Subsample
    [sim_path] = parsim(calib,var,data,paramhat,sim_sol,random1,random2,random3,random_ed,WShock1_path,WShock2_path,MError,wdgrid1,wdgrid2,Educ_b);

   
    %%% Write Results to Summary Path Variables 
    pC_path(:,:,z)       = sim_path.C_path;
    pY_path(:,:,z)       = sim_path.Y_path;
    pGCI_path(:,:,z)     = sim_path.GCI_path;
    pCTAX_path(:,:,z)    = sim_path.CTAX_path;
    pITAX_path(:,:,z)    = sim_path.ITAX_path;
    pSSC_path(:,:,z)     = sim_path.SSC_path;
    pHINS_path(:,:,z)    = sim_path.HINS_path;
    pMPB_path(:,:,z)     = sim_path.MPB_path;
    pEPB_path(:,:,z)     = sim_path.EPB_path;
    pDPB_path(:,:,z)     = sim_path.DPB_path;
    pNPB_path(:,:,z)     = sim_path.NPB_path;
    pExper_path(:,:,z)   = sim_path.Exper_path;
    pSav_path(:,:,z)     = sim_path.Sav_path;
    pSavChoice_path(:,:,z) = sim_path.SavChoice_path;

    pFav_path(:,:,z)     = sim_path.Fav_path;

    pUINS_path(:,:,z)    = sim_path.UINS_path;
    pPINS_path(:,:,z)    = sim_path.PINS_path;
    pWAGE_path(:,:,z)    = sim_path.WAGE_path;
    pWAGE2_path(:,:,z)   = sim_path.WAGE2_path;
    pWShock2_path(:,:,z) = sim_path.WShock2_path;   % rename to match sizes
    pUIB_path(:,:,z)     = sim_path.UIB_path;
    pSAB_path(:,:,z)     = sim_path.SAB_path;
    pEmpl_path(:,:,z)    = sim_path.Empl_path;
    pReti_path(:,:,z)    = sim_path.Reti_path;    

    pHealth_path(:,:,z)  = sim_path.Health_path;
    pPov_path(:,:,z)     = sim_path.Pov_path;

    pType(:,:,z)         = sim_path.Type;
    pEduc(:,:,z)         = sim_path.Educ;

    pExpRatio_path(:,:,z) = sim_path.ExpRatio_path;

    pWealth_path(:,:,z) = sim_path.Wealth_path;

    
end
%disp('-------------------------------------------------------------------')
%disp('Bytes transferred within par-pool to workers:')
%tocBytes(gcp);
%toc



%%% Convert Dimension Back
for z = 1:Z
    if z == 1
        C_path      = pC_path(:,:,z);
        Y_path      = pY_path(:,:,z);
        GCI_path    = pGCI_path(:,:,z);
        CTAX_path   = pCTAX_path(:,:,z);
        ITAX_path   = pITAX_path(:,:,z);
        SSC_path    = pSSC_path(:,:,z);
        HINS_path   = pHINS_path(:,:,z);
        MPB_path    = pMPB_path(:,:,z);
        EPB_path    = pEPB_path(:,:,z);
        DPB_path    = pDPB_path(:,:,z);
        NPB_path    = pNPB_path(:,:,z);
        Exper_path  = pExper_path(:,:,z);
        Sav_path    = pSav_path(:,:,z);
        SavChoice_path = pSavChoice_path(:,:,z);

        Fav_path    = pFav_path(:,:,z);

        UINS_path   = pUINS_path(:,:,z);
        PINS_path   = pPINS_path(:,:,z);
        WAGE_path   = pWAGE_path(:,:,z);
        WAGE2_path  = pWAGE2_path(:,:,z);
        p2WShock2_path = pWShock2_path(:,:,z);
        UIB_path    = pUIB_path(:,:,z);
        SAB_path    = pSAB_path(:,:,z);
        Empl_path   = pEmpl_path(:,:,z);
        Reti_path   = pReti_path(:,:,z);

        Health_path = pHealth_path(:,:,z);
        Pov_path    = pPov_path(:,:,z);
        
        Type        = pType(:,:,z);
        Educ        = pEduc(:,:,z);

        ExpRatio_path = pExpRatio_path(:,:,z);

        Wealth_path = pWealth_path(:,:,z);

    else
        C_path      = [C_path;pC_path(:,:,z)]; %#ok<*AGROW>
        Y_path      = [Y_path;pY_path(:,:,z)];
        GCI_path    = [GCI_path;pGCI_path(:,:,z)];
        CTAX_path   = [CTAX_path;pCTAX_path(:,:,z)];
        ITAX_path   = [ITAX_path;pITAX_path(:,:,z)];
        SSC_path    = [SSC_path;pSSC_path(:,:,z)];
        HINS_path   = [HINS_path;pHINS_path(:,:,z)];
        MPB_path    = [MPB_path;pMPB_path(:,:,z)];
        EPB_path    = [EPB_path;pEPB_path(:,:,z)];
        DPB_path    = [DPB_path;pDPB_path(:,:,z)];
        NPB_path    = [NPB_path;pNPB_path(:,:,z)];
        Exper_path  = [Exper_path;pExper_path(:,:,z)];
        Sav_path    = [Sav_path;pSav_path(:,:,z)];
        SavChoice_path    = [SavChoice_path;pSavChoice_path(:,:,z)];

        Fav_path    = [Fav_path;pFav_path(:,:,z)];

        UINS_path   = [UINS_path;pUINS_path(:,:,z)];
        PINS_path   = [PINS_path;pPINS_path(:,:,z)];
        WAGE_path   = [WAGE_path;pWAGE_path(:,:,z)];
        WAGE2_path  = [WAGE2_path;pWAGE2_path(:,:,z)];
        p2WShock2_path = [p2WShock2_path;pWShock2_path(:,:,z)];
        UIB_path    = [UIB_path;pUIB_path(:,:,z)];
        SAB_path    = [SAB_path;pSAB_path(:,:,z)];
        Empl_path   = [Empl_path;pEmpl_path(:,:,z)];
        Reti_path   = [Reti_path;pReti_path(:,:,z)];

        Health_path = [Health_path;pHealth_path(:,:,z)];
        Pov_path    = [Pov_path;pPov_path(:,:,z)];

        Type        = [Type;pType(:,:,z)];
        Educ        = [Educ;pEduc(:,:,z)];

        ExpRatio_path    = [ExpRatio_path;pExpRatio_path(:,:,z)];

        Wealth_path = [Wealth_path;pWealth_path(:,:,z)];
    end
    
    

end

    WShock2_path = p2WShock2_path;


%%% Write Path Variables to Struct
sim_path = v2struct(C_path,Y_path,GCI_path,ITAX_path,CTAX_path,SSC_path,UINS_path,PINS_path, ...
                   HINS_path,WAGE_path,WAGE2_path,WShock2_path,UIB_path,SAB_path,MPB_path, ...
                   EPB_path,DPB_path,NPB_path,Type,Educ,Empl_path,Reti_path,Health_path, ...
                   Wealth_path,Sav_path,Exper_path,Pov_path,Fav_path,SavChoice_path,ExpRatio_path);




end         % function end