% function MetaVol=interface_p2_1D(param)
param=.0;
%% for only 1 straight grain boundary without particle
% clear all
savedir='test';
mkdir(savedir)
% figure;
% clf
% phase field parameters
L=5*[1 1]*1;
alpha=1*[1 1]*1;
beta=1*[1 1]*1;
gamma=1*1.5*[1 1]*1;
kappa=1*[1 1]*1;
epsilon=5*1;

DelG=[0 param];
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
scale=5;
mboxsize=15*scale; % y axis in pixels
nboxsize=1; % x axis
delx=2/scale;      % length unit per pixelx
grainD=15*scale;  % in pixels

% Particle geometry
pr=10;  % size in length unit
xparticle=fix(nboxsize/2); % position on the grid
yparticle=fix(mboxsize/2*7.5/10);


timestepn=300;
delt=0.005;

% *** Phase Field Procedure *** (so small and simple piece of code!)
eta=zeros(mboxsize,nboxsize,p);
% making initial structure
% eta(:,:,1)=circlegrain(mboxsize,nboxsize,nboxsize/2,5*mboxsize/10,grainD,'dome');
% eta(:,:,2)=imcomplement(eta(:,:,1));
eta(:,:,1)=zeros(mboxsize,nboxsize);
x=0.4;
x=fix(mboxsize*x);
eta(1:x,:,1)=1;
eta(:,:,2)=imcomplement(eta(:,:,1));

% ppf is phase variable representing particles
%particledistro(nboxsize,mboxsize,particles_number,radius)
% [ppf]=particledistro(nboxsize,mboxsize,1,pr/delx*2,xparticle,yparticle);
ppf=zeros(mboxsize,nboxsize);
% ppf(1:mboxsize/2,:)=1;
eta2=zeros(mboxsize,nboxsize,p); %pre-assignment

%savesettings
save(strcat(pwd,'/',savedir,'/','setings.mat'))

%initialization
j=1;
for tn=1:40
    for i=1:mboxsize
            del2=1/delx^2*(0.5*(eta(indg(i+1,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-1,mboxsize),j,:))...
                +0.25*(eta(indg(i+2,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-2,mboxsize),j,:)));
            sumterm=eta(i,j,:)*sum(eta(i,j,:).^2)-eta(i,j,:).^3;
            detadtM=-alpha.*reshape(eta(i,j,:),1,p)+beta.*reshape(eta(i,j,:),1,p).^3-kappa.*reshape(del2,1,p);
            detadt=-L.*(detadtM+2*gamma(1)*reshape(sumterm,1,p));
            eta2(i,j,:)=eta(i,j,:)+reshape(delt*detadt,1,1,2);
    end
    eta=eta2;
end

j=1;
for tn=1:timestepn
    for i=1:mboxsize
            del2=1/delx^2*(0.5*(eta(indg(i+1,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-1,mboxsize),j,:))...
                +0.25*(eta(indg(i+2,mboxsize),j,:)-2*eta(i,j,:)+eta(indg(i-2,mboxsize),j,:)));
            sumterm=eta(i,j,:)*sum(eta(i,j,:).^2)-eta(i,j,:).^3;
            detadtM=-alpha.*reshape(eta(i,j,:),1,p)+beta.*reshape(eta(i,j,:),1,p).^3-kappa.*reshape(del2,1,p)+...
                +6*(reshape(eta(i,j,:),1,p)-reshape(eta(i,j,:),1,p).^2).*DelG;
            detadt=-L.*(detadtM+2*gamma(1)*reshape(sumterm,1,p));
            eta2(i,j,:)=eta(i,j,:)+reshape(delt*detadt,1,1,2);
    end
    eta=eta2;
    phi=sum(eta(:,:,1:p).^2,3);
    phi=phi+ppf;
%     [cur1,cur2,detach,cent1,cent2]=analysecontourgrains(eta,xparticle,yparticle,tn,ppf);
%     cent1p=cent1;
%     cent2p=cent2;

    %%% Visulaizations

    %% simple structure
    %   subplot(2,3,1)
    %
    % drawgrains(phi,xparticle,yparticle,tn)
    %     contourgrains(eta,xparticle,yparticle,tn,ppf)
    %% Energy plots
    %     [ME,E]=calculateE(eta,ppf,mboxsize,nboxsize,delx);
    % VecE(tn)=E;
    %     drawE(rot90(rot90(ME)),xparticle,yparticle,tn,eta,ppf)

    %% Middle point curvature and speed
%     [cur1,cur2,detach,cent1,cent2]=analysecontourgrains(eta,xparticle,yparticle,tn,ppf);
%     curi1(tn)=cur1;
%     curi2(tn)=cur2;
%     detachi(tn)=detach;
    %% speed
    %     speed1(tn)=(cent1-cent1p)/delt;
    %     speed2(tn)=(cent2-cent2p)/delt;
    %     cent1p=cent1;
    %     cent2p=cent2;
%     Mcent1(tn)=cent1;Mcent2(tn)=cent2;

    %
    %     %% Speed Plots
    %     subplot(2,3,[6])
    %     plot(timevec(2:end),speed1,timevec(2:end),speed2,'r');
    %     title(strcat('v_{\eta_1}= ', num2str(speed1(tn)),' , ',...
    %         'v_{\eta_2}= ', num2str(speed2(tn))));
    %     xlabel('time')
    %     %% Curvature Plots
    %     subplot(3,1,3)
    %     plot(timevec(2:end),curi1,timevec(2:end),curi2,'r');
    %         xlabel('time')
    %     title(strcat('\kappa_{\eta_1}= ', num2str(cur1),' , ',...
    %         '\kappa_{\eta_2}= ', num2str(cur2)));


    %% Velocity map
