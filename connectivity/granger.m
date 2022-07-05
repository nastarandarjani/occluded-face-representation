function granger(timepoint)
    run('/home/nastaran/MVGC1-1.2/startup.m');
    
    INFO = [];
    order = zeros(11, 1);
    fstat = nan(11, 21, 21);
    for subject = 1:11
        data = load(['../data/preprocessed/FC_preprocessing/sub', ...
                    num2str(subject), '.mat']);
        data = data.data;
        label_mat = load(['../data/label/sub', num2str(subject), '.mat']);
        label_mat = label_mat.imageseq;
        img_name = split(label_mat, '.');

        % labeling trials
        task = nan(2865, 2);
        for i=1:2865
            x = split(img_name(i, 1), '_');
            if strcmp(x(1), 'id')
                if ~strcmp(x(3), 'n')
                    task(i, 1) = str2double(x(2)) - 1;
                    task(i, 2) = find(strcmp(["pixel"; "phase"; ...
                            "texture"], string(x(5))));
                end
            end
        end
        % delete NaN labels
        cfg = [];
        cfg.trials = ~isnan(task(:, 1));
        cfg.latency = timepoint;
        data = ft_selectdata(cfg, data);
        task = task(~isnan(task(:, 1)), :);

    %     data.elec.coordsys = 'eeglab';
    %     cfg = [];
    %     cfg.elec = data.elec;   
    %     layout = ft_prepare_layout(cfg);
    %     
    %     figure(1); clf;
    %     cfg = [];
    %     cfg.layout = layout;
    %     cfg.colorbar = 'yes';
    %     ft_topoplotER(cfg, data);
    %     
        % apply surface laplacian
        cfg = [];
        cfg.method = 'spline';
        data = ft_scalpcurrentdensity(cfg, data);
    %     
    %     figure(2); clf;
    %     cfg = [];
    %     cfg.layout = layout;
    %     cfg.colorbar = 'yes';
    %     ft_topoplotER(cfg, data);

        % detrend and derivate trials
        cfg = [];
        cfg.detrend = 'yes';
        cfg.derivative = 'yes';
        data = ft_preprocessing(cfg, data);

        % select ROI channels
        chnl = ft_channelselection({'FFC1h', 'FCC1h', 'AF3', ...
            'FP1', 'FPz', 'AFP1', 'AFP5', 'F1', 'AFF3h', 'AFF1h'}, data);
        cfg = [];
        cfg.channel = chnl;
        fr_data = ft_selectdata(cfg, data);

        cfg.channel = ft_channelselection({'T7','TP7','TTP7h', ...
            'TPP7h'}, data);
        lt_data = ft_selectdata(cfg, data);

        cfg.channel = ft_channelselection({'T8','TP8','TTP8h', ...
            'TPP8h'}, data);
        rt_data = ft_selectdata(cfg, data);

        cfg.channel = ft_channelselection({'O*'}, data);
        oc_data = ft_selectdata(cfg, data);

        data = ft_appenddata([], fr_data, lt_data, rt_data, oc_data);
        chnl = data.label;

        data = ft_checkdata(data, 'datatype', 'timelock', 'feedback', ...
            'no');
        % (channel, time, trial)
        data = permute(data.trial, [2, 3, 1]);

    %     [ksstat, cval] = mvgc_kpss(data, 0.05);
    %     is_stationary = sum(ksstat < cval, 2);
    %     stationary_trials = (is_stationary == size(data, 1));
    %     fprintf('%d trials kept.\n', size(data, 3) - ...
    %             sum(stationary_trials));
    %     data = data(:, :, stationary_trials);

        [AIC, BIC, morder] = tsdata_to_infocrit(data, 20);
        fprintf('best order: %d\n', morder);

    %     plot_tsdata([AIC BIC]',{'AIC','BIC'}, 1/1200);
    %     title('Model order estimation'); 
    %     hold on
    %     scatter((morder-1)/1200, AIC(morder),'k','filled', ...
    %           'DisplayName', 'best order');                 
    %     hold off

        [F, A, SIG] = GCCA_tsdata_to_pwcgc(data, morder);
        assert(~isbad(A),'VAR estimation failed');

        [G, info] = var_to_autocov(A, SIG);
        disp(info);

        assert(~isbad(F,false),'GC calculation failed');

    %     pval = mvgc_pval(F,morder,size(data, 2),size(data, 3),1,1, ...
    %             size(data, 1)-2);
    %     sig = significance(pval, 0.05, 'FDR');

    %     [FTUP,FTLO] = mvgc_confint(0.05, F, morder, size(data, 2), ...
    %             size(data, 3),1,1,size(data, 1)-2);
    % 
    %     % Critical GC value.
    %     FTCRIT = mvgc_cval(0.05, morder, size(data, 2),size(data, 3), ...
    %             1,1,size(data, 1)-2);

    %     figure;
    %     plot_pw(F);
    %     yticklabels(chnl);
    %     xticklabels(chnl);
    %     xtickangle(90);

    %     figure; clf;
    %     subplot(1,3,1);
    %     plot_pw(F);
    %     title('Pairwise-conditional GC');
    %     subplot(1,3,2);
    %     plot_pw(pval);
    %     title('p-values');
    %     subplot(1,3,3);
    %     plot_pw(sig);
    %     title(['Significant at p = 0.05']);

    %     figure; clf
    %     plot_confints(F,FTUP,FTLO,FTCRIT);
    %     title(sprintf(...
    %         'Theoretical distribution\nconfidence intervals'));
        INFO = [INFO, info];
        order(subject) = morder;
        fstat(subject, :, :) = F;
    end
    
    save(['../data/result/granger/gr_', num2str(timepoint(1)), '_', ...
         num2str(timepoint(2)), '.mat'], 'INFO', 'order', 'fstat');
end