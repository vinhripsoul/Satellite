function [xvec] = RKplot(PeriodInSec,rN,vN,muEarth)
   
    dt=0.1;
    tvector=(0:dt:PeriodInSec);
    vt=length(tvector);
    x0=[rN;vN];
    xvec=zeros(6,vt+1);
    xvec(:,1)=x0;
    
    for k=1:vt
        xvec(:,k+1) = tobe(xvec(:,k),tvector(k),dt,muEarth);
    end
    
end