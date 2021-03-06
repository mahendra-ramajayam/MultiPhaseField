
clear all

simnumber=2
x=0.1; % initial condition.
xend=0.85; % ending potions of interface

figure;
% phase field parameters
L=1*[1 1];
alpha=2*[1 1];
beta=2*[1 1];
gamma=2*1.5*[1 1];
kappa=4*[1 1];
epsilon=5;

DelG=[0 0.2];
% BCValue=value;

% setings structure
settings.L=L(1);
settings.alpha=alpha(1);
settings.beta=beta(1);
settings.gamma=gamma(1);
settings.kappa=kappa(1);
settings.epsilon=epsilon(1);
settings.DelG=DelG;
settings.accuracy='low';
% geometry settings
p=2;
global nboxsize mboxsize
global delx delt scale
scale=1;
mboxsize=300*scale; % y axis in pixels
nboxsize=100*scale; % x axis
delx=2/scale;      % length unit per pixel

% Particle geometry

timestepn=2000;
delt=0.2;
%savesettings
% save(strcat(pwd,'/',savedir,'/','setings.mat'))

% *** Phase Field Procedure *** (so small and simple piece of code!)
eta=zeros(mboxsize,nboxsize,p);
% making initial structure
% eta(:,:,1)=circlegrain(mboxsize,nboxsize,nboxsize/2,4.5*mboxsize/10,grainD,'dome');
eta(:,:,1)=zeros(mboxsize,nboxsize);
x=fix(mboxsize*x);
eta(1:x,:,1)=1;
eta(:,:,2)=imcomplement(eta(:,:,1));

% particles distribution specification
diameter=2;
particles_fraction=0.1;
% particles number
particlesn=particles_fraction*nboxsize*nboxsize/diameter^2

[ppf,xparticle,yparticle]=particledistroN(mboxsize,nboxsize,particlesn,diameter,'uniform');
eta2=zeros(mboxsize,nboxsize,p); %pre-assignment

%initialization
for tn=1:5
    for i=1:mboxsize
        for j=1:nboxsize
            del2=1/delx^2*(0.5*(eta(indg(i+1,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-1,mboxsize),j,:))...
                +0.25*(eta(indg(i+2,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-2,mboxsize),j,:)))...
                +1/delx^2*(0.5*(eta(i,indg(j+1,nboxsize),:)-2*eta(i,j,:)+eta(i,indg(j-1,nboxsize),:))...
                +0.25*(eta(i,indg(j+2,nboxsize),:)-2*eta(i,j,:)+eta(i,indg(j-2,nboxsize),:)));
            sumterm=eta(i,j,:)*sum(eta(i,j,:).^2)-eta(i,j,:).^3;
            detadtM=(-alpha.*reshape(eta(i,j,:),1,p)+beta.*reshape(eta(i,j,:),1,p).^3-kappa.*reshape(del2,1,p)+...
                2*epsilon.*reshape(eta(i,j,:),1,p)*ppf(i,j))...
                +6*(reshape(eta(i,j,:),1,p)-reshape(eta(i,j,:),1,p).^2).*DelG;
            detadt=-L.*(detadtM+2*gamma(1)*reshape(sumterm,1,p));
            eta2(i,j,:)=eta(i,j,:)+reshape(delt*detadt,1,1,2);
            eta2(i,j,find(eta2(i,j,:)>1))=1;
            eta2(i,j,find(eta2(i,j,:)<0))=0;
        end
    end
    eta=eta2;
    [deletax1 deletay1]=gradient(eta(:,:,1),delx,delx);
    [deletax2 deletay2]=gradient(eta(:,:,2),delx,delx);
    phi=imcomplement(abs(deletax1)+abs(deletay1)+abs(deletax2)+abs(deletay2));
    imshow(phi)
    title(num2str(tn))
    pause(0.01)
end

