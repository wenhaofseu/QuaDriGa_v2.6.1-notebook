%% QuaDriGa_v2.6.1 P170
clc;clear all;close all;
s = qd_simulation_parameters;      % Set up simulation parameters
s.show_progress_bars = 1;          % Disable progress bars
s.center_frequency = 2.53e9;       % Set center frequency
l = qd_layout(s);                  % Create new QuaDRiGa layout

l.no_tx = 2;                                            % Two BSs
l.tx_position(:,1) = [ -142 ; 355 ; 64 ];               % Outdoor BS
l.tx_position(:,2) = [ 5 ; 0; 10 ];                     % Indoor BS

l.no_rx = 2;                                            % Two MTs
l.rx_track(1,1) = qd_track('linear', 2 );             % Linear track with 20 cm length
l.rx_track(1,1).name = 'Rx1';                           % Set the MT1 name
l.rx_track(1,1).scenario = {'WINNER_UMa_C2_NLOS'};  % Two Scenarios

l.rx_track(1,2) = qd_track('linear', 0.2 );             % Linear track with 20 cm length
l.rx_track(1,2).name = 'Rx2';                           % Set the MT2 name
l.rx_position(:,2) = [ 100;50;0 ];                      % Start position of the MT2 track
interpolate_positions( l.rx_track, s.samples_per_meter );  % Interpolate positions
l.rx_track(1,2).scenario = {'WINNER_UMa_C2_LOS'};
l.visualize
[a1,a2] = l.get_channels();