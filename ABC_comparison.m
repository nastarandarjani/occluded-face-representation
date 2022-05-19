function ABC_comparison(C, S1, S2)
% ABC_comparison computes channel-wise decoding and plots decodings ...
% topoplots 
% 

    startup_MVPA_Light
    cond = ["occluded", "occluder"];

    % for c = 1: 86-118, 157-168
    % for c = 2: 88-110, 120-142

    name = ['D', 'E', 'F'; ...
            'A', 'B', 'C'];

    range = [86, 118, 157, 168; ...
             88, 110, 120, 142];
    for sub=1:11
        subject = ['sub', num2str(sub)];
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
        label_mat = cellfun(@(x)strsplit(x, '_'), label_mat, 'UniformOutput',...
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

        % prepare channel neighbours
        cfg = [];
        cfg.method = 'triangulation';
        cfg.channel = data.label;
        cfg.elec = data.elec;
        neighbours = ft_prepare_neighbours(cfg);

        for C = 1:2    
            if numel(unique(task(:, C))) == 2
                classifier = 'lda';
            else
                classifier = 'multiclass_lda';
            end

            for S = 1:3
                cfg = [];
                cfg.method = 'mvpa';
                cfg.latency = [data.time{1}(range(C, S)), ...
                               data.time{1}(range(C, S+1))];
                cfg.avgovertime = 'yes';
                cfg.features = 'time';
                cfg.mvpa.classifier = classifier;
                cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
                cfg.mvpa.k = 10;
                cfg.design = task(:, C);
                cfg.neighbours  = neighbours;
                stat = ft_timelockstatistics(cfg, data);

                save(['../data/result/mvpa/representation/ABC/', subject, ...
                    '_', char(cond(C)), name(C, S),'_where.mat'], 'stat');
            end
        end
    end

    close all;
    % load data as cell-array
    g1 = cell(11, 1);
    g2 = cell(11, 1);
    for sub = 1:11
        data = load(['../data/result/mvpa/representation/ABC/sub', ...
            num2str(sub), '_', char(cond(C)), name(C, S1), '_where.mat']);
        data = data.stat;
        g1{sub} = data.mvpa;
        data = load(['../data/result/mvpa/representation/ABC/sub', ...
            num2str(sub), '_', char(cond(C)), name(C, S2), '_where.mat']);
        data = data.stat;
        g2{sub} = data.mvpa;
    end

    val1 = mv_combine_results(g1, 'average');
    val1 = mv_select_result(val1, 'kappa');
    val1.name = name(C, S1);

    val2 = mv_combine_results(g2, 'average');
    val2 = mv_select_result(val2, 'kappa');
    val2.name = name(C, S2);
    % combine = mv_combine_results({occluded, occluder}, 'merge');
    combine = val1;
    combine.perf = val1.perf - val2.perf;

    cfg = [];
    cfg.metric = 'kappa';
    cfg.test = 'permutation';
    cfg.correctm = 'bonferroni';
    cfg.n_permutations = 1000;
    cfg.statistic = 'wilcoxon';
    cfg.null = 0;
    cfg.design = 'between';
    all_results = [g1; g2];
    cfg.group = [ones(11,1); 2*ones(11,1)];
    stat = mv_statistics(cfg, all_results);

    data.elec.coordsys = 'eeglab';
    cfg = [];
    cfg.elec = data.elec;   
    layout = ft_prepare_layout(cfg);

    cfg = [];
    cfg.parameter = 'kappa';
    cfg.layout = layout;
    cfg.colorbar = 'yes';
    cfg.highlight = 'labels';
    cfg.highlightchannel = find(stat.mask);
    data.kappa = combine.perf;
    ft_topoplotER(cfg, data);
    
    saveas(gcf, ['../data/result/mvpa/representation/ABC/', ...
            char(cond(C)), name(C, S1), name(C, S2), '.jpg']);
end