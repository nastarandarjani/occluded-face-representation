function pc = FDR_(p)
% Copyright (c) 2016 Nuno Fachada
% Distributed under the MIT License (See accompanying file LICENSE or copy 
% at http://opensource.org/licenses/MIT)
%
    np = numel(p);
    pdims = size(p);
    % Reshape input into a row vector, keeping original shape for later
    % converting results into original shape
    p = reshape(p, 1, np);

    % Descendent vector
    vdec = np:-1:1;

    % Sort p-values in descending order
    [pc, pidx] = sort(p, 'descend');
    % Get indexes of p-value indexes
    [~, ipidx] = sort(pidx);
    % BH-specific transformation
    pc = (np ./ vdec) .* pc;
    % Cumulative minimum
    pc = cmin(pc);    

    % Reorder p-values to original order
    pc = pc(ipidx);
    
    pc(pc > 1) = 1;    
    % Reshape result vector to original form
    pc = reshape(pc, pdims);
    
    function p = cmin(p)
        for i = 2:numel(p)
            if p(i) > p(i - 1)
                p(i) = p(i - 1);
            end
        end
    end
end