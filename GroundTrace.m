function [lat,lon,alt] = GroundTrace(year,month,day,hour,minute,second,rN,vN,PeriodInSec,muEarth)
    
    dt=1;
    tvector=(0:dt:PeriodInSec);
    vt=length(tvector);
    x0=[rN;vN];
    xvec=zeros(6,vt+1);
    xvec(:,1)=x0;
    
    for k=1:vt
        xvec(:,k+1) = tobe(xvec(:,k),tvector(k),dt,muEarth);
    end

    JD0 = JulianDay(year,month,day,hour,minute,second);
   % nt_0 = length(tout_0);
    
    %define space
    lat = zeros(1,vt);
    lon = zeros(1,vt);
    alt = zeros(1,vt);

    for j = 1:vt
        %rN = inertial position vector
        rN = xvec(1:3,j);
        r = norm(rN);
    
        JD = JD0 + tvector(j)/86400;
    
        % theta_ERA = Earth Rotation Angle
        theta_ERA = mod(280.46061837504 + 360.985612288808*(JD - 2451545),360);
    
        % rE = ECEF position vector
        R3 = [cosd(theta_ERA)      sind(theta_ERA)     0;
              -sind(theta_ERA)      cosd(theta_ERA)     0;
              0                     0                   1]; %165
    
        rE = R3 * rN; %(163)
    
        %compute lat long alt
        latitude = asind(rE(3)/r); %(169)
        longitude = atan2d(rE(2), rE(1)); %170
        altitude = r - 6378.137e3; %171
    
        %store value
        lat(j) = latitude;
        lon(j) = longitude;
        alt(j) = altitude;
    end
    