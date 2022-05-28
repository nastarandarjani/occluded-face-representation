function test_train(subject, region)
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
        
    result = cell(100, 2, 3);
    for perm = 1:100
        % y_test(:, 1) = occluded representation
        % y_test(:, 2) = occluder representation
        y_test = nan(191, 2);
        y_train = {nan(4*191, 1), nan(4*191, 1)};
        
        % select average of 50% images as train and rest as test data.
        [C, ~, ic] = unique(label_mat);
        train_when = nan(4*191, length(chnl), length(time));
        train_where = nan(4*191, length(chnl));
        test_when = nan(191, length(chnl), length(time));
        test_where = nan(191, length(chnl));
        for i=1:191
            seq = find(ic == i);
            avg_ind = seq(randperm(length(seq), 12));
            train_when((i-1)*4 + 1:i*4, :, :) = squeeze(mean(reshape(...
                            data_when(avg_ind, :, :), 3, 4, [], 206)));
            train_where((i-1)*4 + 1:i*4, :, :) = squeeze(mean(reshape(...
                            data_where(avg_ind, :), 3, 4, [])));
            avg_ind = seq(~ismember(seq, avg_ind));
            test_when(i, :, :) = mean(data_when(avg_ind, :, :));
            test_where(i, :) = mean(data_where(avg_ind, :));

            % parse image name
            img_name = split(C(i), '.');
            img_name = split(img_name(1), '_');
            if strcmp(img_name(1), 'ix')
                y_train{2}((i-1)*4 + 1:i*4) = find(strcmp(...
                    ["pixel"; "phase"; "scramble"], string(img_name(3))));
            end
            if strcmp(img_name(1), 'id')
                if strcmp(img_name(3), 'n') && strcmp(img_name(4), '1')
                    y_train{1}((i-1)*4 + 1:i*4) = ...
                        str2double(img_name(2)) - 1;
                end
                if ~strcmp(img_name(3), 'n')
                    y_test(i, 1) = str2double(img_name(2)) - 1;
                    y_test(i, 2) = find(strcmp(["pixel"; "phase"; ...
                            "texture"], string(img_name(5))));
                end
            end
        end
        ind = randperm(size(train_when, 1));
        train_when = train_when(ind, :, :);
        train_where = train_where(ind, :, :);
        y_train{1} = y_train{1}(ind);
        y_train{2} = y_train{2}(ind);
        
        train_when = {train_when, train_when};
        train_where = {train_where, train_where};
        
        % delete NaN labels
        train_when{1} = train_when{1}(~isnan(y_train{1}), :, :);
        train_when{2} = train_when{2}(~isnan(y_train{2}), :, :);
        train_where{1} = train_where{1}(~isnan(y_train{1}), :, :);
        train_where{2} = train_where{2}(~isnan(y_train{2}), :, :);
        y_train{1} = y_train{1}(~isnan(y_train{1}), :);
        y_train{2} = y_train{2}(~isnan(y_train{2}), :);

        test_when = test_when(~isnan(y_test(:, 1)), :, :);
        test_where = test_where(~isnan(y_test(:, 1)), :, :);
        y_test = y_test(~isnan(y_test(:, 1)), :);
        
        % average in 50ms time window
        win = 13;
        for tr = 1:size(train_when{1}, 1)
            x = squeeze(train_when{1}(tr, :, :));
            T = ones(length(x));
            T = T - triu(T, floor(win./2)+1) - tril(T, ...
                -floor(win./2)-1) > 0;
            for in = 1:size(x, 1)
                m = repmat(x(in, :), size(x, 2), 1);
                x(in, :) = sum(T.* m, 2);
            end
            train_when{1}(tr, :, :) = x ./ win;
        end
        for tr = 1:size(train_when{2}, 1)
            x = squeeze(train_when{2}(tr, :, :));
            T = ones(length(x));
            T = T - triu(T, floor(win./2)+1) - tril(T, ...
                -floor(win./2)-1) > 0;
            for in = 1:size(x, 1)
                m = repmat(x(in, :), size(x, 2), 1);
                x(in, :) = sum(T.* m, 2);
            end
            train_when{2}(tr, :, :) = x ./ win;
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
    
        cond = ["occluded", "occluder"];
        for c=1:2
            % set classifier
            if numel(unique(y_train{c})) == 2
                classifier = 'lda';
            else
                classifier = 'multiclass_lda';
            end
            
            cfg = [];
            cfg.classifier = classifier;
            cfg.metric = {'kappa', 'f1', 'accuracy'};
            cfg.dimension_names = {'samples', 'chan', 'time'};

            cfg.feature_dimension = 2;
            cfg.mvpa.preprocess = 'zscore';
            [~, result{perm, c, 1}] = mv_classify(cfg, train_when{c}, ...
                y_train{c}, test_when, y_test(:, c));

            cfg.generalization_dimension = 3;
            [~, result{perm, c, 3}] = mv_classify_timextime(cfg, ...
                train_when{c}, y_train{c}, test_when, y_test(:, c));

            cfg.generalization_dimension = [];
            
            
            
            
            cfg.neighbours = neighbours;
            cfg.feature_dimension = 3;
            [~, result{perm, c, 2}] = mv_classify(cfg, train_where{c}, ...
                y_train{c}, test_where, y_test(:, c));
        end
    end
    
    for i=1:2
        type = ["when", "where", "time"];
        for j=1:3
            if isempty(result{1, i, j})
                continue;
            end
            res = mv_combine_results(result(:, i, j), 'average');
            save(['../data/result/mvpa/representation/test_train_', ...
                subject, '_', char(cond(i)), '_', char(type(j)), ...
                char(region), '.mat'], 'res', 'time', '-v7.3');
        end
    end
end