function mvpa_representation(subject)
% 
%
% Written by Nastaran Darjani 
% Developed in MATLAB R2017a
% 
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

%     % prepare layout
%     data.elec.coordsys = 'eeglab';
%     cfg = [];
%     cfg.elec = data.elec;   
%     layout = ft_prepare_layout(cfg);
    
    % prepare channel neighbours
    cfg = [];
    cfg.method = 'triangulation';
    cfg.channel = data.label;
    cfg.elec = data.elec;
    neighbours = ft_prepare_neighbours(cfg);
    
    cond = ["occluded", "occluder"];
    for i=1:2
        % set classifier
        if numel(unique(task(:, i))) == 2
            classifier = 'lda';
        else
            classifier = 'multiclass_lda';
        end

        % across time
        cfg = [];
        cfg.method = 'mvpa';
        cfg.features = 'chan';
        cfg.mvpa.classifier = classifier;
        cfg.mvpa.metric = 'none';
        cfg.mvpa.k = 10;
        cfg.design = task(:, i);
        cfg.timwin = 13;
        % cfg.channel = ft_channelselection({'FP*', 'AFp*'}, data);
        stat = ft_timelockstatistics(cfg, data);

        save(['../data/result/mvpa/representation/', subject, '_', ...
            char(cond(i)), '_when.mat'], 'stat');
%         mv_plot_result(stat.mvpa, stat.time);
%    title([subject, '_', char(cond_list(cond))], 'FontWeight','normal');
%     
        % across channel
        cfg = [];
        cfg.method = 'mvpa';
        cfg.latency = [0.1, 0.3];
        cfg.avgovertime = 'yes';
        cfg.features = 'time';
        cfg.mvpa.classifier = classifier;
        cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
        cfg.mvpa.k = 10;
        cfg.design = task(:, i);
        cfg.neighbours  = neighbours;
        stat = ft_timelockstatistics(cfg, data);
  
        save(['../data/result/mvpa/representation/', subject, '_', ...
            char(cond(i)), '_where.mat'], 'stat');
%    cfg = [];
%    cfg.parameter = 'kappa';
%    cfg.layout = layout;
%    cfg.colorbar = 'yes';
%    cfg.marker = 'labels';
%    ft_topoplotER(cfg, stat);
%    title([subject, '_', char(cond_list(cond))], 'FontWeight','normal');
%    savefig(['../data/result/mvpa/subject/', subject, '_', ...
%        char(cond_list(cond)), '_where.fig']);
    
        % time*time
        cfg = [] ;  
        cfg.method = 'mvpa';
        cfg.mvpa.classifier = classifier;
        cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
        cfg.mvpa.k = 10;
        cfg.features = 'chan';
        cfg.generalize = 'time';
        cfg.design = task(:, i);
        cfg.timwin = 13;
        stat = ft_timelockstatistics(cfg, data);

        save(['../data/result/mvpa/representation/', subject, '_', ...
             char(cond(i)), '_time.mat'], 'stat');
% %    mv_plot_result(stat.mvpa, stat.time, stat.time);
%    savefig(['../data/result/mvpa/subject/', subject, '_', ...
%        char(cond_list(cond)), '_time.fig']);
    end
end