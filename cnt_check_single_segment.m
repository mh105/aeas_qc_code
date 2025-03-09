function [ EEG1 ] = cnt_check_single_segment(fpath, fname)
disp(['Checking the .cnt file [ ', fname, ' ]...', newline])

if isfile(fullfile(fpath, fname))
    diary off
    EEG1 = ANT_interface_readcnt(fname, fpath, [true, 500], true);
    diary on
    cnt_check_segment_issues(EEG1)
else
    disp(['Missing file: [ ', fname, ' ]'])
    EEG1 = [];
end
