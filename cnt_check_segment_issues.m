function [] = cnt_check_segment_issues(EEG1)

%% Check impedance
if ~strcmp(EEG1.event(1).type, '0, Impedance')
    disp('Start impedance measures are missing!')
end

impedance_rows = find(matches({EEG1.event.type}, '0, Impedance'));
if length(impedance_rows) < 2
    disp('End impedance measures are missing!')
end

add_imp_num = length(impedance_rows) - 2;
if  add_imp_num > 0
    disp([num2str(add_imp_num), ' additional impedance measurement found during recording.'])
end

%% Check number of segments and interruptions
disconnect_num = sum(matches({EEG1.event.type}, '9001, Amplifier disconnected'));
if disconnect_num > 0
    disp(['Number of Amplifier disconnection message found: ', num2str(disconnect_num)])
    disp(['Recording is broken into ', num2str(disconnect_num+1), ' segments.'])
end
