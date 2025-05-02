function [ msg_table, rawdata ] = edf_extract_triggers(fpath, fname)
%Convert EyeLink EDF file to asc txt file and read out timestamped triggers
disp(['Checking the .EDF file [ ', fname, ' ]...', newline])

%% Convert EDF into asc txt file using SR Research edf2asc command
current_path = pwd;
cd(fpath)
[~, cmdout] = system(['/usr/local/bin/edf2asc -y ', fname]);
cd(current_path)

convert_success_idx = strfind(cmdout, 'Converted successfully');
if isempty(convert_success_idx)
    disp('EDF file failed to convert to asc format. See below message for errors:')
    disp(cmdout)
    msg_table = [];
    rawdata = [];

else
    disp(cmdout(convert_success_idx:end))

    %% Load the ascII file into a cell array
    filename = fullfile(fpath, strrep(fname, '.EDF', '.asc'));
    delimiter = '\t'; % delimiter is tab
    formatSpec = '%s%s%s%s%s%s%s%s%s%[^\n\r]'; % all columns are in string format
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);
    fclose(fileID);
    rawdata = [dataArray{1:end-1}]; % last column is empty
    clearvars filename delimiter formatSpec fileID dataArray;

    %% Find out start lines and how many recording blocks
    start_line = find(matches(rawdata(:, 1), 'START'));
    end_line = find(matches(rawdata(:, 1), 'END'));
    if isempty(start_line)
        disp('Cannot find the START line in the eyetracking asc file.')
    else
        assert(length(start_line) == length(end_line), 'Difference occurences of START and END lines.')
        if length(start_line) > 1
            disp(['Multiple recording blocks in this .EDF file: ', num2str(length(start_line))])
        end
    end

    %% Check each recording block
    systeminfo_rows = false(size(rawdata, 2), 1);
    for ii = 1:length(start_line)
        % Count the number of calibration and validation at the beginning of each recording block
        if ii == 1
            start_search_idx = 1;
        else
            start_search_idx = end_line(ii-1) + 1;
        end

        systeminfo_rows(start_search_idx:start_line(ii)-1) = true;

        if length(start_line) > 1
            disp(['Recording block ', num2str(ii)])
        end

        cal_line = find(matches(rawdata(start_search_idx:start_line(ii), 1), '>>>>>>> CALIBRATION (HV9,P-CR) FOR LEFT: <<<<<<<<<'));
        disp(['Number of calibration performed to start this block: ', num2str(length(cal_line))])
        if length(cal_line) >= 1
            tmp_idx = start_search_idx:start_line(ii);
            val_line = find(contains(rawdata(tmp_idx(cal_line(end)):start_line(ii), 2), 'VALIDATION HV9 L LEFT'));
            disp(['Number of validation performed for the last calibration: ', num2str(length(val_line))])
        end

        cal_line_post_start = find(matches(rawdata(start_line(ii):end_line(ii), 1), '>>>>>>> CALIBRATION (HV9,P-CR) FOR LEFT: <<<<<<<<<'));
        if length(cal_line_post_start) >= 1
            disp(['Number of additional calibration performed after the block starts: ', num2str(length(cal_line_post_start))])
            tmp_idx = start_line(ii):end_line(ii);
            val_line = find(contains(rawdata(tmp_idx(cal_line_post_start(end)):end_line(ii), 2), 'VALIDATION HV9 L LEFT'));
            disp(['Number of additional validation performed for the last additional calibration: ', num2str(length(val_line))])
        end

        % Confirm that eyetracking configurations are set correctly for each recording block
        config_line = contains(rawdata(start_search_idx:start_line(ii), 2), 'RECCFG');
        rawdata_tmp = rawdata(start_search_idx:start_line(ii), :);
        config_string = strsplit(rawdata_tmp{config_line, 2}, 'RECCFG ');
        assert(isequal(config_string{2}, 'CR 1000 0 0 L'), ['Eyetracking configurations are different from expected: ', config_string{2}])
        % Tracking mode = Pupil-Corneal Reflection
        % Sampling rate = 1000 Hz
        % Online filter level = 0
        % Saved data filter level = 0
        % Tracking eye = LEFT

        config_line = contains(rawdata(start_search_idx:start_line(ii), 2), 'ELCLCFG');
        rawdata_tmp = rawdata(start_search_idx:start_line(ii), :);
        config_string = strsplit(rawdata_tmp{config_line, 2}, 'ELCLCFG ');
        assert(isequal(config_string{2}, 'MTABLER'), ['Eyetracker not in mounted table mode: ', config_string{2}])

        config_line = contains(rawdata(start_search_idx:start_line(ii), 2), 'GAZE_COORDS');
        rawdata_tmp = rawdata(start_search_idx:start_line(ii), :);
        config_string = strsplit(rawdata_tmp{config_line, 2}, 'GAZE_COORDS ');
        assert(isequal(config_string{2}, '0.00 0.00 1920.00 1080.00'), ['Gaze coordinates are different from expected: ', config_string{2}])

        config_line = contains(rawdata(start_search_idx:start_line(ii), 2), 'ELCL_PROC');
        rawdata_tmp = rawdata(start_search_idx:start_line(ii), :);
        config_string = strsplit(rawdata_tmp{config_line, 2}, 'ELCL_PROC ');
        assert(isequal(config_string{2}, 'ELLIPSE  (5)'), ['Pupil tracking algorithm is not ELLIPSE_FIT: ', config_string{2}])

        config_line = strcmp(rawdata(start_line(ii):end_line(ii), 1), 'PRESCALER');
        rawdata_tmp = rawdata(start_line(ii):end_line(ii), :);
        assert(strcmp(rawdata_tmp{config_line, 2}, '1'), ['Gaze position scaler is not 1: ', config_string{2}])

        config_line = strcmp(rawdata(start_line(ii):end_line(ii), 1), 'VPRESCALER');
        rawdata_tmp = rawdata(start_line(ii):end_line(ii), :);
        assert(strcmp(rawdata_tmp{config_line, 2}, '1'), ['Saccade velocity scaler is not 1: ', config_string{2}])

        config_line = strcmp(rawdata(start_line(ii):end_line(ii), 1), 'PUPIL');
        rawdata_tmp = rawdata(start_line(ii):end_line(ii), :);
        assert(strcmp(rawdata_tmp{config_line, 2}, 'DIAMETER'), ['Pupil size measurement unit is not DIAMETER: ', config_string{2}])

    end

    %% Remove systems info at the beginning of each block and keep the MSG rows
    rawdata_msg = rawdata;
    rawdata_msg(systeminfo_rows, :) = [];
    rawdata_msg = rawdata_msg(matches(rawdata_msg(:, 1), 'MSG'), :);

    %% Parition the MSG rows into a trigger table
    time = zeros(size(rawdata_msg, 1), 1);
    msg = zeros(size(rawdata_msg, 1), 1);

    for ii = 1:size(rawdata_msg, 1)
        current_string = strsplit(rawdata_msg{ii, 2}, ' ');
        time(ii) = str2double(current_string{1});
        msg(ii) = str2double(current_string{2});
    end

    msg_table = table;
    msg_table.time = time;
    msg_table.msg = msg;

end
