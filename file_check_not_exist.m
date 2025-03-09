function [] = file_check_not_exist(fpath, fname)
if isfile(fullfile(fpath, fname))
    disp(['Unexpected file: [ ', fname, ' ]'])
end
end
