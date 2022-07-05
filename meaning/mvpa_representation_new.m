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
    
    q = {[1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]};
    
    result = cell(100, 4, 3);
    testlabel = nan(100, 4, 56);
    CF = cell(100, 4);
    Xtest = cell(100, 4);
    for perm = 1:100
        disp(perm)
        
        % y_train(:, 1) = occluded representation
        % y_train(:, 2) = occluder representation
        y_train = cell(191, 2);
        y_test = cell(191, 2);

        % select average of 50% images as train and rest as test data.
        [C, ~, ic] = unique(label_mat);
        train_when = nan(191, length(chnl), length(time));
        train_where = nan(191, length(chnl));
        test_when = nan(191, length(chnl), length(time));
        test_where = nan(191, length(chnl));
        for i = 1:191
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
                if strcmp(img_name(3), 'n')
                    if ~strcmp(img_name(4), '1')
                        y_train{i, 1} = str2double(img_name(2)) - 1;
                        y_test{i, 1} = y_train{i, 1};
                        y_train{i, 2} = zeros(3, 1);
                        y_train{i, 2}(q{str2double(img_name(4)) - 1}) = 1;
                        y_test{i, 2} = y_train{i, 2};
                    end
                end
            elseif strcmp(img_name(1), 'ir')
                if ~strcmp(img_name(4), '1')
                    if ~strcmp(img_name(2), '16')
                        y_train{i, 1} = str2double(img_name(2)) - 6;
                        y_test{i, 1} = y_train{i, 1};
                        y_train{i, 2} = zeros(3, 1);
                        y_train{i, 2}(q{str2double(img_name(4)) - 1}) = 1;
                        y_test{i, 2} = y_train{i, 2};
                    end
                end
            end
        end
        ind = randperm(size(train_when, 1));
        train_when = train_when(ind, :, :);
        train_where = train_where(ind, :, :);
        y_train = y_train(ind, :);

        % delete NaN labels
        train_when = train_when(~cellfun(@isempty, y_train(:, 1)), :, :);
        train_where = train_where(~cellfun(@isempty,y_train(:, 1)), :, :);
        y_train = y_train(~cellfun(@isempty,y_train(:, 1)), :);

        test_when = test_when(~cellfun(@isempty, y_test(:, 1)), :, :);
        test_where = test_where(~cellfun(@isempty, y_test(:, 1)), :, :);
        y_test = y_test(~cellfun(@isempty, y_test(:, 1)), :);

        % average in 50ms time window
        win = 12;   % (12*1000ms)/256Hz ~= 47 ms
        train_when = movmean(train_when, win, 3);
        test_when = movmean(test_when, win, 3);
        
        Y_train = zeros(length(y_train), 4);
        Y_train(:, 1) = cell2mat(y_train(:, 1));
        Y_train(:, 2:end) = cell2mat(y_train(:, 2)')' + 1;
        
        Y_test = zeros(length(y_test), 4);
        Y_test(:, 1) = cell2mat(y_test(:, 1));
        Y_test(:, 2:end) = cell2mat(y_test(:, 2)')' + 1;
        
        cond = ["occluded", "glass", "mask", "hat"];
        for i=1:length(cond)        
            % set classifier
            if numel(unique(Y_train(:, i))) == 2
                classifier = 'lda';
            else
                classifier = 'multiclass_lda';
            end

            if strcmp(analyse, 'when') || strcmp(analyse, 'all')
                % across time
                cfg = [];
                cfg.classifier = classifier;
                cfg.metric = 'kappa';
                cfg.dimension_names = {'samples', 'chan', 'time'};
                cfg.feature_dimension = 2;
                cfg.preprocess = 'zscore';

                [~, result{perm, i, 1}, testlabel(perm, i, :), ...
                    Xtest{perm, i}, CF{perm, i}] = mv_classify(cfg, ...
                    train_when, Y_train(:, i), test_when, Y_test(:, i));
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
                    train_where, Y_train(:, i), test_where, Y_test(:, i));
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
                    train_when, Y_train(:, i), test_when, Y_test(:, i));
            end
        end
    end
    
    for i=1:length(cond)
        type = ["when", "where", "time"];
        for j=1:length(type)
            if isempty(result{1, i, j})
                continue;
            end
            res = mv_combine_results(result(:, i, j), 'average');
            save(['../data/result/mvpa/representation/', subject,...
                '_', char(cond(i)), '_', char(type(j)), char(region), ...
                '.mat'], 'res', 'testlabel', 'Xtest', 'CF', 'time', '-v7.3');
        end
    end
end