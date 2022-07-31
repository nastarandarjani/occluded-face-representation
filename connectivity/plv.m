function plv(subject)
    delta_band = [1 4];
    theta_band = [4 8];
    alpha_band = [8 12];
    beta_band = [12 30];
    low_gamma_band = [30 70];
    high_gamma_band = [70 98];

    freq_bands = [delta_band; theta_band; alpha_band; ...
                beta_band; low_gamma_band; high_gamma_band];
    filename = ['../data/preprocessed/FC_preprocessing/sub', ...
                num2str(subject), '.vhdr'];
    hdr = ft_read_header(filename);
    events = ft_read_event(filename);
    load('location.mat');

    label_mat =load(['../data/label/sub', num2str(subject), '.mat']);
    label_mat = label_mat.imageseq;
    img_name = split(label_mat, '.');
    % labeling trials
    task = nan(2865, 1);
     for i=1:2865
         x = split(img_name(i, 1), '_');
         if strcmp(x(1), 'id')
             if ~strcmp(x(3), 'n')
                 task(i, 1) = str2double(x(2)) - 1;
                 task(i, 2) = find(strcmp(["pixel"; "phase"; "texture"], string(x(5))));
             end
         end
     end
%   for unoccluded face stimulus
%    for i=1:2865
%        x = split(img_name(i, 1), '_');
%        if strcmp(x(1), 'id')
%            if strcmp(x(3), 'n')
%                if strcmp(x(4), '1')
%                    task(i, 1) = str2double(x(2)) - 1;
%                end
%            end
%        end
%    end
    clear label_mat img_name
    
    for freq = 1:6
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
        cfg.bpfilter = 'yes';
        cfg.bpfreq = freq_bands(freq, :);
        cfg.bpfilttype = 'fir';
        cfg.bpfiltord = floor(4/freq_bands(freq, 1) * hdr.Fs);
        data = ft_preprocessing(cfg, data);

        % apply surface laplacian
        cfg = [];
        cfg.method = 'spline';
        cfg.elec = location;
        data = ft_scalpcurrentdensity(cfg, data);
        
        % select ROI channels
        chnl = ft_channelselection({'FFC1h', 'FCC1h', 'AF3', ...
            'FP1', 'FPz', 'AFP1', 'AFP5', 'F1', 'AFF3h', ...
            'AFF1h'}, data);
        cfg = [];
        cfg.channel = chnl;
        fr_data = ft_selectdata(cfg, data);

        cfg.channel = ft_channelselection({'T7','TP7','TTP7h', ...
            'TPP7h'}, data);
        lt_data = ft_selectdata(cfg, data);

        cfg.channel = ft_channelselection({'T8','TP8','TTP8h', ...
            'TPP8h'}, data);
        rt_data = ft_selectdata(cfg, data);

        cfg.channel = ft_channelselection({'O*'}, data);
        oc_data = ft_selectdata(cfg, data);
        clear data;

        data = ft_appenddata([], fr_data, lt_data, rt_data, oc_data);
        clear fr_data lt_data rt_data oc_data;
        
        cfg = [];
        cfg.hilbert = 'angle';
        data = ft_preprocessing(cfg, data);

        cfg = [];
        cfg.toilim = [-0.4 0.6];
        data = ft_redefinetrial(cfg, data);
        time = data.time{1};
        
        data = ft_checkdata(data, 'datatype', 'timelock', ...
                    'feedback', 'no');
        data = data.trial;
        
        save(['../data/result/granger/plv', num2str(subject), ...
            '_', num2str(freq), '.mat'], 'data', 'freq_bands',...
            'time', '-v7.3');
        clear data;
    end
end
