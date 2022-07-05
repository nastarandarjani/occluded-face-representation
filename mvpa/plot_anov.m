% fstat = zeros([126, 3, 206]);
% p_value = zeros([126, 3, 206]);
% for ch = 1:126
%     fprintf(['loading data: ', num2str(ch), '\n']);
%     load(['../data/result/anov/', num2str(ch), '.mat']);
%     fstatCh = cellfun(@(x)cell2mat(x(2:4, 6)),anov, 'UniformOutput',false);
%     fstat(ch, :, :) = horzcat(fstatCh{:});
%     p_value(ch, :, :) = horzcat(p{:});
% end
% save('../data/result/anov/fstat_p_value.mat', 'fstat', 'p_value');

% amplitude = 1 + isFace + identity + meaningfulness + type + location
%               + (1 | subject number)
load('../data/result/anov/fstat_p_value.mat');
load('../data/preprocessed/mvpa_preprocessing/ica/sub1.mat');

for i=1:3
    fstat(:, i, :) = CDF_(fstat(:, i, :));
end

label = data.elec.label;

ind = 1:62;

% cond = ["constant", "isFace", "identity", "meaningfulness", "type", ...
%         "location"];
cond = ["occluded", "occluder", "subject"];
for i=1:length(cond)
    imagesc(squeeze(fstat(ind, i, :)), [0, 1]);
    % bonferroni correction
    pc = squeeze(p_value(ind, i, :) * length(ind));

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
    saveas(gcf, ['../data/result/anov/', char(cond(i)), '.jpg']);
end
