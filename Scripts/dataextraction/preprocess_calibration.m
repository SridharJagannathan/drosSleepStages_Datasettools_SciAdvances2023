clear; clc;
%% Add paths now..
loadpath;


%% Dataset details now..
datasetname = ['27072018_SponSleep']; %'',                  '27072018_SponSleep','14092018_SponSleep',
                                      %'17092018_SponSleep','30102018_SponSleep',
                                      %'01112018_SponSleep','03112018_SponSleep','13112018_SponSleep',
                                      %'28112018_SponSleep',
                                      %'11122018_SponSleep','13122018_SponSleep',
                                      %'18122018_SponSleep','10012019_SponSleep','17012019_SponSleep',
                                      %'22012019_SponSleep','20022019_SponSleep',
                                      %'13032019_SponSleep'
                                      
datasetname = [datasetname '_Calib'];
datasetpath = [pathappend 'SpatialAttention_Drowsiness/drosSleepStages_Datasettools_SciAdvances2023/temp/'];
outputpath = [pathappend 'SpatialAttention_Drowsiness/drosSleepStages_Datasettools_SciAdvances2023/temp/calibration/'];


%% Load the dataset now..
S = [];
S.eeg_filepath = datasetpath;
S.eeg_filename = datasetname;

evalexp = 'pop_loadset(''filename'', [S.eeg_filename ''.set''], ''filepath'', S.eeg_filepath);';

%load the EEGdata set..
[T,EEG] = evalc(evalexp);

%% Load the stimulus segments now..
Stimdata = EEG.data(17,:);
Lfpdata = EEG.data(1:16,:);

%stim segments with +/- 150 are marked as LED ON and OFF segments..
Startidx = find(Stimdata<=-140);

tempval = diff(Startidx);

%this is for identifying seperate stimulus segments..
%each stimulus segment consists of 3 ON and 3 OFF segments..
[~, tempidx] = find(tempval >1000);
tempidx = tempidx+1;

%collect only the last 5 trials..
tempstartpts = tempidx(end-4:end);

Startidx_val = Startidx(tempstartpts);


%% Load the datavalues now..
meanStimtrack =[];
seStimtrack =[];
meanlfp_channel = [];
selfp_channel =[];

Stimtrack_segs = [];
Timetrack_segs =[];
for idx = 1: 5
   Stimtrack_segs(idx,:) =  Stimdata(Startidx_val(idx)-50:Startidx_val(idx)+875);
   Timetrack_segs(idx,:) =  EEG.times(Startidx_val(idx)-50:Startidx_val(idx)+875);
end

meanStimtrack = mean(Stimtrack_segs);
seStimtrack = std(Stimtrack_segs)/sqrt(size(Stimtrack_segs,1));

for chanidx = 1:16
    lfp_channel = [];
    for idx = 1: 5
        lfp_channel(idx,:) =  smooth(Lfpdata(chanidx,Startidx_val(idx)-50:Startidx_val(idx)+875),10);
    end
    meanlfp_channel(chanidx,:) = mean(lfp_channel);
    selfp_channel(chanidx,:) = std(lfp_channel)/sqrt(size(lfp_channel,1));
end


S.outputdataset = [outputpath datasetname];
save(S.outputdataset,'meanStimtrack','seStimtrack', 'meanlfp_channel','selfp_channel');

tempval = [];
