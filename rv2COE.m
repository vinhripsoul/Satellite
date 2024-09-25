function [a,e,i,omega,raan,nu] = rv2COE(mu,rN,vN)
    r = norm(rN);
    v = norm(vN);
    hVec = cross(rN,vN);
    h = norm(hVec);
    nZ = [0;0;1];
    n = norm(nZ);
    h3 = hVec(end);

    % Find a 
        a = (2/r - v^2/mu)^(-1);

    % Find e 
        eVec = 1/mu*cross(vN,hVec)-1/r*rN;
        e = norm(eVec);

    % Find nu 
        nu = acos( (rN'*eVec) / (r*e) )*180/pi;

        if rN'*vN < 0 
            nu = nu+180;
        end
        

    % Find i 
        i = acos(h3/h)*180/pi;

    % Find raan 
        eH = hVec/h;
        eN = cross(nZ,eH);
        eN1 = eN(1,1);
        raan = acos(eN1/norm(eN))*180/pi;

        if eN(2,1) < 0
            raan = 360-raan;
        end

    % Find omega
        eE = eVec/e;
        omega = acos((eN'*eE)/(norm(eN)*norm(eE)))*180/pi;
        
        if eE(3,1) < 0
            omega = 360-omega;
        end


end