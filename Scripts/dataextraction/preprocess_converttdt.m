
clc; 
clear;

%% Load all paths here..
loadpath;

%% Dataset path here..

S.tdtdataset = ['02_27072018_SponSleep']; % '02_27072018_SponSleep','03_14092018_SponSleep', 
                                          % '04_17092018_SponSleep','06_30102018_SponSleep',
                                          % '07_01112018_SponSleep','08_03112018_SponSleep', '09_13112018_SponSleep',
                                          % '12_28112018_SponSleep',
                                          % '14_11122018_SponSleep','15_13122018_SponSleep',
                                          % '16_18122018_SponSleep','17_10012019_SponSleep', '18_17012019_SponSleep',
                                          % '19_22012019_SponSleep','21_20022019_SponSleep',
                                          % '23_13032019_SponSleep'
                                          

%is it a full length single tdt file?
fulllength_file = 'no'; %'no','yes' 


%comment the specific line, whether you are extracting calibration or lfp itself
%session = ['calib'];
session = ['lfp'];

S.tdtdataset_filepath = [pathappend 'SpatialAttention_Drowsiness/SleepOnset_Drosophila/multichannel/dryad_upload/DrosSponSleep_SciAdvances2023_01/'];

S.output_filepath = [pathappend 'SpatialAttention_Drowsiness/drosSleepStages_Datasettools_SciAdvances2023/temp/'];


if strcmp(session,'lfp')
    totalchunks = 13;
    S.tdtdataset_filename = [S.tdtdataset(4:end) '_LFP'];
else
    totalchunks = 1; 
    S.tdtdataset_filename = [S.tdtdataset(4:end) '_Calib'];
end


S.logfile = [S.output_filepath filesep S.tdtdataset_filename '_raw_log.txt'];
diary(S.logfile);
fprintf('---The log started at %s ----',datestr(now));%Displaying this for the log file..


for chunkidx = 1: totalchunks
    
%% Step 1: Extract data in segments of 1 hour each..

    blockname = ['Block-' char(sprintf('%d',chunkidx))];
    
    if (strcmp(fulllength_file,'yes'))
        blockname = ['Block-' char(sprintf('%d',1))]; %only one block..
    end
    
    blockpath = [S.tdtdataset_filepath S.tdtdataset '_LFP' filesep 'lfp' filesep S.tdtdataset_filename filesep blockname];
    
    %unzip the file now..
    if strcmp(session,'lfp')
        zipfile = [blockpath '.zip'];
        tmpfilepath = [S.tdtdataset_filepath S.tdtdataset '_LFP' filesep 'lfp' filesep S.tdtdataset_filename];
        sysstrng = ['unzip ' zipfile ' -d ' tmpfilepath];
        fprintf('\n');
        [status, cmdout]=system(sysstrng,'-echo');
        fprintf('\n');
        
    end
    
    %check the timeduration to start and end..
    [timeduration, info] = TDTduration(blockpath);
    
    fprintf('\nReading file %s..\n',blockpath);
    
    fprintf('Reading Block %d of %d..\n', chunkidx, totalchunks);

    fprintf('Total time duration of recording is: %0.2f secs..\n', timeduration);
    
    starttime = 0;
    
    if (strcmp(fulllength_file,'yes'))
        starttime_block = (chunkidx-1)*3600 + 120;
        endtime_block = starttime_block+3600;
        fprintf('Data extracted from %d (s) to %d (s)\n', starttime_block, endtime_block);
        data = TDTbin2mat(blockpath, 'T1', starttime_block, 'T2', endtime_block);
     else
        data = TDTbin2mat(blockpath);
    end
    
    %Delete the zip file now..
    if strcmp(session,'lfp')
        tmpfoldername = [S.tdtdataset_filepath S.tdtdataset '_LFP' filesep 'lfp' filesep...
                         S.tdtdataset_filename filesep 'temp_' blockname];
        sysstrng = ['mv ' blockpath ' ' tmpfoldername];
        [status, cmdout]=system(sysstrng,'-echo');
        sysstrng = ['rm -rf ' tmpfoldername];
        [status, cmdout]=system(sysstrng);
    end
    
    chandata = data.streams.Wave.data;

    %only the first row has data about the LEDs ON status..
    stimdata = data.streams.InpP.data(1,:);

    %now just to do some remapping of stimulus resampling..
    remapidx = find(abs(stimdata(1,:))<1000000);
    stimdata(1,remapidx) = 0;
    remapidx = find(stimdata(1,:)<-1000000);
    stimdata(1,remapidx) = -150;
    remapidx = find(stimdata(1,:)>1000000);
    stimdata(1,remapidx) = 150;
    
    
    %set the starttime in the eeglab struct..
    if (strcmp(fulllength_file,'yes'))
        eegtimestart = info.headerstarttime + starttime_block;
    else
        eegtimestart = info.headerstarttime + starttime;
    end
    
