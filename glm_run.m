function glm_run()
% glm_run fits a Generalized mixed-effect model of amplitude = 1 + isFace 
% + identity + meaningfulness + type + location + (1 | subject number) over
% each time point and channel of dataset. labeling is described in mvpa_run
% function.
%
% Written by Nastaran Darjani 
% Developed in MATLAB R2017a
% see also: mvpa_run

%     tbl = zeros([2865*11, 5+1]);
%     channel = zeros([126, 206, 2865*11]);
%     for sub=1:11
%         fprintf(['\nloading subject: ', num2str(sub)]);
%         label_mat = load(['../data/label/sub', num2str(sub), '.mat']);
%         label_mat = label_mat.imageseq;
%         task = nan(2865, 5);
%     
%         label_mat = split(label_mat, '.');
%         label_mat = cellstr(label_mat(:, 1));
%         label_mat = cellfun(@(x)strsplit(x, '_'), label_mat, 'UniformOutput', ...
%             false);
%         label = cellfun(@(v)v(1:4), label_mat, 'UniformOutput', false);
%         label = vertcat(label{:});
%         label = string(label);
%         for i=1:2865
%             if strcmp(label(i, 3), 'n')
%                 if ~strcmp(label(i, 4), '1')
%                     task(i, 3) = 1;
%                 else
%                     task(i, 3) = 0;
%                 end
%             else
%                 task(i, 3) = 2;
%             end
%             if strcmp(label(i, 3), 'location')
%                 task(i, 5) = str2double(label(i, 4));
%                 task(i, 4) = find(strcmp(["pixel"; "phase"; "texture"], ...
%                     string(label_mat{i}(5))));
%             end
%             if strcmp(label(i, 1), 'ix')
%                 task(i, 1) = 0;
%                 task(i, 4) =  find(strcmp(["pixel"; "phase"; "scramble"], ...
%                     string(label(i, 3))));
%             else
%                 task(i, 1) = 1;
%                 if ~strcmp(label(i, 2), '16')
%                     if strcmp(label(i, 1), 'id')
%                         task(i, 2) = str2double(label(i, 2)) - 1;
%                     elseif strcmp(label(i, 1), 'ir')
%                         task(i, 2) = str2double(label(i, 2)) - 6;
%                     end
%                 end
%             end
%         end
%         % replace NaN with zero
%         task(isnan(task)) = 0;
%         
%         tbl(2865*(sub-1)+1:2865*sub, :) = [task, ones([2865, 1])*sub];
%         
%         data = load(['../data/preprocessed/downsampled_data/sub', ...
%             num2str(sub), '.mat']);
%         data = data.data;
%         channel( :, :, 2865*(sub-1)+1:2865*sub) = ...
%             reshape(horzcat(data.trial{:}), [126, 206, 2865]);
%     end
    tbl = nan([1620*11, 2+1]);
    channel = nan([126, 206, 1620*11]);
    for sub=1:11
        fprintf(['\nloading subject: ', num2str(sub)]);
        label_mat = load(['../data/label/sub', num2str(sub), '.mat']);
        label_mat = label_mat.imageseq;

        % task(:, 1) = occluded representation
        % task(:, 2) = occluder representation
        task = nan(2865, 2);

        label_mat = split(label_mat, '.');
        label_mat = cellstr(label_mat(:, 1));
        label_mat = cellfun(@(x)strsplit(x, '_'), label_mat, ...
            'UniformOutput', false);
        label = cellfun(@(v)v(1:4), label_mat, 'UniformOutput', false);
        label = vertcat(label{:});
        label = string(label);
        for i=1:2865
            if strcmp(label(i, 1), 'id')
                if ~strcmp(label(i, 3), 'n')
                    task(i, 1) = str2double(label(i, 2)) - 1;
                    task(i, 2) = find(strcmp(["pixel"; "phase"; ...
                        "texture"], string(label_mat{i}(5))));
                end
            end
        end
        data = load(['../data/preprocessed/downsampled_data/sub', ...
            num2str(sub), '.mat']);
        data = data.data;
        
        % delete NaN labels
        cfg = [];
        cfg.trials = ~isnan(task(:, 1)');
        data = ft_selectdata(cfg, data);
        task(isnan(task(:, 1)), :) = [];
        
        tbl(1620*(sub-1)+1:1620*sub, :) = [task, ones([1620, 1])*sub];
        
        channel( :, :, 1620*(sub-1)+1:1620*sub) = ...
            reshape(horzcat(data.trial{:}), [126, 206, 1620]);
    end
    
    tbl = array2table(tbl);
    clear task label_mat data;
    for ch = 1:126
        glme = cell(206, 1);
        fprintf(['\ncalculating glme for channel: ', num2str(ch)]);
        for timepoint = 1:206
            dm = [array2table(squeeze(channel(ch, timepoint, :))) tbl];
            glme{timepoint} = fitglme(dm, ...
                'Var1~1+tbl1+tbl2+(1|tbl3)');
                %'Var1~1+tbl1+tbl2+tbl3+tbl4+tbl5+(1|tbl6)');
        end
        save(['../data/result/glm/glm', num2str(ch) ,'.mat'], 'glme', ...
            '-v7.3');
    end
end