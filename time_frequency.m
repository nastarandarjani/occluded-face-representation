TFR = cell(11, 1);
for subject = 1:11
    filename = ['../data/preprocessed/FC_preprocessing/sub', ...
                num2str(subject), '.vhdr'];
    hdr = ft_read_header(filename);
    events = ft_read_event(filename);

    label_mat =load(['../data/label/sub', num2str(subject), '.mat']);
    label_mat = label_mat.imageseq;
    img_name = split(label_mat, '.');
    
    task = nan(2865, 2);
    for i=1:2865
        x = split(img_name(i, 1), '_');
        % parse image name
        if strcmp(x(1), 'id')
            if ~strcmp(x(3), 'n')
                task(i, 1) = str2double(x(2)) - 1;
                task(i, 2) = find(strcmp(["pixel"; "phase"; ...
                        "texture"], string(x(5))));
            end
        end
    end
    cfg = [];
    cfg.dataset = filename;
    cfg.continuous = 'yes';
    cfg.trialfun = 'trialfun_';
    cfg.tl = [3, 3];
    cfg.hdr = hdr;
    cfg.event = events;
    cfg = ft_definetrial(cfg);
    data = ft_preprocessing(cfg);

    % delete NaN labels
    cfg = [];
    cfg.trials = ~isnan(task(:, 1));
    data = ft_selectdata(cfg, data);

    cfg = [];
    cfg.method     = 'wavelet';
    cfg.width      = 7;
    cfg.output     = 'pow';
    cfg.foi        = 1:2:98;
    cfg.toi        = -0.5:0.05:0.6;
    TFRwave = ft_freqanalysis(cfg, data);
    
    TFR{subject} = TFRwave;
end

save('../data/result/TFR.mat', 'TFR');

TFRwave = ft_appendfreq([], TFR{:});

load("location.mat")
location.coordsys = 'eeglab';
cfg = [];
cfg.elec = location;
layout = ft_prepare_layout(cfg);

% cfg = [];
% cfg.baseline     = [-0.2 -0.1];
% % cfg.baselinetype = 'absolute';
% cfg.zlim         = [-50 50];
% cfg.showlabels   = 'yes';
% cfg.layout       = layout;
% cfg.colorbar     = 'yes';
% figure
% ft_multiplotTFR(cfg, TFRwave);
% 
% cfg              = [];
% cfg.baseline     = [-0.2 -0.1];
% % cfg.baselinetype = 'absolute';
% cfg.maskstyle    = 'saturation';
% cfg.zlim         = [-100 100];
% cfg.channel      = 'all';
% cfg.interactive  = 'no';
% cfg.layout       = layout;
% figure
% ft_singleplotTFR(cfg, TFRwave);

delta_band = [1 4];
theta_band = [4 8];
alpha_band = [8 12];
beta_band = [12 30];
low_gamma_band = [30 70];
high_gamma_band = [70 98];

freq_bands = [delta_band; theta_band; alpha_band; ...
            beta_band; low_gamma_band; high_gamma_band];

for f=1:6
    cfg = [];
    cfg.baseline = [-0.2 -0.1];
    % cfg.baselinetype = 'absolute';
    cfg.xlim = [0.1 0.23 0.4];
    cfg.ylim = freq_bands(f, :);
    cfg.marker = 'on';
    cfg.layout = layout;
    %cfg.colorbar = 'yes';
    figure;
    ft_topoplotTFR(cfg, TFR{1});
end
