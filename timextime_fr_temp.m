% KANKELE

startup_MVPA_Light

data = load(['../data/preprocessed/downsampled_data/', subject, ...
        '.mat']);
data = data.data;
label_mat = load(['../data/label/', subject, '.mat']);
label_mat = label_mat.imageseq;

% task(:, 1) = occluded representation
% task(:, 2) = occluder representation
task = nan(2865, 2);

label_mat = split(label_mat, '.');
label_mat = cellstr(label_mat(:, 1));
label_mat = cellfun(@(x)strsplit(x, '_'), label_mat,'UniformOutput',...
    false);
label = cellfun(@(v)v(1:4), label_mat, 'UniformOutput', false);
label = vertcat(label{:});
label = string(label);
for i=1:2865
    if strcmp(label(i, 1), 'id')
        if ~strcmp(label(i, 3), 'n')
            task(i, 1) = str2double(label(i, 2)) - 1;
            task(i, 2) = find(strcmp(["pixel"; "phase"; "texture"], ...
                string(label_mat{i}(5))));
        end
    end
end

% delete NaN labels
cfg = [];
cfg.trials = ~isnan(task(:, 1)');
data = ft_selectdata(cfg, data);
task(isnan(task(:, 1)), :) = [];
task = transpose(task);
    
cond = ["occluded", "occluder"];
for i=1:2
    % set classifier
    if numel(unique(task(i, :))) == 2
        classifier = 'lda';
    else
        classifier = 'multiclass_lda';
    end

    data = ft_checkdata(data, 'datatype', 'timelock', 'feedback', 'no');
    cfg = [];
    cfg.channel = ft_channelselection({'FP*', 'AFp*', 'AF4'}, data);
    data_fr = ft_selectdata(cfg, data);
    cfg.channel = ft_channelselection({'T*'}, data);
    data_temp = ft_selectdata(cfg, data);
    
    cfg = [];
    cfg.classifier = classifier;
    cfg.metric = {'kappa', 'f1', 'accuracy'};
    mv_classify_timextime(cfg, data_fr.trial, task(i, :), ...
        data_temp.trial, task(i, :));

end
