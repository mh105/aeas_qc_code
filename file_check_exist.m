function [] = file_check_exist(fpath, fname)
if ~isfile(fullfile(fpath, fname))
    disp(['Missing file: [ ', fname, ' ]'])
end
end
