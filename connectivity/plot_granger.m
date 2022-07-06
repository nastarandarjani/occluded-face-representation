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
    
    % replace negative value with zero
    f1(f1 < 0) = 0;
    f2(f2 < 0) = 0;
    fb(fb < 0) = 0;
    
    % compute p-value based on signrank
    p1 = nan(21, 21);
    p2 = nan(21, 21);
    pb = nan(21, 21);
    for i=1:21
        for j=1:21
            if i==j
                continue;
            end
            p1(i, j) = signrank(f1(:, i, j));
            p2(i, j) = signrank(f2(:, i, j));
            pb(i, j) = signrank(fb(:, i, j));
        end
    end
    % apply FDR correction
    p1 = FDR_(p1);
    p2 = FDR_(p2);
    pb = FDR_(pb);
    
    % average granger casaulity value
    f1 = squeeze(mean(f1, 1));
    f2 = squeeze(mean(f2, 1));
    fb = squeeze(mean(fb, 1));
    
    % set non-significant connections to zero
    f1 = (p1 <= 0.05) .* f1;
    fb = (pb <= 0.05) .* fb;
    f2 = (p2 <= 0.05) .* f2;
    
    figure;
    subplot(1, 3, 2);
    plot_pw(f1, parula);
    yticklabels(chnl);
    xticklabels(chnl);
    xtickangle(90);
    title('first peak connections');
    caxis([0, max([f1(:); f2(:); fb(:)])]);
    colorbar;
    
    subplot(1, 3, 3);
    plot_pw(f2, parula);
    yticklabels(chnl);
    xticklabels(chnl);
    xtickangle(90);
    title('second peak connections');
    caxis([0, max([f1(:); f2(:); fb(:)])]);
    colorbar;
    
    subplot(1, 3, 1);
    plot_pw(fb, parula);
    yticklabels(chnl);
    xticklabels(chnl);
    xtickangle(90);
    title('baseline connections');
    caxis([0, max([f1(:); f2(:); fb(:)])]);
    colorbar;
    
    topoplotFC_(f1 - fb, chnl);
    title('normalised first peak connections')
    topoplotFC_(f2 - fb, chnl);
    title('normalised second peak connections')
%     topoplotFC_(fb, chnl);
       
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
    
    idx = logical(eye(size(merged_f1)));
    merged_f1(idx) = nan;
    merged_f2(idx) = nan;
    merged_fb(idx) = nan;
    
    figure;
    subplot(1, 3, 2)
    plot_pw(merged_f1, parula)
    colorbar
    caxis([0, max([merged_f1(:); merged_f2(:); merged_fb(:)])])
    title('first peak region connections')
    subplot(1, 3, 3)
    plot_pw(merged_f2, parula)
    colorbar
    caxis([0, max([merged_f1(:); merged_f2(:); merged_fb(:)])])
    title('second peak region connections')
    subplot(1, 3, 1)
    plot_pw(merged_fb, parula)
    colorbar
    caxis([0, max([merged_f1(:); merged_f2(:); merged_fb(:)])])
    title('baseline region connections')
        
    norm_f1 = merged_f1-merged_fb;
    norm_f2 = merged_f2-merged_fb;
    figure;
    subplot(1, 2, 1)
    imagesc(norm_f1);
    caxis([min([norm_f1(:); norm_f2(:)]), max([norm_f1(:); norm_f2(:)])]);
    title('normalized first peak region connections');
    axis('square');
    colorbar
    subplot(1, 2, 2)
    imagesc(norm_f2);
    caxis([min([norm_f1(:); norm_f2(:)]), max([norm_f1(:); norm_f2(:)])]);
    title('normalized second peak region connections');
    axis('square');
    colorbar
end