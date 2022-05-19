function mvpa_representation(subject, analyse, region)
% 
%
% Written by Nastaran Darjani 
% Developed in MATLAB R2017a
% 
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
    
    % prepare channel neighbours
    cfg = [];
    cfg.method = 'triangulation';
    cfg.channel = data.label;
    cfg.elec = data.elec;
    cfg.neighbours = ft_prepare_neighbours(cfg);
    neighbours = channelconnectivity(cfg);
    neighbours = logical(double(neighbours) + eye(size(neighbours)));
    
    
    % y_train(:, 1) = occluded representation
    % y_train(:, 2) = occluder representation
    y_train = nan(191, 2);
    y_test = nan(2865, 2);
    
    % select average of 50% images as train and rest as test data.
    [C, ~, ic] = unique(label_mat);
    test_ind = [];
    avg = cell(1, 191);
    for i=1:191
        seq = find(ic == i);
        avg_ind = seq(randperm(length(seq), 8));
        cfg = [];
        cfg.trials = avg_ind;
        avg{i} = ft_timelockanalysis([], ft_selectdata(cfg, data));
        tst = seq(~ismember(seq, avg_ind));
        test_ind = [test_ind; tst];
        
        % parse image name
        img_name = split(C(i), '.');
        img_name = split(img_name(1), '_');
        if strcmp(img_name(1), 'id')
            if ~strcmp(img_name(3), 'n')
                y_train(i, 1) = str2double(img_name(2)) - 1;
                y_test(tst, 1) = y_train(i, 1);
                y_train(i, 2) = find(strcmp(["pixel"; "phase"; ...
                        "texture"], string(img_name(5))));
                y_test(tst, 2) = y_train(i, 2);
            end
        end
    end
    ind = randperm(length(avg));
    avg = avg(ind);
    y_train = y_train(ind, :);
    x_train = ft_appenddata([], avg{:});
    cfg = [];
    cfg.trials = test_ind;
    x_test = ft_selectdata(cfg, data);
    
    % delete NaN labels
    cfg = [];
    cfg.trials = ~isnan(y_train(:, 1)');
    x_train = ft_selectdata(cfg, data);
    y_train(isnan(y_train(:, 1)), :) = [];
    
    cfg = [];
    cfg.trials = ~isnan(y_test(:, 1)');
    x_test = ft_selectdata(cfg, data);
    y_test(isnan(y_test(:, 1)), :) = [];
    
    % average in 50ms time window
    win = 13;
    for tr = 1:numel(x_train.trial)
        x = x_train.trial{tr};
        T = ones(length(x));
        T = T - triu(T, floor(win./2)+1) - tril(T, -floor(win./2)-1) > 0;
        for in = 1:size(x, 1)
            m = repmat(x(in, :), size(x, 2), 1);
            x(in, :) = sum(T.* m, 2);
        end
        x_train.trial{tr} = x ./ win;
    end
    for tr = 1:numel(x_test.trial)
        x = x_test.trial{tr};
        T = ones(length(x));
        T = T - triu(T, floor(win./2)+1) - tril(T, -floor(win./2)-1) > 0;
        for in = 1:size(x, 1)
            m = repmat(x(in, :), size(x, 2), 1);
            x(in, :) = sum(T.* m, 2);
        end
        x_test.trial{tr} = x ./ win;
    end
    
    x_train = ft_checkdata(x_train, 'datatype', 'timelock', 'feedback', ...
        'no');
    x_tr_when = x_train.trial;
    
    x_test = ft_checkdata(x_test, 'datatype', 'timelock', 'feedback', ...
        'no');
    x_ts_when = x_test.trial;
    
    cfg = [];
    cfg.latency = [0.1000 0.3000];
    cfg.avgovertime = 'yes';
    x_train = ft_selectdata(cfg, x_train);
    x_tr_where = x_train.trial;
    x_test = ft_selectdata(cfg, x_test);
    x_ts_where = x_test.trial;
    
    cond = ["occluded", "occluder"];
    for i=1:2
        % set classifier
        if numel(unique(y_train(:, i))) == 2
            classifier = 'lda';
        else
            classifier = 'multiclass_lda';
        end
        
        if strcmp(analyse, 'when') || strcmp(analyse, 'all')
            % across time
            cfg = [];
            cfg.classifier = classifier;
            cfg.metric = {'kappa', 'f1', 'accuracy', 'none'};
            cfg.dimension_names = {'samples', 'chan', 'time'};
            cfg.feature_dimension = 2;
            
            [~, result] = mv_classify(cfg, x_tr_when, ...
                        y_train(:, i), x_ts_when, y_test(:, i));
            save(['../data/result/mvpa/representation/', subject, '_', ...
                char(cond(i)), '_when', char(region), '.mat'], ...
                'result', 'time', '-v7.3');
        end
            
        if strcmp(analyse, 'where') || strcmp(analyse, 'all')
            cfg = [];
            cfg.classifier = classifier;
            cfg.metric = {'kappa', 'f1', 'accuracy', 'none'};
            cfg.dimension_names = {'samples', 'chan', 'time'};
            cfg.feature_dimension = 3;
            cfg.neighbours = neighbours;
            
            [~, result] = mv_classify(cfg, x_tr_where, ...
                        y_train(:, i), x_ts_where, y_test(:, i));
  
            save(['../data/result/mvpa/representation/', subject, '_', ...
                char(cond(i)), '_where', char(region), '.mat'], ...
                'result', 'time', '-v7.3');
        end
            
        if strcmp(analyse, 'time') || strcmp(analyse, 'all')
            cfg = [];
            cfg.classifier = classifier;
            cfg.metric = {'kappa', 'f1', 'accuracy', 'none'};
            cfg.dimension_names = {'samples', 'chan', 'time'};
            cfg.feature_dimension = 2;
            cfg.generalization_dimension = 3;
            
            [~, result] = mv_classify_timextime(cfg, x_tr_when, ...
                        y_train(:, i), x_ts_when, y_test(:, i));
            save(['../data/result/mvpa/representation/', subject, '_', ...
                char(cond(i)), '_time', char(region), '.mat'], ...
                'result', 'time', '-v7.3');
        end
    end
end