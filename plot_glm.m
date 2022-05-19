% tstat = zeros([126, 3, 206]);
% p_value = zeros([126, 3, 206]);
% for ch = 1:126
%     fprintf(['loading data: ', num2str(ch), '\n']);
%     glm = load(['../data/result/glm/glm', num2str(ch), '.mat']);
%     glm = glm.glme;
%     tstatCh = cellfun(@(x)x.Coefficients.tStat,glm,'UniformOutput',false);
%     tstat(ch, :, :) = horzcat(tstatCh{:});
%     p_valueC=cellfun(@(x)x.Coefficients.pValue,glm,'UniformOutput',false);
%     p_value(ch, :, :) = horzcat(p_valueC{:});
% end
% save('../data/result/glm/tstat_p_value.mat', 'tstat', 'p_value');

% amplitude = 1 + isFace + identity + meaningfulness + type + location
%               + (1 | subject number)
load('../data/result/glm/tstat_p_value.mat');
load('../data/result/mvpa/subject/sub1_identity_time.mat');

for i=1:3
    tstat(:, i, :) = CDF_(tstat(:, i, :));
end

[~, ind] = sort(stat.elec.chanpos(:, 1), 'descend');


% cond = ["constant", "isFace", "identity", "meaningfulness", "type", ...
%         "location"];
cond = ["constant", "occluded", "occluder"];
for i=1:length(cond)
    imagesc(squeeze(tstat(ind, i, :)), [0, 1]);
    % bonferroni correction
    pc = squeeze(p_value(ind, i, :) * numel(p_value(ind, i, :)));

    B = bwboundaries(pc <= 0.05);
    hold on
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:,2), boundary(:,1), 'k', 'linewidth', 1);
    end
    xticks(1:25.6:206);
    yticks(1:length(label));
    yticklabels(label);
    xticklabels(-0.2:0.1:0.6);
    plot(gca, [52, 52], ylim(gca), '--k');
    colorbar;
    set(gca, 'YGrid', 'off', 'XGrid', 'on');
    title(char(cond(i)));
    hold off
    ytickangle(90)
    saveas(gcf, ['../data/result/glm/', char(cond(i)), '.jpg']);
end