function [] = samplus(calib,var)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Static microsimulation for estimation sample %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Unpack model elements:
% -------------------------
sim_calib = {'fieldnames','tau','T','N','SOEPdatadir'};

sim_var   = {'fieldnames','lw','work','wagel','wl','nw','ioldy','age',...
            'ob','ed','pens','pl','ex','h','hl','jobsep','nw_soep07','w_lead'};

%%% unpack model calibration
    v2struct(calib,sim_calib);
    
    v2struct(var,sim_var);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Microsimulation using estimation sample info:
% -------------------------------------------------    
%%% Gross wage
wage   =52.*40.*max(exp(lw),8.5).*work;
wagel  =52.*40.*max(wagel,8.5).*wl; %#ok<NODEF>

%%% Gross capital income
gci   = nw      .*tau;

%%% Income tax
bg =max(wage-1000,0);
bg1=((bg- 8652)./10000);
bg2=((bg-13669)./10000);

itax=     1.*(bg>=8653) .*(bg<=13669).*((993.62*bg1+1400).*bg1);
itax=itax+1.*(bg>=13670).*(bg<=53665).*((225.40*bg2+2397).*bg2+952.48);
itax=itax+1.*(bg>=53666)             .*((0.42*bg)-8394.14);

itax=itax.*1.055;

%%% Capital tax
ctax   =max(gci-  801,0).*0.25.*1.055;

%%% Social security contributions
sscuw = 6200*12;
h_i   = 0.147/2;
r_i   = 0.187/2;
u_i   = 0.03 /2;

uic   =min(u_i.*wage  ,u_i     *sscuw);
hic   =min(h_i.*wage  ,h_i*0.75*sscuw);
pic   =min(r_i.*wage  ,r_i     *sscuw);

ssc   =uic+hic+pic;


%%% Unemployment insurance benefits
bg =max(wagel-1000,0);
bg1=((bg- 8652)./10000);
bg2=((bg-13669)./10000);

itax_0=       1.*(bg>=8653) .*(bg<=13669).*((993.62*bg1+1400).*bg1);
itax_0=itax_0+1.*(bg>=13670).*(bg<=53665).*((225.40*bg2+2397).*bg2+952.48);
itax_0=itax_0+1.*(bg>=53666)             .*((0.42*bg)-8394.14);

itax_0=itax_0.*1.055;

ssc_0  =min(u_i.*wagel,u_i*sscuw)+min(h_i.*wagel,h_i*0.75*sscuw)+min(r_i.*wagel,r_i*sscuw);

uib=0.6.*(wagel-itax_0-ssc_0).*(work==0).*(wl==1);


%%% Pension benefits
epb   =ioldy;


%%% Social assistance benefits
regalw   =404+46+300;


sab=max(regalw*12-(wage+uib+gci+epb-itax-ctax-ssc),0);
sab=sab-max(min(sab,nw-500*repmat(reshape(age(1:T,1),1,T),[N 1])),0); 
sab=sab.*ob;


%%% Adding employer contributions
ssc=ssc*2; %#ok<NASGU>
uic=uic*2;
pic=pic*2;
hic=hic*2;


%%% Additional income variables
rge=wage;
rgi=wage+gci;
ri1=wage+gci-itax-ctax-(hic/2)-(uic/2)-(pic/2);
ri2=wage+gci-itax-ctax-(hic/2)-(uic/2)-(pic/2)+uib;
ri3=wage+gci-itax-ctax-(hic/2)-(uic/2)-(pic/2)+uib+sab;
ri4=wage+gci-itax-ctax-(hic/2)-(uic/2)-(pic/2)+uib+sab+epb;


%%% Transform data
id=zeros(N,T);
for n=1:N
    id(n,:)=repmat(n,[1 T]);
end

ID          =reshape(id,N*T,1);
Age         =reshape(repmat(age(1:T,1)',[N 1]),N*T,1);
Ob          =reshape(ob,N*T,1);
EDUC        =reshape(ed,N*T,1);
Empl        =reshape(work,N*T,1);
Empl_lag    =reshape(wl,N*T,1);
Reti        =reshape(pens,N*T,1);
Reti_lag    =reshape(pl,N*T,1);

Exper       =reshape(ex,N*T,1);
WAGE        =reshape(wage,N*T,1);
Health      =reshape(h,N*T,1);
Health_lag  =reshape(hl,N*T,1);
Wealth      =reshape(nw,N*T,1);
Jobsep      =reshape(jobsep,N*T,1);
Wealth_SOEP07 = reshape(nw_soep07,N*T,1);
Empl_lead   =reshape(w_lead,N*T,1);

GCI=reshape(gci,N*T,1);
ITAX=reshape(itax,N*T,1);
CTAX=reshape(ctax,N*T,1);
UIC=reshape(uic,N*T,1);
PIC=reshape(pic,N*T,1);
HIC=reshape(hic,N*T,1);
UIB=reshape(uib,N*T,1);
SAB=reshape(sab,N*T,1);
EPB=reshape(epb,N*T,1);
RGE=reshape(rge,N*T,1);
RGI=reshape(rgi,N*T,1);
RI1=reshape(ri1,N*T,1);
RI2=reshape(ri2,N*T,1);
RI3=reshape(ri3,N*T,1);
RI4=reshape(ri4,N*T,1);


%%% Export to .txt-file
    %TAB = table(ID,Age,Ob,EDUC,Empl,Empl_lag,Reti,Reti_lag,Savcat,Exper,WAGE,Health,Health_lag,Wealth,Jobsep,GCI,ITAX,CTAX,UIC,PIC,HIC,UIB,SAB,EPB,RGE,RGI,RI1,RI2,RI3,RI4,Wealth_SOEP07,Empl_lead);
    TAB = table(ID,Age,Ob,EDUC,Empl,Empl_lag,Reti,Reti_lag,Exper,WAGE,Health,Health_lag,Wealth,Jobsep,GCI,ITAX,CTAX,UIC,PIC,HIC,UIB,SAB,EPB,RGE,RGI,RI1,RI2,RI3,RI4,Wealth_SOEP07,Empl_lead);
    %writetable(TAB,'MatlabCode/02_output/esample_plus.txt');
    writetable(TAB,join([SOEPdatadir,'esample_plus.txt']));


end