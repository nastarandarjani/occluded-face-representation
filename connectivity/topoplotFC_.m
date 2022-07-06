function topoplotFC_(F, chnl, percent)
    figure;
    % create layout
    model = load('../data/preprocessed/mvpa_preprocessing/ica/sub1.mat');
    model = model.data;
    model = rmfield(model, 'trial');
    model.elec.coordsys = 'eeglab';
    cfg = [];
    cfg.elec = model.elec;
    layout = ft_prepare_layout(cfg);
    chidx = find(ismember(model.elec.label, chnl));
    subset = [1; 9; 13; 17];
    hold on
    % delete within group connections
    for i=1:21
        for j=1:21
            if (find(i >= subset, 1, 'last') == ...
                    find(j >= subset, 1, 'last'))
                F(i, j) = nan;
            end
        end
    end
    F(isnan(F)) = 0;
    F(F < 0) = 0;
    cm = colormap(flipud(parula(length(unique(round(F(:), 4))))));
    for i = 1:21 % to
        for j = 1:21 % from
            if F(i, j) == 0
                continue;
            end
            target = find(strcmp(layout.label, chnl{i}));
            source = find(strcmp(layout.label, chnl{j}));
            
            quiver(layout.pos(target, 1), layout.pos(target, 2), ...
                layout.pos(source, 1) - layout.pos(target, 1), ...
                layout.pos(source, 2) - layout.pos(target, 2), 0, ...
                'linewidth', 1.5, 'color', ...
                cm(round(F(i, j), 4) == sort(unique(round(F(:), 4))), :));
        end
    end
    ft_plot_layout(layout, 'box', 'no', 'point', 'no', ...
            'pointsymbol', '.', 'pointsize', 10, ...
            'pointcolor', 'k', 'chanindx', chidx, 'labeloffset', 0.01);
    colorbar;
    hold off;
end