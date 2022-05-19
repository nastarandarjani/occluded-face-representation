function data = CDF_(x)
    shape = size(x);
	x = reshape(x, [1, numel(x)]);
    n = length(x);
    [sorted, ~, index] = unique(x);
    value = (n - [length(sorted)-1:-1:0]') ./ n;
    data = reshape(value(index), shape);
end