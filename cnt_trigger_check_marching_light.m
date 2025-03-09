function [] = cnt_trigger_check_marching_light(EEG_event)

event_array = {EEG_event.type};
targetSeq = {'1', '2', '4', '8', '16', '32', '64'};

eventStr = strjoin(event_array, ' ');
targetStr = strjoin(targetSeq, ' ');

if ~contains(eventStr, targetStr)
    dips('Cannot find marching light triggers in this task recording.')
end
