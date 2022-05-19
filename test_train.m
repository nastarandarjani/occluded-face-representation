function test_train(subject)
    startup_MVPA_Light
    
    % load data
    data = load(['../data/preprocessed/downsampled_data/', subject, ...
        '.mat']);
    data = data.data;
    label_mat = load(['../data/label/', subject, '.mat']);
    label_mat = label_mat.imageseq;
    
    % y_test(:, 1) = occluded representation
    % y_test(:, 2) = occluder representation
    y_test = nan(2865, 2);
    
    y_train = {nan(2865, 1), nan(2865, 1)};
    
    label_mat = split(label_mat, '.');
    label_mat = cellstr(label_mat(:, 1));
    label_mat = cellfun(@(x)strsplit(x, '_'), label_mat,'UniformOutput',...
        false);
    label = cellfun(@(v)v(1:4), label_mat, 'UniformOutput', false);
    label = vertcat(label{:});
    label = string(label);
    for i=1:2865
        if strcmp(label(i, 1), 'ix')
            y_train{2}(i) = find(strcmp(["pixel"; "phase"; "scramble"], ...
                    label(i, 3)));
        end
        if strcmp(label(i, 1), 'id')
            if strcmp(label(i, 3), 'n') && strcmp(label(i, 4), '1')
                y_train{1}(i) = str2double(label(i, 2)) - 1;
            end
            if ~strcmp(label(i, 3), 'n')
                y_test(i, 1) = str2double(label(i, 2)) - 1;
                y_test(i, 2) = find(strcmp(["pixel"; "phase"; "texture"],...
                    string(label_mat{i}(5))));
            end
        end
    end
    
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
    
    % delete NaN labels
    cfg = [];
    cfg.trials = ~isnan(y_test(:, 1)');
    x_test = ft_selectdata(cfg, data);
    y_test(isnan(y_test(:, 1)), :) = [];
    
    cfg = [];
    cfg.trials = ~isnan(y_train{1});
    x_train{1} = ft_selectdata(cfg, data);
    y_train{1} = y_train{1}(~isnan(y_train{1}), :);
    
    cfg = [];
    cfg.trials = ~isnan(y_train{2});
    x_train{2} = ft_selectdata(cfg, data);
    y_train{2} = y_train{2}(~isnan(y_train{2}), :);
    
    % prepare channel neighbours
    cfg = [];
    cfg.method = 'triangulation';
    cfg.channel = data.label;
    cfg.elec = data.elec;
    cfg.neighbours = ft_prepare_neighbours(cfg);
    neighbours = channelconnectivity(cfg);
    neighbours = logical(double(neighbours) + eye(size(neighbours)));
       
        
    for i=1:2
        x_train{i} = ft_checkdata(x_train{i}, 'datatype', 'timelock', ...
            'feedback', 'no');
        x_tr_when{i} = x_train{i}.trial;
    end
    x_test = ft_checkdata(x_test, 'datatype', 'timelock', 'feedback', 'no');
    x_ts_when = x_test.trial;
    
    cfg = [];
    cfg.latency = [0.1000 0.3000];
    cfg.avgovertime = 'yes';
    for i=1:2
        x_train{i} = ft_selectdata(cfg, x_train{i});
        x_tr_where{i} = x_train{i}.trial;
    end
    x_test = ft_selectdata(cfg, x_test);
    x_ts_where = x_test.trial;
    
    cond = ["occluded", "occluder"];
  
    for c=1:2
        cfg = [];
        cfg.classifier = 'multiclass_lda';
        cfg.metric = {'kappa', 'f1', 'accuracy', 'none'};
        cfg.dimension_names = {'samples', 'chan', 'time'};
    
        cfg.feature_dimension = 2;
        [~, result] = mv_classify(cfg, x_tr_when{c}, ...
            y_train{c}, x_ts_when, y_test(:, c));
        save(['../data/result/mvpa/representation/test_train_', subject, ...
            '_', char(cond(c)), '_when.mat'], 'result');
        
        cfg.generalization_dimension = 3;
        [~, result] = mv_classify_timextime(cfg, x_tr_when{c}, ...
            y_train{c}, x_ts_when, y_test(:, c));
        save(['../data/result/mvpa/representation/test_train_', subject, ...
            '_', char(cond(c)), '_time.mat'], 'result');
        
        cfg.generalization_dimension = [];
        cfg.neighbours = neighbours;
        cfg.feature_dimension = 3;
        [~, result] = mv_classify(cfg, x_tr_where{c}, ...
            y_train{c}, x_ts_where, y_test(:, c));
        save(['../data/result/mvpa/representation/test_train_', subject, ...
            '_', char(cond(c)), '_where.mat'], 'result');
        
    end
end