function [] = cnt_trigger_check_bluegrass_memory(EEG_event, Fs)

event_array = {EEG_event.type};
task_start_code_idx = find(matches(event_array, '100'));
task_code = event_array{task_start_code_idx + 1};

if ~isequal(task_code, '103')
    disp(['Task code trigger for this bluegrass_memory recording is not 103. The code is instead: ', task_code])
end

% get rid of the set-up triggers and keep only triggers after task starts
event_array(1:task_start_code_idx+1) = [];

%% Check that the expected triggers are all present
n_blocks = 2;
n_trials_per_block_practice = 2;
n_trials_per_block = 30;
n_images_per_trial = 5;

block_start_idx = find(matches(event_array, '122'));
block_end_idx = find(matches(event_array, '123'));

% Subject is allowed to repeat the practice block
n_blocks_practice = length(block_start_idx) - n_blocks;
n_blocks_total = n_blocks_practice + n_blocks;

if length(block_end_idx) ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of trials are found in the file.'])
end

n_target_trials = n_blocks_practice * n_trials_per_block_practice + n_blocks * n_trials_per_block;
n_test_trials = n_target_trials * n_images_per_trial;

target_idx = find(matches(event_array, '2'));
if length(target_idx) ~= n_target_trials
    disp(['Not exactly ', num2str(n_target_trials), ' target trials are found in the file.'])
end

test_idx = find(matches(event_array, '3'));
if length(test_idx) ~= n_test_trials
    disp(['Not exactly ', num2str(n_test_trials), ' test trials are found in the file.'])
end

%% Check that the ordering of these triggers are as expected
tmp_event_array = event_array(~contains(event_array, {'Impedance', '127', 'boundary', 'Amplifier'}));
eventStr = strjoin(tmp_event_array, ' ');

targetSeq_practice = repmat([{'2'}, repmat({'3'}, 1, n_images_per_trial)], 1, n_trials_per_block_practice);
targetSeq_practice = [{'122'}, targetSeq_practice, {'123'}];
targetStr = strjoin(targetSeq_practice, ' ');
indices = strfind(eventStr, targetStr); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks_practice
    disp(['Not exactly ', num2str(n_blocks_practice), ' blocks of ordered practice trial triggers are found in the file.'])
end

targetSeq = repmat([{'2'}, repmat({'3'}, 1, n_images_per_trial)], 1, n_trials_per_block);
targetStr = strjoin(targetSeq, ' ');
indices = strfind(eventStr, targetStr); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks
    disp(['Not exactly ', num2str(n_blocks), ' blocks of ordered trial triggers are found in the file.'])
end

%% Report the total task duration
task_duration_seconds = EEG_event(end).latency / Fs;
disp(['Task duration = ', char(seconds(task_duration_seconds), 'mm:ss.SSS')])
