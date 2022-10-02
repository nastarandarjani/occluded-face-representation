function [IT, PFC] = single_neuron(Res)
    % first peak: 50-200 ms
    % second peak: 200-450 ms
    
    % select trials
    trl = [39:65, 77:103, 115:141, 153:179];
    Res.IT = Res.IT(trl, :, :);
    Res.PFC = Res.PFC(trl, :, :);
    
    % delete NaN rows (trials)
    deleted_trials = any(isnan(Res.PFC), 2);
    deleted_trials = find(deleted_trials(:, 1, 1));
    Res.IT(deleted_trials, :, :) = [];
    Res.PFC(deleted_trials, :, :) = [];
    
    % moving average over 50 ms
    Res.IT = movmean(Res.IT, 50, 3);
    Res.PFC = movmean(Res.PFC, 50, 3);
    
    % calculate correlation within each trial
    cor_IT = nan(size(Res.IT, 1), size(Res.IT, 1), size(Res.IT, 3));
    cor_PFC = nan(size(Res.IT, 1), size(Res.IT, 1), size(Res.PFC, 3));
    for t = 1:size(Res.IT, 3)
        fprintf('%d ', t);
        cor_IT(:, :, t) = 1 - corr(squeeze(Res.IT(:, :, t))', 'Type', ...
            'Spearman');
        cor_PFC(:, :, t) = 1 - corr(squeeze(Res.PFC(:, :, t))', 'Type', ...
            'Spearman');
    end
    fprintf('\n');
    
    % compute occluder model
    occluder = ones(108, 108);
    for i = 1:4
        occluder(27*(i-1) + 1:27*i, 27*(i-1) + 1:27*i) = 0;
    end
    occluder(deleted_trials, :) = [];
    occluder(:, deleted_trials) = [];
    occluder = occluder(:);

    cor_IT = reshape(cor_IT, [104*104, 2000]);
    cor_PFC = reshape(cor_PFC, [104*104, 2000]);
    IT = nan(2000, 1);
    PFC = nan(2000, 1);
    for t = 1:size(Res.IT, 3)
        fprintf('%d ', t);
        IT(t) = corr(occluder, cor_IT(:, t), 'Type', 'Kendall');
        PFC(t) = corr(occluder, cor_PFC(:, t), 'Type', 'Kendall');
    end
    fprintf('\n');

    save('../data/result/rdm/occluder_neuron.mat', 'IT', 'PFC');


    % compute occluded model
    occluded = ones(108, 108);
    for i = 1:3
        ind = i:3:108;
        for j = 1:length(ind)
            occluded(ind(j), ind) = 0;
        end
    end
    occluded(deleted_trials, :) = [];
    occluded(:, deleted_trials) = [];
    occluded = occluded(:);

    cor_IT = reshape(cor_IT, [104*104, 2000]);
    cor_PFC = reshape(cor_PFC, [104*104, 2000]);
    IT = nan(2000, 1);
    PFC = nan(2000, 1);
    for t = 1:size(Res.IT, 3)
        fprintf('%d ', t);
        IT(t) = corr(occluded, cor_IT(:, t), 'Type', 'Kendall');
        PFC(t) = corr(occluded, cor_PFC(:, t), 'Type', 'Kendall');
    end
    fprintf('\n');

    save('../data/result/rdm/occluded_neuron.mat', 'IT', 'PFC');
end
