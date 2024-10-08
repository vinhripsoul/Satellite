clc;
clear all;
close all;
format longg; 
options = odeset('RelTol',1e-12,'AbsTol',1e-12);

% GIVENS              %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Universal
        muEarth = 3.986004418e14; % m^3 / s^2
        REarth = 6378.137e3; % meter
        costTime = 3500/3600; % $/seconds
        costDeltaV = 250; % $*seconds/meter
        year = 2023;
        month = 2;
        day = 1;
        hour = 0;
        minute = 0;
        second = 0;
    % GPS
        aGPS = 26558e3; % meter
        eGPS = 0;
        iGPS = 54.96; % degree
        omegaGPS = 0; % degree
        raanGPS = 30; % degree
        nuGPS = 0; % degree
    % Satellite
        aSAT = 42164e3; % meter
        eSAT = 0; % degree
        iSAT = 0; % degree
        omegaSAT = 0; % degree
        raanSAT = 30; % degree
        nuSAT = 150; % degree
    % LEO Graveyard
        aLEOgrave = 6553.137e3; % meter
    % GEO Graveyard
        aGEOgrave = 42664e3; % meter
    % LEO Staging
        aLEOstage = REarth+450e3; % meter
        iLEOstage = 45; % degree
    % GEO Staging
        aGEOstage = 42164e3; % meter
        iGEOstage = 0; % degree
    % MOSS
        latMOSS = 37.17;
        longMOSS = -5.62;
    % GEODSS
        latGEODSS = 20.71;
        longGEODSS = -156.26;


