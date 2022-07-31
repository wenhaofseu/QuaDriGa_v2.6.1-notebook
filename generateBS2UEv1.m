clc;clear;close all;
addpath(genpath('/home/xliangseu/Users/wenhao/channelModel/QuaDriGa_2021.07.12_v2.6.1'));
s = qd_simulation_parameters; %初始化
s.center_frequency = 4.9e9; %设中心频点
%% 基站天线配置
M_BS = 8; %垂直1驱M_BS
N_BS = 1; %水平1驱N_BS
Mg_BS = 2;
Ng_BS = 8;
ElcTltAgl_BS = 7; %天线电调下倾角
Hspc_Tx_BS = 0.37*s.wavelength; %水平阵子间距
Vspc_Tx_BS = 0.37*s.wavelength; %垂直阵子间距

BSAntArray = qd_arrayant.generate('3gpp-mmw',M_BS,N_BS,...
    s.center_frequency,6,ElcTltAgl_BS,...
    Vspc_Tx_BS/s.wavelength,Mg_BS,Ng_BS,...
    Vspc_Tx_BS/s.wavelength*M_BS,Hspc_Tx_BS/s.wavelength*N_BS); 
    %注意这里传入的是相对于各频点的等效间距(以波长为单位)
BSAntArray.no_elements = 1;
    
%% UE侧天线配置
UEAntArray = qd_arrayant('xpol');
% UEAntArray = copy(BSAntArray);
UEAntArray.no_elements = 1;

%% 根据实际需要调整参数
UENum = 10;
UESpeed = 3; %[km/h]
Timelength = 10*5e-3; %Sample Period Length,[s]
UETrackLength = UESpeed/3.6*Timelength; %计算UE运动路径长度  
IndoorRatio = 0; %室内用户占比
TimeInterval = 5e-3; %时间采样间隔,[s]
SnapNum = 1+floor(Timelength/TimeInterval);
        
BW = 10e6;
ScNum = 12*3;
RBNum = ScNum/12;
RBIdx = -RBNum/2:RBNum/2-1;
ScInterval = 15e3;
RBInterval = ScInterval*12;
RsIdx = RBIdx*RBInterval/BW;

seedNum = 20;
sf = zeros(seedNum,UENum);
kf = zeros(seedNum,UENum);
gain = zeros(seedNum,UENum);
PL = zeros(seedNum,UENum);
channel_gain_total = zeros(seedNum,UENum,RBNum,SnapNum);
for ind_seed = 1:seedNum
    %%% 配置空间布局
    rng(ind_seed);


    %% 配置BS-UE信道参数
    s1 = qd_simulation_parameters; %初始化
    s1.center_frequency = 4.9e9; %设中心频点
    s1.set_speed(UESpeed,TimeInterval);
    s1.use_random_initial_phase = true;
    s1.use_3GPP_baseline = 0;


    %BS位置
    BSlocation = [0;0;30];
    % UE撒点
    rho_min = 20;
    rho_max = 50;
    rho = rho_min+(rho_max-rho_min)*rand(1,UENum);
    phi =  120*rand(1,UENum)-60;
    UEcenter = [200;0;1.5];
    UElocation = zeros(3,UENum);
    d = zeros(1,UENum);
    for ind_UE = 1:UENum
        rho_n = rho(ind_UE);
        phi_n = phi(ind_UE);
        UElocation(:,ind_UE) = [-rho_n*cosd(phi_n);rho_n*sind(phi_n);0]+UEcenter;
        d(ind_UE) = norm(UElocation(:,ind_UE)-BSlocation);
    end
    
    PL(ind_seed,:) = 20*log10(d)+32.45+20*log10(4.9);
 
    %UE track
    for ind_UE = 1:UENum
        UEtrack(1,ind_UE) = qd_track.generate('linear',UETrackLength);
        UEtrack(1,ind_UE).name = num2str(ind_UE);
        UEtrack(1,ind_UE).interpolate('distance',1/s1.samples_per_meter,[],[],1);
    end

    % BS-UE
    l1 = qd_layout(s1); %布局初始化
    l1.no_tx = 1; %配置基站个数
    l1.tx_array = BSAntArray; %配置基站侧天线
    l1.tx_position = BSlocation; %配置基站空间位置
    l1.no_rx = UENum; %配置用户个数
    l1.rx_array = UEAntArray; %配置用户侧天线
    l1.rx_track = UEtrack;
    l1.rx_position = UElocation; %配置用户空间位置
    l1.set_scenario('3GPP_38.901_UMa_NLOS');
%     l1.set_scenario('Freespace');

    [BS2UE_channel,BS2UE_builder] = l1.get_channels();
    sf(ind_seed,:) = BS2UE_builder.sf;
    kf(ind_seed,:) = BS2UE_builder.kf;
    gain(ind_seed,:) = sum(BS2UE_builder.gain,2)';
%     gain(ind_seed,:) = BS2UE_builder.gain;
    D_all = cell(1,UENum);
    for ind_UE = 1:UENum
        D = BS2UE_channel(ind_UE).fr(BW,RsIdx);
        D_all{1,ind_UE} = D;
        for ind_RB = 1:RBNum
            for ind_Snap = 1:SnapNum
                channel_gain_total(ind_seed,ind_UE,ind_RB,ind_Snap) = norm(D(:,:,ind_RB,ind_Snap),'fro')^2;
%                 channel_gain_total(ind_seed,ind_UE,ind_RB,ind_Snap) = norm(D(:,:,ind_RB,ind_Snap),'fro')^2/(BSAntArray.no_elements*UEAntArray.no_elements);
            end
        end
    end
    channel_gain = mean(channel_gain_total,[3,4]);
end
gain = 10*log10(gain);
channel_gain = 10*log10(channel_gain);