%     [nablaetax,nablaetay]=gradient(eta(:,:,1),delx,delx);
%     %     nablaetax((phi>0.99))=nan;
%     %     nablaetay((phi>0.99))=nan;
%     Mvelocx=Mdetadt./nablaetax;
%     Mvelocy=Mdetadt./nablaetay;
%     %         Mveloc=sqrt(Mvelocx.^2+Mvelocy.^2);
%     Mveloc=Mdetadt./sqrt(nablaetax.^2+nablaetay.^2);
    %
    %% Average velocity field over certain area of the domain:
%     [vel]=aveveloc(Mveloc,phi,ppf,Mdetadt,'dome');
%     Mvel(tn)=vel;
%     %     MD(tn)=D;
%     h=subplot(2,3,1);
%     plot(timevec(2:end),-Mvel)
%     title('Velocity average based on the field')
%     xlabel(strcat('Time= ', num2str(tn*delt)))

    %% plotting places where average velocity is calculated
%     maxM=0.9*max(max(abs(Mdetadt)));
%     h=subplot(2,3,6);
%     phivel=phi;
%     phivel(abs(Mdetadt)>maxM)=0;
%     imshow(phivel)

    %     h=subplot(2,3,2);
    %     drawvelocity(Mvelocx);
    %     set(h,'clim',[-0.5 0.5])
    %     title('X velocity component')
    %     %
    %     h=subplot(2,3,3);
    %     drawvelocity(Mvelocy)
    %     set(h,'clim',[-0.7 0.7])
    %     title('Y velocity component')
    %
%     h=subplot(2,3,2);
%     drawvelocity(Mveloc)
%     set(h,'clim',[-0.9 0])
%     title('Velocity Magnitude')
%     xlabel(strcat('Time= ', num2str(tn*delt)))
%     %
    %     h=subplot(2,3,6);
    %     drawvelocity(nablaetax)
    %     set(h,'clim',[-0.3 0.3])
    %     title('\nabla \eta x')
    %
    %     h=subplot(2,3,4);
    %     drawvelocity(nablaetay)
    %     set(h,'clim',[-0.3 0.3])
    %     title('\nabla \eta y')
    %
    %     h=subplot(2,3,1);
    %     drawvelocity(Mdetadt)
    %     set(h,'clim',[-0.2 0])
    %     title('d\eta / dt')

    %% Force on a circular region inside the domain
%     [F,Fprofile,ME,xp,yp]=Force(eta,ppf,setings,pr,xparticle,yparticle);
%     Mforce(:,tn)=F';
%     h=subplot(2,3,4);
%     plot(timevec(2:end),Mforce(2,:))
%     hold on
%     plot(timevec(2:end),Mforce(1,:),'r')
%     title('Force acting on circular region, red=Fx, blue=Fy')
%     xlabel(strcat('Time= ', num2str(tn*delt)))
%     hold off

    %% Draw Energy Field
%    h=subplot(2,1,2);
    [ME,E]=calculateE(eta,ppf,mboxsize,nboxsize,delx,settings);
%     drawvelocity(ME)
%     title(['Energy density at timestep' num2str(tn)])
    % %     set(h,'clim',[-0.2 0])



    %% Volume of each phase field
     etaVol=etaVolume(eta(:,1,1),delx,nboxsize,mboxsize,'high');
     MetaVol(:,tn)=etaVol;
%     h=subplot(2,3,5);
%     plot(timevec(2:end),MetaVol(1,:)/(mboxsize*nboxsize*delx^2))
%     hold on
%     plot(timevec(2:end),MetaVol(2,:)/(mboxsize*nboxsize*delx^2),'r')
%     plot(timevec(2:end),(MetaVol(1,:)+MetaVol(2,:))/(mboxsize*nboxsize*delx^2),'g')
%     title('Volume fraction of phases')
%     xlabel(strcat('Time= ', num2str(tn*delt)))
%     hold off

   %% Draw del2 Field
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


    %     disp(strcat('Time= ', num2str(tn*delt)))

    % plotting profiles of energy order parameters
% figure
% clf 
% y=[1:mboxsize]*delx-mboxsize*delx/2;
% subplot(2,1,1)
% plot(y,eta(:,fix(nboxsize/2)+1,1))
% hold on
% plot(y,eta(:,fix(nboxsize/2)+1,2),'r')
% ylabel('Ordere Parameter')
% plot(y,ppf(:,fix(nboxsize/2)+1),'g')
% 
% plot(mboxsize/2*delx*[0 0],[0 1],'k')
% 
% subplot(2,1,2)
% plot(y,ME(:,fix(nboxsize/2)+1),'r')
% xlabel('Position (X unit)')
% ylabel('Energy Density')
% title(['Energy density at timestep' num2str(tn)])
% grid on
% hold on
% % plot(mboxsize/2*delx*[0 0],[0 0.8e-18],'k')
% pause(0.01)

end

Sigma=E/(nboxsize*delx)*1e18


