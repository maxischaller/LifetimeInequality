function [var] = vargen(calib,data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare Variables containing Data %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% STRUCTURE:
%   1. Unpack model calibration
%   2. Generate variables & Preallocate choices and choice sets
%   3. Write model calibration to structure: "var"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 1. Unpack Model Calibration
v2struct(calib);
    % > Note: this unpacks all contents of "calib"-struct

X = data.X;     % data-matrix


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 2. Generate Variables // Preallocate Choices and Choice Sets

%%% leisure time
l = zeros(J,1);
for j = K+1:J
    l(j,1) = 1;
end


%%% savings choice
sav = zeros(J,1);            
for j = 1:J-1    
    if     j==1  || j==14
        sav(j,1)= -5000;
    elseif j==2  || j==15
        sav(j,1)= -2500;
    elseif j==3  || j==16
        sav(j,1)= -1000;
    elseif j==4  || j==17
        sav(j,1)=  -500;
    elseif j==6  || j==19
        sav(j,1)=   500;
    elseif j==7  || j==20
        sav(j,1)=  1000;
    elseif j==8  || j==21
        sav(j,1)=  2500;
    elseif j==9  || j==22
        sav(j,1)=  5000;
    elseif j==10 || j==23
        sav(j,1)=  7500;
    elseif j==11 || j==24
        sav(j,1)= 10000;
    elseif j==12 || j==25
        sav(j,1)= 12500;
    elseif j==13 || j==26
        sav(j,1)= 15000;
    end    
end

sav(K+1:J-1) = -sav(K+1:J-1);


%%% Age
age = zeros(81,1);
for t = 1:81
    age(t,1) = t+19;
end


%--------------------------------------
% Preallocate Choices and Choice Sets
ob      = zeros(N,T);
choice  = zeros(N,T,M,3);      
noret   = ones(N,T,D,M,3);
nolab   = ones(N,T,D,M,3);
nolab(:,:,:,:,1)=0;

ic  = zeros(N,1);   

% Fill Choices and Choice Sets from observed data
for n=1:N
    for t=1:T
        for w=1:W
            if age(t,1) == X(n,1,w)

                %%% Observed choices
                if     X(n,2,w) == 1
                    choice(n,t,:,1) = 1;

                elseif X(n,2,w) == 0 && X(n,3,w) == 0
                    choice(n,t,:,2) = 1;

                elseif X(n,3,w) == 1 && X(n,11,w) == 0
                    choice(n,t,:,3) = 1;
                end

                %%% Variables
                ob(n,t)     = 1;                               % Observation for n in t
                work(n,t)   = X(n,2,w);                        % Employment status
                pens(n,t)   = X(n,3,w);                        % Pensioner status
                ed(n,t)     = X(n,4,w);                        % Years of education
                ex(n,t)     = X(n,5,w);                        % Years of work experience
                lw(n,t)     = log(X(n,6,w)+(X(n,6,w)==0));     % Log wage
                h(n,t)      = X(n,7,w);                        % Good health
                hl(n,t)     = X(n,8,w);                        % Lagged good health
                wl(n,t)     = X(n,9,w);                        % Lagged employment
                nw(n,t)     = X(n,10,w);                       % Net wealth
                pl(n,t)     = X(n,11,w);                       % Lagged pensioner status
                wagel(n,t)  = X(n,12,w);                       % Lagged wage
                ioldy(n,t)  = X(n,13,w);                       % pension benefits
                spell(n,t)  = X(n,14,w);                       % spells-counter
                jobsep(n,t) = X(n,15,w);                       % Job separation
                nw_soep07(n,t) = X(n,16,w);                    % Observed/cross-sect. wealth
                w_lead(n,t)    = X(n,17,w);                    % lead on 'work'


                if t <= 10 || (h(n,t) == 1 && t <= 43)
                    noret(n,t,:,:,3) = 0;                      % If zero, no retirement possible
                end
            end


            % Initial conditions (Education)
            if t == 1 && age(t,1) == X(n,1,w)

                ic(n,1) = ed(n,t); 

            elseif t > 1 && age(t,1) == X(n,1,w) && ob(n,t-1) == 0 && sum(ob(n,1:t-1),2)==0

                ic(n,1) = ed(n,t); 

            end
        end
    end
end
 

%%% Years of education
ed = ic.*ob;


%%% Education Choice (NxkxM)
choice_ed = zeros(N,size(educyrs,1),M);
for n=1:N
    choice_ed(n,ic(n,1)-(educyrs(1,1)-1),:) = 1;
end


%%% Overview Sample Statistics Education
tab_ed = tabulate(categorical(max(ed,[],2)));
    % disp("Observed distribution of years of education:")
    % disp("--------------------------------------------")
    % disp("    Years     No. Obs.     Share (%)")
    % disp(tab_ed);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 3. Write to Variables Struct
var = v2struct(l,sav,age,ob,choice,choice_ed,noret,nolab,ic, ...
                    work,pens,ed,ex,lw,h,hl,wl,nw,...
                    pl,wagel,ioldy,spell,jobsep,tab_ed,nw_soep07,w_lead);


end