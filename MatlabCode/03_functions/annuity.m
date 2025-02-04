%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actuarially fair annuity value of accumulated wealth %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fav] = annuity(t,calib,data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unpack:
% -------

ann_calib   = {'fieldnames','S','nwgrid','tau'};
ann_data    = {'fieldnames','spbh','spgh'};


%%% unpack model calibration and mortality data
v2struct(calib,ann_calib);
v2struct(data,ann_data);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Derivation:
% -----------
fav=zeros(S,4);

%%% probability of dying:
dp(:,1)=[(1-spbh(t+1:80,t,1))' 1]';
dp(:,2)=[(1-spgh(t+1:80,t,1))' 1]';
dp(:,3)=[(1-spbh(t+1:80,t,2))' 1]';
dp(:,4)=[(1-spgh(t+1:80,t,2))' 1]';

%%% gen probability weights for annuity derivation:
px(:,1)=[(1-spbh(t,t,1)) cumprod(spbh(t:80,t,1),1)'.*dp(:,1)']';
px(:,2)=[(1-spgh(t,t,1)) cumprod(spgh(t:80,t,1),1)'.*dp(:,2)']';
px(:,3)=[(1-spbh(t,t,2)) cumprod(spbh(t:80,t,2),1)'.*dp(:,3)']';
px(:,4)=[(1-spgh(t,t,2)) cumprod(spgh(t:80,t,2),1)'.*dp(:,4)']';

%%% derive annuity weighted by survival probabilities
for i=1:(99-(t+19))
    fav(:,1)=fav(:,1)+px(i,1).*nwgrid(:,1)./(((1-(1+tau)^(-i))/tau)*(1+tau));
    fav(:,2)=fav(:,2)+px(i,2).*nwgrid(:,1)./(((1-(1+tau)^(-i))/tau)*(1+tau));
    fav(:,3)=fav(:,3)+px(i,3).*nwgrid(:,1)./(((1-(1+tau)^(-i))/tau)*(1+tau));
    fav(:,4)=fav(:,4)+px(i,4).*nwgrid(:,1)./(((1-(1+tau)^(-i))/tau)*(1+tau));
end

end