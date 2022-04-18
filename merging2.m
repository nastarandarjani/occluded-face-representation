data = [];
for num = 1:9
    file = sprintf('../data/raw/sub10_task_07_02_2022_15_16_03_00%02d.mat',...
        num - 1);
    num-1
    data1 = load(file);
    data1 = squeeze(data1.data);
    data = cat(2, data, data1);
end

trig = data(130, :);
data(130, :) = diff([data(130, 1), data(130, :)]);
data(130, data(130, :) > 25) = 100;
data(1, :) = [];
data(129, data(129, :) ~= -50) = 0;

ind = find(data(129, :) ~= 0);
interval = diff([0, ind])
rest = ~ismember(interval, [739, 740, 741, 742, 743]);

plot(trig/100);
hold on
plot(data(129, :));
scatter(ind, rest, 'r*');

% plot(trig/100);
% hold on
% plot((data(129, :)*-1)/50);
% plot(1, 50)

%data(129, find(data(129, :), 1, 'last')) = 0;