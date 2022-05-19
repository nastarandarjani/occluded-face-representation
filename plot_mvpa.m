function plot_mvpa()
% plot_mvpa plots and saves .mat files from mvpa_run function in path.
% path = '../data/result/mvpa/subject/plot/'
% path = '../data/result/mvpa/representation/plot/'
%
% Written by Nastaran Darjani 
% Developed in MATLAB R2017a
% 
    close all;
    startup_MVPA_Light
    
    
    path = '../data/result/mvpa/subject/plot/';

    dirinf = dir('../data/result/mvpa/subject/sub*.mat');
    nfiles = length(dirinf);
    for n=1:nfiles
        infile = dirinf(n).name;
        load(['../data/result/mvpa/subject/', infile]);
        SP = split(infile, '_');
        switch SP{3}(1:end-4)
            case 'when'
                mv_plot_result(stat.mvpa, stat.time);
                figHandles = findall(0,'Type','figure');
%                 set(gca, 'YTick', 1:2:length(stat.label), 'YTickLabel', ...
%                 stat.label(1:2:end));
                savefig(figHandles(1), [path, infile(1:end-4), '_acc.fig']);
                saveas(figHandles(1), [path, infile(1:end-4), '_acc.jpg']);
                savefig(figHandles(2), [path, infile(1:end-4), '_f1.fig']);
                saveas(figHandles(2), [path, infile(1:end-4), '_f1.jpg']);
                savefig(figHandles(3), [path, infile(1:end-4), '_kappa.fig']);
                saveas(figHandles(3), [path, infile(1:end-4), '_kappa.jpg']);
                close all;
            case 'both'
                mv_plot_result(stat.mvpa, stat.time);
                figHandles = findall(0,'Type','figure');
%                 set(gca, 'YTick', 1:2:length(stat.label), 'YTickLabel', ...
%                 stat.label(1:2:end));
                savefig(figHandles(1), [path, infile(1:end-4), '_acc.fig']);
                saveas(figHandles(1), [path, infile(1:end-4), '_acc.jpg']);
                savefig(figHandles(2), [path, infile(1:end-4), '_f1.fig']);
                saveas(figHandles(2), [path, infile(1:end-4), '_f1.jpg']);
                savefig(figHandles(3), [path, infile(1:end-4), '_kappa.fig']);
                saveas(figHandles(3), [path, infile(1:end-4), '_kappa.jpg']);
                close all;
            case 'where'
                % prepare layout
                stat.elec.coordsys = 'eeglab';
                cfg = [];
                cfg.elec = stat.elec;   
                layout = ft_prepare_layout(cfg);
                
                cfg = [];
                cfg.parameter = 'kappa';
                cfg.layout = layout;
                cfg.colorbar = 'yes';
                cfg.marker = 'labels';
                ft_topoplotER(cfg, stat);
                cfg.parameter = 'f1';
                ft_topoplotER(cfg, stat);
                cfg.parameter = 'accuracy';
                ft_topoplotER(cfg, stat);
                figHandles = findall(0,'Type','figure');
                savefig(figHandles(1), [path, infile(1:end-4), '_acc.fig']);
                saveas(figHandles(1), [path, infile(1:end-4), '_acc.jpg']);
                savefig(figHandles(2), [path, infile(1:end-4), '_f1.fig']);
                saveas(figHandles(2), [path, infile(1:end-4), '_f1.jpg']);
                savefig(figHandles(3), [path, infile(1:end-4),'_kappa.fig']);
                saveas(figHandles(3), [path, infile(1:end-4), '_kappa.jpg']);
                close all;
            case 'time'
                stat.mvpa.perf(2) = [];
                stat.mvpa.perf_std(2) = [];
                stat.mvpa.n_metrics = 2;
                stat.mvpa.metric(2) = [];
                stat.mvpa.perf_dimension_names(2) = [];
                stat.mvpa.cfg.metric(2) = [];
                stat.mvpa.cfg.dimension_names(2) = [];
                mv_plot_result(stat.mvpa, stat.time, stat.time);
                figHandles = findall(0,'Type','figure');
                savefig(figHandles(1), [path, infile(1:end-4), ...
                    '_acc.fig']);
                saveas(figHandles(1), [path, infile(1:end-4), ...
                    '_acc.jpg']);
                savefig(figHandles(2), [path, infile(1:end-4), ...
                    '_kappa.fig']);
                saveas(figHandles(2), [path, infile(1:end-4), ...
                    '_kappa.jpg']);
                close all;
        end
    end
end
