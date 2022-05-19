function v1_v2_v4(subject, analyse, region)
    startup_MVPA_Light
        
    % add '_' to not empty elements of region 
    if ~ strcmp(region, "")
        region = string(['_', char(region)]);
    end

    % load data
    data = load(['../data/preprocessed/downsampled_data/', subject, ...
        '.mat']);
    data = data.data;
    label_mat = load(['../data/label/', subject, '.mat']);
    label_mat = label_mat.imageseq;
    
    % task(:, 1) = v1
    % task(:, 2) = v2
    % task(:, 3) = v4    
    task = nan(2865, 3);
    
    label_mat = split(label_mat, '.');
    label_mat = cellstr(label_mat(:, 1));
    label_mat = cellfun(@(x)strsplit(x, '_'), label_mat,'UniformOutput',...
        false);
    label = cellfun(@(v)v(1:4), label_mat, 'UniformOutput', false);
    label = vertcat(label{:});
    label = string(label);
    for i=1:2865
        if strcmp(label(i, 1), 'id') && ~strcmp(label(i, 3), 'n')
            task(i, :) = 1;
            ind = strcmp(["pixel"; "phase"; "texture"], ...
                string(label_mat{i}(5)));
            task(i, ind) = 2;
        end
    end
    
    % delete NaN labels
    cfg = [];
    cfg.trials = ~isnan(task(:, 1)');
    data = ft_selectdata(cfg, data);
    task(isnan(task(:, 1)), :) = [];
    
    % average in 50ms time window
    win = 13;
    for tr = 1:numel(data.trial)
        x = data.trial{tr};
        T = ones(length(x));
        T = T - triu(T, floor(win./2)+1) - tril(T, -floor(win./2)-1) > 0;
        for in = 1:size(x, 1)
            m = repmat(x(in, :), size(x, 2), 1);
            x(in, :) = sum(T.* m, 2);
        end
        data.trial{tr} = x ./ win;
    end
    
    % select channel based on region
    if strcmp(region, '_fr')
        chnl = ft_channelselection({'FP*', 'AF*'}, data);
    elseif strcmp(region, '_temp')
        chnl = ft_channelselection({'T*'}, data);
    else
        chnl = ft_channelselection({'*'}, data);
    end
    
    % prepare channel neighbours
    cfg = [];
    cfg.method = 'triangulation';
    cfg.channel = data.label;
    cfg.elec = data.elec;
    neighbours = ft_prepare_neighbours(cfg);
    
    cond = ["v1", "v2", "v4"];
    for i=1:3
        % set classifier
        if numel(unique(task(:, i))) == 2
            classifier = 'lda';
        else
            classifier = 'multiclass_lda';
        end
        
        if strcmp(analyse, 'when') || strcmp(analyse, 'all')
            % across time
            cfg = [];
            cfg.method = 'mvpa';
            cfg.features = 'chan';
            cfg.mvpa.classifier = classifier;
            cfg.mvpa.metric = {'kappa', 'f1', 'accuracy', 'none'};
            cfg.mvpa.k = 10;
            cfg.design = task(:, i);
            cfg.channel = chnl;
            stat = ft_timelockstatistics(cfg, data);

            save(['../data/result/mvpa/representation/', subject, '_', ...
                char(cond(i)), '_when', char(region), '.mat'], ...
                'stat', '-v7.3');
        end
            
        if strcmp(analyse, 'where') || strcmp(analyse, 'all')
            cfg = [];
            cfg.method = 'mvpa';
            cfg.latency = [0.1, 0.3];
            cfg.avgovertime = 'yes';
            cfg.features = 'time';
            cfg.mvpa.classifier = classifier;
            cfg.mvpa.metric = {'kappa', 'f1', 'accuracy', 'none'};
            cfg.mvpa.k = 10;
            cfg.design = task(:, i);
            cfg.neighbours  = neighbours;
            cfg.channel = chnl;
            stat = ft_timelockstatistics(cfg, data);
  
            save(['../data/result/mvpa/representation/', subject, '_', ...
                char(cond(i)), '_where', char(region), '.mat'], ...
                'stat', '-v7.3');
        end
            
        if strcmp(analyse, 'time') || strcmp(analyse, 'all')
            cfg = [] ;  
            cfg.method = 'mvpa';
            cfg.mvpa.classifier = classifier;
            cfg.mvpa.metric = {'kappa', 'f1', 'accuracy', 'none'};
            cfg.mvpa.k = 10;
            cfg.features = 'chan';
            cfg.generalize = 'time';
            cfg.design = task(:, i);
            cfg.channel = chnl;
            stat = ft_timelockstatistics(cfg, data);

            save(['../data/result/mvpa/representation/', subject, '_', ...
                 char(cond(i)), '_time', char(region), '.mat'], ...
                 'stat', '-v7.3');
        end
    end
end
