clc;
clear; 
%% Add paths now..
loadpath;


%% Dataset details now..
datasetname = ['06032019_SponSleep']; %'27072018_SponSleep','14092018_SponSleep',
                                      %'17092018_SponSleep','30102018_SponSleep',
                                      %'01112018_SponSleep','03112018_SponSleep','13112018_SponSleep',
                                      %'28112018_SponSleep',
                                      %'11122018_SponSleep','13122018_SponSleep','18122018_SponSleep',
                                      %'10012019_SponSleep','17012019_SponSleep','22012019_SponSleep',
                                      %'20022019_SponSleep',
                                      %'13032019_SponSleep'

session = ['lfp'];

if strcmp(session,'lfp')
    totalchunks = 12; %11,12
    datasetname = [datasetname '_LFP'];
else
    totalchunks = 1; 
    datasetname = [datasetname '_Calib'];
end

datasetpath =    [pathappend 'SpatialAttention_Drowsiness/drosSleepStages_Datasettools_SciAdvances2023/temp/'];
outputpath =     [pathappend 'SpatialAttention_Drowsiness/drosSleepStages_Datasettools_SciAdvances2023/temp/'];

%% Step1: Interpolate the data such that it covers the full second..

for chunkidx = 1: totalchunks

%% Load the dataset now..
S = [];
S.eeg_filepath = datasetpath;
S.eeg_filename = [datasetname  '_chunk_' char(sprintf('%0.2d',chunkidx))];

fprintf('Processing Chunk %d of %d..\n', chunkidx, totalchunks);

evalexp = 'pop_loadset(''filename'', [S.eeg_filename ''.set''], ''filepath'', S.eeg_filepath);';

%load the EEGdata set..
[T,EEG] = evalc(evalexp);

%% Load the reference dataset now..
S = [];
S.eeg_filepath = datasetpath;
S.eeg_filename = [datasetname  '_chunk_' char(sprintf('%0.2d',chunkidx+1))];

evalexp = 'pop_loadset(''filename'', [S.eeg_filename ''.set''], ''filepath'', S.eeg_filepath);';

%load the EEGdata set..
[T,EEG_ref] = evalc(evalexp);

if str2num(EEG.timestart(1:2)) > str2num(EEG_ref.timestart(1:2))
   EEG_ref.timestart(1:2) =  num2str(str2num(EEG_ref.timestart(1:2)) + 24);
   EEG_ref.timeend(1:2) =  num2str(str2num(EEG_ref.timeend(1:2)) + 24);
end

time_1stblockstart = str2num(EEG.timestart(1:2))*3600 + str2num(EEG.timestart(4:5))*60 + ...
                     str2num(EEG.timestart(7:8)) + str2num(EEG.timestart(10:12))*(10^-3);

time_refblockstart = str2num(EEG_ref.timestart(1:2))*3600 + str2num(EEG_ref.timestart(4:5))*60 + ...
                     str2num(EEG_ref.timestart(7:8)) + str2num(EEG_ref.timestart(10:12))*(10^-3);

%timeduration = ceil(EEG.xmax);
timeduration = time_refblockstart - time_1stblockstart; %each block should ideally be of 3601 secs, but some can be larger..
samplespersec = 1000/EEG.srate;
timeseries = 0: samplespersec: (timeduration-samplespersec/1000)*1000;

fprintf('Block %d start time: %s\n',chunkidx,EEG.timestart);
fprintf('Block %d end time: %s\n',chunkidx,EEG.timeend);
fprintf('Block %d duration of (s): %0.2f\n',chunkidx, EEG.xmax);

timeduration_ref = round(EEG_ref.xmax);
timeseries_ref = timeduration*1000: samplespersec: (timeduration + EEG_ref.xmax)*1000;

%% Interpolate now channel by channel..
chandata = double(EEG.data);
refdata = double(EEG_ref.data);

interpolatedchandata = [];
interpolatedduration = [];

for chanidx = 1: EEG.nbchan
    
    
    
    tmpchandata = nan(1,length(timeseries));
    if length(chandata(chanidx,:)) > length(timeseries)
        tmpchandata(1:length(timeseries)) = chandata(chanidx,1:length(timeseries));
    else
        tmpchandata(1:length(EEG.times)) = chandata(chanidx,:);
    end
    
    tmpchandata = [tmpchandata  refdata(chanidx,:)];
    tmptimeseries = [timeseries  timeseries_ref];
    
    if chanidx == 1
        fprintf('Interpolated timepoints duration: %d (ms)\n',sum(isnan(tmpchandata))*4);
        interpolatedduration = sum(isnan(tmpchandata))*4/1000;
    end
    
    querytimepoints = tmptimeseries(isnan(tmpchandata));
    tmptimeseries(isnan(tmpchandata)) =[];
    tmpchandata(isnan(tmpchandata)) =[];
    
    vq = interp1(tmptimeseries, tmpchandata,querytimepoints);
    
    if length(chandata(chanidx,:)) > length(timeseries)
        interpolatedchandata(chanidx,:) = [chandata(chanidx,1:length(timeseries)) vq];
    else
        interpolatedchandata(chanidx,:) = [chandata(chanidx,:) vq];
    end
    
end

%% Save the data now in the EEGlab file..
EEG.data = interpolatedchandata;

EEG.setname = [EEG.filename(1:end-4) '_interp'];
EEG.filename = [EEG.setname];
EEG.filepath = [];
EEG.times  = timeseries;


if interpolatedduration < 1 %if the interpolated duration is less than 1 sec

    %to compute the millisecond duration..
    tmpendtime =  str2num(EEG.timeend(10:end))/1000;
    tmpendtime = tmpendtime + timeduration - str2num(EEG.duration)- 1/(EEG.srate);
    if (tmpendtime<0) %this happens when the timing between the adjacent blocks overlap..
        fprintf('Reduced block %d duration: %s (s)\n',chunkidx, num2str(abs(tmpendtime)));
        tmpendtime =  str2num(EEG.timeend(7:end));
        tmpendtime = tmpendtime + timeduration - str2num(EEG.duration)- 1/(EEG.srate);
        tmpstr = num2str(tmpendtime);
        EEG.timeend(end-(length(tmpstr)-1):end) = tmpstr;
        
        
    else
        tmpstr = num2str(tmpendtime);
        EEG.timeend(end-2:end) = tmpstr(end-2:end);
    end
                                              
else
    
     %to compute the second duration..
     tmpendtime =  str2num(EEG.timeend(7:end));
     tmpendtime = tmpendtime + timeduration - str2num(EEG.duration)- 1/(EEG.srate);
     tmpstr = num2str(tmpendtime);
     EEG.timeend(end-(length(tmpstr)-1):end) = tmpstr;
    
end


EEG.xmin = min(EEG.times);
EEG.xmax = max(EEG.times/1000); %in secs..
EEG.pnts = length(EEG.data);

EEG.duration = num2str(timeduration);

evalexp = 'eeg_checkset(EEG)';
[T,EEG] = evalc(evalexp);

S.eeg_filename = EEG.filename;
S.output_folder  = outputpath;

fprintf('Saving to %s\n',[S.eeg_filename]);
pop_saveset(EEG,'filepath',S.output_folder,'filename',[S.eeg_filename '.set']);

fprintf('Interpolated block %d start time: %s\n',chunkidx,EEG.timestart);
fprintf('Interpolated block %d end time: %s\n',chunkidx,EEG.timeend);
fprintf('Interpolated block %d duration: %s (s)\n',chunkidx, EEG.duration);

tempval = [];

end

tempval = [];