% CALCULATIONS            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 1. Satellite plane change to GPS inclination
        [rNSAT1i,vNSAT1i] = COE2rv(muEarth,aSAT,eSAT,iSAT,raanSAT,omegaSAT,nuSAT); % start position
        % Time required
            PSAT = 2*pi*aSAT^(3/2) / sqrt(muEarth);
            nuSAT1f = 180 - omegaSAT; % now at descending node (also is apogee)
            t1 = (nuSAT1f - nuSAT)/360 * PSAT;
        % Delta V required
            deltai1 = iGPS - iSAT;
            v1 = sqrt(muEarth/aSAT);
            deltaV1 = abs(2*v1*sind(deltai1/2));

        [rNSAT1f,vNSAT1f] = COE2rv(muEarth,aSAT,eSAT,iGPS,raanSAT,omegaSAT,nuSAT1f); % end position


    % 2. Satellite transfer to GPS orbit
        [rNSAT2i,vNSAT2i] = COE2rv(muEarth,aSAT,eSAT,iGPS,raanSAT,omegaSAT,nuSAT1f); % start position
        % Time and Delta V required
            [case1_2,time1_2,atrans1_2,case2_2,time2_2,atrans2_2,~,~,~,deltaV2_2] = deltaV(aSAT,aSAT,aSAT,aGPS,aGPS,aGPS,muEarth);
            deltaV2 = case2_2; % m/s
            t2 = time2_2;
        % Calculating transfer orbit
            etrans2 = aSAT/atrans2_2 - 1;
            Ptrans2 = t2;
            [rNtrans2,vNtrans2] = COE2rv(muEarth,atrans2_2,etrans2,iGPS,raanSAT,omegaSAT,nuSAT1f);
            [tout2,trans2] = ode45(@tobeom,[0,Ptrans2],[rNtrans2',vNtrans2'],options,muEarth);

            rNtrans2f = trans2(end,1:3)'; % Satellite is now at perigee of GPS
            vNtrans2f = trans2(end,4:6)';


    % 3. Satellite chases GPS
        PGPS = 2*pi*aGPS^(3/2) / sqrt(muEarth);
        nuGPS3 = (t2+t1)/PGPS * 360;
        theta3 = 360-nuGPS3;
        [deltaV3,t3,achase3] = PhaseSame(aGPS,theta3,1,muEarth); 
            % k=1 -> t=4.7271e4, delv = 229.5232 -> $103339
            % k=2 -> t=9.0344e4, delv = 120.0423 -> $117845
            %Vnew = Vold -delta* vold/norm(vold)

        vNnew3_1 = vNtrans2f - deltaV2_2*(vNtrans2f/norm(vNtrans2f)); %go from transfer orbit to GPS orbit
        vNnew3_2 = vNnew3_1 + (deltaV3 / 2)*(vNnew3_1/norm(vNnew3_1)); %go from GPS orbit to phasing orbit
        [tout3,plot3a] = ode45(@tobeom,[0,t3],[rNtrans2f',vNnew3_2'],options,muEarth);
        vNnew3_3 = vNnew3_2 - (deltaV3 / 2)*(vNnew3_2/norm(vNnew3_2)); %go from phasing orbit back to GPS orbit
        

    % 4. Satellite (with GPS) transfer to graveyards
        % GEO (Chose this one)
            % Time and Delta V required
                [dVGEOgrave1,timeGEOgrave1,atransGEOgrave1,dVGEOgrave2,timeGEOgrave2,atransGEOgrave2,~,deltaEndApogee4,~,~] = deltaV(aGPS,aGPS,aGPS,aGEOgrave,aGEOgrave,aGEOgrave,muEarth);
                deltaV4_1 = dVGEOgrave2; % m/s
                t4_1 = timeGEOgrave2;
                costGEOgrave = (t4_1/3600*3500)+(deltaV4_1/1000*250000);
            % Calculating transfer orbit
                etrans4_1 = aGEOgrave/atransGEOgrave2 - 1;
                [rNtrans4_1,vNtrans4_1] = COE2rv(muEarth,atransGEOgrave2,etrans4_1,iGPS,raanGPS,omegaGPS,0);
                [tout4_1,trans4_1] = ode45(@tobeom,[0,t4_1],[rNtrans4_1',vNtrans4_1'],options,muEarth);
                rNtrans4f = trans4_1(end,1:3)';
                vNtrans4f = trans4_1(end,4:6)';
            % Orbit 1 period
                PGEOgrave = 2*pi*aGEOgrave^(3/2) / sqrt(muEarth);
                vNnew4_1 = vNtrans4f + deltaEndApogee4*(vNtrans4f/norm(vNtrans4f)); %go from transfer orbit to GEOgrave orbit
                [tout4,plot4] = ode45(@tobeom,[0,PGEOgrave],[rNtrans4f',vNnew4_1'],options,muEarth);

        % LEO
            % Time and Delta V required
                [dVLEOgrave1,timeLEOgrave1,atransLEOgrave1,dVLEOgrave2,timeLEOgrave2,atransLEOgrave2,~,~,~,~] = deltaV(aGPS,aGPS,aGPS,aLEOgrave,aLEOgrave,aLEOgrave,muEarth);
                deltaV4_2 = dVLEOgrave2; % m/s
                t4_2 = timeLEOgrave2;
                costLEOgrave = (t4_2/3600*3500)+(deltaV4_2/1000*250000);


    % 5. Satellite plane change to staging orbits
        % LEO
            % Delta V for inclination
                deltai5LEOi = iLEOstage - iGPS;
                v5_1 = sqrt(muEarth/aGEOgrave);
                deltaV5_1 = abs(2*v5_1*sind(deltai5LEOi/2));
            % Transfer
                [dVLEOstage1,timeLEOstage1,atransLEOstage1,dVLEOstage2,timeLEOstage2,atransLEOstage2,~,~,~,deltaEndPerigeeLEO5] = deltaV(aGEOgrave,aGEOgrave,aGEOgrave,aLEOstage,aLEOstage,aLEOstage,muEarth);
                deltaV5LEOt = dVLEOstage2; % m/s
                t5LEO = timeLEOstage2;
            % Calculating transfer orbit
                etrans5LEO = aGEOgrave/atransLEOstage2 - 1;
                [rNtrans5_1,vNtrans5_1] = COE2rv(muEarth,atransLEOstage2,etrans5LEO,iLEOstage,raanGPS,omegaGPS,180);
                [tout5_1,trans5_1] = ode45(@tobeom,[0,t5LEO],[rNtrans5_1',vNtrans5_1'],options,muEarth);
                rNtrans5_1f = trans5_1(end,1:3)';
                vNtrans5_1f = trans5_1(end,4:6)';
            
                costLEOstage = (t5LEO/3600*3500)+((deltaV5_1+deltaV5LEOt)/1000*250000);
        % GEO (Chose this one)
            % Delta V required for inclination
                deltai5_2 = iGEOstage - iGPS;
                v5_2 = sqrt(muEarth/aGEOgrave);
                deltaV5_2 = abs(2*v5_2*sind(deltai5_2/2));
            % Transfer
                [dVGEOstage1,timeGEOstage1,atransGEOstage1,dVGEOstage2,timeGEOstage2,atransGEOstage2,~,~,~,deltaEndPerigeeGEO5] = deltaV(aGEOgrave,aGEOgrave,aGEOgrave,aGEOstage,aGEOstage,aGEOstage,muEarth);
                deltaV5GEOt = dVGEOstage2; % m/s
                t5GEO = timeGEOstage2;
            % Calculating transfer orbit
                etrans5GEO = aGEOgrave/atransGEOstage2 - 1;
                [rNtrans5_2,vNtrans5_2] = COE2rv(muEarth,atransGEOstage2,etrans5GEO,iGEOstage,raanGPS,omegaGPS,180);
                [tout5_2,trans5_2] = ode45(@tobeom,[0,t5GEO],[rNtrans5_2',vNtrans5_2'],options,muEarth);
                rNtrans5_2f = trans5_2(end,1:3)';
                vNtrans5_2f = trans5_2(end,4:6)';
            
                costGEOstage = (t5GEO/3600*3500)+((deltaV5_2+deltaV5GEOt)/1000*250000);
    % 6. Final data
        totaldeltaV = deltaV1 + deltaV2 + deltaV3 + deltaV4_1 + deltaV5_2 + deltaV5GEOt;
        totaltime = t1 + t2 + t3 + t4_1 + PGEOgrave + t5GEO;
        profit = 2500000 - (totaldeltaV/1000 * 250000 + totaltime/3600*3500);
        
