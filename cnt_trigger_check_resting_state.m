function [] = cnt_trigger_check_resting_state(EEG_event, Fs)

event_array = {EEG_event.type};
latency_array = cell2mat({EEG_event.latency});
task_start_code_idx = find(matches(event_array, '100'));
task_code = event_array{task_start_code_idx + 1};

if ~isequal(task_code, '101')
    disp(['Task code trigger for this resting_state recording is not 101. The code is instead: ', task_code])
end

% get rid of the set-up triggers and keep only triggers after task starts
event_array(1:task_start_code_idx+1) = [];
latency_array(1:task_start_code_idx+1) = [];

%% Check that the expected triggers are all present
EyesClosed_Start_idx = find(matches(event_array, '2'));
if length(EyesClosed_Start_idx) > 1
    disp('Multiple eyes closed start trigger ["2"] found in the file.')
    EyesClosed_Start_idx = EyesClosed_Start_idx(1);
end
if isempty(EyesClosed_Start_idx)
    disp('Resting state eyes closed start trigger ["2"] is missing from the file.')
end

EyesClosed_End_idx = find(matches(event_array, '3'));
if length(EyesClosed_End_idx) > 1
    disp('Multiple eyes closed start trigger ["3"] found in the file.')
    EyesClosed_End_idx = EyesClosed_End_idx(1);
end
if isempty(EyesClosed_End_idx)
    disp('Resting state eyes closed end trigger ["3"] is missing from the file.')
end

EyesOpen_Start_idx = find(matches(event_array, '4'));
if length(EyesOpen_Start_idx) > 1
    disp('Multiple eyes closed start trigger ["4"] found in the file.')
    EyesOpen_Start_idx = EyesOpen_Start_idx(1);
end
if isempty(EyesOpen_Start_idx)
    disp('Resting state eyes open start trigger ["4"] is missing from the file.')
end

EyesOpen_End_idx = find(matches(event_array, '5'));
if length(EyesOpen_End_idx) > 1
    disp('Multiple eyes closed start trigger ["5"] found in the file.')
    EyesOpen_End_idx = EyesOpen_End_idx(1);
end
if isempty(EyesOpen_End_idx)
    disp('Resting state eyes open end trigger ["5"] is missing from the file.')
end

%% Check that the ordering of these triggers are as expected
targetSeq = {'2', '3', '4', '5'};
tmp_event_array = event_array(~contains(event_array, {'Impedance', '127', 'boundary', 'Amplifier'}));
eventStr = strjoin(tmp_event_array, ' ');
targetStr = strjoin(targetSeq, ' ');
if ~contains(eventStr, targetStr)
    disp(['The resting state triggers are not following the correct order ["2345"]: ', eventStr])
end

%% Report the eyes closed and eyes open period durations
EyesClosed_seconds = (latency_array(EyesClosed_End_idx) - latency_array(EyesClosed_Start_idx)) / Fs;
disp(['Eyes closed period duration = ', char(seconds(EyesClosed_seconds), 'mm:ss.SSS')])
disp(['Deviation from the target 180s duration = ', num2str(EyesClosed_seconds*1000 - 180*1000), 'ms'])

EyesOpen_seconds = (latency_array(EyesOpen_End_idx) - latency_array(EyesOpen_Start_idx)) / Fs;
disp(['Eyes open period duration = ', char(seconds(EyesOpen_seconds), 'mm:ss.SSS')])
disp(['Deviation from the target 180s duration = ', num2str(EyesOpen_seconds*1000 - 180*1000), 'ms'])

%% Report the total task duration
task_duration_seconds = EEG_event(end).latency / Fs;
disp(['Task duration = ', char(seconds(task_duration_seconds), 'mm:ss.SSS')])
