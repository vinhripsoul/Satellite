function [rE,vE] = ECI2ECEF(year,month,day,hour,minute,second,rN,vN)
    omegaEarth = 7.2921158e-5;

    JD = JulianDay(year,month,day,hour,minute,second);
    thetaERA = mod(280.46061837504 + 360.985612288808*(JD - 2451545),360);
    Rot3 = [cosd(thetaERA) sind(thetaERA) 0;
           -sind(thetaERA) cosd(thetaERA) 0;
           0 0 1];

    rE = Rot3*rN;
    vE = -omegaEarth*rE + Rot3*vN;