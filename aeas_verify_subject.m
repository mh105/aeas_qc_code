function [] = aeas_verify_subject(subID)
%
% **AEAS PROJECT FUNCTION - VERIFY_SUBJECT**
%
% - used to verify all files that should be present in a subject folder and
% checks over all file naming conventions. Produce a subID_verify_log.txt
% file in the log folder that summarizes missing files and outputs basic
% information such as task durations.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ##### Inputs:
%
%           - subID:        a string of subject identifier: e.g. "SP001".
%                           this function will automatically search for
%                           relevant files in the subject folder
%                           Filenames to vet are hardcoded.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% ###### Outputs:
%
%           - no output for this function.
%
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

%% Add path to appropriate folders
% matlabroot will help detect the current environment
dataDir = SleepEEG_addpath(matlabroot);
subDir = fullfile(dataDir, subID);

%% Command window display settings
% Beginning of command window messages.
mHead = 'aeas_verify_subject: ';

%% Open a new subID_verify_log.txt
infofn = fullfile(subDir, 'log', [subID, '_verify_log.txt']);
if isfile(infofn)
    delete(infofn)
end

diary(infofn)
disp([mHead, 'Checking subject: ', subID])
startdatetime = char(datetime);
startdatetime = strrep(startdatetime,':','_');
disp(startdatetime)

%%





%% Check that all files are present for the subject
disp([newline newline])
disp('[Checking that all subfolders have the correct files...]')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp([mHead, 'folder: ', subID, '/fastscan'])
p = fullfile(subDir, 'fastscan');
file_check_exist(p, [subID, '_fastscan.mat'])
file_check_exist(p, [subID, '_fastscan.txt'])
file_check_exist(p, [subID, '_labelled.fsn'])
file_check_exist(p, [subID, '.fsn'])
disp([newline, 'completed.'])

disp('--------------------------------------------------')
disp([mHead, 'folder: ', subID, '/raw'])
p = fullfile(subDir, 'raw');
file_check_exist(p, [subID, '_resting.cnt'])
file_check_exist(p, [subID, '_resting.evt'])
file_check_not_exist(p, [subID, '_resting.seg'])

% Since the task data are contained in one recording with multiple segments
% and using the recording date in the file name, we need a flexible routine
% to detect them and flag
raw_fns = {dir(p).name};
raw_fns = raw_fns(~startsWith(raw_fns, '.') & ~contains(raw_fns, 'resting') & contains(raw_fns, subID));
task_fn_body = unique(erase(raw_fns, {'.cnt', '.evt', '.seg'}));
if length(task_fn_body) > 1
    disp('Multiple task files:')
    disp(task_fn_body)
else
    file_check_exist(p, [task_fn_body{1}, '.cnt'])
    file_check_exist(p, [task_fn_body{1}, '.evt'])
    file_check_exist(p, [task_fn_body{1}, '.seg'])
end
disp([newline, 'completed.'])

disp('--------------------------------------------------')
disp([mHead, 'folder: ', subID, '/set'])
p = fullfile(subDir, 'set');
file_check_exist(p, [subID, '_resting_ds500_Z3.set'])
disp([newline, 'completed.'])

disp('--------------------------------------------------')
disp([mHead, 'folder: ', subID, '/task'])
p = fullfile(subDir, 'task');
num_reps_psychopy = zeros(1, 5);
edf_fns = cell(1, 5);
[ num_reps_psychopy(1), edf_fns{1} ] = file_check_psychopy_files(p, subID, 'resting_state');
[ num_reps_psychopy(2), edf_fns{2} ] = file_check_psychopy_files(p, subID, 'emg_artifact');
[ num_reps_psychopy(3), edf_fns{3} ] = file_check_psychopy_files(p, subID, 'bluegrass_memory');
[ num_reps_psychopy(4), edf_fns{4} ] = file_check_psychopy_files(p, subID, 'auditory_oddball');
[ num_reps_psychopy(5), edf_fns{5} ] = file_check_psychopy_files(p, subID, 'feature_binding');
disp([newline, 'completed.'])
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

%%





%% Check basic quality of EEG .cnt files
disp([newline newline])
disp('[Checking the number of triggers and multiple segments in ANT-Neuro .cnt files...]')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp([mHead, 'folder: ', subID, '/raw', newline])
p = fullfile(subDir, 'raw');

%%
disp('--------------------------------------------------')
EEG1 = cnt_check_single_segment(p, [subID, '_resting.cnt']);
if ~isempty(EEG1)
    cnt_trigger_check_marching_light(EEG1.event)
    cnt_trigger_check_resting_state(EEG1.event, EEG1.srate)
end
disp([newline, 'completed.'])

%%
disp('--------------------------------------------------')
[ EEG_tasks, num_reps_EEG ] = cnt_check_multiple_segment(p, [task_fn_body{1}, '.cnt']);
disp([newline, 'completed.'])

