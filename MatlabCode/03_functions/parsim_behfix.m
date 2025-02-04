function [sim_path] = parsim_behfix(calib,var,data,base)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parallelized simulation of life-cycle paths - Behavior fixed to baseline %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack Model Parameters and Variables:
%  --------------------------------------
sim_calib = {'fieldnames','N','T','D','M','J','S','E','H','L','K','R', ...
                'wdbase','nwgrid','edgrid','exgrid','bingrid','lwgrid', ...
                'educyrs','betta','tau','DeltaO','DeltaS','wdbase','weight', ...
                'Tau','NWTest','LSum1','LSum2','Nodis','MPplus','Psi','Omega',...
                'DeltaH1','DeltaH2','Zeta','Xi','Adjust','D_INC','Z',...
                'NoWT','TaxLT','scWT',...
                'regalw','LTalpha','LTbeta','MeanExpRatio'};

sim_data   = {'fieldnames','spbh','spgh'};

%%% unpack model parameters
    v2struct(calib,sim_calib); 
    sav = var.sav;   
    v2struct(data,sim_data);

    blim = calib.blim;
    wealth_llim = -50000;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Preparation of Life-Cycle Paths and Addional Settings:
%  -------------------------------------------------------

% -----------------------------------
%%% Configuration TaxTransfer-System 
    sscuw  = 6200*12;            % maximum contributions
    h_i    =       0.147/2;      % health insurance contribution
    r_i    = (0.187+Tau)/2;      % pension insurance contribution
    u_i    =        0.03/2;      % unemployment insurance contribution
    

