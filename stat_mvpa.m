function stat_mvpa(path)
% stat_mvpa applies group-wise statistics over mvpa_run results.
% permutation test (n = 1000) with wilcoxon test (alpha = 0.05) over kappa
% and accuracy results of time decoding and channel decoding calculated.
% bonferroni correction applies to avoid multiple comparison problem. plots
% with bold significant line saves.
%
% Null hypothesis in accuracy is 100/numberOfClasses and in kappa is 0.
%
% Written by Nastaran Darjani
% Developed in MATLAB R2017a

    startup_MVPA_Light
    
    cond_list = ["occluded", "occluder"]; 
    %["isFace", "identity", "meaningfulness", "type", "location"];
    for cond = 1:length(cond_list)
        close all;
        % load data as cell-array
        results = cell(11, 1);
        for sub = 1:11
            data = load([path, 'sub', num2str(sub), '_', ...
                char(cond_list(cond)), '_when.mat']);
            data = data.stat;
            results{sub} = data.mvpa;
        end
        
        res = mv_select_result(results, 'kappa');
        result_average = mv_combine_results(res, 'average');
        
        cfg = [];
        cfg.metric = 'kappa';
        cfg.test = 'permutation';
        cfg.correctm = 'cluster';	% 'bonferroni'
        cfg.n_permutations = 1000;
        cfg.alpha = 0.05;
        cfg.design = 'within';
        cfg.clustercritval  = 1.96;
        % t-test assumes that the data is normally distributed, which might
        % not be true for AUC. The Wilcoxon signrank test does not make such 
        % assumptions so could be preferred in this situation.
        cfg.statistic = 'wilcoxon';
        cfg.null = 0; % random classifier
        stat = mv_statistics(cfg, res);
        mv_plot_result(result_average, data.time, 'mask', stat.mask(1,:));
   
        res = mv_select_result(results, 'accuracy');
        result_average = mv_combine_results(res, 'average');
        
        cfg = [];
        cfg.metric = 'accuracy';
        cfg.test = 'permutation';
        cfg.correctm = 'cluster';
        cfg.n_permutations = 1000;
        cfg.alpha = 0.05;
        cfg.design = 'within';
        cfg.statistic = 'wilcoxon';
        cfg.clustercritval  = 1.96;
        cfg.null = (1 / data.mvpa.n_classes); % random classifier
        stat = mv_statistics(cfg, res);
        mv_plot_result(result_average, data.time, 'mask', stat.mask(1, :));
        
        figHandles = findall(0,'Type','figure');
        savefig(figHandles(2), [path, char(cond_list(cond)), ...
            '_when_acc.fig']);
        saveas(figHandles(2), [path, char(cond_list(cond)), ...
            '_when_acc.jpg']);
        savefig(figHandles(1), [path, char(cond_list(cond)), ...
            '_when_kappa.fig']);
        saveas(figHandles(1), [path, char(cond_list(cond)), ...
            '_when_kappa.jpg']);
    end
    
    
    for cond = 1:length(cond_list)
        close all;
        
        results = cell(11, 1);
        for sub = 1:11
            data = load([path, 'sub', num2str(sub), '_', ...
                char(cond_list(cond)), '_where.mat']);
            data = data.stat;
            results{sub} = data.mvpa;
        end
        data.elec.coordsys = 'eeglab';
        cfg = [];
        cfg.elec = data.elec;   
        layout = ft_prepare_layout(cfg);
        
        res = mv_select_result(results, 'kappa');
        result_average = mv_combine_results(res, 'average');
        
        cfg = [];
        cfg.metric = 'kappa';
        cfg.test = 'permutation';
        cfg.correctm = 'bonferroni';	% 'bonferroni'
        cfg.n_permutations = 1000;
        cfg.alpha = 0.05;
        cfg.design = 'within';
        cfg.statistic = 'wilcoxon';
        cfg.null = 0; % random classifier
        stat = mv_statistics(cfg, res);
        cfg = [];
        cfg.parameter = 'kappa';
        cfg.layout = layout;
        cfg.colorbar = 'yes';
        cfg.highlight = 'labels';
        cfg.highlightchannel = find(stat.mask(1, :));
        data.kappa = result_average.perf{1};
        ft_topoplotER(cfg, data);
        
        res = mv_select_result(results, 'accuracy');
        result_average = mv_combine_results(res, 'average');

        cfg = [];
        cfg.metric = 'accuracy';
        cfg.test = 'permutation';
        cfg.correctm = 'bonferroni';
        cfg.n_permutations = 1000;
        cfg.alpha = 0.05;
        cfg.design = 'within';
        cfg.statistic = 'wilcoxon';
        cfg.null = (1 / data.mvpa.n_classes); % random classifier
        stat = mv_statistics(cfg, res);

        cfg = [];
        cfg.parameter = 'accuracy';
        cfg.layout = layout;
        cfg.colorbar = 'yes';
        cfg.highlight = 'labels';
        cfg.highlightchannel = find(stat.mask(1, :));
        data.accuracy = result_average.perf{1};
        ft_topoplotER(cfg, data);
        
        figHandles = findall(0,'Type','figure');
        savefig(figHandles(2), [path, char(cond_list(cond)), ...
            '_where_acc.fig']);
        saveas(figHandles(2), [path, char(cond_list(cond)), ...
            '_where_acc.jpg']);
        savefig(figHandles(1), [path, char(cond_list(cond)), ...
            '_where_kappa.fig']);
        saveas(figHandles(1), [path, char(cond_list(cond)), ...
            '_where_kappa.jpg']);
    end
    
    for cond = 1:length(cond_list)
        close all;
        % load data as cell-array
        results = cell(11, 1);
        for sub = 1:11
            data = load([path, 'sub', num2str(sub), '_', ...
                char(cond_list(cond)), '_time.mat']);
            data = data.stat;
            results{sub} = data.mvpa;
        end
        
        res = mv_select_result(results, 'kappa');
        result_average = mv_combine_results(res, 'average');
        
        cfg = [];
        cfg.metric = 'kappa';
        cfg.test = 'permutation';
        cfg.correctm = 'cluster';	% 'bonferroni'
        cfg.n_permutations = 1000;
        cfg.alpha = 0.05;
        cfg.design = 'within';
        cfg.statistic = 'wilcoxon';
        cfg.clustercritval = 1.96;
        cfg.null = 0; % random classifier
        stat = mv_statistics(cfg, res);
        mv_plot_result(result_average, data.time, data.time);
        B = bwboundaries(stat.mask);
        hold on
        for k = 1:length(B)
            boundary = B{k} ./ 256 - 0.206;
            plot(boundary(:,2), boundary(:,1), 'k', 'linewidth', 1)
        end
        hold off
        
        res = mv_select_result(results, 'accuracy');
        result_average = mv_combine_results(res, 'average');
        
        cfg = [];
        cfg.metric = 'accuracy';
        cfg.test = 'permutation';
        cfg.correctm = 'cluster';
        cfg.n_permutations = 1000;
        cfg.alpha = 0.05;
        cfg.design = 'within';
        cfg.statistic = 'wilcoxon';
        cfg.clustercritval  = 1.96;
        cfg.null = (1 / data.mvpa.n_classes); % random classifier
        stat = mv_statistics(cfg, res);
        mv_plot_result(result_average, data.time, data.time);
        B = bwboundaries(stat.mask);
        hold on
        for k = 1:length(B)
            boundary = B{k} ./ 256 - 0.2004;
            plot(boundary(:,2), boundary(:,1), 'k', 'linewidth', 1)
        end
        hold off
        
        figHandles = findall(0,'Type','figure');
        savefig(figHandles(2), [path, char(cond_list(cond)), ...
            '_time_acc.fig']);
        saveas(figHandles(2), [path, char(cond_list(cond)), ...
            '_time_acc.jpg']);
        savefig(figHandles(1), [path, char(cond_list(cond)), ...
            '_time_kappa.fig']);
        saveas(figHandles(1), [path, char(cond_list(cond)), ...
            '_time_kappa.jpg']);
    end
end