function plv = plot_plv()
       
    load('/home/nastaran/Desktop/data/result/granger/PLV.mat');
    load('/home/nastaran/Desktop/data/result/granger/chnl.mat');
    
    conn = nchoosek(1:21, 2);
    plv = nan(11, 6, length(conn), size(PLV, 5));
    for sub = 1:11
        for freq = 1:6
            disp([sub, freq]);
            for i = 1:length(conn)
                    e = squeeze(exp(1i*(...
                        PLV(sub, freq, :, conn(i, 1), :) - ...
                        PLV(sub, freq, :, conn(i, 2), :))));
                    plv(sub, freq, i, :) = abs(sum(e)) / 1620;
            end
        end
    end
    clear PLV;
    
    % compute p-value based on signrank
    pval = nan(6, 210, 1201);
    for f = 1:6
        for c = 1:210
            disp([f, c])
            for t = 1:1201
                pval(f, c, t) = signrank(plv(:, f, c, t));
            end
        end
    end
    % apply FDR correction
    pval = FDR_(pval);
    plv(:, pval > 0.05) = nan;
    
    % average over subjects
    plv = squeeze(mean(plv, 1));
    
    % remove within group connections    
    subset = [1; 9; 13; 17];
    for i = 1:length(conn)
        if (find(conn(i, 1) >= subset, 1, 'last') == ...
            find(conn(i, 2) >= subset, 1, 'last'))
            conn(i, :) = nan(1, 2);
        end
    end
    plv(:, isnan(conn(:, 1)), :) = [];
    conn(isnan(conn(:, 1)), :) = [];
        
    p = nan(6, 21, 21, 1201);
    for f=1:6
        for i=1:length(conn)
            p(f, conn(i, 1), conn(i, 2), :) = plv(f, i, :);
        end
    end
    plv = p;  
    
    % compute time intervals
    [~, f1_start] = min(abs(time - 0.1));
    [~, f2_start] = min(abs(time - 0.23));
    [~, f2_end] = min(abs(time - 0.4));
    [~, fb_start] = min(abs(time - -0.1));
    [~, fb_end] = min(abs(time - 0.1));
    f1 = mean(plv(:, :, :, f1_start:f2_start), 4);
    f2 = mean(plv(:, :, :, f2_start:f2_end), 4);
    fb = mean(plv(:, :, :, fb_start:fb_end), 4);
    
    for f=1:6
        figure(f);
        subplot(1, 3, 1)
        imagesc(squeeze(fb(f, :, :))');
        colorbar;
        yticklabels(chnl);
        xticklabels(chnl);
        xtickangle(90);
        xticks(1:21);
        yticks(1:21);
        axis('square');
        caxis([0, max([fb(:); f1(:); f2(:)])]);
        title('baseline connections');
        subplot(1, 3, 2)
        imagesc(squeeze(f1(f, :, :))');
        colorbar;
        yticklabels(chnl);
        xticklabels(chnl);
        xtickangle(90);
        xticks(1:21);
        yticks(1:21);
        axis('square');
        caxis([0, max([fb(:); f1(:); f2(:)])]);
        title('first peak connections');
        subplot(1, 3, 3)
        imagesc(squeeze(f2(f, :, :))');
        colorbar;
        yticklabels(chnl);
        xticklabels(chnl);
        xtickangle(90);
        xticks(1:21);
        yticks(1:21);
        axis('square');
        caxis([0, max([fb(:); f1(:); f2(:)])]);
        title('second peak connections');
    end
    
    merged_plv = nan(6, 4, 4, 1201);
    for i = 1:6
        merged = [nanmean(plv(i, 1:8, :, :)); ...
            nanmean(plv(i, 9:12, :, :)); ...
            nanmean(plv(i, 13:16, :, :)); ...
            nanmean(plv(i, 17:end, :, :))];
        merged = squeeze(merged);
        merged_plv(i, :, :, :) = [nanmean(merged(:, 1:8, :), 2), ...
            nanmean(merged(:, 9:12, :), 2),...
            nanmean(merged(:, 13:16, :), 2), ...
            nanmean(merged(:, 17:end, :), 2)];
    end
    merged_f1 = mean(merged_plv(:, :, :, f1_start:f2_start), 4);
    merged_f2 = mean(merged_plv(:, :, :, f2_start:f2_end), 4);
    merged_fb = mean(merged_plv(:, :, :, fb_start:fb_end), 4);
    
    tiledlayout(6, 3, 'Padding', 'none', 'TileSpacing', 'compact'); 
    for f=1:6
        nexttile;
        imagesc(squeeze(merged_fb(f, :, :))');
        colorbar;
        xticks(1:4);
        yticks(1:4);
        axis('square');
        caxis([0, max([squeeze(max(merged_fb(f, :, :))); ...
            squeeze(max(merged_f1(f, :, :))); ...
            squeeze(max(merged_f2(f, :, :)))])]);
        title('baseline region connections');
        nexttile;
        imagesc(squeeze(merged_f1(f, :, :))');
        colorbar;
        xticks(1:4);
        yticks(1:4);
        axis('square');
        caxis([0, max([squeeze(max(merged_fb(f, :, :))); ...
            squeeze(max(merged_f1(f, :, :))); ...
            squeeze(max(merged_f2(f, :, :)))])]);
        title('first peak region connections');
        nexttile;
        imagesc(squeeze(merged_f2(f, :, :))');
        colorbar;
        xticks(1:4);
        yticks(1:4);
        axis('square');
        caxis([0, max([squeeze(max(merged_fb(f, :, :))); ...
            squeeze(max(merged_f1(f, :, :))); ...
            squeeze(max(merged_f2(f, :, :)))])]);
        title('second peak region connections');
    end
    
    for f=1:6
        subplot(2, 3, f)
        imagesc(squeeze(merged_f2(f, :, :) - merged_f1(f, :, :))');
        colorbar;
        xticks(1:4);
        yticks(1:4);
        axis('square');
        caxis([min(min(merged_f2(f, :, :) - merged_f1(f, :, :))),...
            max(max(merged_f2(f, :, :) - merged_f1(f, :, :)))]);
    end
    
    tiledlayout(6, 2, 'Padding', 'none', 'TileSpacing', 'compact'); 
    for f=1:6
        nexttile;
        imagesc(squeeze(merged_f1(f, :, :) - merged_fb(f, :, :))');
        colorbar;
        xticks(1:4);
        yticks(1:4);
        axis('square');
        caxis([min(squeeze(min(...
            merged_f1(f, :, :) - merged_fb(f, :, :)))), ...
            max(squeeze(max(...
            merged_f1(f, :, :) - merged_fb(f, :, :))))]);
        title('first peak region connections');
        nexttile;
        imagesc(squeeze(merged_f2(f, :, :) - merged_fb(f, :, :))');
        colorbar;
        xticks(1:4);
        yticks(1:4);
        axis('square');
        caxis([min(squeeze(min(...
            merged_f1(f, :, :) - merged_fb(f, :, :)))), ...
            max(squeeze(max(...
            merged_f1(f, :, :) - merged_fb(f, :, :))))]);
        title('second peak region connections');
    end
end
