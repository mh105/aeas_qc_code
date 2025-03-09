function [] = cnt_trigger_check_auditory_oddball(EEG_event, Fs)

event_array = {EEG_event.type};
task_start_code_idx = find(matches(event_array, '100'));
task_code = event_array{task_start_code_idx + 1};

if ~isequal(task_code, '104')
    disp(['Task code trigger for this auditory_oddball recording is not 104. The code is instead: ', task_code])
end

% get rid of the set-up triggers and keep only triggers after task starts
event_array(1:task_start_code_idx+1) = [];

%% Check that the expected triggers are all present
n_blocks = 1;
n_trials_per_block = 100;
percent_oddball = 0.2;

n_regular_trials = n_trials_per_block * (1 - percent_oddball);
n_oddball_trials = n_trials_per_block * percent_oddball;

block_start_idx = find(matches(event_array, '122'));
block_end_idx = find(matches(event_array, '123'));
if length(block_start_idx) ~= n_blocks || length(block_end_idx) ~= n_blocks
    disp(['Not exactly ', num2str(n_blocks), ' blocks of trials are found in the file.'])
end

regular_idx = find(matches(event_array, '41'));
if length(regular_idx) ~= n_regular_trials
    disp(['Not exactly ', num2str(n_regular_trials), ' regular tone trials are found in the file.'])
end

oddball_idx = find(matches(event_array, '42'));
if length(oddball_idx) ~= n_oddball_trials
    disp(['Not exactly ', num2str(n_oddball_trials), ' oddball tone trials are found in the file.'])
end

%% Report the total task duration
task_duration_seconds = EEG_event(end).latency / Fs;
disp(['Task duration = ', char(seconds(task_duration_seconds), 'mm:ss.SSS')])