%% Step 2:  Downsample the data..

inputfreq = data.streams.Wave.fs;% Actual Sampling Frequency
inputsamplerate = 1/inputfreq;

resamplefreq = 250; %resample to 250 Hz..% Desired Sampling Frequency
%[N,D] = rat(resamplefreq/inputfreq, 0.0001); % Rational Fraction Approximation

Tx = 0:inputsamplerate:(inputsamplerate*length(chandata)-inputsamplerate);

for idx = 1: size(chandata,1)
    %chandata_resamp(idx,:) = resample(double(chandata(idx,:)), N, D);% Resampled Signal 
    chandata_resamp(idx,:) = resample(double(chandata(idx,:)), Tx, resamplefreq);% Resampled Signal 
end


inputfreq = data.streams.InpP.fs;% Actual Sampling Frequency
inputsamplerate = 1/inputfreq;
%[N,D] = rat(resamplefreq/inputfreq); % Rational Fraction Approximation

Tx = 0:inputsamplerate:(inputsamplerate*length(stimdata)-inputsamplerate);

for idx = 1: size(stimdata,1)
    %stimdata_resamp(idx,:) = resample(double(stimdata(idx,:)), N, D);% Resampled Signal  
    stimdata_resamp(idx,:) = resample(double(stimdata(idx,:)), Tx, resamplefreq);% Resampled Signal
end

%recorded data duration..
fprintf('Duration as per header: %0.2f (s)\n',timeduration);
%actual data duration..
fprintf('Duration as per actual data (before resampling): %0.2f (s)\n',(1/data.streams.Wave.fs)*length(chandata));

clear chandata stimdata data

if strcmp(session,'lfp')
    LFP = [chandata_resamp];
else
    
    %stimdata_resamp = stimdata_resamp(1:length(chandata_resamp)); %for '22112018_SponSleep_Calib'
    %stimdata_resamp = stimdata_resamp(1:length(chandata_resamp)); %for '18122018_SponSleep_Calib'
    %stimdata_resamp = stimdata_resamp(1:length(chandata_resamp)); %for  '06032019_SponSleep_Calib'
    LFP = [chandata_resamp; stimdata_resamp];
    
end

clear chandata_resamp

fprintf('Duration as per actual data (after resampling): %0.2f (s)\n',(1/resamplefreq)*length(LFP));


if abs(timeduration - (1/resamplefreq)*length(LFP)) > 1 && (strcmp(fulllength_file,'no'))
   warning('header and actual data duration differ');  
end
 
endtime = (1/resamplefreq)*length(LFP);

%% Step 3:  Store it in a EEGlab file..
samplerate = resamplefreq; 
timeres = 1/samplerate;
Tottime = endtime - starttime - timeres;
timepoints = 0: timeres :Tottime;

%% Step 4: Create EEGlab file for LfP data..
EEG = [];
EEG.setname = [S.tdtdataset_filename '_' blockname];
EEG.filename = [S.tdtdataset_filename '_' blockname];
EEG.filepath = [];
EEG.nbchan = size(LFP,1);
EEG.chanlocs(1).labels = 'LfP';
EEG.data = double(LFP);
EEG.times  = timepoints;
EEG.xmax = max(EEG.times);
EEG.xmin = min(EEG.times);
EEG.pnts = length(LFP);

EEG.icawinv =[];
EEG.icaweights =[];
EEG.icasphere =[];
EEG.icaact = [];
EEG.trials = 1;
EEG.srate = samplerate;
EEG.event = [];


