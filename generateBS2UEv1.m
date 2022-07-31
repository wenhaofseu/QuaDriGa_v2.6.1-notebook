clc;clear;close all;
addpath(genpath('/home/xliangseu/Users/wenhao/channelModel/QuaDriGa_2021.07.12_v2.6.1'));
s = qd_simulation_parameters; %��ʼ��
s.center_frequency = 4.9e9; %������Ƶ��
%% ��վ��������
M_BS = 8; %��ֱ1��M_BS
N_BS = 1; %ˮƽ1��N_BS
Mg_BS = 2;
Ng_BS = 8;
ElcTltAgl_BS = 7; %���ߵ�������
Hspc_Tx_BS = 0.37*s.wavelength; %ˮƽ���Ӽ��
Vspc_Tx_BS = 0.37*s.wavelength; %��ֱ���Ӽ��

BSAntArray = qd_arrayant.generate('3gpp-mmw',M_BS,N_BS,...
    s.center_frequency,6,ElcTltAgl_BS,...
    Vspc_Tx_BS/s.wavelength,Mg_BS,Ng_BS,...
    Vspc_Tx_BS/s.wavelength*M_BS,Hspc_Tx_BS/s.wavelength*N_BS); 
    %ע�����ﴫ���������ڸ�Ƶ��ĵ�Ч���(�Բ���Ϊ��λ)
BSAntArray.no_elements = 1;
    
%% UE����������
UEAntArray = qd_arrayant('xpol');
% UEAntArray = copy(BSAntArray);
UEAntArray.no_elements = 1;

%% ����ʵ����Ҫ��������
UENum = 10;
UESpeed = 3; %[km/h]
Timelength = 10*5e-3; %Sample Period Length,[s]
UETrackLength = UESpeed/3.6*Timelength; %����UE�˶�·������  
IndoorRatio = 0; %�����û�ռ��
TimeInterval = 5e-3; %ʱ��������,[s]
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
    %%% ���ÿռ䲼��
    rng(ind_seed);


    %% ����BS-UE�ŵ�����
    s1 = qd_simulation_parameters; %��ʼ��
    s1.center_frequency = 4.9e9; %������Ƶ��
    s1.set_speed(UESpeed,TimeInterval);
    s1.use_random_initial_phase = true;
    s1.use_3GPP_baseline = 0;


    %BSλ��
    BSlocation = [0;0;30];
    % UE����
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
    l1 = qd_layout(s1); %���ֳ�ʼ��
    l1.no_tx = 1; %���û�վ����
    l1.tx_array = BSAntArray; %���û�վ������
    l1.tx_position = BSlocation; %���û�վ�ռ�λ��
    l1.no_rx = UENum; %�����û�����
    l1.rx_array = UEAntArray; %�����û�������
    l1.rx_track = UEtrack;
    l1.rx_position = UElocation; %�����û��ռ�λ��
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