function [rho, u, p, e] = L_F_split(dx, rho0, u0, p0, tEnd, time_advance_type)
%input initial condition & total time
global gamma CFL N epsilon
t = 0;
rho = rho0;
u = u0;
p = p0;
E = p ./ ((gamma-1) * rho) + u.^2/2;
U = [rho; rho.*u; rho.*E];   % U values at i
while t <= tEnd
    % update time step 
    a = sqrt(gamma * p ./ rho);
    S_max = max(max(abs(u) + a));
    if time_advance_type == 1
%         dt = dx * CFL / S_max;
        dt = 0.0001;
    elseif time_advance_type == 2
        dt = 0.0001;
    end
    % time advance
    U_sub = U;
    L = Calculate_L_LF_split(U, dx, time_advance_type);
    U = U_sub + dt * L;
    % compute flow properties
    rho = U(1,:);
    u = U(2,:)./rho;
    E = U(3,:)./rho;
    p = (gamma-1).*(E-u.^2./2).*rho;
    e = p./(gamma-1)./rho;
    t = t+dt;
end
end
function  L = Calculate_L_LF_split(U, dx, time_advance_type)
    global gamma CFL N epsilon
    rho = U(1,:);
    u = U(2,:)./rho;
    E = U(3,:)./rho;
    p = (gamma-1).*(E-u.^2./2).*rho;
    H = (p * gamma) ./ ((gamma-1) * rho) + u.^2/2;
    a = sqrt(gamma * p ./ rho);
    lambda_ast = max(max(abs(u) + a));
    F = [rho.*u; rho.*u.^2+p; rho.*u.*H]; 
    for i = 1:N+3
%         Jacobian = [0                                           1                                  0;
%                     (gamma-3)/2*u(i)^2                   (3-gamma)*u(i)                     gamma-1;
%                     -gamma*u(i)*E(i)+(gamma-1)*u(i)^3    gamma*E(i)-3*(gamma-1)/2*u(i)^2    gamma*u(i)];
        F_pos(:,i) = (F(:,i) + lambda_ast * U(:,i)) / 2;
        F_neg(:,i) = (F(:,i) - lambda_ast * U(:,i)) / 2;
    end
    % apply upwind scheme
    if time_advance_type == 1   % 1st order
        for i = 2:N+2
            L(:,i) = - 1/dx * (F_pos(:,i) - F_pos(:,i-1) + F_neg(:,i+1) - F_neg(:,i));
        end
        L(:,1) = -1/dx*(F_neg(:,2) - F_neg(:,1));      
        L(:,N+3) = -1/dx*(F_pos(:,N+3) - F_pos(:,N+2));  
    elseif time_advance_type == 2    % 2nd order
        for i = 3:N+1
            L(:,i) = - 1/2/dx * (3 * F_pos(:,i) - 4 * F_pos(:,i-1) + F_pos(:,i-2) - F_neg(:,i+2) + 4*F_neg(:,i+1) - 3*F_neg(:,i));
        end
        L(:,2) = - 1/dx * (F_pos(:,2) - F_pos(:,1) + F_neg(:,3) - F_neg(:,2));
        L(:,N+2) = - 1/dx * (F_pos(:,N+2) - F_pos(:,N+1) + F_neg(:,N+3) - F_neg(:,N+2));
        L(:,1) = -1/dx*(F_neg(:,2) - F_neg(:,1));      
        L(:,N+3) = -1/dx*(F_pos(:,N+3) - F_pos(:,N+2));  
    end
end