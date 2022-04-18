function label = map_label(imageseq)
% Written by Nastaran Darjani
% Developed in MATLAB R2017a
% see also: mvpa_run
%
    imageseq = split(imageseq, '.');
    imageseq = cellstr(imageseq(:, 1));
    imageseq = cellfun(@(x)strsplit(x, '_'), imageseq, 'UniformOutput', ...
        false);
    
    label = cellfun(@(v)v(1:4), imageseq, 'UniformOutput', false);
    label = vertcat(label{:});
    label = string(label);
    
    % whether the image is face or not
    isFace = nan(2865, 1);
    % which face it is
    identity = nan(2865, 1);
    % the occluder is meaningful or not
    meaningfulness = nan(2865, 1);
    % location of occluder
    location =  nan(2865, 1);
    % type of occluder
    type = nan(2865, 1);
    for i=1:2865
        if strcmp(label(i, 3), 'n')
            if strcmp(label(i, 4), '1')
                isFace(i) = 2;
            else
                type(i) = str2double(label(i, 4)) - 1;
                if ~strcmp(label(i, 2), '16')
                    meaningfulness(i) = 2;
                end
            end
        else
            if strcmp(label(i, 1), 'id')
                type(i) = find(strcmp(["pixel"; "phase"; "texture"], ...
                string(imageseq{i}(5)))) + 7;
            end
        end
        if strcmp(label(i, 3), 'location')
            location(i) = str2double(label(i, 4));
            meaningfulness(i) = 1;
        end
        if strcmp(label(i, 1), 'ir')
            if strcmp(label(i, 2), '16')
                isFace(i) = 1;
            else
                identity(i) = str2double(label(i, 2)) - 6;
            end
        elseif strcmp(label(i, 1), 'id')
            identity(i) = str2double(label(i, 2)) - 1;
        else
            isFace(i) = 1;
        end
    end
    
    label = [isFace, identity, meaningfulness, type, location];
end