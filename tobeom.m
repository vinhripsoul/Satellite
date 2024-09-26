function xdot=tobeom(t,xin,mu)

rvec=xin(1:3);
rdotvec=xin(4:6);

r=norm(rvec);
rddotvec=-mu/r^3*rvec;

xdot=[rdotvec;rddotvec];
end