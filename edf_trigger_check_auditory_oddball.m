function [] = edf_trigger_check_auditory_oddball(msg_table, rawdata)

%% Check that the expected triggers are all present
n_blocks = 1;
n_trials_per_block = 100;
percent_oddball = 0.2;

n_regular_trials = n_trials_per_block * (1 - percent_oddball);
n_oddball_trials = n_trials_per_block * percent_oddball;

block_start_idx = find(msg_table.msg == 122);
block_end_idx = find(msg_table.msg == 123);
if length(block_start_idx) ~= n_blocks || length(block_end_idx) ~= n_blocks
    disp(['Not exactly ', num2str(n_blocks), ' blocks of trials are found in the file.'])
end

regular_idx = find(msg_table.msg == 41);
if length(regular_idx) ~= n_regular_trials
    disp(['Not exactly ', num2str(n_regular_trials), ' regular tone trials are found in the file.'])
end

oddball_idx = find(msg_table.msg == 42);
if length(oddball_idx) ~= n_oddball_trials
    disp(['Not exactly ', num2str(n_oddball_trials), ' oddball tone trials are found in the file.'])
end

%% Report the total task duration
start_line = find(matches(rawdata(:, 1), 'MSG'), 1);
current_string = strsplit(rawdata{start_line, 2}, ' ');
start_time = str2double(current_string{1});
end_line = find(matches(rawdata(:, 1), 'END'), 1, 'last');
task_duration_milliseconds = str2double(rawdata{end_line, 2}) - start_time;
disp(['Task duration = ', char(seconds(task_duration_milliseconds / 1000), 'mm:ss.SSS')])