% -----------------------------------
%%% Define Path Array:
    % > fixed to baseline
    Type        = base.Type;
    Educ        = base.Educ;
    Reti_path   = base.Reti;
    Empl_path   = base.Empl;
    Exper_path  = base.Exper;
    Health_path = base.Health;

    WAGE_path   = base.WAGE;
    WAGE2_path  = base.WAGE2;
    WShock2_path = base.WShock2;

    SavChoice_path = base.SavChoice;


    C_path     =zeros(R/Z,T+1);               % consumption
    Y_path     =zeros(R/Z,T+1);               % income
    GCI_path   =zeros(R/Z,T+1);               % gross capital income
        % > not required; SavChoice j from baseline
        %V_path     =zeros(R/Z,T+1,3);             % value function
        %P_path     =zeros(R/Z,T+1,3);             % probability 3 employment choices (empl, unempl, ret)
        %TEMP_path  =zeros(R/Z,T+1,J);
    ITAX_path  =zeros(R/Z,T+1);               % income tax
    CTAX_path  =zeros(R/Z,T+1);               % capital tax
    SSC_path   =zeros(R/Z,T  );               % social secu contributions
    UINS_path  =zeros(R/Z,T  );               % unemployment insurance
    PINS_path  =zeros(R/Z,T  );               % pension insurance
    HINS_path  =zeros(R/Z,T  );               % health insurance

    UIB_path   =zeros(R/Z,T  );               % unemployment benefits
    SAB_path   =zeros(R/Z,T  );               % social assistance benefits
    GPB_path   =zeros(R/Z,T+1,2);             % gross pension benefits
    MPB_path   =zeros(R/Z,T+1);               % minimum pension benefits
    EPB_path   =zeros(R/Z,T+1);       
    DPB_path   =zeros(R/Z,T+1);
    NPB_path   =zeros(R/Z,T+1);               % net pension benefits
    NPP_path   =zeros(R/Z,T+1,2);             % net pension points
  
    Wealth_path=zeros(R/Z,T+1);
    Sav_path   =zeros(R/Z,T+1);               % savings
    Fav_path   =zeros(R/Z,T+1);               % fair-annuity

    ExpRatio_path   =ones(R/Z,T+1);          % Experience Ratio path (derived from baseline Exper_path



    for r = 1:R/Z    % Number of Observations in simulated Subsample      
        
     
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Draws for Ability Type
        % -------------------------
        % >>> fixed to baseline
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Derive Education Choice
        % -------------------------            
        % >>> fixed to baseline
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Start Simulation of Life-Cycle
        % --------------------------------
        for t = 1 + 1*(Educ(r,1)>12)*(Educ(r,1)-12):T
                         
            % > age at start of life-cycle cond. on education choice
    
            % > k=12 > entry at t=1 / age 20
            % > k=13 > entry at t=2 / age 21
    
            % >>> entry in LC: k+8 (first year in labor market)
    
            % --------------------
            %%% Initial Status
            % >>> fixed to baseline
        
        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% Dynamic Simulations
            % ----------------------
    
            % -----------------------
            %%% Non-Retired
            if Reti_path(r,t) == 1

                %%% Experience-ratio
                if t == 1
                    ExpRatio_path(r,t) = 0;
                else
                    if t == 1 + 1*(Educ(r,1)>12)*(Educ(r,1)-12)
                        ExpRatio_path(r,t) = 0;
                    else
                        ExpRatio_path(r,t) = (Exper_path(r,t)/((t-1) - (Educ(r,1)>12)*(Educ(r,1)-12)));
                    end
                end  


                %%% Assign Value Function to choices in t cond. on state
                % for j=1:J
                %     % > derive interpolant cond. on lagged employment status
                %     if     Empl_path(r,t)==1
                %         F=griddedInterpolant(G1,G2,G3,G4,G5 ,V(:,:,:,:,:,Health_path(r,t),Empl_path(r,t),Type(r,1),j,t),'linear');
                %     elseif Empl_path(r,t)==2
                %         F=griddedInterpolant(G6,G7,G8,G9,G10,V(:,:,:,:,:,Health_path(r,t),Empl_path(r,t),Type(r,1),j,t),'linear');
                %     end
                % 
                %     % > query interpolant
                %     if t==1+1*(Educ(r,1)>12)*(Educ(r,1)-12)         % entry age life-cycle
                %         if     Empl_path(r,t)==1
                %             TEMP_path(r,t,j)=F(Wealth_path(r,t),Exper_path(r,t),Educ(r,1),                                    2 ,WShock1_path(r,t));
                %         elseif Empl_path(r,t)==2    % > never occurs in first period?!
                %             TEMP_path(r,t,j)=F(Wealth_path(r,t),Exper_path(r,t),Educ(r,1),                                    2 ,WShock2_path(r,t));
                %         end
                %             % > query for entry age: nw=0; exp=0; ?
                % 
                %     else   
                %         if     Empl_path(r,t)==1
                %             TEMP_path(r,t,j)=F(Wealth_path(r,t),Exper_path(r,t),Educ(r,1),max(log((WAGE_path(r,t-1)/(52*40))),2),WShock1_path(r,t));
                %         elseif Empl_path(r,t)==2
                %             TEMP_path(r,t,j)=F(Wealth_path(r,t),Exper_path(r,t),Educ(r,1),max(log((WAGE_path(r,t-1)/(52*40))),2),WShock2_path(r,t));
                %         end
                %     end
                % 
                % end
    
                %%% Early Retirement Restricion
                % if t <= 10 || (Health_path(r,t) == 2 && t <= 43)
                %     TEMP_path(r,t,J) = -inf;
                % end            
                % 
                % 
                % %%% Value Function / maximize over savings choices
                % V_path(r,t,1) = max(TEMP_path(r,t,  1:K  ),[],3);
                % V_path(r,t,2) = max(TEMP_path(r,t,K+1:J-1),[],3);
                % V_path(r,t,3) = max(TEMP_path(r,t,    J  ),[],3);
                % 
                % 
                % %%% Derive Offer/Separation Probability
                % off=o(1+((Educ(r,1)>=12)*2),Health_path(r,t),Type(r,1),t);
                % sep=s(1+((Educ(r,1)>=12)*2),Health_path(r,t),Type(r,1),t);            
                % 
                % 
                % %%% Calibrate Offer Probability at Labor Market entry
                % if  t==1+1*(Educ(r,1)>12)*(Educ(r,1)-12)
                %         a1 = DeltaO;
                % 
                %         % > overwrite in struct
                %         calib.DeltaO = 0;
                % 
                %         % > derive offers
                %         off=o(1+((Educ(r,1)>=12)*2),Health_path(r,t),Type(r,1),t) * 2;
                % 
                %         % > re-set in struct
                %         calib.DeltaO = a1;
                % end
                

                % -------------------------------
                %%% Choice & Choice Probabilities
                % for j=1:3
                % 
                %     if  t==1+1*(Educ(r,1)>12)*(Educ(r,1)-12)        % life-cycle entry
                % 
                %         P_path(r,t,j)=   off .*((exp(V_path(r,t,j)))            ./sum(squeeze(exp(V_path(r,t,:)))       ,1))+ ...
                %                       (1-off).*((exp(V_path(r,t,j)).*nolab(j,1))./sum(squeeze(exp(V_path(r,t,:))).*nolab,1));
                % 
                % 
                %     else
                % 
                %         P_path(r,t,j)=  (Empl_path(r,t)-1) .*(   sep .*((exp(V_path(r,t,j)).*nolab(j,1))./sum(squeeze(exp(V_path(r,t,:))).*nolab,1)) + ...
                %                                               (1-sep).*((exp(V_path(r,t,j))            )./sum(squeeze(exp(V_path(r,t,:)))       ,1)))+ ...
                %                      (1-(Empl_path(r,t)-1)).*(   off .*((exp(V_path(r,t,j))            )./sum(squeeze(exp(V_path(r,t,:)))       ,1)) + ...
                %                                               (1-off).*((exp(V_path(r,t,j)).*nolab(j,1))./sum(squeeze(exp(V_path(r,t,:))).*nolab,1)));
                % 
                %     end
                % end
    
    
                %%% CCP Path / Employment Choice of Individual
                % P_path(r,t,:) = cumsum(P_path(r,t,:),3);
                % 
                %     j = 1;                                         
                %     while P_path(r,t,j) < random2(r,t)
                %         j=j+1;
                %     end     
                %     % > after loop, j = (1,2,3) indicates choice of individual
                % 
                % 
                % %%% Deteremine Optimal Saving Choice
                % if     j==1          % employed      
                %     i=1;
                %     while TEMP_path(r,t,i)<max(TEMP_path(r,t,1:K),[],3)
                %         i=i+1;
                %     end
                %     j=i;
                % elseif j==2          % unemployed
                %     i=1;
                %     while TEMP_path(r,t,K+i)<max(TEMP_path(r,t,K+1:J-1),[],3)
                %         i=i+1;
                %     end
                %     j=K+i;
                % elseif j==3         % retirement
                %     j=J;
                % end
                    % > returns j with position of optimal savings choice
                    %    (among J alternatives)
                
                
                %Reti_path(r,t)
                %SavChoice_path(r,t)

                % --------------------------------------
                %%% Compute Tax-Transfer Variables
                
                %%% > if choice is non-retirement
                %if j<=J-1
                if SavChoice_path(r,t) <= J-1
    
                    %%% > derive wage-path
                    % >>> fixed to baseline

    
                    %%% > Derive Tax-Transfer Paths
                    bg =max(WAGE_path(r,t)-1000,0);
                    bg1=((bg- 8652)./10000);
                    bg2=((bg-13669)./10000);
    
                    ITAX_path(r,t)=               1.*(bg>=8653) .*(bg<=13669).*((993.62*bg1+1400).*bg1);
                    ITAX_path(r,t)=ITAX_path(r,t)+1.*(bg>=13670).*(bg<=53665).*((225.40*bg2+2397).*bg2+952.48);
                    ITAX_path(r,t)=ITAX_path(r,t)+1.*(bg>=53666)             .*((0.42*bg)-8394.14);
    
                    if NoWT == 0
                        ITAX_path(r,t)=ITAX_path(r,t).*1.055;
                    elseif NoWT == 1
                        ITAX_path(r,t)=ITAX_path(r,t).*scWT;
                    end
    
                    GCI_path(r,t)=Wealth_path(r,t).*tau;
    
                    if NoWT == 0                      
                        CTAX_path(r,t)=max(GCI_path(r,t)-801,0).*0.25.*1.055;
                    elseif NoWT == 1
                        CTAX_path(r,t)=max(GCI_path(r,t)-801,0).*0.25.*scWT;
                    end

                    if TaxLT == 1 
                        ITAX_path(r,t) = ITAX_path(r,t) * (1 + LTalpha*(ExpRatio_path(r,t)-MeanExpRatio(t))*(ExpRatio_path(r,t)>=MeanExpRatio(t)) - LTbeta*(MeanExpRatio(t)-ExpRatio_path(r,t))*(ExpRatio_path(r,t)<MeanExpRatio(t)));
                        CTAX_path(r,t) = CTAX_path(r,t) * (1 + LTalpha*(ExpRatio_path(r,t)-MeanExpRatio(t))*(ExpRatio_path(r,t)>=MeanExpRatio(t)) - LTbeta*(MeanExpRatio(t)-ExpRatio_path(r,t))*(ExpRatio_path(r,t)<MeanExpRatio(t)));                    
                    end


                    UINS_path(r,t)=min(u_i.*WAGE_path(r,t),u_i*sscuw);
    
                    HINS_path(r,t)=min(h_i.*WAGE_path(r,t),h_i*0.75*sscuw);
    
                    PINS_path(r,t)=min((r_i+Psi.*(WAGE_path(r,t)./36187).*(WAGE_path(r,t)>36187)+Omega).*WAGE_path(r,t),r_i*sscuw);
    
                    SSC_path(r,t)=UINS_path(r,t)+HINS_path(r,t)+PINS_path(r,t);
    
                end           
    
    
                %%% > if choice is unemployment or retirement
                if SavChoice_path(r,t)>K && SavChoice_path(r,t)<=J-1            % > unemployment
    
                    if t>1+1*(Educ(r,1)>12)*(Educ(r,1)-12)
                        UIB_path(r,t)=0.6.*(WAGE_path(r,t-1)-ITAX_path(r,t-1)-SSC_path(r,t-1))      .*(Empl_path(r,t)==2);
                    end
    
                    if NoWT == 0
                        SAB_path(r,t)=(regalw*12-max(min(regalw*12,Wealth_path(r,t)-NWTest(t,1)),0)).*(Empl_path(r,t)==1);
                    elseif NoWT == 1
                        SAB_path(r,t)=(regalw*12).*(Empl_path(r,t)==1);
                    end

                    %WAGE_path(r,t)  =0;
                    ITAX_path(r,t)  =0;
                    UINS_path(r,t)  =0;
                    HINS_path(r,t)  =0;
                    PINS_path(r,t)  =0;
                    SSC_path(r,t)   =0;
    
    
                elseif SavChoice_path(r,t) == J                 % > retirement
    
                    NPP_path(r,t,1)=NPP_path(r,t,1)+(Health_path(r,t)==1).*max((60-(t+19)),0).*NPP_path(r,t,1)./max((t+19-Educ(r,1)-7),1);
    
                    GPB_path(r,t,1)=NPP_path(r,t,1).*30.45.*12.*(1+Zeta.*(((NPP_path(r,t,1).*30.45.*12)-(40.*30.45.*12))./(40.*30.45.*12)).*((NPP_path(r,t,1).*30.45.*12)>(40.*30.45.*12))+Xi);
                    GPB_path(r,t,2)=NPP_path(r,t,2).*30.45.*12.*(1+Zeta.*(((NPP_path(r,t,2).*30.45.*12)-(40.*30.45.*12))./(40.*30.45.*12)).*((NPP_path(r,t,2).*30.45.*12)>(40.*30.45.*12))+Xi);
    
                    GPB_path(r,t,1)=GPB_path(r,t)-min(max(63-(t+19),0),3).*0.036.*GPB_path(r,t);
                    GPB_path(r,t,2)=GPB_path(r,t)-min(    65-(t+19)   ,5).*0.036.*GPB_path(r,t);
    
                    bg =max(0.5.*((Health_path(r,t)==1).*GPB_path(r,t,1)+(Health_path(r,t)==2).*GPB_path(r,t,2))-102,0);
                    bg1=((bg- 8652)./10000);
                    bg2=((bg-13669)./10000);
    
                    ITAX_path(r,t)=               1.*(bg>=8653) .*(bg<=13669).*((993.62*bg1+1400).*bg1);
                    ITAX_path(r,t)=ITAX_path(r,t)+1.*(bg>=13670).*(bg<=53665).*((225.40*bg2+2397).*bg2+952.48);
                    ITAX_path(r,t)=ITAX_path(r,t)+1.*(bg>=53666)             .*((0.42*bg)-8394.14);
    
                    if NoWT == 0
                        ITAX_path(r,t)=ITAX_path(r,t).*1.055;
                    elseif NoWT == 1
                        ITAX_path(r,t)=ITAX_path(r,t).*scWT;
                    end
    

                    if TaxLT == 1
                        ITAX_path(r,t) = ITAX_path(r,t) * (1 + LTalpha*(ExpRatio_path(r,t)-MeanExpRatio(t))*(ExpRatio_path(r,t)>=MeanExpRatio(t)) - LTbeta*(MeanExpRatio(t)-ExpRatio_path(r,t))*(ExpRatio_path(r,t)<MeanExpRatio(t)));                 
                    end


                end
    
                
                % --------------------------------------
                %%% Compute savings and consumption path
    
                if     SavChoice_path(r,t)>K && SavChoice_path(r,t)<J && Empl_path(r,t)==1
                    Sav_path(r,t)=max(sav(SavChoice_path(r,t),1),-(Wealth_path(r,t) - min(blim,Wealth_path(r,t))))+GCI_path(r,t)-CTAX_path(r,t);
    
                elseif SavChoice_path(r,t)<=K || (SavChoice_path(r,t)>K && SavChoice_path(r,t)<J && Empl_path(r,t)==2)
                    Sav_path(r,t)=max(sav(SavChoice_path(r,t),1),-(Wealth_path(r,t) - min(blim,Wealth_path(r,t))))+GCI_path(r,t)-CTAX_path(r,t);
    
                elseif SavChoice_path(r,t)==J
    
                    sp=spbh(:,:,1+(Educ(r,1)>=12)).*(Health_path(r,t)==1)+spgh(:,:,1+(Educ(r,1)>=12)).*(Health_path(r,t)==2); %#ok<USENS>
                    dp=[(1-sp(t+1:80,t,1))' 1]';
                    px=[(1-sp(t,t,1)) cumprod(sp(t:80,t,1),1)'.*dp(:,1)']';
                    eta=tau;
                    tau=1e-10;
                    for i=1:(99-(t+19))
                        Sav_path(r,t)=Sav_path(r,t)-px(i,1).*Wealth_path(r,t)./(((1-(1+tau)^(-i))/tau)*(1+tau));
                    end
                    tau=eta;
    
                    for i=1:(99-(t+19))
                        Fav_path(r,t)=Fav_path(r,t)+px(i,1).*Wealth_path(r,t)./(((1-(1+tau)^(-i))/tau)*(1+tau));
                    end
    
                    GCI_path(r,t)=Fav_path(r,t)+Sav_path(r,t);
    
                    if NoWT == 0
                        CTAX_path(r,t)=max(GCI_path(r,t)-801,0).*0.25.*1.055;
                    elseif NoWT == 1
                        CTAX_path(r,t)=max(GCI_path(r,t)-801,0).*0.25.*scWT;
                    end
                    

                    if TaxLT == 1
                        CTAX_path(r,t) = CTAX_path(r,t) * (1 + LTalpha*(ExpRatio_path(r,t)-MeanExpRatio(t))*(ExpRatio_path(r,t)>=MeanExpRatio(t)) - LTbeta*(MeanExpRatio(t)-ExpRatio_path(r,t))*(ExpRatio_path(r,t)<MeanExpRatio(t))); 
                    end                    
    
                    HINS_path(r,t)=min(h_i.*((Health_path(r,t)==1).*GPB_path(r,t,1)+(Health_path(r,t)==2).*GPB_path(r,t,2)),h_i*0.75*sscuw);
    
                    SSC_path(r,t)=HINS_path(r,t);
    
                    if     t<=40
    
                        DPB_path(r,t)=GPB_path(r,t,1)-ITAX_path(r,t)-SSC_path(r,t);
    
                    elseif t> 40
    
                        EPB_path(r,t)=GPB_path(r,t,2)-ITAX_path(r,t)-SSC_path(r,t);
    
                        if Health_path(r,t) == 1
                            DPB_path(r,t)=GPB_path(r,t,1)-GPB_path(r,t,2);
                        end
    
                    end
    
                    if LSum2 == 1
                        EPB_path(r,t)=EPB_path(r,t)+D_INC;
                    end
    
                    MPB_path(r,t)=max(EPB_path(r,t)+DPB_path(r,t)+Fav_path(r,t)-CTAX_path(r,t),regalw*12*(1+MPplus))-(EPB_path(r,t)+DPB_path(r,t)+Fav_path(r,t)-CTAX_path(r,t));
                    
                    NPB_path(r,t)=EPB_path(r,t)+DPB_path(r,t)+MPB_path(r,t);
    
                end
    
                % -------------------------------------
                %%% Compute net income and consumption
    
                if     SavChoice_path(r,t)<=J-1  
                    Y_path(r,t)=WAGE_path(r,t)+UIB_path(r,t)+SAB_path(r,t)+GCI_path(r,t)-ITAX_path(r,t)-CTAX_path(r,t)-SSC_path(r,t);
    
                elseif SavChoice_path(r,t)==J   
                    Y_path(r,t)=NPB_path(r,t)+GCI_path(r,t)-CTAX_path(r,t);
    
                    if     LSum1 == 1
                        Y_path(r,t)  =Y_path(r,t)  +D_INC;
                        NPB_path(r,t)=NPB_path(r,t)+D_INC;
                    end
    
                end
    
                C_path(r,t)=max(Y_path(r,t)-Sav_path(r,t),0);
    
    
    
                % -------------------------------------
                %%% Adding employer contributions
                SSC_path(r,t) = SSC_path(r,t)*2;
                UINS_path(r,t)= UINS_path(r,t)*2;
                PINS_path(r,t)= PINS_path(r,t)*2;
                HINS_path(r,t)= HINS_path(r,t)*2;
    
    
                % -------------------------------------
                % Transition of other state variables
                Wealth_path(r,t+1)=max(Wealth_path(r,t)+Sav_path(r,t),wealth_llim);
    
                %%% savings choice path
                % >>> fixed to baseline
    
                %Exper_path(r,t+1)=Exper_path(r,t)+(Empl_path(r,t+1)==2);
                NPP_path(r,t+1)  =NPP_path(r,t)  +(Empl_path(r,t+1)==2).*min(WAGE_path(r,t)./36187,2);
    
 % ------------------------------------------------------------------------------------
            else    % (Reti_path(r,t)>1) "state: in retirement"
 
                % > Experience-ratio 
                ExpRatio_path(r,t) = ExpRatio_path(r,t-1);

                %%% Project Path Variables from t-1
                C_path(r,t)     = C_path(r,t-1);
                Y_path(r,t)     = Y_path(r,t-1);
                GCI_path(r,t)   = GCI_path(r,t-1);
                CTAX_path(r,t)  = CTAX_path(r,t-1);
                SSC_path(r,t)   = SSC_path(r,t-1);
                HINS_path(r,t)  = HINS_path(r,t-1);
    
                GPB_path(r,t,:) = GPB_path(r,t-1,:);
    
                if     t<=40 || t> 41
    
                    EPB_path(r,t)=EPB_path(r,t-1);
                    DPB_path(r,t)=DPB_path(r,t-1);
    
                elseif t==41  % age 60 
    
                    EPB_path(r,t)=GPB_path(r,t,2)-ITAX_path(r,t)-(SSC_path(r,t)/2);
                    DPB_path(r,t)=GPB_path(r,t,1)-GPB_path(r,t,2);
    
                end
    
    
                MPB_path(r,t)   = MPB_path(r,t-1);
                NPB_path(r,t)   = NPB_path(r,t-1);
                Sav_path(r,t)   = Sav_path(r,t-1);
    
                Wealth_path(r,t+1)=max(Wealth_path(r,t)+Sav_path(r,t),wealth_llim);
    
                %Exper_path(r,t+1) = Exper_path(r,t);
                NPP_path(r,t+1)   = NPP_path(r,t);
                %Empl_path(r,t+1)  = Empl_path(r,t);
                %Reti_path(r,t+1)  = Reti_path(r,t);            
    
    
    
            end  % Reti_path = (1,2)
    
    
            % --------------------------
            %%% Health Path:
            % >>> fixed to baseline
       
      
        end   % t=entry:T loop
    
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Simulation post Life-Cycle T+1 (age 65)
        % ----------------------------------------
    
        t = T+1;
    
        if Reti_path(r,t)==1  % state: non-retired; i.e T+1 is first period in retirement (compulsory)

            ExpRatio_path(r,t) = ExpRatio_path(r,t-1);
    
            NPP_path(r,t,1)=NPP_path(r,t,1)+(Health_path(r,t)==1).*max((60-(t+19)),0).*NPP_path(r,t,1)./max((t+19-Educ(r,1)-7),1);
    
            GPB_path(r,t,1)=NPP_path(r,t,1).*30.45.*12.*(1+Zeta.*(((NPP_path(r,t,1).*30.45.*12)-(40.*30.45.*12))./(40.*30.45.*12)).*((NPP_path(r,t,1).*30.45.*12)>(40.*30.45.*12))+Xi);
            GPB_path(r,t,2)=NPP_path(r,t,2).*30.45.*12.*(1+Zeta.*(((NPP_path(r,t,2).*30.45.*12)-(40.*30.45.*12))./(40.*30.45.*12)).*((NPP_path(r,t,2).*30.45.*12)>(40.*30.45.*12))+Xi);
    
            GPB_path(r,t,1)=GPB_path(r,t)-min(max(63-(t+19),0),3).*0.036.*GPB_path(r,t);
            GPB_path(r,t,2)=GPB_path(r,t)-min(    65-(t+19)   ,5).*0.036.*GPB_path(r,t);
    
            bg =max(0.5.*((Health_path(r,t)==1).*GPB_path(r,t,1)+(Health_path(r,t)==2).*GPB_path(r,t,2))-102,0);
            bg1=((bg- 8652)./10000);
            bg2=((bg-13669)./10000);
    
            ITAX_path(r,t)=               1.*(bg>=8653) .*(bg<=13669).*((993.62*bg1+1400).*bg1);
            ITAX_path(r,t)=ITAX_path(r,t)+1.*(bg>=13670).*(bg<=53665).*((225.40*bg2+2397).*bg2+952.48);
            ITAX_path(r,t)=ITAX_path(r,t)+1.*(bg>=53666)             .*((0.42*bg)-8394.14);
    
            if NoWT == 0
                ITAX_path(r,t)=ITAX_path(r,t).*1.055;
            elseif NoWT == 1
                ITAX_path(r,t)=ITAX_path(r,t).*scWT;
            end

            if TaxLT == 1
                ITAX_path(r,t) = ITAX_path(r,t) * (1 + LTalpha*(ExpRatio_path(r,t)-MeanExpRatio(t))*(ExpRatio_path(r,t)>=MeanExpRatio(t)) - LTbeta*(MeanExpRatio(t)-ExpRatio_path(r,t))*(ExpRatio_path(r,t)<MeanExpRatio(t)));
            end            
    
            % --------------------------------------
            %%% Compute savings and consumption path
            sp=spbh(:,:,1+(Educ(r,1)>=12)).*(Health_path(r,t)==1)+spgh(:,:,1+(Educ(r,1)>=12)).*(Health_path(r,t)==2);
            dp=[(1-sp(t+1:80,t,1))' 1]';
            px=[(1-sp(t,t,1)) cumprod(sp(t:80,t,1),1)'.*dp(:,1)']';
            eta=tau;
            tau=1e-10;
            for i=1:(99-(t+19))
                Sav_path(r,t)=Sav_path(r,t)-px(i,1).*Wealth_path(r,t)./(((1-(1+tau)^(-i))/tau)*(1+tau));
            end
            tau=eta;
    
            for i=1:(99-(t+19))
                Fav_path(r,t)=Fav_path(r,t)+px(i,1).*Wealth_path(r,t)./(((1-(1+tau)^(-i))/tau)*(1+tau));
            end
    
            GCI_path(r,t)=Fav_path(r,t)+Sav_path(r,t);
    
            if NoWT == 0
                CTAX_path(r,t)=max(GCI_path(r,t)-801,0).*0.25.*1.055;
            elseif NoWT == 1
                CTAX_path(r,t)=max(GCI_path(r,t)-801,0).*0.25.*scWT;
            end

            if TaxLT == 1
                CTAX_path(r,t) = CTAX_path(r,t) * (1 + LTalpha*(ExpRatio_path(r,t)-MeanExpRatio(t))*(ExpRatio_path(r,t)>=MeanExpRatio(t)) - LTbeta*(MeanExpRatio(t)-ExpRatio_path(r,t))*(ExpRatio_path(r,t)<MeanExpRatio(t))); 
            end            

            HINS_path(r,t)=min(h_i.*((Health_path(r,t)==1).*GPB_path(r,t,1)+(Health_path(r,t)==2).*GPB_path(r,t,2)),h_i*0.75*sscuw);
    
            SSC_path(r,t)=HINS_path(r,t);
    
            EPB_path(r,t)=GPB_path(r,t,2)-ITAX_path(r,t)-SSC_path(r,t);
    
            if Health_path(r,t) == 1
                DPB_path(r,t)=GPB_path(r,t,1)-GPB_path(r,t,2);   
            end
    
            if LSum2 == 1
                EPB_path(r,t)=EPB_path(r,t)+D_INC;
            end
    
            MPB_path(r,t)=max(EPB_path(r,t)+DPB_path(r,t)+Fav_path(r,t)-CTAX_path(r,t),regalw*12*(1+MPplus))-(EPB_path(r,t)+DPB_path(r,t)+Fav_path(r,t)-CTAX_path(r,t));
    
            NPB_path(r,t)=EPB_path(r,t)+DPB_path(r,t)+MPB_path(r,t);
    
    
            % --------------------------------------        
            % Compute net income and consumption
            Y_path(r,t)=NPB_path(r,t)+GCI_path(r,t)-CTAX_path(r,t);
    
            if     LSum1 == 1
                Y_path(r,t)  =Y_path(r,t)  +D_INC;
                NPB_path(r,t)=NPB_path(r,t)+D_INC;
            end
    
            C_path(r,t)=max(Y_path(r,t)-Sav_path(r,t),0);
    
    
            % --------------------------------------        
            % Adding employer contributions
            SSC_path(r,t)= SSC_path(r,t)*2;
            HINS_path(r,t)=HINS_path(r,t)*2;
    
            % ----------------------------------------------------------------------------------------
        else  % state: already in retirement pre age 65
    
            ExpRatio_path(r,t) = ExpRatio_path(r,t-1);

            C_path(r,t)   = C_path(r,t-1);
            Y_path(r,t)   = Y_path(r,t-1);
            GCI_path(r,t) = GCI_path(r,t-1);
            CTAX_path(r,t) = CTAX_path(r,t-1);
            SSC_path(r,t) = SSC_path(r,t-1);
            HINS_path(r,t)= HINS_path(r,t-1);
            GPB_path(r,t) = GPB_path(r,t-1);
            MPB_path(r,t) = MPB_path(r,t-1);
            EPB_path(r,t) = EPB_path(r,t-1);
            DPB_path(r,t) = DPB_path(r,t-1);
            NPB_path(r,t) = NPB_path(r,t-1);
            Sav_path(r,t) = Sav_path(r,t-1);
    
        end 
    
  
    end     % R-loop



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Transform Path Variables
    % ----------------------------------------
    %   > characterize values over retirenment lifespan
    
    %%% Expand retirement values (saved in dim2:46) over retirement lifespan
    C_path      = [    C_path repmat(    C_path(:,T+1),[1 100-(T+20)])];
    Y_path      = [    Y_path repmat(    Y_path(:,T+1),[1 100-(T+20)])];
    GCI_path    = [  GCI_path repmat(  GCI_path(:,T+1),[1 100-(T+20)])];
    CTAX_path   = [ CTAX_path repmat( CTAX_path(:,T+1),[1 100-(T+20)])];
    ITAX_path   = [ ITAX_path repmat( ITAX_path(:,T+1),[1 100-(T+20)])];
    SSC_path    = [  SSC_path repmat(  SSC_path(:,T+1),[1 100-(T+20)])];
    HINS_path   = [ HINS_path repmat( HINS_path(:,T+1),[1 100-(T+20)])];
    MPB_path    = [  MPB_path repmat(  MPB_path(:,T+1),[1 100-(T+20)])];
    EPB_path    = [  EPB_path repmat(  EPB_path(:,T+1),[1 100-(T+20)])];
    DPB_path    = [  DPB_path repmat(  DPB_path(:,T+1),[1 100-(T+20)])];
    NPB_path    = [  NPB_path repmat(  NPB_path(:,T+1),[1 100-(T+20)])];
    Exper_path  = [Exper_path repmat(Exper_path(:,T+1),[1 100-(T+20)])];
    Sav_path    = [  Sav_path repmat(  Sav_path(:,T+1),[1 100-(T+20)])];

    SavChoice_path = [SavChoice_path repmat(SavChoice_path(:,T+1),[1 100-(T+20)])];

    ExpRatio_path = [ExpRatio_path repmat(ExpRatio_path(:,T+1),[1 100-(T+20)])];
    
    %%% Zero-Values in Retirement
    UINS_path   = [UINS_path                     zeros(R/Z,100-(T+20)+1)];
    PINS_path   = [PINS_path                     zeros(R/Z,100-(T+20)+1)];
    WAGE_path   = [WAGE_path                     zeros(R/Z,100-(T+20)+1)];
    WAGE2_path  = [WAGE2_path                    zeros(R/Z,100-(T+20)+1)];
    WShock2_path= [WShock2_path                  zeros(R/Z,100-(T+20)+1)];
    UIB_path    = [ UIB_path                     zeros(R/Z,100-(T+20)+1)];
    SAB_path    = [ SAB_path                     zeros(R/Z,100-(T+20)+1)];
    % > keep from base:
    Empl_path   = [max(Empl_path(:,2:T+1)-1,0)   zeros(R/Z,100-(T+20)+1)];
    Reti_path   = [max(Reti_path(:,2:T+1)-1,0)    ones(R/Z,100-(T+20)+1)];
    
    %%% Transform
    Health_path = max(Health_path-1,0);         % before: bh=1; gh=2
    Pov_path    = 1*(C_path<816*12);            


    
    %%% Write Path Variables to Struct
    sim_path = v2struct(C_path,Y_path,GCI_path,ITAX_path,CTAX_path,SSC_path,UINS_path,PINS_path, ...
                       HINS_path,WAGE_path,WAGE2_path,WShock2_path,UIB_path,SAB_path,MPB_path, ...
                       EPB_path,DPB_path,NPB_path,Type,Educ,Empl_path,Reti_path,Health_path, ...
                       Wealth_path,Sav_path,Exper_path,Pov_path,Fav_path,SavChoice_path,ExpRatio_path);







end     % function