%%{
% TRACES        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ground trace Satellite
        tTotal1 = t1;
        tTotal2 = t1 + t2;
        tTotal3 = tTotal2 + t3;
        tTotal4a = tTotal3 + t4_1;
        tTotal4b = tTotal4a + PGEOgrave;
        tTotal5 = tTotal4b + t5GEO;
    
        [lat1,lon1,alt1]    = GroundTrace(year,month,day,hour,minute,second,rNSAT1i,vNSAT1i,t1,muEarth); 
        [lat2,lon2,alt2]    = GroundTrace(year,month,day,hour,minute,tTotal1,rNtrans2,vNtrans2,t2,muEarth); 
        [lat3,lon3,alt3]    = GroundTrace(year,month,day,hour,minute,tTotal2,rNtrans2f,vNnew3_2,t3,muEarth); 
        [lat4a,lon4a,alt4a] = GroundTrace(year,month,day,hour,minute,tTotal3,rNtrans4_1,vNtrans4_1,t4_1,muEarth); 
        [lat4b,lon4b,alt4b] = GroundTrace(year,month,day,hour,minute,tTotal4a,rNtrans4f,vNnew4_1,PGEOgrave,muEarth); 
        [lat5,lon5,alt5]    = GroundTrace(year,month,day,hour,minute,tTotal4b,rNtrans5_2,vNtrans5_2,t5GEO,muEarth); 
    
    % Ground trace GPS
        [rNGPS,vNGPS] = COE2rv(muEarth,aGPS,eGPS,iGPS,raanGPS,omegaGPS,nuGPS);
        [lat1GPS,lon1GPS,alt1GPS]    = GroundTrace(year,month,day,hour,minute,second,rNGPS,vNGPS,tTotal3,muEarth); 
        [lat2GPS,lon2GPS,alt2GPS]    = GroundTrace(year,month,day,hour,minute,tTotal3,rNtrans4_1,vNtrans4_1,t4_1,muEarth); 
        [lat3GPS,lon3GPS,alt3GPS]    = GroundTrace(year,month,day,hour,minute,tTotal4a,rNtrans4f,vNnew4_1,tTotal5,muEarth); 
    
    % Sensor MOSS
        % Values without constraints
            [azimuthMOSS1,elevationMOSS1]   = AzElObs(year,month,day,hour,minute,second,rNSAT1i,vNSAT1i,latMOSS,longMOSS,t1,muEarth);
            [azimuthMOSS2,elevationMOSS2]   = AzElObs(year,month,day,hour,minute,tTotal1,rNtrans2,vNtrans2,latMOSS,longMOSS,t2,muEarth); 
            [azimuthMOSS3,elevationMOSS3]   = AzElObs(year,month,day,hour,minute,tTotal2,rNtrans2f,vNnew3_2,latMOSS,longMOSS,t3,muEarth); 
            [azimuthMOSS4a,elevationMOSS4a] = AzElObs(year,month,day,hour,minute,tTotal3,rNtrans4_1,vNtrans4_1,latMOSS,longMOSS,t4_1,muEarth); 
            [azimuthMOSS4b,elevationMOSS4b] = AzElObs(year,month,day,hour,minute,tTotal4a,rNtrans4f,vNnew4_1,latMOSS,longMOSS,PGEOgrave,muEarth); 
            [azimuthMOSS5,elevationMOSS5]   = AzElObs(year,month,day,hour,minute,tTotal4b,rNtrans5_2,vNtrans5_2,latMOSS,longMOSS,t5GEO,muEarth); 
            [azimuthMOSS6,elevationMOSS6]   = AzElObs(year,month,day,hour,minute,second,rNGPS,vNGPS,latMOSS,longMOSS,tTotal3,muEarth);
            [azimuthMOSS7,elevationMOSS7]   = AzElObs(year,month,day,hour,minute,tTotal3,rNtrans4_1,vNtrans4_1,latMOSS,longMOSS,t4_1,muEarth);
            [azimuthMOSS8,elevationMOSS8]   = AzElObs(year,month,day,hour,minute,tTotal4a,rNtrans4f,vNnew4_1,latMOSS,longMOSS,tTotal5,muEarth);
        % Apply constraints
            AzimuthMOSS1 = zeros(size(azimuthMOSS1));
            AzimuthMOSS2 = zeros(size(azimuthMOSS2));
            AzimuthMOSS3 = zeros(size(azimuthMOSS3));
            AzimuthMOSS4a = zeros(size(azimuthMOSS4a));
            AzimuthMOSS4b = zeros(size(azimuthMOSS4b));
            AzimuthMOSS5 = zeros(size(azimuthMOSS5));
            AzimuthMOSS6 = zeros(size(azimuthMOSS6));
            AzimuthMOSS7 = zeros(size(azimuthMOSS7));
            AzimuthMOSS8 = zeros(size(azimuthMOSS8));

            ElevationMOSS1 = zeros(size(elevationMOSS1));
            ElevationMOSS2 = zeros(size(elevationMOSS2));
            ElevationMOSS3 = zeros(size(elevationMOSS3));
            ElevationMOSS4a = zeros(size(elevationMOSS4a));
            ElevationMOSS4b = zeros(size(elevationMOSS4b));
            ElevationMOSS5 = zeros(size(elevationMOSS5));
            ElevationMOSS6 = zeros(size(elevationMOSS6));
            ElevationMOSS7 = zeros(size(elevationMOSS7));
            ElevationMOSS8 = zeros(size(elevationMOSS8));


            j1 = 1;
            j2 = 1;
            j3 = 1;
            j4a = 1;
            j4b = 1;
            j5 = 1;
            j6 = 1;
            j7 = 1;
            j8 = 1;

            for i = 1:length(azimuthMOSS1)
                if elevationMOSS1(i) >= 10 
                    AzimuthMOSS1(j1) = azimuthMOSS1(i); 
                    ElevationMOSS1(j1) = elevationMOSS1(i);
                    j1 = j1 + 1; 
                end
            end
            for i = 1:length(azimuthMOSS2)
                if elevationMOSS2(i) >= 10 
                    AzimuthMOSS2(j2) = azimuthMOSS2(i); 
                    ElevationMOSS2(j2) = elevationMOSS2(i);
                    j2 = j2 + 1; 
                end
            end
            for i = 1:length(azimuthMOSS3)
                if elevationMOSS3(i) >= 10 
                    AzimuthMOSS3(j3) = azimuthMOSS3(i); 
                    ElevationMOSS3(j3) = elevationMOSS3(i);
                    j3 = j3 + 1; 
                end
            end
            for i = 1:length(azimuthMOSS4a)
                if elevationMOSS4a(i) >= 10 
                    AzimuthMOSS4a(j4a) = azimuthMOSS4a(i); 
                    ElevationMOSS4a(j4a) = elevationMOSS4a(i);
                    j4a = j4a + 1; 
                end
            end
            for i = 1:length(azimuthMOSS4b)
                if elevationMOSS4b(i) >= 10 
                    AzimuthMOSS4b(j4b) = azimuthMOSS4b(i); 
                    ElevationMOSS4b(j4b) = elevationMOSS4b(i);
                    j4b = j4b + 1; 
                end
            end
            for i = 1:length(azimuthMOSS5)
                if elevationMOSS5(i) >= 10 
                    AzimuthMOSS5(j5) = azimuthMOSS5(i); 
                    ElevationMOSS5(j5) = elevationMOSS5(i);
                    j5 = j5 + 1; 
                end
            end
            for i = 1:length(azimuthMOSS6)
                if elevationMOSS6(i) >= 10 
                    AzimuthMOSS6(j6) = azimuthMOSS6(i); 
                    ElevationMOSS6(j6) = elevationMOSS6(i);
                    j6 = j6 + 1; 
                end
            end
            for i = 1:length(azimuthMOSS7)
                if elevationMOSS7(i) >= 10 
                    AzimuthMOSS7(j7) = azimuthMOSS7(i); 
                    ElevationMOSS7(j7) = elevationMOSS7(i);
                    j7 = j7 + 1; 
                end
            end
            for i = 1:length(azimuthMOSS8)
                if elevationMOSS8(i) >= 10 
                    AzimuthMOSS8(j8) = azimuthMOSS8(i); 
                    ElevationMOSS8(j8) = elevationMOSS8(i);
                    j8 = j8 + 1; 
                end
            end
        % Final values
        AzimuthMOSS1 = 180+AzimuthMOSS1(1:j1-1);
        AzimuthMOSS2 = 180+AzimuthMOSS2(1:j2-1);
        AzimuthMOSS3 = 180+AzimuthMOSS3(1:j3-1);
        AzimuthMOSS4a = 180+AzimuthMOSS4a(1:j4a-1);
        AzimuthMOSS4b = 180+AzimuthMOSS4b(1:j4b-1);
        AzimuthMOSS5 = 180+AzimuthMOSS5(1:j5-1);
        AzimuthMOSS6 = 180+AzimuthMOSS6(1:j6-1);
        AzimuthMOSS7 = 180+AzimuthMOSS7(1:j7-1);
        AzimuthMOSS8 = 180+AzimuthMOSS8(1:j8-1);

        ElevationMOSS1 = ElevationMOSS1(1:j1-1);
        ElevationMOSS2 = ElevationMOSS2(1:j2-1);
        ElevationMOSS3 = ElevationMOSS3(1:j3-1);
        ElevationMOSS4a = ElevationMOSS4a(1:j4a-1);
        ElevationMOSS4b = ElevationMOSS4b(1:j4b-1);
        ElevationMOSS5 = ElevationMOSS5(1:j5-1);
        ElevationMOSS6 = ElevationMOSS6(1:j6-1);
        ElevationMOSS7 = ElevationMOSS7(1:j7-1);
        ElevationMOSS8 = ElevationMOSS8(1:j8-1);

    % Sensor GEODSS
        % Values without constraints
            [azimuthGEODSS1,elevationGEODSS1]   = AzElObs(year,month,day,hour,minute,second,rNSAT1i,vNSAT1i,latGEODSS,longGEODSS,t1,muEarth);
            [azimuthGEODSS2,elevationGEODSS2]   = AzElObs(year,month,day,hour,minute,tTotal1,rNtrans2,vNtrans2,latGEODSS,longGEODSS,t2,muEarth); 
            [azimuthGEODSS3,elevationGEODSS3]   = AzElObs(year,month,day,hour,minute,tTotal2,rNtrans2f,vNnew3_2,latGEODSS,longGEODSS,t3,muEarth); 
            [azimuthGEODSS4a,elevationGEODSS4a] = AzElObs(year,month,day,hour,minute,tTotal3,rNtrans4_1,vNtrans4_1,latGEODSS,longGEODSS,t4_1,muEarth); 
            [azimuthGEODSS4b,elevationGEODSS4b] = AzElObs(year,month,day,hour,minute,tTotal4a,rNtrans4f,vNnew4_1,latGEODSS,longGEODSS,PGEOgrave,muEarth); 
            [azimuthGEODSS5,elevationGEODSS5]   = AzElObs(year,month,day,hour,minute,tTotal4b,rNtrans5_2,vNtrans5_2,latGEODSS,longGEODSS,t5GEO,muEarth); 
            [azimuthGEODSS6,elevationGEODSS6]   = AzElObs(year,month,day,hour,minute,second,rNGPS,vNGPS,latGEODSS,longGEODSS,tTotal3,muEarth);
            [azimuthGEODSS7,elevationGEODSS7]   = AzElObs(year,month,day,hour,minute,tTotal3,rNtrans4_1,vNtrans4_1,latGEODSS,longGEODSS,t4_1,muEarth);
            [azimuthGEODSS8,elevationGEODSS8]   = AzElObs(year,month,day,hour,minute,tTotal4a,rNtrans4f,vNnew4_1,latGEODSS,longGEODSS,tTotal5,muEarth);
        % Apply constraints
            AzimuthGEODSS1 = zeros(size(azimuthGEODSS1));
            AzimuthGEODSS2 = zeros(size(azimuthGEODSS2));
            AzimuthGEODSS3 = zeros(size(azimuthGEODSS3));
            AzimuthGEODSS4a = zeros(size(azimuthGEODSS4a));
            AzimuthGEODSS4b = zeros(size(azimuthGEODSS4b));
            AzimuthGEODSS5 = zeros(size(azimuthGEODSS5));
            AzimuthGEODSS6 = zeros(size(azimuthGEODSS6));
            AzimuthGEODSS7 = zeros(size(azimuthGEODSS7));
            AzimuthGEODSS8 = zeros(size(azimuthGEODSS8));

            ElevationGEODSS1 = zeros(size(elevationGEODSS1));
            ElevationGEODSS2 = zeros(size(elevationGEODSS2));
            ElevationGEODSS3 = zeros(size(elevationGEODSS3));
            ElevationGEODSS4a = zeros(size(elevationGEODSS4a));
            ElevationGEODSS4b = zeros(size(elevationGEODSS4b));
            ElevationGEODSS5 = zeros(size(elevationGEODSS5));
            ElevationGEODSS6 = zeros(size(elevationGEODSS6));
            ElevationGEODSS7 = zeros(size(elevationGEODSS7));
            ElevationGEODSS8 = zeros(size(elevationGEODSS8));

            k1 = 1;
            k2 = 1;
            k3 = 1;
            k4a = 1;
            k4b = 1;
            k5 = 1;
            k6 = 1;
            k7 = 1;
            k8 = 1;

            for i = 1:length(azimuthGEODSS1)
                if elevationGEODSS1(i) >= 10 
                    AzimuthGEODSS1(k1) = azimuthGEODSS1(i); 
                    ElevationGEODSS1(k1) = elevationGEODSS1(i);
                    k1 = k1 + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS2)
                if elevationGEODSS2(i) >= 10 
                    AzimuthGEODSS2(k2) = azimuthGEODSS2(i); 
                    ElevationGEODSS2(k2) = elevationGEODSS2(i);
                    k2 = k2 + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS3)
                if elevationGEODSS3(i) >= 10 
                    AzimuthGEODSS3(k3) = azimuthGEODSS3(i); 
                    ElevationGEODSS3(k3) = elevationGEODSS3(i);
                    k3 = k3 + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS4a)
                if elevationGEODSS4a(i) >= 10 
                    AzimuthGEODSS4a(k4a) = azimuthGEODSS4a(i); 
                    ElevationGEODSS4a(k4a) = elevationGEODSS4a(i);
                    k4a = k4a + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS4b)
                if elevationGEODSS4b(i) >= 10 
                    AzimuthGEODSS4b(k4b) = azimuthGEODSS4b(i); 
                    ElevationGEODSS4b(k4b) = elevationGEODSS4b(i);
                    k4b = k4b + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS5)
                if elevationGEODSS5(i) >= 10 
                    AzimuthGEODSS5(k5) = azimuthGEODSS5(i); 
                    ElevationGEODSS5(k5) = elevationGEODSS5(i);
                    k5 = k5 + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS6)
                if elevationGEODSS6(i) >= 10 
                    AzimuthGEODSS6(k6) = azimuthGEODSS6(i); 
                    ElevationGEODSS6(k6) = elevationGEODSS6(i);
                    k6 = k6 + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS7)
                if elevationGEODSS7(i) >= 10 
                    AzimuthGEODSS7(k7) = azimuthGEODSS7(i); 
                    ElevationGEODSS7(k7) = elevationGEODSS7(i);
                    k7 = k7 + 1; 
                end
            end
            for i = 1:length(azimuthGEODSS8)
                if elevationGEODSS8(i) >= 10 
                    AzimuthGEODSS8(k8) = azimuthGEODSS8(i); 
                    ElevationGEODSS8(k8) = elevationGEODSS8(i);
                    k8 = k8 + 1; 
                end
            end
        % Final values
        AzimuthGEODSS1 = 180+AzimuthGEODSS1(1:k1-1);
        AzimuthGEODSS2 = 180+AzimuthGEODSS2(1:k2-1);
        AzimuthGEODSS3 = 180+AzimuthGEODSS3(1:k3-1);
        AzimuthGEODSS4a = 180+AzimuthGEODSS4a(1:k4a-1);
        AzimuthGEODSS4b = 180+AzimuthGEODSS4b(1:k4b-1);
        AzimuthGEODSS5 = 180+AzimuthGEODSS5(1:k5-1);
        AzimuthGEODSS6 = 180+AzimuthGEODSS6(1:k6-1);
        AzimuthGEODSS7 = 180+AzimuthGEODSS7(1:k7-1);
        AzimuthGEODSS8 = 180+AzimuthGEODSS8(1:k8-1);

        ElevationGEODSS1 = ElevationGEODSS1(1:k1-1);
        ElevationGEODSS2 = ElevationGEODSS2(1:k2-1);
        ElevationGEODSS3 = ElevationGEODSS3(1:k3-1);
        ElevationGEODSS4a = ElevationGEODSS4a(1:k4a-1);
        ElevationGEODSS4b = ElevationGEODSS4b(1:k4b-1);
        ElevationGEODSS5 = ElevationGEODSS5(1:k5-1);
        ElevationGEODSS6 = ElevationGEODSS6(1:k6-1);
        ElevationGEODSS7 = ElevationGEODSS7(1:k7-1);
        ElevationGEODSS8 = ElevationGEODSS8(1:k8-1);

