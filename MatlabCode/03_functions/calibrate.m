function [calib] = calibrate()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup Model Parameters   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% STRUCTURE:
%   1. Define Switches used in all scripts
%   2. Specify general model characteristics
%   3. Define calibrated parameters
%   4. Define state-space grid
%   5. Load job separation model parameters
%   6. Write model calibration to structure: "calib"

%%% INPUT:
%   Reduced form estimates of job separations model:
%       - Parameters: "params_jobsep.txt"
%       - VarCovar Matrix: "var_covar_jobsep.txt"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 1. Switches:
Adjust  = 0;
Tau     = 0;         % Absolute change in pension contribution rate
Const   = 0;         % 1: offers and separations are kept unchanged in choice probabilities
Const2  = 0;         % 1: offers and separations are kept unchanged in simulations
LSum1   = 0;         % Lump sum increase in pension benefits after means test
LSum2   = 0;         % Lump sum increase in pension benefits before means test
Nodis   = 0;         % 1: early retreiment disincentives are set to zero
Psi     = 0;
Zeta    = 0;
Xi      = 0;
Omega   = 0;
Ret60   = 0;
Ret63   = 0;
Ret65   = 0;
MPplus  = 0;         % Relative change in social assistance benefits 
DeltaO  = 0;         % Relative change in job offer rate 
DeltaS  = 0;         % Relative change in job separation rate
DeltaH1 = 0;         % Relative change in trans prob from bad to good health
DeltaH2 = 0;         % Relative change in trans prob from good to good health
D_INC   = 0;          
Mort    = 1;         % Mortality: 0 = no, 1 = heterogeneous 

NoWT    = 0;         % PolicySim: exclude wealth test
TaxLT   = 0;         % PolicySim: include lifetime taxation

BehFix  = 0;         % switch off reshaping of simulated trajectories (Empl,Reti,Health) for fixed behavior sims.
EdFix   = 0;         % fix education choices to baseline

LTalpha = 1;      
LTbeta  = 1;  

scWT    = 1.055;     % updated solidarity tax for rev-neutrality of wealth test scenarios

MeanExpRatio = ones(1,81);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 2. General Model Characteristics:

N=3280;              % Number of individuals in the data set
W=12;                % Number of waves in the data set
T=45;                % Number of years, age 20 to age 64
S=9;                 % Number of grid points for net wealth
E=6;                 % Number of grid points for work experience
H=4;                 % Number of grid points for education
L=5;                 % Number of grid points for lagged log(wage)
D=5;                 % Number of grid points for wage shock
J=27;                % Number of choices
K=13;                % Number of grid points for saving choice
M=3;                 % Number of unobserved types


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 3. Calibrated Parameters

tau =0.01;           % Real interest rate
betta=0.99;          % Subjective discount rate
rho =1.50;           % CRRA (constant relative risk aversion?)

blim = -20000;       % borrowing limit
regalw  = 700;       % social assistance benefits

%%% Number of draws for simulations:
R = 50000;             % Number of obs per simulated subsample

%%% Simulation seed (used in: drawgen.m)
seed = 2131;

%%% Age-specific value of Wealth-Test:
NWTest=zeros(T+1,1);
for t=1:T+1
    NWTest(t,1)=(t+19)*500;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 4. Define Grid Variables:

nwgrid=[blim 0 10000 20000 30000 50000 100000 150000 700000]';
    S = size(nwgrid,1);
exgrid=[0 10 20 30 40 50]';                               %#ok<*NASGU> % Grid points experience
edgrid=[8 11 12 18]';                                     % Grid points for years of education
lwgrid=[2 2.5 3 3.5 4]';                                  % Grid points for lagged log(wage)

educyrs = (8:1:18)';

% Grid Binary Variables (Health; Lagged Empl. Status)
bingrid=zeros(2,1);                                       
bingrid(2,1)=1;

% Grid Support Wage Shock
for d=1:D
    wdbase(d,1)=-2+(d-1);                                %#ok<AGROW>
end

for d=1:D
    weight(d,1)=normpdf(wdbase(d,1));                   %#ok<AGROW>
end
weight=weight./sum(weight,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 5. Job Separation Model: Load Reduced Form Estimates

    phi_s = load('MatlabCode/01_input/params_jobsep.txt');

    ihess_sep = load('MatlabCode/01_input/var_covar_jobsep.txt');
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 6. Write to Struct
calib = v2struct;

end