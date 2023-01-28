function RDM(subject, region)
    startup_MVPA_Light

    % add '_' to not empty elements of region 
    if ~strcmp(region, "")
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
    data_when = data_when.trial;

    result = cell(100, 2, 6);
    for perm = 1:100
        % y_train(:, 1) = occluded representation
        % y_train(:, 2) = occluder representation
        y_train = nan(191, 2);
        y_test = nan(191, 2);

        % select average of 50% images as train and rest as test data.
        [C, ~, ic] = unique(label_mat);
        train_when = nan(191, length(chnl), length(time));
        test_when = nan(191, length(chnl), length(time));
        for i=1:191
            seq = find(ic == i);
            avg_ind = seq(randperm(length(seq), 8));
            train_when(i, :, :) = mean(data_when(avg_ind, :, :));
            avg_ind = seq(~ismember(seq, avg_ind));
            test_when(i, :, :) = mean(data_when(avg_ind, :, :));

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
        ind = randperm(size(train_when, 1));
        train_when = train_when(ind, :, :);
        y_train = y_train(ind, :);

        % delete NaN labels
        train_when = train_when(~isnan(y_train(:, 1)), :, :);
        y_train = y_train(~isnan(y_train(:, 1)), :);

        test_when = test_when(~isnan(y_test(:, 1)), :, :);
        y_test = y_test(~isnan(y_test(:, 1)), :);
        
        % average in 50ms time window
        win = 12;   % (12*1000ms)/256Hz ~= 47 ms
        train_when = movmean(train_when, win, 3);
        test_when = movmean(test_when, win, 3);
        
        for i=1:2
            num_class = numel(unique(y_train(:, i)));

            % across time
            cfg = [];
            cfg.classifier = 'lda';
            cfg.metric = {'kappa', 'accuracy'};
            cfg.dimension_names = {'samples', 'chan', 'time'};
            cfg.feature_dimension = 2;
            cfg.preprocess = 'zscore';

            labels = nchoosek(1:num_class, 2);
            for j = 1:length(labels)
                ind = find(any(y_train(:, i) == labels(j, :), 2));
                X = train_when(ind, :, :);
                [~, ~, Y] = unique(y_train(ind, i));

                ind = find(any(y_test(:, i) == labels(j, :), 2));
                X_test = test_when(ind, :, :);
                [~, ~, Y_test] = unique(y_test(ind, i));

                [~, result{perm, i, j}] = mv_classify(cfg, ...
                    X, Y, X_test, Y_test);
            end
        end
    end

    save(['../data/result/rdm/', subject, char(region), '.mat'], 'result', ...
        'time', '-v7.3');


    % calculate correlation of EEG data
    occluder = nan(11, 108, 108, 206);
    face = nan(11, 108, 108, 206);
    for sub = 1:11
        subject = ['sub', num2str(sub)];
        res = load(['../data/result/rdm/', subject, char(region), '.mat']);
        time = res.time;
        result = res.result;

        res = nan(2, 6, 206);
        for i = 1:2
            for j = 1:6
                if i == 2 && j>3
                    continue;
                end
                temp = mv_combine_results(result(:, i, j), 'average');
                res(i, j, :) = temp.perf{1};
            end
        end

        ind = nchoosek(1:4, 2);
        for i = 1:length(ind)
            face(sub, (ind(i, 1)-1)*27 + 1  : ind(i, 1)*27, ...
                (ind(i, 2)-1)*27 + 1 : ind(i, 2)*27, :) = ones(27, 27) .* res(1, i, :);
            face(sub, (ind(i, 2)-1)*27 + 1 : ind(i, 2)*27, ...
                (ind(i, 1)-1)*27 + 1  : ind(i, 1)*27, :) = ones(27, 27) .* res(1, i, :);
        end

        ind = nchoosek(1:3, 2);
        mat = nan(3, 3, 206);
        for i = 1:3
            mat(ind(i, 1), ind(i, 2), :) = res(2, i, :);
            mat(ind(i, 2), ind(i, 1), :) = res(2, i, :);
        end
        occluder(sub, :, :, :) = repmat(mat, 36);
        save(['../data/result/rdm/', subject, char(region), '.mat'], ...
            'face', 'occluder', 'time');
    end


end
