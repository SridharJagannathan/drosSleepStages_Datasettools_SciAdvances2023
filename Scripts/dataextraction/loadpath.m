%% Set the path for the external toolbox folder and add it to MATLAB search directory

%% Determine location
pathappend = '/rds/project/tb419/rds-tb419-bekinschtein/Sri/'; %'/work/imagingQ/'

%% Add paths now..
%TDT toolbox path
tdt_toolbox = [pathappend 'SpatialAttention_Drowsiness/Scripts/toolboxes/TDTMatlabSDK'];
addpath(genpath(tdt_toolbox));

%EEGlab path
eeglab_toolbox = [pathappend 'SpatialAttention_Drowsiness/Scripts/toolboxes/eeglab13_5_4b'];
addpath(genpath(eeglab_toolbox));
rmpath(genpath([eeglab_toolbox '/functions/octavefunc']));