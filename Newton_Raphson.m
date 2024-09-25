function [results_newton] = Newton_Raphson(M,e,epsilon)
results_newton = [];
k=1;
dE=100;
Ek = M;

while (abs(dE) > epsilon)

    %How much E changes per iteration
    dE = (M - Ek + e*sin(Ek))/(1-e*cos(Ek));

    % Newton update
    E_kp1 = Ek + dE; 
 
    % Results table
    results_newton(k,:) = [k Ek dE E_kp1];
    k = k+1;

    % Reassign variables
    Ek = E_kp1;

end
end