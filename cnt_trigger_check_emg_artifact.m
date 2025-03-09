function [] = cnt_trigger_check_emg_artifact(EEG_event, Fs)

event_array = {EEG_event.type};
task_start_code_idx = find(matches(event_array, '100'));
task_code = event_array{task_start_code_idx + 1};

if ~isequal(task_code, '105')
    disp(['Task code trigger for this emg_artifact recording is not 105. The code is instead: ', task_code])
end

% get rid of the set-up triggers and keep only triggers after task starts
event_array(1:task_start_code_idx+1) = [];

%% Check that the expected triggers are all present
n_blocks_practice = 1;
n_blocks = 2;
n_trials_per_block = 6;

n_blocks_total = n_blocks_practice + n_blocks;
n_videos = n_blocks_total * n_trials_per_block;

block_start_idx = find(matches(event_array, '122'));
block_end_idx = find(matches(event_array, '123'));
if length(block_start_idx) ~= n_blocks_total || length(block_end_idx) ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of trials are found in the file.'])
end

video_start_idx = find(matches(event_array, '3'));
video_end_idx = find(matches(event_array, '4'));
if length(video_start_idx) ~= n_videos || length(video_end_idx) ~= n_videos
    disp(['Not exactly ', num2str(n_videos), ' trials are found in the file.'])
end

%% Check that the ordering of these triggers are as expected
targetSeq = repmat({'3', '4'}, 1, n_trials_per_block);
tmp_event_array = event_array(~contains(event_array, {'Impedance', '127', 'boundary', 'Amplifier'}));
eventStr = strjoin(tmp_event_array, ' ');
targetStr = strjoin(targetSeq, ' ');
indices = strfind(eventStr, targetStr); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of ordered trial triggers are found in the file.'])
end

%% Report the total task duration
task_duration_seconds = EEG_event(end).latency / Fs;
disp(['Task duration = ', char(seconds(task_duration_seconds), 'mm:ss.SSS')])
