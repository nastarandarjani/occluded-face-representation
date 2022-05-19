function delete_false_trigger(num)
    file = sprintf('../data/raw/sub2_task_11_01_2022_12_00_24_00%02d.mat',...
        num - 1);
    data = load(file);
    data = squeeze(data.data);

    disp(['first value:', num2str(data(130, 1))]);
    disp(['last value:', num2str(data(130, end))]);

    indexBefore = [data(130, 1), data(130, 1:end-1)];
    indexAfter = [data(130, 2:end), data(130, end)];
    compareBeforeAfter = (indexBefore == indexAfter);
    noiseIndex = find(compareBeforeAfter & ~(indexBefore == data(130, :))...
                & ~ismember(data(130, :), [50, 100]));
    data(130, noiseIndex) = indexBefore(noiseIndex);

    indexBefore = [data(130, 1), data(130, 1:end-1)];
    indexAfter = [data(130, 2:end), data(130, end)];
    compareBeforeAfter = (indexBefore == indexAfter);
    noiseIndex = find(~compareBeforeAfter & ~ismember(data(130, :), ...
        [50, 100]));
    for i=1:length(noiseIndex)
        if ismember(data(130, noiseIndex(i)-1), [0, 50, 100])
            data(130, noiseIndex(i)) = data(130, noiseIndex(i)-1);
        elseif ismember(data(130, noiseIndex(i)+1), [0, 50, 100])
            data(130, noiseIndex(i)) = data(130, noiseIndex(i)+1);
        else
            disp(['sanity check: ', num2str(i)]);
        end
    end
    save(file, 'data', '-v7.3');
end