se=strel('square',6);
timevec=0;
tn=0;
xend=fix(mboxsize*xend);
while eta(xend,1,1)<0.5 % when interface arrives at xend
%     Mdetadt=zeros(mboxsize,nboxsize);
    tn=tn+1
    [yii,xjj]=find(...
        imerode((phi>0.9),se)==0);
    for ii=1:length(xjj)
        i=yii(ii);j=xjj(ii);
        del2=1/delx^2*(0.5*(eta(indg(i+1,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-1,mboxsize),j,:))...
            +0.25*(eta(indg(i+2,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-2,mboxsize),j,:)))...
            +1/delx^2*(0.5*(eta(i,indg(j+1,nboxsize),:)-2*eta(i,j,:)+eta(i,indg(j-1,nboxsize),:))...
            +0.25*(eta(i,indg(j+2,nboxsize),:)-2*eta(i,j,:)+eta(i,indg(j-2,nboxsize),:)));
        sumterm=eta(i,j,:)*sum(eta(i,j,:).^2)-eta(i,j,:).^3;
        detadtM=(-alpha.*reshape(eta(i,j,:),1,p)+beta.*reshape(eta(i,j,:),1,p).^3-kappa.*reshape(del2,1,p)+...
            2*epsilon.*reshape(eta(i,j,:),1,p)*ppf(i,j))...
            +6*(reshape(eta(i,j,:),1,p)-reshape(eta(i,j,:),1,p).^2).*DelG;
        detadt=-L.*(detadtM+2*gamma(1)*reshape(sumterm,1,p));
        % matrix of the eta.dot
        eta2(i,j,:)=eta(i,j,:)+reshape(delt*detadt,1,1,2);
        eta2(i,j,find(eta2(i,j,:)>1))=1;
        eta2(i,j,find(eta2(i,j,:)<0))=0;
    end
    eta=eta2;

    % making optimization matrix
    [deletax1 deletay1]=gradient(eta(:,:,1),delx,delx);
    [deletax2 deletay2]=gradient(eta(:,:,2),delx,delx);
    phi=imcomplement(abs(deletax1)+abs(deletay1)+abs(deletax2)+abs(deletay2));
    %     phi=sum(eta(:,:,1:p).^2,3);

    timevec(tn+1)=timevec(tn)+delt;
    %%% Visulaizations

    %% simple structure
    %   subplot(2,3,1)
    drawgrains(phi,xparticle,yparticle,tn)
    %     contourgrains(eta,xparticle,yparticle,tn,ppf)

    %% Draw Energy Field
    %    h=subplot(2,1,2);
    %     [ME,E]=calculateE(eta,ppf,mboxsize,nboxsize,delx,settings);
    %     drawvelocity(ME)
    %     MME(tn)=E;
    %     title(['Energy density at timestep' num2str(tn)])
    % %     set(h,'clim',[-0.2 0])

    %% Volume of each phase field
    etaVol=etaVolume(eta(:,:,1),delx,nboxsize,mboxsize,'low');
    MetaVol(tn)=etaVol;
    %     h=subplot(2,3,5);
    %     plot(timevec(2:end),MetaVol(1,:)/(mboxsize*nboxsize*delx^2))
    %     hold on
    %     plot(timevec(2:end),MetaVol(2,:)/(mboxsize*nboxsize*delx^2),'r')
    %     plot(timevec(2:end),(MetaVol(1,:)+MetaVol(2,:))/(mboxsize*nboxsize*delx^2),'g')
    %     title('Volume fraction of phases')
    %     xlabel(strcat('Time= ', num2str(tn*delt)))
    %     hold off

    % %% Draw del2 Field
    %    h=subplot(2,1,1);
    %
    %     drawvelocity(Mdel2)
    %
    %     % %     set(h,'clim',[-0.2 0])
    %     title(['\nabla^2 at timestep' num2str(tn)])

    %   savegrains(eta,ppf,E,xparticle,yparticle,tn,savedir)

    % additional expriments
    %     MMdetadt(:,:,tn)=Mdetadt;
    %     MMeta1(:,:,tn)=eta(:,:,1);
    %
    %% SAVING

    %  save(strcat(pwd,'/',savedir,'/',num2str(tn),'.mat'),...
    %      'Mdetadt','eta','Mveloc','Mvelocx','Mvelocy','tn')
    pause(0.01)
    %     disp(strcat('Time= ', num2str(tn*delt)))

    %% find position of interfface on the corner
    %
    %     intindex=find(eta(:,end,1)>0.01 & eta(:,end,1)<0.99);
    %     intpos=interp1(eta(intindex,end,1),intindex*delx,0.5,'spline');
    %     Mintpos(tn)=intpos;
    %         if mod(tn,200)==0
    %                 drawvelocity(ME)
    %                 title(['Energy density at timestep' num2str(tn)])
    % %               filename=strcat(pwd,'/',num2str(tn),'.png');
    % %             print('-f1','-dpng','-r100',filename)
    %         end
end

savedir='/media/disk/sim_res/Nparticle_interface/';
mkdir(savedir)
save([savedir num2str(simnumber) '.mat'])

return
load('/media/disk/sim_res/Nparticle_interface/0.mat')
% particles volume fraction
pf=sum(sum(ppf))/mboxsize/nboxsize;
MV=MetaVol+pf.*MetaVol;
t=timevec(2:end);
 figure
 plot(t,MV,'g')

pp=polyfit(t,MV,1);
intvel=pp(1)/(nboxsize*delx)

intvel0=2.7725;
Pf=DelG(2)*(1-intvel/intvel0)


