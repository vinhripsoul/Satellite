function xnew=tobe(xin,t,dt,mu)

k1=tobeom(t,xin,mu);
k2=tobeom(t+dt/2, xin+k1*dt/2, mu);
k3=tobeom(t+dt/2, xin+k2*dt/2, mu);
k4=tobeom(t+dt, xin+k3*dt, mu);

xnew=xin+dt/6*(k1+2*k2+2*k3+k4);
end