function [] = edf_trigger_check_emg_artifact(msg_table, rawdata)

%% Check that the expected triggers are all present
n_blocks_practice = 1;
n_blocks = 2;
n_trials_per_block = 6;

n_blocks_total = n_blocks_practice + n_blocks;
n_videos = n_blocks_total * n_trials_per_block;

block_start_idx = find(msg_table.msg == 122);
block_end_idx = find(msg_table.msg == 123);
if length(block_start_idx) ~= n_blocks_total || length(block_end_idx) ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of trials are found in the file.'])
end

video_start_idx = find(msg_table.msg == 3);
video_end_idx = find(msg_table.msg == 4);
if length(video_start_idx) ~= n_videos || length(video_end_idx) ~= n_videos
    disp(['Not exactly ', num2str(n_videos), ' trials are found in the file.'])
end

%% Check that the ordering of these triggers are as expected
targetSeq = repmat([3, 4], 1, n_trials_per_block);
msgSeq = msg_table.msg';
indices = strfind(msgSeq, targetSeq); % Find starting indices of occurrences
numOccurrences = numel(indices); % Count the number of occurrences

if numOccurrences ~= n_blocks_total
    disp(['Not exactly ', num2str(n_blocks_total), ' blocks of ordered trial triggers are found in the file.'])
end

%% Report the total task duration
start_line = find(matches(rawdata(:, 1), 'MSG'), 1);
current_string = strsplit(rawdata{start_line, 2}, ' ');
start_time = str2double(current_string{1});
end_line = find(matches(rawdata(:, 1), 'END'), 1, 'last');
task_duration_milliseconds = str2double(rawdata{end_line, 2}) - start_time;
disp(['Task duration = ', char(seconds(task_duration_milliseconds / 1000), 'mm:ss.SSS')])
