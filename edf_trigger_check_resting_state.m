function [] = edf_trigger_check_resting_state(msg_table, rawdata)

%% Check that the expected triggers are all present
EyesClosed_Start_idx = find(msg_table.msg == 2);
if length(EyesClosed_Start_idx) > 1
    disp('Multiple eyes closed start trigger ["2"] found in the file.')
    EyesClosed_Start_idx = EyesClosed_Start_idx(1);
end
if isempty(EyesClosed_Start_idx)
    disp('Resting state eyes closed start trigger ["2"] is missing from the file.')
end

EyesClosed_End_idx = find(msg_table.msg == 3);
if length(EyesClosed_End_idx) > 1
    disp('Multiple eyes closed start trigger ["3"] found in the file.')
    EyesClosed_End_idx = EyesClosed_End_idx(1);
end
if isempty(EyesClosed_End_idx)
    disp('Resting state eyes closed end trigger ["3"] is missing from the file.')
end

EyesOpen_Start_idx = find(msg_table.msg == 4);
if length(EyesOpen_Start_idx) > 1
    disp('Multiple eyes closed start trigger ["4"] found in the file.')
    EyesOpen_Start_idx = EyesOpen_Start_idx(1);
end
if isempty(EyesOpen_Start_idx)
    disp('Resting state eyes open start trigger ["4"] is missing from the file.')
end

EyesOpen_End_idx = find(msg_table.msg == 5);
if length(EyesOpen_End_idx) > 1
    disp('Multiple eyes closed start trigger ["5"] found in the file.')
    EyesOpen_End_idx = EyesOpen_End_idx(1);
end
if isempty(EyesOpen_End_idx)
    disp('Resting state eyes open end trigger ["5"] is missing from the file.')
end

%% Check that the ordering of these triggers are as expected
targetSeq = [2, 3, 4, 5];
msgSeq = msg_table.msg';

if length(strfind(msgSeq, targetSeq)) ~= 1
    disp(['The resting state triggers are not following the correct order ["2345"]: ', num2str(msgSeq)])
end

%% Report the eyes closed and eyes open period durations
EyesClosed_milliseconds = msg_table.time(EyesClosed_End_idx) - msg_table.time(EyesClosed_Start_idx);
disp(['Eyes closed period duration = ', char(seconds(EyesClosed_milliseconds / 1000), 'mm:ss.SSS')])
disp(['Deviation from the target 180s duration = ', num2str(EyesClosed_milliseconds - 180*1000), 'ms'])

EyesOpen_milliseconds = msg_table.time(EyesOpen_End_idx) - msg_table.time(EyesOpen_Start_idx);
disp(['Eyes open period duration = ', char(seconds(EyesOpen_milliseconds / 1000), 'mm:ss.SSS')])
disp(['Deviation from the target 180s duration = ', num2str(EyesOpen_milliseconds - 180*1000), 'ms'])

%% Report the total task duration
start_line = find(matches(rawdata(:, 1), 'MSG'), 1);
current_string = strsplit(rawdata{start_line, 2}, ' ');
start_time = str2double(current_string{1});
end_line = find(matches(rawdata(:, 1), 'END'), 1, 'last');
task_duration_milliseconds = str2double(rawdata{end_line, 2}) - start_time;
disp(['Task duration = ', char(seconds(task_duration_milliseconds / 1000), 'mm:ss.SSS')])