if ~isempty(EEG_tasks)
    %%
    task_order = 1;
    if ~isempty(EEG_tasks{task_order})
        disp('--------------------------------------------------')
        disp(['Checking the task triggers during [ ', 'emg_artifact', ' ]...', newline])
        if num_reps_psychopy(task_order + 1) ~= num_reps_EEG(task_order) % verify the task repetition number
            disp(['The numbers of times starting the task do not match between PsychoPy files (',...
                num2str(num_reps_psychopy(task_order + 1)), ') and EEG recording (', num2str(num_reps_EEG(task_order)) ,').'])
        end
        cnt_trigger_check_marching_light(EEG_tasks{task_order}.event)
        cnt_trigger_check_emg_artifact(EEG_tasks{task_order}.event, EEG_tasks{task_order}.srate)
        disp([newline, 'completed.'])
    end

    %%
    task_order = 2;
    if ~isempty(EEG_tasks{task_order})
        disp('--------------------------------------------------')
        disp(['Checking the task triggers during [ ', 'bluegrass_memory', ' ]...', newline])
        if num_reps_psychopy(task_order + 1) ~= num_reps_EEG(task_order) % verify the task repetition number
            disp(['The numbers of times starting the task do not match between PsychoPy files (',...
                num2str(num_reps_psychopy(task_order + 1)), ') and EEG recording (', num2str(num_reps_EEG(task_order)) ,').'])
        end
        cnt_trigger_check_marching_light(EEG_tasks{task_order}.event)
        cnt_trigger_check_bluegrass_memory(EEG_tasks{task_order}.event, EEG_tasks{task_order}.srate)
        disp([newline, 'completed.'])
    end

    %%
    task_order = 3;
    if ~isempty(EEG_tasks{task_order})
        disp('--------------------------------------------------')
        disp(['Checking the task triggers during [ ', 'auditory_oddball', ' ]...', newline])
        if num_reps_psychopy(task_order + 1) ~= num_reps_EEG(task_order) % verify the task repetition number
            disp(['The numbers of times starting the task do not match between PsychoPy files (',...
                num2str(num_reps_psychopy(task_order + 1)), ') and EEG recording (', num2str(num_reps_EEG(task_order)) ,').'])
        end
        cnt_trigger_check_marching_light(EEG_tasks{task_order}.event)
        cnt_trigger_check_auditory_oddball(EEG_tasks{task_order}.event, EEG_tasks{task_order}.srate)
        disp([newline, 'completed.'])
    end

    %%
    task_order = 4;
    if ~isempty(EEG_tasks{task_order})
        disp('--------------------------------------------------')
        disp(['Checking the task triggers during [ ', 'feature_binding', ' ]...', newline])
        if num_reps_psychopy(task_order + 1) ~= num_reps_EEG(task_order) % verify the task repetition number
            disp(['The numbers of times starting the task do not match between PsychoPy files (',...
                num2str(num_reps_psychopy(task_order + 1)), ') and EEG recording (', num2str(num_reps_EEG(task_order)) ,').'])
        end
        cnt_trigger_check_marching_light(EEG_tasks{task_order}.event)
        cnt_trigger_check_feature_binding(EEG_tasks{task_order}.event, EEG_tasks{task_order}.srate)
        disp([newline, 'completed.'])
    end

end
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

%%





%% Check basic quality of eyetracking .EDF files
disp([newline newline])
disp('[Checking the number of triggers in EyeLink .EDF files...]')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp([mHead, 'folder: ', subID, '/task', newline])
p = fullfile(subDir, 'task');

%%
task_order = 1;
if ~isempty(edf_fns{task_order})
    disp('--------------------------------------------------')
    [ msg_table, rawdata ] = edf_extract_triggers(p, edf_fns{task_order});
    if ~isempty(msg_table)
        fprintf(newline)
        edf_trigger_check_resting_state(msg_table, rawdata)
    end
    disp([newline, 'completed.'])
end

%%
task_order = 2;
if ~isempty(edf_fns{task_order})
    disp('--------------------------------------------------')
    [ msg_table, rawdata ] = edf_extract_triggers(p, edf_fns{task_order});
    if ~isempty(msg_table)
        fprintf(newline)
        edf_trigger_check_emg_artifact(msg_table, rawdata)
    end
    disp([newline, 'completed.'])
end

%%
task_order = 3;
if ~isempty(edf_fns{task_order})
    disp('--------------------------------------------------')
    [ msg_table, rawdata ] = edf_extract_triggers(p, edf_fns{task_order});
    if ~isempty(msg_table)
        fprintf(newline)
        edf_trigger_check_bluegrass_memory(msg_table, rawdata)
    end
    disp([newline, 'completed.'])
end

%%
task_order = 4;
if ~isempty(edf_fns{task_order})
    disp('--------------------------------------------------')
    [ msg_table, rawdata ] = edf_extract_triggers(p, edf_fns{task_order});
    if ~isempty(msg_table)
        fprintf(newline)
        edf_trigger_check_auditory_oddball(msg_table, rawdata)
    end
    disp([newline, 'completed.'])
end

%%
task_order = 5;
if ~isempty(edf_fns{task_order})
    disp('--------------------------------------------------')
    [ msg_table, rawdata ] = edf_extract_triggers(p, edf_fns{task_order});
    if ~isempty(msg_table)
        fprintf(newline)
        edf_trigger_check_feature_binding(msg_table, rawdata)
    end
    disp([newline, 'completed.'])
end

%%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

%%
diary off
close all

end
