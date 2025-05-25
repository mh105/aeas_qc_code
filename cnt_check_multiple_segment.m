function [ EEG_tasks, num_reps ] = cnt_check_multiple_segment(fpath, fname)
disp(['Checking the .cnt file [ ', fname, ' ]...'])
disp(['      Splitting the multi-segment file into individual task sets...', newline])

if isfile(fullfile(fpath, fname))
    diary off
    EEG1 = ANT_interface_readcnt(fname, fpath, [true, 500], true);
    diary on

    %% Now we need to chop up the recording into individual tasks
    % Note that sometimes a task might get started but terminated early and
    % there will be a second start of the same task. This needs to get
    % handled as well.
    partition_triggers = {};
    event_array = {EEG1.event.type};
    latency_array = {EEG1.event.latency};
    idx = contains(event_array, {'Impedance', 'Amplifier disconnected'}) | matches(event_array, {'100', '101', '102', '103', '104', '105', '106'});
    partition_triggers(:, 1) = latency_array(idx)';
    partition_triggers(:, 2) = event_array(idx)';
    partition_triggers(:, 3) = num2cell(find(idx)');

    %% We need to first handle the possible case of amplifier disconnection
    % Every amplifier disconnection event populates two additional
    % impedance values checks surrounding this trigger. We need to skip
    % these when partitioning the recording. We check this iteratively.
    disconnect_idx = find(contains(partition_triggers(:, 2), 'Amplifier disconnected'), 1); % returns the first nonzero index
    while ~isempty(disconnect_idx)
        % Remove the surrounding rows from the partition triggers table
        partition_triggers(disconnect_idx-1:disconnect_idx+1, :) = [];
        disconnect_idx = find(contains(partition_triggers(:, 2), 'Amplifier disconnected'), 1);
    end

    %% Partition the triggers based on pairs of impedance checks
    imp_idx = find(contains(partition_triggers(:, 2), 'Impedance'));
    assert(mod(length(imp_idx), 2) == 0, 'Partitioning encountered odd number of impedance checks. Cannot proceed!')

    partitions = cell(1, length(imp_idx) / 2);
    for ii = 1:length(partitions)
        start_idx = imp_idx(ii*2 - 1);
        end_idx = imp_idx(ii*2);
        partitions{ii} = partition_triggers(start_idx:end_idx, :);
    end

    %% Next we need to figure out the corresponding task code for each partition
    % There is a special edge case if a task is restarted without manually
    % stopping an ongoing recording, then we will end up with multiple task
    % codes within each partition that needs to be handled.
    task_codes = zeros(length(partitions), 2);
    for ii = 1:length(partitions)
        current_triggers = partitions{ii};
        task_code_idx = find(matches(current_triggers(:, 2), '100'));

        if isempty(task_code_idx)
            % This corresponds to a recording that was started but the
            % psychopy task did not begin, i.e., did not advance beyond the
            % subject info dialog box
            current_task_code = '';
        else
            if isscalar(task_code_idx)
                current_task_code = current_triggers{task_code_idx+1, 2};
            else
                % First make sure they are the same task code. If not, then
                % there is something wrong here
                current_task_code = unique(current_triggers(task_code_idx+1, 2));
                assert(isscalar(current_task_code), 'Multiple task codes within a partition. Please check!')
                current_task_code = current_task_code{1};
    
                % Then we use the latest task code as starting point, and we
                % need to copy over the initial impedance since the recording
                % continued and we do not have an extra impedance check
                EEG1.event(length(EEG1.event) + 1) = EEG1.event(current_triggers{1, 3});
                EEG1.event(length(EEG1.event)).latency = current_triggers{task_code_idx(end) - 1, 1};
                EEG1.event(length(EEG1.event)).type = [EEG1.event(length(EEG1.event)).type, ' (previous)'];
    
                % We update the partition table as well
                tmp_line = current_triggers(1, :);
                tmp_line{1} = EEG1.event(length(EEG1.event)).latency;
                tmp_line{2} = [tmp_line{2}, ' (previous)'];
                tmp_line{3} = NaN;
                current_triggers(1:task_code_idx(end)-1, :) = [];
                current_triggers = [tmp_line; current_triggers]; %#ok<AGROW>
                partitions{ii} = current_triggers;
            end
    
            % Verify the standardized partition triggers for later extraction
            assert(size(current_triggers, 1) == 4, 'Current triggers are not size 4. Extra triggers or missing triggers.')
            assert(isequal(current_triggers{2, 2}, '100'), 'Second trigger is not a task start code. Something is wrong.')
            assert(isequal(find(contains(current_triggers(:, 2), 'Impedance')), [1, 4]'), 'Impedance triggers are not the first and last triggers.')
        end

        % Save out the detected task code
        task_codes(ii, 1) = str2double(current_task_code);
        task_codes(ii, 2) = length(task_code_idx);
    end

    % Resort the EEG1.event struct in case we appended impedance checks
    diary off
    EEG1 = eeg_checkset(EEG1, 'eventconsistency');
    diary on

    %% Output each task recording as a separate EEG struct
    num_reps = zeros(1, 4); % also keep track of how many times it repeats
    EEG_tasks = cell(1, 4);

    % emg_artifact - task code = 105
    [ EEG_tasks{1}, num_reps(1) ] = cnt_extract_task_segment(EEG1, partitions, task_codes, 105);

    % bluegrass_memory - task code = 103
    [ EEG_tasks{2}, num_reps(2) ] = cnt_extract_task_segment(EEG1, partitions, task_codes, 103);

    % auditory_oddball - task code = 104
    [ EEG_tasks{3}, num_reps(3) ] = cnt_extract_task_segment(EEG1, partitions, task_codes, 104);

    % feature_binding - task code = 106
    [ EEG_tasks{4}, num_reps(4) ] = cnt_extract_task_segment(EEG1, partitions, task_codes, 106);

    %% Check each EEG struct for recording issues before output
    disp(['Checking the .cnt file segment of ', '[ emg_artifact ]', '...'])
    if ~isempty(EEG_tasks{1})
        cnt_check_segment_issues(EEG_tasks{1})
    else
        disp(['Missing file segment [ ', 'emg_artifact', ' ] in the .cnt file.'])
    end
    fprintf(newline)

    disp(['Checking the .cnt file segment of ', '[ bluegrass_memory ]', '...'])
    if ~isempty(EEG_tasks{2})
        cnt_check_segment_issues(EEG_tasks{2})
    else
        disp(['Missing file segment [ ', 'bluegrass_memory', ' ] in the .cnt file.'])
    end
    fprintf(newline)

    disp(['Checking the .cnt file segment of ', '[ auditory_oddball ]', '...'])
    if ~isempty(EEG_tasks{3})
        cnt_check_segment_issues(EEG_tasks{3})
    else
        disp(['Missing file segment [ ', 'auditory_oddball', ' ] in the .cnt file.'])
    end
    fprintf(newline)

    disp(['Checking the .cnt file segment of ', '[ feature_binding ]', '...'])
    if ~isempty(EEG_tasks{4})
        cnt_check_segment_issues(EEG_tasks{4})
    else
        disp(['Missing file segment [ ', 'feature_binding', ' ] in the .cnt file.'])
    end

else
    disp(['Missing file: [ ', fname, ' ]'])
    EEG_tasks = [];
    num_reps = [];
end