%}

% PLOTS         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Earth
        figure(1)
        rotate3d on;
        imData = imread('2_no_clouds_4k.jpg');
        
        [xS,yS,zS] = sphere(50);
        earth_radius = 6378137.0;  % meters
        xSE = earth_radius*xS;
        ySE = earth_radius*yS;
        zSE = earth_radius*zS;
        surface(xSE,ySE,zSE);
        axis equal
        grid on
        xlabel('Inertial x (m)')
        ylabel('Inertial y (m)')
        zlabel('Inertial z (m)')
        title('3D Plot of the Satellite Orbits');
        ch = get(gca,'children');
        set(ch,'facecolor','texturemap','cdata',flipud(imData),'edgecolor','none');
        hold on 
    % Position.
        [tout1,plot1] = ode45(@tobeom,[0,t1],[rNSAT1i',vNSAT1i'],options,muEarth);

        
        
        plot3(plot1(:,1),plot1(:,2),plot1(:,3), 'color','#ff0303', 'Linewidth', 2);
        plot3(trans2(:,1),trans2(:,2),trans2(:,3), 'color','#e995fc', 'Linewidth', 2);
        plot3(plot3a(:,1),plot3a(:,2),plot3a(:,3), 'color','#88f502', 'Linewidth', 2);
        plot3(trans4_1(:,1),trans4_1(:,2),trans4_1(:,3), 'color','#028cf5', 'Linewidth', 2);
        plot3(plot4(:,1),plot4(:,2),plot4(:,3), 'color','#050505', 'Linewidth', 2);
        plot3(trans5_2(:,1),trans5_2(:,2),trans5_2(:,3), 'color','#028cf5', 'Linewidth', 2);


        % Orbits plots
