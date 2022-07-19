function mvpa_representation(subject, analyse, region, time_point)
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
    
    cfg = [];
    cfg.latency = time_point;
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
        
        % y_train(:, 1) = occluded representation
        % y_train(:, 2) = occluder representation
        y_train = nan(191, 2);
        y_test = nan(191, 2);

        % select average of 50% images as train and rest as test data.
        [C, ~, ic] = unique(label_mat);
        train_when = nan(191, length(chnl), length(time));
        test_when = nan(191, length(chnl), length(time));
        train_where = nan(191, length(chnl));
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
                    y_train(i, 1) = str2double(img_name(2)) - 1;
                    y_test(i, 1) = y_train(i, 1);
                    y_train(i, 2) = find(strcmp(["pixel"; "phase"; ...
                            "texture"], string(img_name(5))));
                    y_test(i, 2) = y_train(i, 2);
                end
            end
        end
        ind = randperm(size(train_where, 1));
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
                cfg.metric = {'kappa', 'f1', 'accuracy'};
                cfg.dimension_names = {'samples', 'chan', 'time'};
                cfg.feature_dimension = 2;
                cfg.preprocess = 'zscore';
                
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
                cfg.preprocess = 'zscore';

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
                cfg.preprocess = 'zscore';

                [~, result{perm, i, 3}] = mv_classify_timextime(cfg, ...
                    train_when, y_train(:, i), test_when, y_test(:, i));
            end
        end
    end
    
    for i=1:2
        type = ["when", "where", "time"];
        time_point = string(time_point);
        for j=1:3
            if isempty(result{1, i, j})
                continue;
            end
            res = mv_combine_results(result(:, i, j), 'average');
            save(['data/result/mvpa/representation/', subject,...
                '_', char(cond(i)), '_', char(type(j)), char(region), ...
                char(time_point(1)), '_', char(time_point(2)), ...
                '.mat'], 'res', 'time', '-v7.3');
        end
    end
end
