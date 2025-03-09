function [] = edf_trigger_check_feature_binding(msg_table, rawdata)

%% Check that the expected triggers are all present
n_blocks = 1;
n_trials_per_block_practice = 4;
n_trials_per_block = 80;

block_start_idx = find(msg_table.msg == 122);
block_end_idx = find(msg_table.msg == 123);

% Subject is allowed to repeat the practice block
n_blocks_practice = length(block_start_idx) - n_blocks;
n_blocks_total = n_blocks_practice + n_blocks;

if length(block_end_idx) ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of trials are found in the file.'])
end

n_trials = n_blocks_practice * n_trials_per_block_practice + n_blocks * n_trials_per_block;

trial_code_array = [9, 10, 11, 12, 13, 14, 16];
for ii = 1:length(trial_code_array)
    if sum(msg_table.msg == trial_code_array(ii)) ~= n_trials
        disp(['Not exactly ', num2str(n_trials), ' trials are found in the file using trigger code: ', trial_code_array{ii}])
    end
end

%% Check that the ordering of these triggers are as expected
msgSeq = msg_table.msg';

targetSeq_practice = repmat(trial_code_array, 1, n_trials_per_block_practice);
targetSeq_practice = [122, targetSeq_practice, 123];
indices = strfind(msgSeq, targetSeq_practice); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks_practice
    disp(['Not exactly ', num2str(n_blocks_practice), ' blocks of ordered practice trial triggers are found in the file.'])
end

targetSeq = repmat(trial_code_array, 1, n_trials_per_block);
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
