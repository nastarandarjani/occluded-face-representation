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
    
    cfg = [];
    cfg.latency = [0.1000 0.3000];
    cfg.avgovertime = 'yes';
    data_where = ft_selectdata(cfg, data_when);
    data_where = data_where.trial;
    
    data_when = data_when.trial;
    
    % prepare channel neighbours
    cfg = [];
    cfg.method = 'triangulation';
    cfg.channel = data.label;
    cfg.elec = data.elec;
    cfg.neighbours = ft_prepare_neighbours(cfg);
    neighbours = channelconnectivity(cfg);
    neighbours = logical(double(neighbours) + eye(size(neighbours)));
    
    result = cell(100, 3, 3);
    for perm = 1:100
    
        % y_train(:, 1) = v1
        % y_train(:, 2) = v2
        % y_train(:, 3) = v4    
        y_train = nan(191, 3);
        y_test = nan(191, 3);
        
        % select average of 50% images as train and rest as test data.
        [C, ~, ic] = unique(label_mat);
        train_when = nan(191, length(chnl), length(time));
        train_where = nan(191, length(chnl));
        test_when = nan(191, length(chnl), length(time));
        test_where = nan(191, length(chnl));
        for i=1:191
            seq = find(ic == i);
            avg_ind = seq(randperm(length(seq), 8));
            train_when(i, :, :) = mean(data_when(avg_ind, :, :));
            train_where(i, :, :) = mean(data_where(avg_ind, :));
            avg_ind = seq(~ismember(seq, avg_ind));
            test_when(i, :, :) = mean(data_when(avg_ind, :, :));
            test_where(i, :, :) = mean(data_where(avg_ind, :));

            % parse image name
            img_name = split(C(i), '.');
            img_name = split(img_name(1), '_');
            if strcmp(img_name(1), 'id')
                if ~strcmp(img_name(3), 'n')
                    y_train(i, :) = 1;
                    y_test(i, :) = 1;
                    ind = find(strcmp(["pixel"; "phase"; ...
                            "texture"], string(img_name(5))));
                    y_train(i, ind) = 2;
                    y_test(i, ind) = 2;
                end
            end
        end
        ind = randperm(size(train_when, 1));
        train_when = train_when(ind, :, :);
        train_where = train_where(ind, :, :);
        y_train = y_train(ind, :);

        % delete NaN labels
        train_when = train_when(~isnan(y_train(:, 1)), :, :);
        train_where = train_where(~isnan(y_train(:, 1)), :, :);
        y_train = y_train(~isnan(y_train(:, 1)), :);

        test_when = test_when(~isnan(y_test(:, 1)), :, :);
        test_where = test_where(~isnan(y_test(:, 1)), :, :);
        y_test = y_test(~isnan(y_test(:, 1)), :);

        % average in 50ms time window
        win = 13;
        for tr = 1:size(train_when, 1)
            x = squeeze(train_when(tr, :, :));
            T = ones(length(x));
            T = T - triu(T, floor(win./2)+1) - tril(T, ...
                -floor(win./2)-1) > 0;
            for in = 1:size(x, 1)
                m = repmat(x(in, :), size(x, 2), 1);
                x(in, :) = sum(T.* m, 2);
            end
            train_when(tr, :, :) = x ./ win;
        end
        for tr = 1:size(test_when, 1)
            x = squeeze(test_when(tr, :, :));
            T = ones(length(x));
            T = T - triu(T, floor(win./2)+1) - tril(T, ...
                -floor(win./2)-1) > 0;
            for in = 1:size(x, 1)
                m = repmat(x(in, :), size(x, 2), 1);
                x(in, :) = sum(T.* m, 2);
            end
            test_when(tr, :, :) = x ./ win;
        end

        cond = ["v1", "v2", "v4"];
        for i=1:3
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
                cfg.metric = {'kappa', 'f1', 'accuracy'};
                cfg.dimension_names = {'samples', 'chan', 'time'};
                cfg.feature_dimension = 2;
                cfg.mvpa.preprocess = 'zscore';

                [~, result{perm, i, 1}] = mv_classify(cfg, ...
                    train_when, y_train(:, i), test_when, y_test(:, i));
            end

            if strcmp(analyse, 'where') || strcmp(analyse, 'all')
                cfg = [];
                cfg.classifier = classifier;
                cfg.metric = {'kappa', 'f1', 'accuracy'};
                cfg.dimension_names = {'samples', 'chan', 'time'};
                cfg.feature_dimension = 3;
                cfg.neighbours = neighbours;
                cfg.mvpa.preprocess = 'zscore';

                [~, result{perm, i, 2}] = mv_classify(cfg, ...
                    train_where, y_train(:, i), test_where, y_test(:, i));
            end

            if strcmp(analyse, 'time') || strcmp(analyse, 'all')
                cfg = [];
                cfg.classifier = classifier;
                cfg.metric = {'kappa', 'f1', 'accuracy'};
                cfg.dimension_names = {'samples', 'chan', 'time'};
                cfg.feature_dimension = 2;
                cfg.generalization_dimension = 3;
                cfg.mvpa.preprocess = 'zscore';

                [~, result{perm, i, 3}] = mv_classify_timextime(cfg, ...
                    train_when, y_train(:, i), test_when, y_test(:, i));
            end
        end
    end
    for i=1:3
        type = ["when", "where", "time"];
        for j=1:3
            if isempty(result{1, i, j})
                continue;
            end
            res = mv_combine_results(result(:, i, j), 'average');
            save(['../data/result/mvpa/representation/', subject,...
                '_', char(cond(i)), '_', char(type(j)), char(region), ...
                '.mat'], 'res', 'time', '-v7.3');
        end
    end
end
