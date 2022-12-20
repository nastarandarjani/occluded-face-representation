function [IT, PFC] = single_neuron(Res, region)
    % first peak: 50-200 ms
    % second peak: 200-450 ms
    startup_MVPA_Light

    if ~ strcmp(region, "")
    	region = string(['_', char(region)]);
    end
    
    % select trials
    trl = [39:65, 77:103, 115:141, 153:179];
    Res.IT = Res.IT(trl, :, 300:1100);
    Res.PFC = Res.PFC(trl, :, 300:1100);

    % resample to 256 Hz
    Res.IT = permute(resample(permute(Res.IT, [3, 1, 2]), ...
            256, 1000), [2, 3, 1]);
    Res.PFC = permute(resample(permute(Res.PFC, [3, 1, 2]), ...
            256, 1000), [2, 3, 1]);

    % moving average over 50 ms
    Res.IT = movmean(Res.IT, 50, 3);
    Res.PFC = movmean(Res.PFC, 50, 3);
    
    % delete NaN rows (trials)
    deleted_trials = any(isnan(Res.PFC), 2);
    deleted_trials = find(deleted_trials(:, 1, 1));
    Res.IT(deleted_trials, :, :) = [];
    Res.PFC(deleted_trials, :, :) = [];
    
    % calculate correlation within each trial
    cor_IT = nan(size(Res.IT, 1), size(Res.IT, 1), size(Res.IT, 3));
    cor_PFC = nan(size(Res.IT, 1), size(Res.IT, 1), size(Res.PFC, 3));
    fprintf('calculating single neuron correlation\n');
    for t = 1:size(Res.IT, 3)
        cor_IT(:, :, t) = 1 - corr(squeeze(Res.IT(:, :, t))');
        cor_PFC(:, :, t) = 1 - corr(squeeze(Res.PFC(:, :, t))');
    end

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
    end

%         data = load(['../data/preprocessed/mvpa_preprocessing/ica/', ...
%                 subject, '.mat']);
%         data = data.data;
%         label_mat = load(['../data/label/', subject, '.mat']);
%         label_mat = label_mat.imageseq;
%         time = data.time{1};
% 
%         % select channel based on region
%         if strcmp(region, '_fr')
%             chnl = ft_channelselection({'FP*', 'AF*'}, data);
%         elseif strcmp(region, '_temp')
%             chnl = ft_channelselection({'T*'}, data);
%         else
%             chnl = ft_channelselection({'*'}, data);
%         end
%         cfg = [];
%         cfg.channel = chnl;
%         data = ft_selectdata(cfg, data);
% 
%         data_when = ft_checkdata(data, 'datatype', 'timelock', 'feedback', ...
%             'no');
%         data_when = data_when.trial;
%         
%         % average over repititions
%         [C, ~, ic] = unique(label_mat);
%         res = nan(108, length(chnl), length(time));
%         ind = 1;
%         for i=1:191            
%             if any(contains(label_mat(ic == i), 'location'))
%                 res(ind, :, :) = mean(data_when(ic == i, :, :));
%                 ind = ind + 1;
%             end
%         end
% 
%         cor = nan(108, 108, length(res));
%         fprintf('calculating EEG correlation for subject = %d \n', sub);
%         for t = 1:length(res)
%             cor(:, :, t) = 1 - corr(squeeze(res(:, :, t))');
%         end
%         cor_EEG(sub, :, :, :) = cor;
%     end
% 
%     save(['../data/result/rdm/rdm_EEG', char(region), '.mat'], 'cor_EEG');


    IT = nan(11, 206, 206, 1);
    PFC = nan(11, 206, 206, 1);
    for sub = 1:11
        res = squeeze(face(sub, :, :, :));
        res(deleted_trials, :, :) = [];
        res(:, deleted_trials, :) = [];

        corr_IT = reshape(cor_IT, [104*104, 206]);
        corr_PFC = reshape(cor_PFC, [104*104, 206]);
        res = reshape(res, [104*104, 206]);

        fprintf('calculating RSA for subject = %d \n', sub);
        parfor t = 1:size(Res.IT, 3)
            for t2 = 1:206
                IT(sub, t, t2) = corr(res(:, t), corr_IT(:, t2), 'type', 'Spearman', 'rows', 'pairwise');
                PFC(sub, t, t2) = corr(res(:, t), corr_PFC(:, t2), 'type', 'Spearman', 'rows', 'pairwise');
            end
        end
    end

    save(['../data/result/rdm/rsa_face', char(region), '.mat'], 'IT', 'PFC');


    IT = nan(11, 206, 206, 1);
    PFC = nan(11, 206, 206, 1);
    for sub = 1:11
        res = squeeze(occluder(sub, :, :, :));
        res(deleted_trials, :, :) = [];
        res(:, deleted_trials, :) = [];

        cor_IT = reshape(cor_IT, [104*104, 206]);
        cor_PFC = reshape(cor_PFC, [104*104, 206]);
        res = reshape(res, [104*104, 206]);

        fprintf('calculating RSA for subject = %d \n', sub);
        parfor t = 1:size(Res.IT, 3)
            for t2 = 1:206
            IT(sub, t, t2) = corr(res(:, t), cor_IT(:, t2), 'type', 'Spearman', 'rows', 'pairwise');
            PFC(sub, t, t2) = corr(res(:, t), cor_PFC(:, t2), 'type', 'Spearman', 'rows', 'pairwise');
            end
        end
    end

    save(['../data/result/rdm/rsa_occluder', char(region), '.mat'], 'IT', 'PFC');
    
%     % compute occluder model
%     occluder = ones(108, 108);
%     for i = 1:4
%         occluder(27*(i-1) + 1:27*i, 27*(i-1) + 1:27*i) = 0;
%     end
%     occluder(deleted_trials, :) = [];
%     occluder(:, deleted_trials) = [];
%     occluder = occluder(:);
% 
%     cor_IT = reshape(cor_IT, [104*104, 2000]);
%     cor_PFC = reshape(cor_PFC, [104*104, 2000]);
%     IT = nan(2000, 1);
%     PFC = nan(2000, 1);
%     for t = 1:size(Res.IT, 3)
%         fprintf('%d ', t);
%         IT(t) = corr(occluder, cor_IT(:, t), 'Type', 'Kendall');
%         PFC(t) = corr(occluder, cor_PFC(:, t), 'Type', 'Kendall');
%     end
%     fprintf('\n');
% 
%     save('../data/result/rdm/occluder_neuron.mat', 'IT', 'PFC');

    x = load( '../data/result/mvpa/representation/ica-zscore/sub1_occluder_time.mat');
    x = x.res;
    x.plot = x.plot(1);
    x.perf = CDF_(squeeze(mean(PFC)));
    x.perf_std = squeeze(std(PFC)) ./ 11;
    x.metric = 'correlation';
    x.n_metrics = 1;

    mv_plot_result(x, time, time);
    xlabel('macaque');
    ylabel('human');
    title(char(region));
    %touch(gca);

%     % compute occluded model
%     occluded = ones(108, 108);
%     for i = 1:3
%         ind = i:3:108;
%         for j = 1:length(ind)
%             occluded(ind(j), ind) = 0;
%         end
%     end
%     occluded(deleted_trials, :) = [];
%     occluded(:, deleted_trials) = [];
%     occluded = occluded(:);
% 
%     cor_IT = reshape(cor_IT, [104*104, 2000]);
%     cor_PFC = reshape(cor_PFC, [104*104, 2000]);
%     IT = nan(2000, 1);
%     PFC = nan(2000, 1);
%     for t = 1:size(Res.IT, 3)
%         fprintf('%d ', t);
%         IT(t) = corr(occluded, cor_IT(:, t), 'Type', 'Kendall');
%         PFC(t) = corr(occluded, cor_PFC(:, t), 'Type', 'Kendall');
%     end
%     fprintf('\n');
% 
%     save('../data/result/rdm/occluded_neuron.mat', 'IT', 'PFC');
% 
% 
%     % plot results
%     plot(IT);
%     hold on
%     plot(PFC);
%     xline(500, '--k')
%     xticklabels(-500:200:1500);
%     legend('IT', 'PFC')
%     xlabel('Time')
%     ylabel('Correlation')
%     touch(gca);
% 
%     print('../data/result/rdm/occluder-monkey', '-depsc');
end
