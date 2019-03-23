% implementation of a distributed consenus protocol for clock
% synchronization in wireless sensor network

% 10/11/2017
% created by Mengheng Xue

% Setting the parameters
clear
close all

TIME_ITER = .01;
max_time_step = 60;
% case 1: regulate conncection which guarantees strong conncection 
% GRAPH = [ 1 1 0 0;
%           1 1 1 1;
%           0 1 1 1;
%           0 1 1 1; ];

% case 2: insufficient connection
          GRAPH = [ 1 1 0 0;
          1 1 1 1;
          0 1 1 0;
          0 1 0 1; ];
% case 3: full connection
%           GRAPH = [ 1 1 1 1;
%           1 1 1 1;
%           1 1 1 1;
%           1 1 1 1; ];

num_node = 4;
beta_initial = [2 3 8 1] * TIME_ITER; % the initial offset for each node 
alpha = [0.8 0.9 1.1 1.3] * TIME_ITER; % local clock skew are per TIME_ITER
      
% GRAPH = [ ...
% 	0	0	1	1	0	0	0	0	0	0;
% 	0	0	1	1	0	0	0	0	0	0;
% 	1	1	0	0	1	1	0	0	0	0;
% 	1	1	0	0	1	1	0	0	0	0;
% 	0	0	1	1	0	0	1	1	0	0;
% 	0	0	1	1	0	0	1	1	0	0;
% 	0	0	0	0	1	1	0	0	1	1;
% 	0	0	0	0	1	1	0	0	1	1;
% 	0	0	0	0	0	0	1	1	0	0;
% 	0	0	0	0	0	0	1	1	0	0; ];
% num_node = 10;           
% beta_initial = [2 3 8 1 12 1 3 3 9 10] * TIME_ITER;  
% alpha = [0.2 0.6 1.1 0.8 1.4 1.3 0.7 0.9 1.0 0.8] * TIME_ITER;


rho = 0.6; % the tuning parameter which is set by the author as 0.6

% Applying the algorithm
alpha_vir = zeros(max_time_step, num_node); % the virtual clock skew estimation 
alpha_rel = cell(max_time_step, 1); % the relative clock skew estimation 
tau = zeros(max_time_step, num_node); % the local time on each node
time_vir = zeros(max_time_step, num_node); 
offset_vir = zeros(max_time_step, num_node);

alpha_vir(1, :) = ones(1, num_node);
alpha_rel(:) = {GRAPH};
tau(1, :) = beta_initial;
time_vir(1, :) = tau(1,:);

% assuming that there is TX/RX between all nodes at each time step
for t = 2:1:max_time_step
    tau(t, :) = tau(t-1, :) + alpha; 
    % Go through the graph for links
    for i=1:1:num_node
        for j=1:1:num_node
            if GRAPH(i, j) ~= 0 % link is found where i RXs from j
                % update the relative skew estimation 
                alpha_rel{t}(i,j) = rho*alpha_rel{t-1}(i,j) + (1-rho) *(tau(t,j)-tau(t-1,j))/(tau(t,i)-tau(t-1,i));
                % update the skew compensation
                alpha_vir(t,i) = rho*alpha_vir(t-1,i) + (1-rho)*alpha_rel{t-1}(i,j)*alpha_vir(t-1,j);
                % compute the offset compension 
                offset_vir(t,i) = offset_vir(t-1,i) + (1-rho) * (alpha_vir(t-1,j)*tau(t-1,j)+ offset_vir(t-1, j) - alpha_vir(t-1,i)*tau(t-1,i) - offset_vir(t-1, i));
            end
        end
    end
    time_vir(t, :) = alpha_vir(t, :).*tau(t, :) + offset_vir(t,:);
end

% plot local time of each node 
time_step = 1:max_time_step;
figure;
C = {'k','m','r','b',[.5 .6 .7],[.8 .2 .6]} % Cell array of colros.
for i=1:1:num_node
    plot(time_step, tau(:, i),'.-','color', C{i});
    hold on;
end
%title('Local Time within Nodes');
legend('node 1','node 2','node 3','node 4');
xlabel('Iterations');
ylabel('Time (s)');
grid on;
hold off;

% plot the vritual time within each node
figure;
for i = 1:1:num_node
    plot(time_step, time_vir(:, i),'color', C{i},'marker','.');
    hold on;
end
hold on;
%title('Virtual Time within Nodes');
legend('node 1','node 2','node 3','node 4');
xlabel('Iterations');
ylabel('Time (s)');
grid on;
hold off;

% plot the relative skew compare to node 2 
figure;
temp = zeros(1,max_time_step);
for i=1:1:num_node
    for j=1:1:max_time_step
        temp(j) = alpha_rel{j}(2,i);
    end
    plot(1:1:max_time_step, temp,'color', C{i},'marker','.');
    hold on;
end
% Note: a line at 0 indicates no link. A line at 1 indicates self.
% Expectation: ([Other Node Speed] / [This Node Speed]) convergence
%title('Relative Skew Estimation as Seen by Node 2')
legend('node 1 to node 2','node 2 to node 2','node 3 to node 2','node 4 to node 2');
xlabel('Iterations');
ylabel('Skew (rate/rate)');
grid on;
hold off;

% plot virual skew estimation of each node 
figure;
for i=1:1:num_node
    plot(1:1:max_time_step, alpha_vir(:, i),'color', C{i},'marker','.');
    hold on;
end
%title('Virtual Skew Estimation within Nodes');
legend('node 1','node 2','node 3','node 4');
xlabel('Iterations');
ylabel('Skew (rate/rate)');
grid on;
hold off;

% plot virtual offset estimation within nodes
figure;
for i=1:1:num_node
    plot(1:1:max_time_step, offset_vir(:, i),'color', C{i},'marker','.');
    hold on;
end
%title('Virtual Offset Estimation within Nodes');
legend('node 1','node 2','node 3','node 4');
xlabel('Iterations');
ylabel('Offset (sec)');
grid on;
hold off;


figure;
error = zeros(max_time_step, num_node);
for j=1:1:max_time_step
    for i=1:1:num_node
        error(j,i) = 100*(time_vir(j,i) - mean(time_vir(j,:)))/mean(time_vir(j,:));
    end
end
for i=1:1:num_node
    plot(1:1:max_time_step, error(:, i),'color', C{i},'marker','.');
    hold on;
end
title('Error Percentage from Instantaneous Mean of Local Times');
legend('node 1','node 2','node 3','node 4');
xlabel('Iterations');
ylabel('Error Percentage (%)');
grid on;
hold off;

%%
% plot local time of each node 
time_step = 1:max_time_step;
figure;
for i=1:1:num_node
    plot(time_step, tau(:, i),'-s','color', rand(1,3),'MarkerSize',3);
    hold on;
end
title('Local Time within Nodes');
%legend('node 1','node 2','node 3','node 4');
xlabel('Iterations');
ylabel('Time (s)');
grid on;
hold off;