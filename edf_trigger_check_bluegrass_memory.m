function [] = edf_trigger_check_bluegrass_memory(msg_table, rawdata)

%% Check that the expected triggers are all present
n_blocks = 2;
n_trials_per_block_practice = 2;
n_trials_per_block = 30;
n_images_per_trial = 5;

block_start_idx = find(msg_table.msg == 122);
block_end_idx = find(msg_table.msg == 123);

% Subject is allowed to repeat the practice block
n_blocks_practice = length(block_start_idx) - n_blocks;
n_blocks_total = n_blocks_practice + n_blocks;

if length(block_end_idx) ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of trials are found in the file.'])
end

n_target_trials = n_blocks_practice * n_trials_per_block_practice + n_blocks * n_trials_per_block;
n_test_trials = n_target_trials * n_images_per_trial;

target_idx = find(msg_table.msg == 2);
if length(target_idx) ~= n_target_trials
    disp(['Not exactly ', num2str(n_target_trials), ' target trials are found in the file.'])
end

test_idx = find(msg_table.msg == 3);
if length(test_idx) ~= n_test_trials
    disp(['Not exactly ', num2str(n_test_trials), ' test trials are found in the file.'])
end

%% Check that the ordering of these triggers are as expected
msgSeq = msg_table.msg';

targetSeq_practice = repmat([2, repmat(3, 1, n_images_per_trial)], 1, n_trials_per_block_practice);
targetSeq_practice = [122, targetSeq_practice, 123];
indices = strfind(msgSeq, targetSeq_practice); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks_practice
    disp(['Not exactly ', num2str(n_blocks_practice), ' blocks of ordered practice trial triggers are found in the file.'])
end

targetSeq = repmat([2, repmat(3, 1, n_images_per_trial)], 1, n_trials_per_block);
indices = strfind(msgSeq, targetSeq); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks
    disp(['Not exactly ', num2str(n_blocks), ' blocks of ordered trial triggers are found in the file.'])
end

%% Report the total task duration
start_line = find(matches(rawdata(:, 1), 'MSG'), 1);
current_string = strsplit(rawdata{start_line, 2}, ' ');
start_time = str2double(current_string{1});
end_line = find(matches(rawdata(:, 1), 'END'), 1, 'last');
task_duration_milliseconds = str2double(rawdata{end_line, 2}) - start_time;
disp(['Task duration = ', char(seconds(task_duration_milliseconds / 1000), 'mm:ss.SSS')])
