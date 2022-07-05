function stat_mvpa(path, analyse, isNormalize, region)



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
    
    %cond_list = ["occluded", "occluder"];
    cond_list = ["v1", "v2", "v4"];
    %["isFace", "identity", "meaningfulness", "type", "location"];
    
    startup_MVPA_Light
    
    model = load(['../data/preprocessed/downsampled_data/sub1.mat']);
    model = model.data;
    model = rmfield(model, 'trial');
    model.time = 0.2;
    
    if ~ strcmp(region, "")
    	region = string(['_', char(region)]);
    end        
    
    for cond = 1:length(cond_list)
        close all;
        
        if strcmp(analyse, 'when') || strcmp(analyse, 'all')
            % load data as cell-array
            results = cell(11, 1);
            for sub = 1:11
                data = load([path, 'sub', num2str(sub), '_', ...
                    char(cond_list(cond)), '_when', char(region), '.mat']);
                results{sub} = data.res;
            end
            time = data.time;
        
            res = mv_select_result(results, 'kappa');
            result_average = mv_combine_results(res, 'average');
            result_average.perf_std = result_average.perf_std{1}/sqrt(11);

            cfg = [];
            cfg.metric = 'kappa';
            cfg.test = 'permutation';
            cfg.correctm = 'cluster';	% 'bonferroni'
            cfg.n_permutations = 1000;
            cfg.alpha = 0.05;
            cfg.design = 'within';
            cfg.clustercritval  = 1.96;
            cfg.statistic = 'wilcoxon';
            cfg.null = 0; 
            stat = mv_statistics(cfg, res);
            mv_plot_result(result_average, time, 'mask', stat.mask(1,:));
   
            res = mv_select_result(results, 'accuracy');
            result_average = mv_combine_results(res, 'average');
            result_average.perf_std = result_average.perf_std{1}/sqrt(11);
        
            cfg = [];
            cfg.metric = 'accuracy';
            cfg.test = 'permutation';
            cfg.correctm = 'cluster';
            cfg.n_permutations = 1000;
            cfg.alpha = 0.05;
            cfg.design = 'within';
            cfg.statistic = 'wilcoxon';
            cfg.clustercritval  = 1.96;
            cfg.null = (1 / data.res.n_classes); % random classifier
            stat = mv_statistics(cfg, res);
            mv_plot_result(result_average, time, 'mask', stat.mask(1, :));
        
            figHandles = findall(0,'Type','figure');
            saveas(figHandles(1), [path, char(cond_list(cond)), ...
                '_when_acc', char(region), '.jpg']);
            saveas(figHandles(2), [path, char(cond_list(cond)), ...
                '_when_kappa', char(region), '.jpg']);
        end
    end
    
    
    for cond = 1:length(cond_list)
        close all;

        if strcmp(analyse, 'where') || strcmp(analyse, 'all')
            if strcmp(region, '')
                results = cell(11, 1);
                for sub = 1:11
                    data = load([path, 'sub', num2str(sub), '_', ...
                        char(cond_list(cond)), '_where', char(region),...
                        '.mat']);
                    results{sub} = data.res;
                end
                
                model.elec.coordsys = 'eeglab';
                cfg = [];
                cfg.elec = model.elec;   
                layout = ft_prepare_layout(cfg);

                res = mv_select_result(results, 'kappa');
                result_average = mv_combine_results(res, 'average');
                result_average.perf_std = ...
                    result_average.perf_std{1}/sqrt(11);

                cfg = [];
                cfg.metric = 'kappa';
                cfg.test = 'permutation';
                cfg.correctm = 'bonferroni';	
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
                if (isNormalize)
                    model.kappa = CDF_(result_average.perf{1});
                else
                    model.kappa = result_average.perf{1};
                end
                ft_topoplotER(cfg, model);

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
                cfg.null = (1 / data.res.n_classes); % random classifier
                stat = mv_statistics(cfg, res);

                cfg = [];
                cfg.parameter = 'accuracy';
                cfg.layout = layout;
                cfg.colorbar = 'yes';
                cfg.highlight = 'labels';
                cfg.highlightchannel = find(stat.mask(1, :));
                if (isNormalize)
                    model.accuracy = CDF_(result_average.perf{1});
                else
                    model.accuracy = result_average.perf{1};
                end
                ft_topoplotER(cfg, model);

                figHandles = findall(0,'Type','figure');
                saveas(figHandles(1), [path, char(cond_list(cond)), ...
                    '_where_acc', char(region), '.jpg']);
                saveas(figHandles(2), [path, char(cond_list(cond)), ...
                    '_where_kappa', char(region), '.jpg']);

            else
                fprintf('topoplot is not available with region.\n');
            end
        end
    end
    
    for cond = 1:length(cond_list)
        close all;
        
        if strcmp(analyse, 'time') || strcmp(analyse, 'all')
            results = cell(11, 1);
            for sub = 1:11
                data = load([path, 'sub', num2str(sub), '_', ...
                    char(cond_list(cond)), '_time', char(region), '.mat']);
                results{sub} = data.res;
            end
            time = data.time;

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
            if (isNormalize)
                result_average.perf = CDF_(result_average.perf{1});
            else
                result_average.perf = result_average.perf{1};
            end
            mv_plot_result(result_average, time, time);
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
            cfg.null = (1 / data.res.n_classes); % random classifier
            stat = mv_statistics(cfg, res);
            if (isNormalize)
                result_average.perf = CDF_(result_average.perf{1});
            else
                result_average.perf = result_average.perf{1};
            end
            mv_plot_result(result_average, time, time);
            B = bwboundaries(stat.mask);
            hold on
            for k = 1:length(B)
                boundary = B{k} ./ 256 - 0.2004;
                plot(boundary(:,2), boundary(:,1), 'k', 'linewidth', 1)
            end
            hold off

            figHandles = findall(0,'Type','figure');
            saveas(figHandles(1), [path, char(cond_list(cond)), ...
                '_time_acc', char(region), '.jpg']);
            saveas(figHandles(2), [path, char(cond_list(cond)), ...
                '_time_kappa', char(region), '.jpg']);
        end
    end
end
