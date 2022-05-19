function data = merging(subject)
    data = [];
    for num = 1:10
        file = sprintf('../data/raw/Sub5_Task_25_01_2022_14_43_36_00%02d.mat',...
            num - 1);
        num-1
        data1 = load(file);
        data1 = squeeze(data1.data);
        data = cat(2, data, data1);
    end
    
   
    data(130, :) = diff([data(130, 1), data(130, :)]);
    data(130, data(130, :) > 25) = 100;
    data(1, :) = [];
    data(129, data(129, :) ~= -50) = 0;
%     data(129, abs(data(129, :)+50) >= 5) = 0;
    %data(129, find(data(129, :), 1, 'last')) = 0;
    
    save(['../data/merged/', subject, '.mat'], 'data', '-v7.3');
end