evalexp = 'eeg_checkset(EEG)';
[T,EEG] = evalc(evalexp);

% filter the data now..
evalexp = 'pop_eegfiltnew(EEG, 0.5, 0);';
[T,EEG] = evalc(evalexp);

evalexp = 'pop_eegfiltnew(EEG, 0, 40);';
[T,EEG] = evalc(evalexp);

%Remove the line noise
linefreq = 50;
fprintf('Notch filtering at %dHz...\n',linefreq);

evalexp = 'pop_eegfiltnew(EEG,linefreq-2,linefreq+2,[],1);';
[T,EEG] = evalc(evalexp);

evalexp = 'pop_eegfiltnew(EEG,(linefreq*2)-2,(linefreq*2)+2,[],1);';
[T,EEG] = evalc(evalexp);




if (strcmp(fulllength_file,'yes'))
    eegtimeend = info.headerstarttime + starttime_block + EEG.xmax;
else
    eegtimeend = info.headerstarttime + EEG.xmax;
end

%to compute the millisecond duration..
tmpval = datestr(datenum([1970, 1, 1, 0, 0, eegtimestart]),'HH:MM:SS.FFF');
startms = tmpval(end-2:end);
tmpval = datestr(datenum([1970, 1, 1, 0, 0, eegtimestart+EEG.xmax]),'HH:MM:SS.FFF');
endms = tmpval(end-2:end);

tmpval = datestr(datenum([1970, 1, 1, 0, 0, eegtimestart]),'HH:MM:SS');
d = datetime(tmpval,'TimeZone','UTC');
d.TimeZone = 'Australia/Brisbane';
eegtimestart = datestr(d,'HH:MM:SS.FFF');

tmpval = datestr(datenum([1970, 1, 1, 0, 0, eegtimeend]),'HH:MM:SS');
d = datetime(tmpval,'TimeZone','UTC');
d.TimeZone = 'Australia/Brisbane';
eegtimeend = datestr(d,'HH:MM:SS.FFF');

%add the millisecond duration now..
eegtimestart(end-2:end) = startms;
eegtimeend(end-2:end) = endms;

EEG.timestart = eegtimestart;
EEG.timeend = eegtimeend;

if (str2num(eegtimestart(1:2))>str2num(eegtimeend(1:2))) %check if there is a roll-over in time
    eegtimeend(1:2) = '24'; %change the time to avoid negative duration
end

tmpstarttime = str2num(eegtimestart(1:2))*60*60 +...
               str2num(eegtimestart(4:5))*60    +...
               str2num(eegtimestart(7:8))*1     +...
               str2num(eegtimestart(10:end))/1000;

           
tmpendtime =   str2num(eegtimeend(1:2))*60*60 +...
               str2num(eegtimeend(4:5))*60    +...
               str2num(eegtimeend(7:8))*1     +...
               str2num(eegtimeend(10:end))/1000;
           
tmpduration = (tmpendtime-tmpstarttime);
 if (abs(Tottime - tmpduration)*1000 < 1) %check if the duration difference > 1 ms..
    EEG.duration = num2str(tmpendtime-tmpstarttime);
 else
     error('The durations dont match');
 end
          

if strcmp(session,'calib')
    EEG.data(17,:) = stimdata_resamp;
end

fprintf('Block %d start time: %s\n',chunkidx,EEG.timestart);
fprintf('Block %d end time: %s\n',chunkidx,EEG.timeend);
fprintf('Block %d duration of : %s (s)\n',chunkidx, EEG.duration);
    

%%  Step 5: Create EEGlab file for LfP data..
dataset_filename = S.tdtdataset_filename;
outputfolder = S.output_filepath;

%S = [];
if strcmp(session,'calib')
    S.eeg_filename = [dataset_filename];
else
    S.eeg_filename = [dataset_filename  '_chunk_' char(sprintf('%0.2d',chunkidx))];
end
S.output_folder  = outputfolder;

fprintf('Saving to %s.set.\n',[S.eeg_filename]);
pop_saveset(EEG,'filepath',S.output_folder,'filename',[S.eeg_filename '.set']);

clear EEG stimdata_resamp LFP

end

fprintf('---The log ended at %s ----',datestr(now));%Displaying this for the log file..

diary('off');

tempval = [];

