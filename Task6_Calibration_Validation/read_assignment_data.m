function S = read_assignment_data(filename, sheetName)
% read_assignment_data
% Read the assignment workbook:
%   data_calibration_validation.xlsx
%
% Sheet format observed in the uploaded file:
%   columns 1:3 = [time, temperature, concentration]
%   columns 5:6 = labels and values for T0, CA0, Tf, Caf, Tc
%
% Output S fields:
%   S.t, S.T, S.CA, S.T0, S.CA0, S.Tf, S.CAf, S.Tc

    raw = readcell(filename, 'Sheet', sheetName);

    % Main data block
    dataBlock = raw(:,1:3);
    keepRows = ~cellfun(@(x) isempty(x) || (isstring(x) && strlength(x)==0), dataBlock(:,1));
    dataBlock = dataBlock(keepRows,:);

    S.t  = cell2mat(dataBlock(:,1));
    S.T  = cell2mat(dataBlock(:,2));
    S.CA = cell2mat(dataBlock(:,3));

    % Conditions block
    labels = raw(:,5);
    values = raw(:,6);

    S.T0  = NaN;
    S.CA0 = NaN;
    S.Tf  = NaN;
    S.CAf = NaN;
    S.Tc  = NaN;

    for i = 1:numel(labels)
        if ischar(labels{i}) || isstring(labels{i})
            key = lower(strtrim(string(labels{i})));
            val = values{i};
            switch key
                case "t0"
                    S.T0 = val;
                case "ca0"
                    S.CA0 = val;
                case "tf"
                    S.Tf = val;
                case {"caf","c_af"}
                    S.CAf = val;
                case "tc"
                    S.Tc = val;
            end
        end
    end

    % Fallback: use first data row if initial conditions were not found
    if isnan(S.T0),  S.T0  = S.T(1);  end
    if isnan(S.CA0), S.CA0 = S.CA(1); end
end
