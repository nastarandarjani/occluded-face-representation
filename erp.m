function erp(path)
    startup_MVPA_Light

    cfg = [];
    sub = 1;

    subject = ['sub', num2str(sub)];
    data = load(['../data/preprocessed/mvpa_preprocessing/ica/', ...
            subject, '.mat']);
    data = data.data;
    label_mat = load(['../data/label/', subject, '.mat']);
    label_mat = label_mat.imageseq;
    img_name = split(label_mat, '.');

    ind_face = zeros(1, 2865);
    ind_nonface = zeros(1, 2865);
    for i=1:2865
        x = split(img_name(i, 1), '_');
        if strcmp(x(1), 'id')
            if strcmp(x(3), 'n')
                if strcmp(x(4), '1')
                    ind_face(i) = 1;
                end
            end
        elseif strcmp(x(1), 'ix')
            ind_nonface(i) = 1;
        end
    end

    cfg.trials = find(ind_face);
    face = ft_selectdata(cfg, data);

    cfg.trials = find(ind_nonface);
    nonface = ft_selectdata(cfg, data);

    ERP_face = ft_timelockanalysis([], face);
    ERP_nonface = ft_timelockanalysis([], nonface);
    time = ERP_face.time;

    ERP_face.elec.coordsys = 'eeglab';
    ERP_nonface.elec.coordsys = 'eeglab';
    cfg = [];
    cfg.xlim = [0.15 0.2];
    cfg.zlim = [-9 6];
    cfg.colorbar = 'yes';
    ft_topoplotER(cfg, ERP_face);
    print('-vector', [path, 'face_topo'], '-depsc');
    ft_topoplotER(cfg, ERP_nonface);
    print('-vector', [path, 'nonface_topo'], '-depsc');

    cfg = [];
    cfg.channel = ft_channelselection({'P8', 'P10', 'PO8'}, data);
    ERP_face = ft_selectdata(cfg, ERP_face);
    ERP_nonface = ft_selectdata(cfg, ERP_nonface);

    x = load( '../data/result/mvpa/representation/ica-zscore/sub1_occluder_when.mat');
    x = x.res;
    x.plot = x.plot(1);
    x.perf = zeros(206, 1);
    x.perf_std = [];
    x.metric = 'microvolt';
    x.n_metrics = 1;
    
    x.perf = mean(ERP_face.avg)';
    y = x;
    y.perf = mean(ERP_nonface.avg)';
    set(groot, 'defaultLineLineWidth', 2);
    mv_plot_result({x, y}, time);
    legend('face', 'nonface');
    pbaspect([3, 1, 1]);
    legend('Location', 'southeast');
    print('-vector', [path, 'nonface_plot'], '-depsc');
end