%         [rNGPS,vNGPS] = COE2rv(muEarth,aGPS,eGPS,iGPS,raanGPS,omegaGPS,nuGPS);
%         [rNGEOgrave,vNGEOgrave] = COE2rv(muEarth, aGEOgrave,eGPS,iGPS,raanGPS,omegaGPS,nuGPS);
%         [rNLEOstage,vNLEOstage] = COE2rv(muEarth, aLEOstage,eGPS,iLEOstage,raanGPS,omegaGPS,nuGPS);
%         [toutls,plotls] = ode45(@tobeom,[0,100000],[rNLEOstage',vNLEOstage'],options,muEarth);
%         [toutgg,plotgg] = ode45(@tobeom,[0,100000],[rNGEOgrave',vNGEOgrave'],options,muEarth);
%         [toutSAT,plotSAT] = ode45(@tobeom,[0,PSAT],[rNSAT1f',vNSAT1f'],options,muEarth);
%         [toutGPS,plotGPS] = ode45(@tobeom,[0,PGPS],[rNGPS',vNGPS'],options,muEarth);
%         plot3(plotls(:,1),plotls(:,2),plotls(:,3), 'black', 'Linewidth', 2);
%         plot3(plotSAT(:,1),plotSAT(:,2),plotSAT(:,3), 'black', 'Linewidth', 2);
%         plot3(plotGPS(:,1),plotGPS(:,2),plotGPS(:,3), 'yellow', 'Linewidth', 2);
%         plot3(plotgg(:,1),plotgg(:,2),plotgg(:,3), 'cyan', 'Linewidth', 2);


