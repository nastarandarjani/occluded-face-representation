function mvpa_run(subject, cond)
% mvpa_run uses mvpa_light toolbox from fieldtrip extension to classify
% over time and channels.
% Classifier: multiclass-lda will be chosen For multiclass problems, and 
% simple lda chose for 2-class problems.
% Metric: Cohen's kappa coefficient, f1 score, accuracy
% Cross Validation: 10-fold CV with 5 repetition
% time decoding, channel decoding (with triangulation), channel and time
% decoding and time*time decoding applies and saves in corresponding .mat
% file.
%
% input arguments:
%   - subject: dataset of corresponding subject
%   - cond: 5 type of labeling can be choose to feed classifier (SEE BELOW)
%
% labeling option (cond):
%   1. Whether it is (unoccluded) face or not (either meaningfull or not).
%           x_x_n_1 => 1, (ix_x_x_x) or (ir_16_x_x) => 0
%   2. Whose face it is.
%           id_i_x_x => i-1, ir_i_x_x (except i=16) => i-6
%   3. The occluder in occluded face is meaningfull or not.
%           x_i_n_j (except i=16 or j=1) => 1, x_x_location_x => 0
%   4. type of occluder (either meaningfull or not).
%           x_x_n_i => i-1, id_x_x_x_texture => i+7
%   5. Location of occluder in face.
%           x_x_location_i => i
%
% Written by Nastaran Darjani
% Developed in MATLAB R2017a
% 

    startup_MVPA_Light

    data = load(['../data/preprocessed/downsampled_data/', subject, ...
        '.mat']);
    data = data.data;
    cond_list = ["isFace", "identity", "meaningfulness", "type", ...
        "location"];
    label_mat = load(['../data/label/', subject, '.mat']);
    label_mat = label_mat.imageseq;
    task = map_label(label_mat);
    task = task(:, cond);
    
    % delete NaN labels
    cfg = [];
    cfg.trials = ~isnan(task');
    data = ft_selectdata(cfg, data);
    task(isnan(task)) = [];
    
    % set classifier
    if numel(unique(task)) == 2
        classifier = 'lda';
    else
        classifier = 'multiclass_lda';
    end
    
%    % prepare layout
%    data.elec.coordsys = 'eeglab';
%    cfg = [];
%    cfg.elec = data.elec;   
%    layout = ft_prepare_layout(cfg);

    % across time
    cfg = [] ;  
    cfg.method = 'mvpa';
    cfg.features = 'chan';
    cfg.mvpa.classifier = classifier;
    cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
    cfg.mvpa.k = 10;
    cfg.design = task;
    cfg.timwin = 3;
    stat = ft_timelockstatistics(cfg, data);
    
    save(['../data/result/mvpa/subject/', subject, '_', ...
        char(cond_list(cond)), '_when.mat'], 'stat');
%    mv_plot_result(stat.mvpa, stat.time);
%    title([subject, '_', char(cond_list(cond))], 'FontWeight','normal');
%    savefig(['../data/result/mvpa/subject/', subject, '_', ...
%        char(cond_list(cond)), '_when.fig']);
    
    % across channel
    cfg = [];
    cfg.method = 'triangulation';
    cfg.channel = data.label;
    cfg.elec = data.elec;
    neighbours = ft_prepare_neighbours(cfg);

    cfg = [] ;  
    cfg.method = 'mvpa';
    cfg.latency = [0.1, 0.3];
    cfg.avgovertime = 'yes';
    cfg.features = 'time';
    cfg.mvpa.classifier = classifier;
    cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
    cfg.mvpa.k = 10;
    cfg.design = task;
    cfg.neighbours = neighbours;
    stat = ft_timelockstatistics(cfg, data);
    
    save(['../data/result/mvpa/subject/', subject, '_', ...
        char(cond_list(cond)), '_where.mat'], 'stat');
%    cfg = [];
%    cfg.parameter = 'kappa';
%    cfg.layout = layout;
%    cfg.colorbar = 'yes';
%    cfg.marker = 'labels';
%    ft_topoplotER(cfg, stat);
%    title([subject, '_', char(cond_list(cond))], 'FontWeight','normal');
%    savefig(['../data/result/mvpa/subject/', subject, '_', ...
%        char(cond_list(cond)), '_where.fig']);
    
%     % both
%     cfg = [] ;  
%     cfg.method = 'mvpa';
%     cfg.features = [];
%     cfg.mvpa.classifier = classifier;
%     cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
%     cfg.mvpa.k = 10;
%     cfg.design = task;
%     stat = ft_timelockstatistics(cfg, data);
%     
%     save(['../data/result/mvpa/subject/', subject, '_', ...
%     char(cond_list(cond)), '_both.mat'], 'stat');
%    mv_plot_result(stat.mvpa, stat.time);
%    title([subject, '_', char(cond_list(cond))], 'FontWeight','normal');
%    set(gca, 'YTick', 1:2:length(stat.label), 'YTickLabel', ...
%        stat.label(1:2:end));
%    savefig(['../data/result/mvpa/subject/', subject, '_', ...
%        char(cond_list(cond)), '_both.fig']);
    
    % time*time
    cfg = [] ;  
    cfg.method = 'mvpa';
    cfg.mvpa.classifier = classifier;
    cfg.mvpa.metric = {'kappa', 'f1', 'accuracy'};
    cfg.mvpa.k = 10;
    cfg.features = 'chan';
    cfg.generalize = 'time';
    cfg.design = task;
    stat = ft_timelockstatistics(cfg, data);
    
    save(['../data/result/mvpa/subject/', subject, '_', ...
         char(cond_list(cond)), '_time.mat'], 'stat');
%    mv_plot_result(stat.mvpa, stat.time, stat.time);
%    savefig(['../data/result/mvpa/subject/', subject, '_', ...
%        char(cond_list(cond)), '_time.fig']);
end
