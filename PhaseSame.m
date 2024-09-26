function [deltaV,time,achase] = PhaseSame(atarget,theta,k,mu)

    % Calculation
        omegatarget = sqrt(mu/(atarget^3));
        Pchase = 2*pi*atarget^(3/2)/sqrt(mu) + theta*(pi/180)/(k*omegatarget);
        achase = ((mu*Pchase^2)/(4*pi^2))^(1/3);
        Vchase = sqrt(mu*(2/atarget - 1/achase));
        Vtarget=sqrt(mu/atarget);
        deltaV = 2*abs(Vtarget-Vchase);
        time = k*Pchase;
    
end