%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute transition probabilities %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [q] = transit(t,s,o,calib,data)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unpack Parameters:
% ------------------
q_calib = {'fieldnames','S','E','H','D','L','M','J','K','DeltaH1','DeltaH2','weight'};
q_data  = {'fieldnames','hgg','hbg'};

v2struct(calib,q_calib);
v2struct(data,q_data);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Derive Transitions Probabilities:
% ---------------------------------

q = zeros(S,E,H,L,D,2,2,M,4,J-1);

wd = repmat(reshape(weight,1,1,1,1,D),[S E 2 L 1 1 1 M 1 K]);

%%% Low Education && Employed in t
    % - job separation probabilities apply
%  > & bad-health in t:
    % 1) t+1: bh, non-sep -> employment t+1 available
    q(:,:,1:2,:,:,1,2,:,1,1:K)    =(1-repmat(reshape(s(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(1-max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
    % 1) t+1: gh, non-sep
    q(:,:,1:2,:,:,2,2,:,1,1:K)    =(1-repmat(reshape(s(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(  max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
    % 2) t+1: bh, sep -> employment t+1 not available
    q(:,:,1:2,:,:,1,2,:,2,1:K)    =   repmat(reshape(s(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(1-max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
    % 2) t+1: gh, sep
    q(:,:,1:2,:,:,2,2,:,2,1:K)    =   repmat(reshape(s(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(  max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;

 %  > & good-health in t:
    % 3) t+1: bh, non-sep
    q(:,:,1:2,:,:,1,2,:,3,1:K)    =(1-repmat(reshape(s(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(1-max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;
    % 3) t+1: gh, non-sep
    q(:,:,1:2,:,:,2,2,:,3,1:K)    =(1-repmat(reshape(s(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(  max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;
    % 4) t+1: bh, sep
    q(:,:,1:2,:,:,1,2,:,4,1:K)    =   repmat(reshape(s(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(1-max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;
    % 4) t+1, gh, sep
    q(:,:,1:2,:,:,2,2,:,4,1:K)    =   repmat(reshape(s(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(  max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;



%%% High Education && Employed in t
% > & bad-health in t:
    % 1) t+1 bh; non-sep
    q(:,:,3:4,:,:,1,2,:,1,1:K)    =(1-repmat(reshape(s(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(1-max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
    % 1) t+1 gh; non-sep
    q(:,:,3:4,:,:,2,2,:,1,1:K)    =(1-repmat(reshape(s(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(  max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
    % 2) t+1 bh; sep
    q(:,:,3:4,:,:,1,2,:,2,1:K)    =   repmat(reshape(s(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(1-max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
    % 2) t+1 gh; sep
    q(:,:,3:4,:,:,2,2,:,2,1:K)    =   repmat(reshape(s(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(  max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
% > & good-health in t:
    % 3) t+1: bh, non-sep
    q(:,:,3:4,:,:,1,2,:,3,1:K)    =(1-repmat(reshape(s(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(1-max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;
    % 3) t+1 gh; non-sep
    q(:,:,3:4,:,:,2,2,:,3,1:K)    =(1-repmat(reshape(s(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ])).*(  max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;
    % 4) t+1 bh; sep
    q(:,:,3:4,:,:,1,2,:,4,1:K)    =   repmat(reshape(s(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(1-max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;
    % 4) t+1 gh; sep
    q(:,:,3:4,:,:,2,2,:,4,1:K)    =   repmat(reshape(s(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1   K  ]) .*(  max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd; 



%%% Low Education && Unemployed in t
    % - job-offer probabilites apply
    % - unemployment in t indicated by dim-10 of q (choice in t)
% > & bad-health in t:
    q(:,:,1:2,:,:,1,1,:,1,K+1:J-1)=   repmat(reshape(o(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(1-max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
    q(:,:,1:2,:,:,2,1,:,1,K+1:J-1)=   repmat(reshape(o(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(  max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
    q(:,:,1:2,:,:,1,1,:,2,K+1:J-1)=(1-repmat(reshape(o(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(1-max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
    q(:,:,1:2,:,:,2,1,:,2,K+1:J-1)=(1-repmat(reshape(o(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(  max(hbg(t+1,1)-((1-hbg(t+1,1)).*DeltaH1),0)).*wd;
% > & good-health in t    
    q(:,:,1:2,:,:,1,1,:,3,K+1:J-1)=   repmat(reshape(o(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(1-max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;
    q(:,:,1:2,:,:,2,1,:,3,K+1:J-1)=   repmat(reshape(o(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(  max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;
    q(:,:,1:2,:,:,1,1,:,4,K+1:J-1)=(1-repmat(reshape(o(1:2,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(1-max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;
    q(:,:,1:2,:,:,2,1,:,4,K+1:J-1)=(1-repmat(reshape(o(1:2,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(  max(hgg(t+1,1)-((1-hgg(t+1,1)).*DeltaH2),0)).*wd;

    

%%% High Education && Unemployment in t
% > & bad-health in t
    q(:,:,3:4,:,:,1,1,:,1,K+1:J-1)=   repmat(reshape(o(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(1-max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
    q(:,:,3:4,:,:,2,1,:,1,K+1:J-1)=   repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(  max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
    q(:,:,3:4,:,:,1,1,:,2,K+1:J-1)=(1-repmat(reshape(o(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(1-max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
    q(:,:,3:4,:,:,2,1,:,2,K+1:J-1)=(1-repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(  max(hbg(t+1,2)-((1-hbg(t+1,2)).*DeltaH1),0)).*wd;
% > & good-health in t    
    q(:,:,3:4,:,:,1,1,:,3,K+1:J-1)=   repmat(reshape(o(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(1-max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;
    q(:,:,3:4,:,:,2,1,:,3,K+1:J-1)=   repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1]) .*(  max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;
    q(:,:,3:4,:,:,1,1,:,4,K+1:J-1)=(1-repmat(reshape(o(3:4,1,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(1-max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;
    q(:,:,3:4,:,:,2,1,:,4,K+1:J-1)=(1-repmat(reshape(o(3:4,2,:,t+1),1,1,2,1,1,1,1,M),[S E 1 L D 1 1 1 1 J-K-1])).*(  max(hgg(t+1,2)-((1-hgg(t+1,2)).*DeltaH2),0)).*wd;



end