%%{
    % Ground Traces Satellite
        figure(2)
        hold on;

        plot(lon1, lat1, '.','color','#ff0303');  
        plot(lon2, lat2, '.','color','#ff0303');  
        plot(lon3, lat3, '.','color','#ff0303');  
        plot(lon4a, lat4a, '.','color','#ff0303');  
        plot(lon4b, lat4b, '.','color','#ff0303');  
        plot(lon5, lat5, '.','color','#ff0303');  

        grid on; 
        xlim([-180, 180]);
        ylim([-90 90]);
        img = imread('2_no_clouds_4k.jpg');
        h = image(xlim,-ylim,img);
        uistack(h,'bottom')
        alpha(0.6);
        xlabel('Longitude (deg)'); 
        ylabel('Latitude (deg)');
        title('Ground Traces of the Satellite');
        hold off

    % Ground Traces GPS
        figure(3)
        hold on;

        plot(lon1GPS, lat1GPS, '.','color','#88f502');  
        plot(lon2GPS, lat2GPS, '.','color','#88f502');  
        plot(lon3GPS, lat3GPS, '.','color','#88f502');  


        grid on; 
        xlim([-180, 180]);
        ylim([-90 90]);
        img = imread('2_no_clouds_4k.jpg');
        h = image(xlim,-ylim,img);
        uistack(h,'bottom')
        alpha(0.6);
        xlabel('Longitude (deg)'); 
        ylabel('Latitude (deg)');
        title('Ground Traces of the GPS');
        hold off

    % MOSS Sensor
        figure(4)
       hold on;
        plot(AzimuthMOSS1, ElevationMOSS1, AzimuthMOSS2, ElevationMOSS2,AzimuthMOSS3, ElevationMOSS3,AzimuthMOSS4a, ElevationMOSS4a,AzimuthMOSS4b, ElevationMOSS4b,AzimuthMOSS5, ElevationMOSS5);
%         plot(AzimuthMOSS2, ElevationMOSS2, 'b.');
%         plot(AzimuthMOSS3, ElevationMOSS3, 'y.');
%         plot(AzimuthMOSS4a, ElevationMOSS4a, 'r.');
%         plot(AzimuthMOSS4b, ElevationMOSS4b, 'r.');
%         plot(AzimuthMOSS5, ElevationMOSS5, 'r.');
        plot(AzimuthMOSS6, ElevationMOSS6,AzimuthMOSS7, ElevationMOSS7,AzimuthMOSS8, ElevationMOSS8);

        grid on; 
        xlabel('Azimuthi (deg)'); 
        ylabel('Elevation (deg)');
        title('MOSS Observation');
        legend('Satellite','GPS')
        hold off;

    % GEODSS Sensor
        figure(5)
        hold on;
        plot(AzimuthGEODSS1, ElevationGEODSS1,'r',AzimuthGEODSS2, ElevationGEODSS2,'r',AzimuthGEODSS3, ElevationGEODSS3,'r',AzimuthGEODSS4a, ElevationGEODSS4a,'r',AzimuthGEODSS4b, ElevationGEODSS4b,'r',AzimuthGEODSS5, ElevationGEODSS5, 'r');
        plot(AzimuthGEODSS6, ElevationGEODSS6,'b',AzimuthGEODSS7, ElevationGEODSS7,'b',AzimuthGEODSS8, ElevationGEODSS8, 'b');

        grid on; 
        xlabel('Azimuthi (deg)'); 
        ylabel('Elevation (deg)');
        title('GEODSS Observation');
        legend('Satellite','GPS')
        hold off;
%}


