function [rN,vN] = COE2rv(mu,a,e,i,raan,omega,nu)

p = a*(1-e^2);

    % find rN
        r = p/(1+e*cosd(nu));
        rP = [r*cosd(nu)
              r*sind(nu)
              0];
        AnP = [cosd(raan)*cosd(omega)-sind(raan)*sind(omega)*cosd(i),-cosd(raan)*sind(omega)-sind(raan)*cosd(omega)*cosd(i), sind(raan)*sind(i);
               sind(raan)*cosd(omega)+cosd(raan)*sind(omega)*cosd(i), -sind(raan)*sind(omega)+cosd(raan)*cosd(omega)*cosd(i), -cosd(raan)*sind(i);
               sind(omega)*sind(i), cosd(omega)*sind(i), cosd(i)];
        rN = AnP * rP;

    % find vN
        vP = [-sqrt(mu/p)*sind(nu)
              sqrt(mu/p)*(e+cosd(nu))
              0];
        vN = AnP*vP;
end