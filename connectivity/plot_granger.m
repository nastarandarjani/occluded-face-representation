function plot_granger()
    run('/home/nastaran/MVGC1-1.2/startup.m');

    % load channel names
    load('../data/result/granger/chnl.mat');
    
    f1 = load('../data/result/granger/gr_0.1_0.23.mat', 'fstat');
    f1 = f1.fstat;
    f2 = load('../data/result/granger/gr_0.23_0.4.mat', 'fstat');
    f2 = f2.fstat;    
    fb = load('../data/result/granger/gr_-0.2_0.mat', 'fstat');
    fb = fb.fstat;
    
    figure;
    subplot(1, 3, 1);
    plot_pw(squeeze(mean(f1, 1)));
    yticklabels(chnl);
    xticklabels(chnl);
    xtickangle(90);
    title('first peak');
    caxis([0, 0.0410]);
    colorbar;
    
    subplot(1, 3, 2);
    plot_pw(squeeze(mean(f2, 1)));
    yticklabels(chnl);
    xticklabels(chnl);
    xtickangle(90);
    title('second peak');
    caxis([0, 0.0410]);
    colorbar;
    
    subplot(1, 3, 3);
    plot_pw(squeeze(mean(fb, 1)));
    yticklabels(chnl);
    xticklabels(chnl);
    xtickangle(90);
    title('baseline');
    caxis([0, 0.0410]);
    colorbar;
    
    f1 = squeeze(mean(f1, 1));
    f2 = squeeze(mean(f2, 1));
    fb = squeeze(mean(fb, 1));
    
    merged = [nansum(f1(1:8, :)); nansum(f1(9:12, :)); ...
        nansum(f1(13:16, :)); nansum(f1(17:end, :))];
    merged_f1 = [nansum(merged(:, 1:8), 2), nansum(merged(:, 9:12), 2),...
        nansum(merged(:, 13:16), 2), nansum(merged(:, 17:end), 2)];
    merged = [nansum(f2(1:8, :)); nansum(f2(9:12, :)); ...
        nansum(f2(13:16, :)); nansum(f2(17:end, :))];
    merged_f2 = [nansum(merged(:, 1:8), 2), nansum(merged(:, 9:12), 2),...
        nansum(merged(:, 13:16), 2), nansum(merged(:, 17:end), 2)];
    merged = [nansum(fb(1:8, :)); nansum(fb(9:12, :)); ...
        nansum(fb(13:16, :)); nansum(fb(17:end, :))];
    merged_fb = [nansum(merged(:, 1:8), 2), nansum(merged(:, 9:12), 2),...
        nansum(merged(:, 13:16), 2), nansum(merged(:, 17:end), 2)];
    
    figure;
    subplot(1, 3, 1)
    plot_pw(merged_f1)
    colorbar
    caxis([0, 0.2788])
    subplot(1, 3, 2)
    plot_pw(merged_f2)
    colorbar
    caxis([0, 0.2788])
    subplot(1, 3, 3)
    plot_pw(merged_fb)
    colorbar
    caxis([0, 0.2788])
    
    figure;
    subplot(1, 2, 1)
    plot_pw(merged_f1-merged_fb)
    colorbar
    subplot(1, 2, 2)
    plot_pw(merged_f2-merged_fb)
    colorbar    
end