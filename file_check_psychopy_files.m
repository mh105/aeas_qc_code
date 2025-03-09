function [ num_rep, edf_fn ] = file_check_psychopy_files(fpath, task_name)
% find all files under the directory
task_fns = {dir(fpath).name};

% filter down to only files containing the task_name string
task_fns = task_fns(contains(task_fns, task_name));

% no matter how many times the task is repeated, we should only have one
% log file for each unique session ID, in this case defaults to 001
log_fn = task_fns(contains(task_fns, '.log') & ~contains(task_fns, 'last_app_load'));
if length(log_fn) > 1
    disp(['Multiple sessions for the task: ', task_name])
    disp(log_fn)
end
log_fn = log_fn{1};
if ~contains(log_fn, [task_name, '_001'])
    disp(['Session number is not 001: ', log_fn])
end

% now we need to figure out how many times the task was initiated
psydat_fns = erase(task_fns(contains(task_fns, '.psydat')), '.psydat');
if length(psydat_fns) > 1
    repeat_idx = erase(psydat_fns, {erase(log_fn, '.log'), '_'});
    num_rep = max(str2double(repeat_idx)) + 1;
    task_fn_body = [erase(log_fn, '.log'), '_', num2str(num_rep - 1)];
    disp(['The task was started ', num2str(num_rep - 1), ' times: ', task_name])
else
    num_rep = 1;
    task_fn_body = erase(log_fn, '.log');
end

file_check_exist(fpath, [task_fn_body, '_last_app_load.log'])
file_check_exist(fpath, [task_fn_body, '.csv'])
edf_fn = [task_fn_body, '.EDF'];
file_check_exist(fpath, edf_fn)
file_check_exist(fpath, [task_fn_body, '.psydat'])

end
