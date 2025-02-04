function [y,gci,dis,itax,ctax,ssc,hic,pic,uic,uib,sab,mpb,npb] = taxtrans(t,wage,calib,data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% German tax and trasfer system / statutory pension scheme %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack:
% -----------
tax_calib = {'fieldnames','S','E','H','L','D','M','J','K','T','Tau','tau', ...
                'nwgrid','NWTest','edgrid','LSum1','LSum2','Nodis', ... 
                'MPplus','NoWT','exgrid','TaxLT',...
                'scWT','regalw','LTalpha','LTbeta','MeanExpRatio'};


%%% unpack model calibration
v2struct(calib,tax_calib);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Create Empty Matrices:
% --------------------------

y    = zeros(S,E,H,L,D,2,2,M,J);        % net income
npb  = zeros(S,E,H,L,D,2,2,M,J);        % net pension benefits
dis  = zeros(S,E,H,L,D,2,2,M,J);        % dissaving
fav  = zeros(S,E,H,L,D,2,2,M,J);        % fair annuity value
gci  = zeros(S,E,H,L,D,2,2,M,J);        % gross capital income before retirement
hic  = zeros(S,E,H,L,D,2,2,M,J);        % health insurance contribution
pic  = zeros(S,E,H,L,D,2,2,M,J);        % pension insurance contribution
uic  = zeros(S,E,H,L,D,2,2,M,J);        % unemployment insurance contribution
ssc  = zeros(S,E,H,L,D,2,2,M,J);        % social secu contribution
uib  = zeros(S,E,H,L,D,2,2,M,J);        % unemployment insurance benefit
sab  = zeros(S,E,H,L,D,2,2,M,J);        % social assistance benefits
bg   = zeros(S,E,H,L,D,2,2,M,J);        % before government labor earnings
itax = zeros(S,E,H,L,D,2,2,M,J);        % income tax burden
ctax = zeros(S,E,H,L,D,2,2,M,J);        % capital income tax burden


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Social Security Contributions before Retirement:
% ----------------------------------------------------

%%% set tax-system parameters
cap     = 2;                            % maximum pension points
sscuw   = 6200*12;                      % maximum contributions
h_i     =       0.147/2;                % health insurance contr rate
r_i     = (0.187+Tau)/2;                % pension insurance contr rate
u_i     =        0.03/2;                % unemployment insurance contr rate


%%% derive annual contributions based on earnings grid
pic(:,:,:,:,:,:,:,:,1:J-1) = min(r_i.*repmat(wage,[1 1 1 1 1 1 1 1 J-1]),r_i*     sscuw);
hic(:,:,:,:,:,:,:,:,1:J-1) = min(h_i.*repmat(wage,[1 1 1 1 1 1 1 1 J-1]),h_i*0.75*sscuw);   
uic(:,:,:,:,:,:,:,:,1:J-1) = min(u_i.*repmat(wage,[1 1 1 1 1 1 1 1 J-1]),u_i     *sscuw);

ssc(:,:,:,:,:,:,:,:,1:J-1) = hic(:,:,:,:,:,:,:,:,1:J-1)+pic(:,:,:,:,:,:,:,:,1:J-1)+uic(:,:,:,:,:,:,:,:,1:J-1);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Taxation before Retirement:
% -------------------------------

%%% labor earnings deductions
bg(:,:,:,:,:,:,:,:,1:J-1) = max(repmat(wage,[1 1 1 1 1 1 1 1 J-1])-1000,0);
    % > taxable income

%%% taxable income by bracket
bg1 = ((bg(:,:,:,:,:,:,:,:,1:J-1)- 8652)./10000);
bg2 = ((bg(:,:,:,:,:,:,:,:,1:J-1)-13669)./10000);


%%% income tax burden accumulated by bracket
itax(:,:,:,:,:,:,:,:,1:J-1) =                             1.*(bg(:,:,:,:,:,:,:,:,1:J-1)>=8653) .*(bg(:,:,:,:,:,:,:,:,1:J-1)<=13669).*((993.62*bg1+1400).*bg1);
itax(:,:,:,:,:,:,:,:,1:J-1) = itax(:,:,:,:,:,:,:,:,1:J-1)+1.*(bg(:,:,:,:,:,:,:,:,1:J-1)>=13670).*(bg(:,:,:,:,:,:,:,:,1:J-1)<=53665).*((225.40*bg2+2397).*bg2+952.48);
itax(:,:,:,:,:,:,:,:,1:J-1) = itax(:,:,:,:,:,:,:,:,1:J-1)+1.*(bg(:,:,:,:,:,:,:,:,1:J-1)>=53666)                                    .*((0.42*bg(:,:,:,:,:,:,:,:,1:J-1))-8394.14);



%%% capital income tax
ctax(:,:,:,:,:,:,:,:,1:J-1) = max((repmat(nwgrid,[1 E H L D 2 2 M J-1])).*tau-801,0).*0.25;         %#ok<NODEF,USENS>


%%% solidarity tax
if NoWT == 0
    itax = 1.055.*itax;
    ctax = 1.055.*ctax;
elseif NoWT == 1
    itax = scWT.*itax;
    ctax = scWT.*ctax;
end


%%% lifetime taxation
if TaxLT == 1
    exp_status = repmat(exgrid',[S 1 H L D 2 2 M J]);
    potexp = repmat(reshape(max(t-max(edgrid+8-20,0),1),1,1,H,1,1,1,1,1,1),[S E 1 L D 2 2 M J]);    %#ok<USENS>

    ExpRatio = exp_status./potexp;
    ExpRatio(ExpRatio>1) = 1;

    itax = itax .* (1 + LTalpha.*(ExpRatio - MeanExpRatio(t)).*(ExpRatio>=MeanExpRatio(t)) - LTbeta.*(MeanExpRatio(t) - ExpRatio).*(ExpRatio<MeanExpRatio(t)) );
    ctax = ctax .* (1 + LTalpha.*(ExpRatio - MeanExpRatio(t)).*(ExpRatio>=MeanExpRatio(t)) - LTbeta.*(MeanExpRatio(t) - ExpRatio).*(ExpRatio<MeanExpRatio(t)) );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gross capital income before retirement 
% ------------------------------------------

gci(:,:,:,:,:,:,:,:,1:J-1) = repmat(nwgrid,[1 E H L D 2 2 M J-1]).*tau;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Net income for the employed 
% -------------------------------

y(:,:,:,:,:,:,:,:,1:K) = repmat(wage,[1 1 1 1 1 1 1 1 K])+gci(:,:,:,:,:,:,:,:,1:K)-itax(:,:,:,:,:,:,:,:,1:K)-ctax(:,:,:,:,:,:,:,:,1:K)-ssc(:,:,:,:,:,:,:,:,1:K);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. Unemployment Benefits:
% --------------------------
%%% Notes:
%   > 1-year eligibility cond. on employment in t-1
%   > same wage-grid is assessed each iteration of t


%%% unemployment benefits
uib(:,:,:,:,:,:,2,:,K+1:J-1) = 0.6.*(repmat(repmat(wage(:,:,:,:,(D+1)/2,:,2,:),[1 1 1 1 1 1 1 1 J-K-1])-itax(:,:,:,:,(D+1)/2,:,2,:,K+1:J-1)-ssc(:,:,:,:,(D+1)/2,:,2,:,K+1:J-1),[1 1 1 1 D]));


%%% social assistance benefits
if NoWT == 0
    sab(:,:,:,:,:,:,1,:,K+1:J-1) = repmat(regalw*12-max(min(regalw*12,nwgrid(:,1)-NWTest(t,1)),0),[1 E H L D 2 1 M J-K-1]);
elseif NoWT ==1
    sab(:,:,:,:,:,:,1,:,K+1:J-1) = repmat(regalw*12,[S E H L D 2 1 M J-K-1]);
end


%%% set social security contributions to zero
ssc(:,:,:,:,:,:,:,:,K+1:J-1) = 0;
hic(:,:,:,:,:,:,:,:,K+1:J-1) = 0;
pic(:,:,:,:,:,:,:,:,K+1:J-1) = 0;
uic(:,:,:,:,:,:,:,:,K+1:J-1) = 0;


%%% set income tax to zero
itax(:,:,:,:,:,:,:,:,K+1:J-1) = 0;


%%% net income in unemployment
y(:,:,:,:,:,:,:,:,K+1:J-1) = uib(:,:,:,:,:,:,:,:,K+1:J-1)+sab(:,:,:,:,:,:,:,:,K+1:J-1)+gci(:,:,:,:,:,:,:,:,K+1:J-1)-ctax(:,:,:,:,:,:,:,:,K+1:J-1);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 6. Saving Capital Income:
% --------------------------

%%% saving == negative dissavings
dis(:,:,:,:,:,:,:,:,1:J-1) = dis(:,:,:,:,:,:,:,:,1:J-1)-(gci(:,:,:,:,:,:,:,:,1:J-1)-ctax(:,:,:,:,:,:,:,:,1:J-1));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 7. Pension Points:
% -------------------

npp = zeros(S,E,H,L,D,2,2,M);


%%% years of full-contribution by experience
%   > average pp given wage at experience grid points
npp(:,2,:,:,:,:,1,:) = npp(:,1,:,:,:,:,1,:)+((min(repmat(wage(:,1,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap)+min(repmat(wage(:,2,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap))./2).*10;
npp(:,3,:,:,:,:,1,:) = npp(:,2,:,:,:,:,1,:)+((min(repmat(wage(:,2,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap)+min(repmat(wage(:,3,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap))./2).*10;
npp(:,4,:,:,:,:,1,:) = npp(:,3,:,:,:,:,1,:)+((min(repmat(wage(:,3,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap)+min(repmat(wage(:,4,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap))./2).*10;
npp(:,5,:,:,:,:,1,:) = npp(:,4,:,:,:,:,1,:)+((min(repmat(wage(:,4,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap)+min(repmat(wage(:,5,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap))./2).*10;
npp(:,E,:,:,:,:,1,:) = npp(:,5,:,:,:,:,1,:)+((min(repmat(wage(:,5,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap)+min(repmat(wage(:,E,:,:,(D+1)/2,:,1,:),[1 1 1 1 D])./36187,cap))./2).*10;

npp(:,:,:,:,:,:,2,:) = npp(:,:,:,:,:,:,1,:);


%%% additional points for early retirement
npp(:,:,:,:,:,1,1,:) = npp(:,:,:,:,:,1,1,:)+max((60-(t+19)),0).*npp(:,:,:,:,:,1,1,:)./max((t+19-repmat(reshape(edgrid(:,1),1,1,H),[S E 1 L D 1 1 M])-7),1);
npp(:,:,:,:,:,1,2,:) = npp(:,:,:,:,:,1,1,:);
%   > receive pension points based on avg. points before entering em-pension



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 8. Pension Benefits and Capital Income:
% ----------------------------------------

%%% gross pension points
gpb = npp.*30.45.*12;


%%% reductions due to early retirement
% Nodis: early retirement disincentives set to 0/1
if     Nodis == 0
        gpb(:,:,:,:,:,1,:,:) = gpb(:,:,:,:,:,1,:,:)-min(max(63-(t+19),0),3).*0.036.*gpb(:,:,:,:,:,1,:,:);
        gpb(:,:,:,:,:,2,:,:) = gpb(:,:,:,:,:,2,:,:)-min(    65-(t+19)   ,5).*0.036.*gpb(:,:,:,:,:,2,:,:);
    if     t==T+1 && T==46
        gpb(:,:,:,:,:,:,:,:) = gpb(:,:,:,:,:,:,:,:)-min(    65-(t+19)   ,5).*0.036.*gpb(:,:,:,:,:,:,:,:);
    end

elseif Nodis == 1
    gpb(:,:,:,:,:,1,:,:) = gpb(:,:,:,:,:,1,:,:);
    gpb(:,:,:,:,:,2,:,:) = gpb(:,:,:,:,:,2,:,:);
end


%%% income tax
bg(:,:,:,:,:,:,:,:,J) = max(0.5.*gpb-102,0);

bg1 = ((bg(:,:,:,:,:,:,:,:,J)-8652)./10000);
bg2 = ((bg(:,:,:,:,:,:,:,:,J)-13669)./10000);

itax(:,:,:,:,:,:,:,:,J) =                         1*(bg(:,:,:,:,:,:,:,:,J)>=8653) .*(bg(:,:,:,:,:,:,:,:,J)<=13669).*((993.62*bg1+1400).*bg1);
itax(:,:,:,:,:,:,:,:,J) = itax(:,:,:,:,:,:,:,:,J)+1*(bg(:,:,:,:,:,:,:,:,J)>=13670).*(bg(:,:,:,:,:,:,:,:,J)<=53665).*((225.40*bg2+2397).*bg2+952.48);
itax(:,:,:,:,:,:,:,:,J) = itax(:,:,:,:,:,:,:,:,J)+1*(bg(:,:,:,:,:,:,:,:,J)>=53666)                                .*((0.42*bg(:,:,:,:,:,:,:,:,J))-8394.14);



%%% capital income tax
% fair annuity value
a = annuity(t,calib,data);           % by wealth-grid and health/educ status

fav(:,:,1:2,:,:,:,:,:,J) = repmat(reshape(a(:,1:2),S,1,1,1,1,2),[1 E 2 L D 1 2 M]);
fav(:,:,3:4,:,:,:,:,:,J) = repmat(reshape(a(:,3:4),S,1,1,1,1,2),[1 E 2 L D 1 2 M]);


% non-interest dissavings 
% to derive expected gross capital income over retirement
eta = tau;
tau = 1e-10; calib.tau=tau;
    a = annuity(t,calib,data);
    dis(:,:,1:2,:,:,:,:,:,J) = repmat(reshape(a(:,1:2),S,1,1,1,1,2),[1 E 2 L D 1 2 M]);
    dis(:,:,3:4,:,:,:,:,:,J) = repmat(reshape(a(:,3:4),S,1,1,1,1,2),[1 E 2 L D 1 2 M]);
tau = eta;        % reset to interest rate
calib.tau = tau;


% captial income tax retirement
ctax(:,:,:,:,:,:,:,:,J) = max(fav(:,:,:,:,:,:,:,:,J)-dis(:,:,:,:,:,:,:,:,J)-801,0).*0.25;


%%% solidarity tax retirement
if NoWT == 0
    itax(:,:,:,:,:,:,:,J) = 1.055.*itax(:,:,:,:,:,:,:,J);
    ctax(:,:,:,:,:,:,:,J) = 1.055.*ctax(:,:,:,:,:,:,:,J);
elseif NoWT == 1
    itax(:,:,:,:,:,:,:,J) = scWT.*itax(:,:,:,:,:,:,:,J);
    ctax(:,:,:,:,:,:,:,J) = scWT.*ctax(:,:,:,:,:,:,:,J);
end

%%% lifetime taxation
if TaxLT == 1
    exp_status = repmat(exgrid',[S 1 H L D 2 2 M 1]);
    potexp = repmat(reshape(max(t-max(edgrid+8-20,0),1),1,1,H,1,1,1,1,1,1),[S E 1 L D 2 2 M 1]); 

    ExpRatio = exp_status./potexp;
    ExpRatio(ExpRatio>1) = 1;

    itax(:,:,:,:,:,:,:,:,J) = itax(:,:,:,:,:,:,:,:,J) .* (1 + LTalpha.*(ExpRatio - MeanExpRatio(t)).*(ExpRatio>=MeanExpRatio(t)) - LTbeta.*(MeanExpRatio(t) - ExpRatio).*(ExpRatio<MeanExpRatio(t)) );
    ctax(:,:,:,:,:,:,:,:,J) = ctax(:,:,:,:,:,:,:,:,J) .* (1 + LTalpha.*(ExpRatio - MeanExpRatio(t)).*(ExpRatio>=MeanExpRatio(t)) - LTbeta.*(MeanExpRatio(t) - ExpRatio).*(ExpRatio<MeanExpRatio(t)) );    

end


%%% gross capital income
gci(:,:,:,:,:,:,:,:,J) = fav(:,:,:,:,:,:,:,:,J)-dis(:,:,:,:,:,:,:,:,J);


%%% social security contributions
%   > only health insurance contributions
ssc(:,:,:,:,:,:,:,:,J) = min(h_i.*gpb,h_i*0.75*sscuw);
hic(:,:,:,:,:,:,:,:,J) = ssc(:,:,:,:,:,:,:,:,J);


%%% net pension benefits
epb(:,:,:,:,:,:,:,:,J)=gpb-itax(:,:,:,:,:,:,:,:,J)-ssc(:,:,:,:,:,:,:,:,J);


%%% Lump sum increase in pension benefits before means test
if     LSum2 == 1
    epb(:,:,:,:,:,:,:,:,J)=epb(:,:,:,:,:,:,:,:,J)+D_INC;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 9. Net Income Retirement:
% --------------------------

%%% minimum pension benefits
%   > only assessment of social assistance eligibility
mpb(:,:,:,:,:,:,:,:,J)=max(epb(:,:,:,:,:,:,:,:,J)+fav(:,:,:,:,:,:,:,:,J)-ctax(:,:,:,:,:,:,:,:,J),regalw*12*(1+MPplus))- ...
                          (epb(:,:,:,:,:,:,:,:,J)+fav(:,:,:,:,:,:,:,:,J)-ctax(:,:,:,:,:,:,:,:,J));


%%% total net pension benefits
%   > if benefits below legal minimum -> transfer of difference
npb(:,:,:,:,:,:,:,:,J)=epb(:,:,:,:,:,:,:,:,J)+mpb(:,:,:,:,:,:,:,:,J);


%%% net income including minimum pension benefits
y(:,:,:,:,:,:,:,:,J)=npb(:,:,:,:,:,:,:,:,J)+gci(:,:,:,:,:,:,:,:,J)-ctax(:,:,:,:,:,:,:,:,J);


%%% lump sum increase in pension benefits after means test
if     LSum1 == 1
    y(:,:,:,:,:,:,:,:,J)    =   y(:,:,:,:,:,:,:,:,J);
    npb(:,:,:,:,:,:,:,:,J)  = npb(:,:,:,:,:,:,:,:,J);
    %   > add +D_INC to both
end



end