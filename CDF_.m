% function data = CDF_(x)
%     shape = size(x);
% 	x = reshape(x, [1, numel(x)]);
%     n = length(x);
%     [sorted, ~, index] = unique(x);
%     value = (n - [length(sorted)-1:-1:0]') ./ n;
%     data = reshape(value(index), shape);
% end
function data = CDF_(x)
    shape = size(x);
	x = reshape(x, [1, numel(x)]);
    x_plus = find(x>=0);
    x_minus = find(x<0);
    
    n_plus = length(x(x_plus));
    [sorted_plus, ~, index_plus] = unique(x(x_plus));
    value = (n_plus - [length(sorted_plus)-1:-1:0]') ./ n_plus;
    data(x_plus) = value(index_plus);
    
    n_minus = length(x(x_minus));
    [sorted_minus, ~, index_minus] = unique(-1 .* x(x_minus));
    value = (n_minus - [length(sorted_minus)-1:-1:0]') ./ n_minus;
    data(x_minus) = -1 * value(index_minus);
    
    data = reshape(data, shape);
end