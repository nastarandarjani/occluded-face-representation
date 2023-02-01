function RDM(Res, region)
    startup_MVPA_Light

    if ~ strcmp(region, "")
    	region = string(['_', char(region)]);
    end
    
    % select trials
    trl = [36:62, 71:97, 106:132, 141:167];
    
    Res.IT = Res.IT(trl, ...
        [35,38,40,45,46,62,64,106:119,121:184], 300:1100);
    Res.PFC = Res.PFC(trl, ...
        [24:29,83:96,98:121,123:132,135:137,139:159,161], 300:1100);

    % moving average over 50 ms
    Res.IT = movmean(Res.IT, 50, 3);
    Res.PFC = movmean(Res.PFC, 50, 3);
    
    % delete NaN rows (trials)
    deleted_trials = any(isnan(Res.PFC), 2);
    deleted_trials = find(deleted_trials(:, 1, 1));
    Res.IT(deleted_trials, :, :) = [];
    Res.PFC(deleted_trials, :, :) = [];

    IT1 = mean(Res.IT(:, :, 280:360), 3);
    IT2 = mean(Res.IT(:,:, 380:450), 3);
    PFC = mean(Res.PFC(:, :, 300:410), 3);
    
    % calculate correlation within each trial
    fprintf('calculating single neuron correlation\n');

    cor_IT1 = 1 - corr(IT1');
    cor_IT2 = 1 - corr(IT2');
    cor_PFC = 1 - corr(PFC');
    save('../data/result/rdm/macaque.mat', 'cor_IT1', "cor_IT2", 'cor_PFC');

    % calculate correlation of EEG data
    occluder = nan(11, 108, 108, 206);
    face = nan(11, 108, 108, 206);
    for sub = 1:11
        subject = ['sub', num2str(sub)];
        data = load(['../data/preprocessed/mvpa_preprocessing/ica/', ...
                subject, '.mat']);
        data = data.data;
        label_mat = load(['../data/label/', subject, '.mat']);
        label_mat = label_mat.imageseq;
        time = data.time{1};

        % select channel based on region
        if strcmp(region, '_fr')
            chnl = ft_channelselection({'FP*', 'AF*'}, data);
        elseif strcmp(region, '_temp')
            chnl = ft_channelselection({'T*'}, data);
        else
            chnl = ft_channelselection({'*'}, data);
        end
        cfg = [];
        cfg.channel = chnl;
        data = ft_selectdata(cfg, data);

        data_when = ft_checkdata(data, 'datatype', 'timelock', 'feedback', ...
            'no');
        data_when = data_when.trial;
        
        % average over repititions
        [C, ~, ic] = unique(label_mat);
        res = nan(108, length(chnl), length(time));
        ind = 1;
        for i=1:191            
            if any(contains(label_mat(ic == i), 'location'))
                res(ind, :, :) = mean(data_when(ic == i, :, :));
                ind = ind + 1;
            end
        end

        cor = nan(108, 108, length(res));
        fprintf('calculating EEG correlation for subject = %d \n', sub);
        for t = 1:length(res)
            cor(:, :, t) = 1 - corr(squeeze(res(:, :, t))');
        end
        cor_EEG(sub, :, :, :) = cor;
    end

    save(['../data/result/rdm/rdm_EEG', char(region), '.mat'], 'cor_EEG');
end
