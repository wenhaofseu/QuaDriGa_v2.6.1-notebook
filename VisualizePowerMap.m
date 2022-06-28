%% QuaDriGa_v2.6.1 P191
clc;clear;close all;
s = qd_simulation_parameters;
s.center_frequency = 4.9e9;                   

l = qd_layout( s );                                     % New QuaDRiGa layout
l.tx_position = [300 0 25]';                              % 25 m BS height
l.no_rx = 100;                                          % 100 MTs
l.randomize_rx_positions( 200, 1.5, 1.5, 0 );           % Assign random user positions
l.rx_position(1,:) = l.rx_position(1,:) + 220;          % Place users east of the BS

floor = randi(5,1,l.no_rx) + 3;                         % Set random floor levels
for n = 1:l.no_rx
    floor( n ) =  randi(  floor( n ) );
end
l.rx_position(3,:) = 3*(floor-1) + 1.5;
indoor_rx = l.set_scenario('3GPP_38.901_UMa',[],[],0.8);    % Set the scenario
l.rx_position(3,~indoor_rx) = 1.5;                      % Set outdoor-users to 1.5 m height
%The 2.6 GHz antenna is constructed from 8 vertically stacked patch elements with +/- 45 degree polarization.
%The electric downtilt is set to 8 degree. There is only 1 BS in the layout. 
%The mobile terminal uses a vertically polarized omni-directional antenna.

l.tx_array = qd_arrayant( '3gpp-3d',  8, 1, s.center_frequency(1), 6, 8 );  % Set 2.6 GHz antenna
l.tx_array.rotate_pattern( 180 , 'z' );      % Rotate BS antenna by 180 degree
l.rx_array = qd_arrayant('omni');      % Set omni-rx antenna

sample_distance = 5;                                    % One pixel every 5 m
x_min           = -50;                                  % Area to be samples in [m]
x_max           = 550;
y_min           = -300;
y_max           = 300;
rx_height       = 1.5;                                  % Mobile terminal height in [m]
tx_power        = 30;                                   % Tx-power in [dBm] per antenna element

% Calculate the map including path-loss and antenna patterns
[ map, x_coords, y_coords] = l.power_map( '3GPP_38.901_UMa_NLOS', 'quick',...
    sample_distance, x_min, x_max, y_min, y_max, rx_height, tx_power);
P_db = 10*log10( sum( map{1}, 4 ) );

% Plot the results
l.visualize([],[],0);                                   % Show BS and MT positions on the map
hold on; imagesc( x_coords, y_coords, P_db ); hold off  % Plot the antenna footprint
axis([x_min,x_max,y_min,y_max]);
caxis( max(P_db(:)) + [-20 0] );                        % Color range
colmap = colormap;
colormap( colmap*0.5 + 0.5 );                           % Adjust colors to be "lighter"
set(gca,'layer','top')                                  % Show grid on top of the map
colorbar('south')
title('Received power [dBm] for 2.6 GHz band');