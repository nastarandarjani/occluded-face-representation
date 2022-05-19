function stat_representation(path, analyse, isNormalize, compare, region)
%
% Written by Nastaran Darjani
% Developed in MATLAB R2017a

    startup_MVPA_Light
    close all;
    
    % sanity check of compare and region arguments
    if strcmp(compare(1), compare(2))
        if strcmp(region(1), region(2))
            fprintf('both groups are the same.\n');
            return;
        end
    else
        if ~strcmp(region(1), region(2))
            fprintf('both region and compare parameters are different.\n');
            return;
        end
    end
    
    % extract saving name file
    if strcmp(compare(1), compare(2))
        save_name = [char(compare(1)), '_', char(region(1)), ...
                    ' vs ', char(region(2))];
        r = ["", ""];
        group = region;
    else
        save_name = [char(compare(1)), ' vs ', char(compare(2))];
        r = strcat(["_", "_"], region);
        group = compare;
    end
            
    % add '_' to not empty elements of region array
    for i=1:2
        if ~ strcmp(region(i), "")
            region(i) = string(['_', char(region(i))]);
        end
    end
        
    if strcmp(analyse, 'when') || strcmp(analyse, 'all')
        % load data as cell-array
        results_occluded = cell(11, 1);
        results_occluder = cell(11, 1);
        for sub = 1:11
            data = load([path, 'sub', num2str(sub), '_', ...
                    char(compare(1)), '_when', char(region(1)),'.mat']);
            data = data.stat;
            results_occluded{sub} = data.mvpa;
            data = load([path, 'sub', num2str(sub),  '_', ...
                char(compare(2)), '_when', char(region(2)),'.mat']);
            data = data.stat;
            results_occluder{sub} = data.mvpa;
        end

        res = mv_select_result(results_occluded, 'kappa');
        occluded = mv_combine_results(res, 'average');
        occluded.name = char(group(1));

        res = mv_select_result(results_occluder, 'kappa');
        occluder = mv_combine_results(res, 'average');
        occluder.name = char(group(2));
        combine = mv_combine_results({occluded, occluder}, 'merge');

        cfg = [];
        cfg.metric = 'kappa';
        cfg.test = 'permutation';
        cfg.correctm = 'cluster';
        cfg.n_permutations = 1000;
        cfg.statistic = 'wilcoxon';
        cfg.null = 0;
        cfg.clustercritval = 1.96;
        cfg.design = 'between';
        all_results = [results_occluded; results_occluder];
        cfg.group = [ones(11,1); 2*ones(11,1)];
        stat = mv_statistics(cfg, all_results);
        mv_plot_result(combine, data.time, 'mask', stat.mask);
        saveas(gcf, [path, save_name, '_when', char(r(1)), '.jpg']);
    end
    
    if (strcmp(analyse, 'where') || strcmp(analyse, 'all')) && ...
        ~any(contains(["_fr", "_temp"], region))
        
        close all;
        % load data as cell-array
        results_occluded = cell(11, 1);
        results_occluder = cell(11, 1);
        for sub = 1:11
            data = load([path, 'sub', num2str(sub),  '_', ...
                char(compare(1)), '_where', char(region(1)),'.mat']);
            data = data.stat;
            results_occluded{sub} = data.mvpa;
            data = load([path, 'sub', num2str(sub),  '_', ...
                char(compare(2)), '_where', char(region(2)),'.mat']);
            data = data.stat;
            results_occluder{sub} = data.mvpa;
        end

        res = mv_select_result(results_occluded, 'kappa');
        occluded = mv_combine_results(res, 'average');
        occluded.name = 'occluded';

        res = mv_select_result(results_occluder, 'kappa');
        occluder = mv_combine_results(res, 'average');
        occluder.name = 'occluder';
        % combine = mv_combine_results({occluded, occluder}, 'merge');
        combine = occluded;
        combine.perf = occluded.perf{1} - occluder.perf{1};

        cfg = [];
        cfg.metric = 'kappa';
        cfg.test = 'permutation';
        cfg.correctm = 'bonferroni';
        cfg.n_permutations = 1000;
        cfg.statistic = 'wilcoxon';
        cfg.null = 0;
        cfg.design = 'between';
        all_results = [results_occluded; results_occluder];
        cfg.group = [ones(11,1); 2*ones(11,1)];
        stat = mv_statistics(cfg, all_results);

        data.elec.coordsys = 'eeglab';
        cfg = [];
        cfg.elec = data.elec;   
        layout = ft_prepare_layout(cfg);
        
        if (isNormalize)
            data.kappa = CDF_(combine.perf);
        else
            data.kappa = combine.perf;
        end

        cfg = [];
        cfg.parameter = 'kappa';
        cfg.layout = layout;
        cfg.colorbar = 'yes';
        cfg.highlight = 'labels';
        cfg.highlightchannel = find(stat.mask);
        ft_topoplotER(cfg, data);
        saveas(gcf, [path, save_name, '_where', char(region(1)), '.jpg']);
    end
        
    if strcmp(analyse, 'time') || strcmp(analyse, 'all')
        
        close all;
        % load data as cell-array
        results_occluded = cell(11, 1);
        results_occluder = cell(11, 1);
        for sub = 1:11
            data = load([path, 'sub', num2str(sub), '_', ...
                char(compare(1)), '_time', char(region(1)),'.mat']);
            data = data.stat;
            results_occluded{sub} = mv_select_result(data.mvpa, 'kappa');
            data = load([path, 'sub', num2str(sub),  '_', ...
                char(compare(2)), '_time', char(region(2)),'.mat']);
            data = data.stat;
            results_occluder{sub}=mv_select_result(data.mvpa, 'kappa');
        end

        occluded = mv_combine_results(results_occluded, 'average');
        occluded.name = char(group(1));

        occluder = mv_combine_results(results_occluder, 'average');
        occluder.name = char(group(2));
        combine = occluded;
        combine.perf = occluded.perf{1} - occluder.perf{1};
        
        if (isNormalize)
            combine.perf = CDF_(combine.perf);
        end

        cfg = [];
        cfg.metric = 'kappa';
        cfg.test = 'permutation';
        cfg.correctm = 'cluster';
        cfg.n_permutations = 1000;
        cfg.statistic = 'wilcoxon';
        cfg.null = 0;
        cfg.clustercritval = 1.96;
        cfg.design = 'between';
        all_results = [results_occluded; results_occluder];
        cfg.group = [ones(11,1); 2*ones(11,1)];
        stat = mv_statistics(cfg, all_results);
        
        h = mv_plot_result(combine, data.time, data.time);
        B = bwboundaries(stat.mask);
        hold on
        for k = 1:length(B)
            boundary = B{k} ./ 256 - 0.2004;
            plot(boundary(:,2), boundary(:,1), 'k', 'linewidth', 1)
        end
        hold off
        saveas(gcf, [path, save_name, '_time', char(r(1)), '.jpg']);
    end
end