function [deltaV1,t1,atrans1,deltaV2,t2,atrans2,deltaStartPerigee,deltaEndApogee,deltaStartApogee,deltaEndPerigee] = deltaV(rpi,rai,ai,rpf,raf,af,mu)

    % Case 1 (starts at perigee)
        atrans1 = (raf+rpi)/2;

        vpi = sqrt( mu*(2/rpi - 1/ai) );
        vptrans1 = sqrt( mu*(2/rpi - 1/atrans1) );
        vatrans1 = sqrt( mu*(2/raf - 1/atrans1) );
        vaf = sqrt( mu*(2/raf - 1/af) );

    % Case 2 (starts at apogee)
        atrans2 = (rpf+rai)/2;

        vai = sqrt( mu*(2/rai - 1/ai) );
        vatrans2 = sqrt( mu*(2/rai - 1/atrans2) );
        vptrans2 = sqrt( mu*(2/rpf - 1/atrans2) );
        vpf = sqrt( mu*(2/rpf - 1/af) );

    % Results
        % Case 1
            deltaV1 = abs(vaf - vatrans1) + abs(vptrans1 - vpi);
            t1 = pi*sqrt(atrans1^3/mu);
        % Case 2
            deltaV2 = abs(vpf - vptrans2) + abs(vatrans2 - vai);
            t2 = pi*sqrt(atrans2^3/mu);
            
        deltaStartPerigee = abs(vptrans1 - vpi);
        deltaEndApogee = abs(vaf - vatrans1);
        deltaStartApogee = abs(vatrans2 - vai);
        deltaEndPerigee = abs(vpf - vptrans2);
end