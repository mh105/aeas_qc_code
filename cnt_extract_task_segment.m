function [ EEG2, num_rep ] = cnt_extract_task_segment(EEG1, partitions, task_codes, select_code)
%% Locate the latest partition (if multiple) with the requested task code
num_rep = sum(task_codes == select_code);
assert(num_rep > 0, 'Cannot find the requested task code. Partitions might be off.')

partition_idx = find(task_codes == select_code, 1, 'last');
select_triggers = partitions{partition_idx};

%% Trim the EEG struct to the task period within the partition
EEG2 = EEG1;
start_sample = select_triggers{1, 1};
end_sample = select_triggers{4, 1};

% Update the setname field
EEG2.setname = ['Split dataset for task code: ', num2str(select_code)];

% Update time axis related fields
EEG2.times = EEG2.times(start_sample:end_sample-1);
EEG2.times = EEG2.times - EEG2.times(1);
EEG2.pnts = length(EEG2.times);
EEG2.xmax = EEG2.times(end) / 1000; % convert from msec to sec

% Update the data field
EEG2.data = EEG2.data(:, start_sample:end_sample-1);

% Update the event field
latencies = cell2mat({EEG2.event.latency});
valid_event_idx = latencies >= start_sample & latencies <= end_sample;
EEG2.event = EEG2.event(valid_event_idx);
for ii = 1:length(EEG2.event)
    EEG2.event(ii).latency = EEG2.event(ii).latency - (start_sample-1);
end

% Update the impedance fields
impedance_rows = find(contains({EEG2.event.type}, 'Impedance'));
initimp_idx = impedance_rows(1);
endimp_idx = impedance_rows(end);
assert(length(EEG2.initimp) == (length(EEG2.event(initimp_idx).impedance) + 1), 'Number of impedance values is incorrect. Cannot update!')
assert(length(EEG2.endimp) == (length(EEG2.event(endimp_idx).impedance) + 1), 'Number of impedance values is incorrect. Cannot update!')
EEG2.initimp(1:end-1) = EEG2.event(initimp_idx).impedance;
EEG2.endimp(1:end-1) = EEG2.event(endimp_idx).impedance;

%% Verify the consistency of all EEG struct fields
EEG2 = eeg_checkset(EEG2);