% RESULTS            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    disp(" ")
    disp(" ")
    disp(" ")
    % 1
        disp('1:')

        disp(" - The satellite is equipped with a cutting-edge net featuring weighted ends that enable it to completely and securely enclose the defunct GPS. Upon reaching the target, the satellite deploys the net to capture the GPS, then transports it to a suitable graveyard orbit.")
    % 2
        disp('2:')

        disp(" - The dead GPS was disposed in the SuperGEO graveyard orbit because the cost to transfer to SuperGEO graveyard was $" + round(costGEOgrave,2) + " while the cost to transfer to LEO graveyard was $" + round(costLEOgrave,2) + ".")
    % 3
        disp('3:')

        disp(" - Maneuver 1 (Satellite performs inclination change to GPS orbit):")
        disp("      - When: 1 February 2023 at 01h59m40s")
        disp("      - Delta V: " + deltaV1 + " m/s")
        disp(" - Maneuver 2 (Satellite transfers to GPS orbit):")
        disp("      - When: 1 February 2023 at 01h59m40s")
        disp("      - Delta V: " + deltaV2 + " m/s")
        disp(" - Maneuver 3 (Satellite chases to GPS):")
        disp("      - When: 1 February 2023 at 10h47m54s")
        disp("      - Delta V: " + deltaV3 + " m/s")
        disp(" - Maneuver 4 (Satellite (with GPS) transfer to GEO graveyard orbit):")
        disp("      - When: 2 February 2023 at 23h55m46s")
        disp("      - Delta V: " + deltaV4_1 + " m/s")
        disp(" - Maneuver 5 (Satellite (with GPS) remains in GEO graveyard orbit for 1 period):")
        disp("      - When: 2 February 2023 at 8h49m46s")
        disp("      - Delta V: 0 m/s")
        disp(" - Maneuver 6 (Satellite (without GPS) performs inclination change to GEO staging orbit):")
        disp("      - When: 3 February 2023 at 9h11m27s")
        disp("      - Delta V: " + deltaV5_2 + " m/s")
        disp(" - Maneuver 7 (Satellite (without GPS) transfers to GEO staging orbit):")
        disp("      - When: 3 February 2023 at 9h11m27s")
        disp("      - Delta V: " + deltaV5GEOt + " m/s")
    % 4
        disp('4:')

        disp(" - The mission was completed on 3 February 2023 at 21h15m53s.")
    % 5
        disp('5:')

        disp(" - The total delta V used for the mission was: " + totaldeltaV + " m/s.")
    % 6
        disp('6:')

        disp(" - The company made $" + round(profit,2) + " in profit.")
    % 8
        disp('8:')

        disp(" - Both the MOSS and Maui sensors can see the satellites. The MOSS sensor is best for this mission because it can see more of the satellite and the GPS as compared to the Maui sensor.")



        % Rounding for time
        % The last orbit doesn't need to be plotted
        %%%%% There are 4 scenarios for delta V
        % Plot GPS in az el 