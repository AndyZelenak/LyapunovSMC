
clear all; close all; clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IC's and simulation parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

V_dot_target_initial = -10;
delta_t = 0.001;
t_start = 0;
t_end = 5;
t = t_start: delta_t: t_end;

x_IC = [3 2 1];

% Pre-allocate
x_OL = zeros(length(t), 3);
x_OL(1,:) = x_IC;
y_OL = zeros(length(t), 1);
y_OL(1) = x_IC(2);      % y = x2

x_CL = zeros(length(t), 3);
x_CL(1,:) = x_IC;
y_CL = zeros(length(t),1 );
y_CL(1) = x_IC(2);      % y = x2

V = zeros(length(t), 1);
V(1) = 0.5*x_IC*x_IC';

u_eq = zeros(length(t),1 );
u_s = zeros(length(t),1 );


for epoch = 2: length(t)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Put the system in normal form, i.e. calculate xi
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    r = 2; % Relative order of the system
    
    dh_dx = [0 1 0]; % 1x3
    
    f = [ -x_CL(epoch-1,1);
        x_CL(epoch-1,3);
        x_CL(epoch-1,1)*x_CL(epoch-1,3) ];
    % 3x1
    
    Lf_h = dh_dx * f; % scalar
    
    dLf_h_dx = [0 0 1]; % 1x3
    
    Lf_2_h = dLf_h_dx*f; % scalar
    
    g = [(2+x_CL(epoch-1,3)^2)/(1+x_CL(epoch-1,3)^2); 0; 1]; % 3x1
    
    Lg_Lf_h = dLf_h_dx * g; % scalar, dLf_h/dx*g
    
    xi(1) = x_CL(epoch-1,2);  % xi(1) = h(x) = x2
    xi(2) = Lf_h;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate u_eq with the switched Lyapunov algorithm
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate dV1_dot_du
    dV1_dot_du = xi(r)*Lg_Lf_h;
    
    % Calculate dV2_dot_du
    dV2_dot_du = (xi(r)*(0.9+0.1*abs(xi(r)-1)) + 0.1*V(epoch-1)*sign( xi(r)-1 ) )*Lg_Lf_h;
    
    % Calculate V_dot_target
    V_dot_target = (V(epoch-1)/V(1))^2*V_dot_target_initial;
    
    % Compare dV1_dot_du and dV2_dot_du to choose the CLF
    dV_dot_du(epoch,:) = [dV1_dot_du dV2_dot_du];
    
    [M,I] = max(abs(dV_dot_du));
    
    % Calculate u_eq with the CLF of choice
    if ( I==1 ) % use V1
        using_V1(epoch) = y_CL(epoch);
        u_eq(epoch) = (V_dot_target - xi(1)*Lf_h - xi(r)*Lf_2_h) /...
            dV1_dot_du;
    else %use V2
        using_V2(epoch) = y_CL(epoch);
        u_eq(epoch) = (V_dot_target -...
            xi(1)*(0.9+0.1*abs(xi(r)-1))*Lf_h-... % for xi(1)
            (xi(r)*(0.9+0.1*abs(xi(r)-1) )+0.1*V(epoch-1)*sign(xi(r)-1))*Lf_2_h )/... % for xi(r)
            dV2_dot_du;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate u_s with the SMC algorithm
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Calculate omega (the surface)
    
    % Calculate u_s
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Apply (u = u_eq + u_s) to the system and simulate for one time step
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    xy = simulate_sys( x_CL(epoch-1,:), y_CL(epoch-1), u_eq(epoch), delta_t);
    x_CL(epoch,:) = xy(1:3);    % First 3 elements are x
    y_CL(epoch) = xy(end);         % Final element is y
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Simulate the open-loop system
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    xy = simulate_sys( x_OL(epoch-1,:), y_OL(epoch-1), 0, delta_t);
    x_OL(epoch,:) = xy(1:3);    % First 3 elements are x
    y_OL(epoch) = xy(end);         % Final element is y
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Update
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Is this legit? Is it invariant with the xi transform?
    V(epoch) = 0.5*x_CL(epoch,:)*x_CL(epoch,:)';
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,2,1)
plot(t, x_OL)
legend('x_1','x_2','x_3','location','NorthWest')
xlabel('Time [s]')
ylabel('x')
title('x: Open Loop')

subplot(2,2,2)
plot(t, y_OL)
xlabel('Time [s]')
ylabel('x')
title('y: Open Loop')

subplot(2,2,3)
plot(t, x_CL)
legend('x_1','x_2','x_3','location','NorthWest')
xlabel('Time [s]')
ylabel('x')
title('x: Closed Loop')

subplot(2,2,4)
plot(t, y_CL)
xlabel('Time [s]')
ylabel('x')
title('y: Closed Loop')

figure
subplot(2,1,1)
plot(t,u_eq)
xlabel('Time [s]')
ylabel('u_e_q')
title('u_e_q: Control effort to stabilize the nominal dynamics')

subplot(2,1,2)
plot(t,u_s)
xlabel('Time [s]')
ylabel('u_s')
title('u_s: Control effort to drive the system towards the sliding mode')