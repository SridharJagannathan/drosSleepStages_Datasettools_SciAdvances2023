function data = TDTbin2mat_old(BLOCK_PATH)
%TDTBIN2MAT  TDT tank data extraction.
%   data = TDTbin2mat(BLOCK_PATH), where BLOCK_PATH is a string, retrieves 
%   all data from specified block directory in struct format.  This reads
%   the binary tank data and requires no Windows-based software.
%
%   data.epocs      contains all epoc store data (onsets, offsets, values)
%   data.snips      contains all snippet store data (timestamps, channels,
%                   and raw data)
%   data.streams    contains all continuous data (sampling rate and raw 
%                   data)
%   data.info       contains additional information about the block
%
%   data = TDTbin2mat(BLOCK_PATH,'parameter',value,...)
%
%   TODO: none of these do anything
%   'parameter', value pairs
%      'T1'         scalar, retrieve data starting at T1 (default = 0 for
%                       beginning of recording)
%      'T2'         scalar, retrieve data ending at T2 (default = 0 for end 
%                       of recording)
%      'SORTNAME'   string, specify sort ID to use when extracting snippets
%      'VERBOSE'    boolean, set to false to diable console output
%      'TYPE'       array of scalars, specifies what type of data stores to 
%                       retrieve from the tank
%                   1: all (default)
%                   2: epocs
%                   3: snips
%                   4: streams
%                   5: scalars
%                   example: 
%                       data = TDT2binmat('C:\TDT\OpenEx\Tanks\Demotank2\Block1\','Type',[1 2]);
%                           > returns only epocs and snips
%      'RANGES'     array of valid time range column vectors
% 

%{
// Demo program showing how to read tsq file and tev file, and
// OpenSorter's sort code file.

// tank file structure
//---------------------
// tbk file has block events information and on second time offsets
// to efficiently locate events if the data is queried by time.
//
// tsq file is a list of event headers, each 40 bytes long,
// ordered strictly by time .
//
// tev file contains event binary data
//
// tev and tsq files work together to get an event's data and
//     attributes
//
// tdx file contains just information about epoc stores,
// is optionally generated after recording for fast retrieval
// of epoc information
//
// OpenSorter sort codes file structure
// ------------------------------------
// Sort codes saved by OpenSorter are stored in block subfolders such as
// Block-3\sort\USERDEFINED\EventName.SortResult.
//
// .SortResult files contain sort codes for 1 to all channels within
// the selected block.  Each file starts with a 1024 byte boolean channel
// map indicating which channel's sort codes have been saved in the file.
// Following this map, is a sort code field that maps 1:1 with the event
// ID for a given block.  The event ID is essentially the Nth occurance of
// an event on the data collection timeline. See lEventID below.
%}

if isunix
  pathsep = '/';
else
  pathsep = '\';
end

% Tank event types (tsqEventHeader.type)
global EVTYPE_UNKNOWN EVTYPE_STRON EVTYPE_STROFF EVTYPE_SCALAR EVTYPE_STREAM  EVTYPE_SNIP;
global EVTYPE_MARK EVTYPE_HASDATA EVTYPE_UCF EVTYPE_PHANTOM EVTYPE_MASK EVTYPE_INVALID_MASK;
EVTYPE_UNKNOWN  = hex2dec('00000000');
EVTYPE_STRON    = hex2dec('00000101');
EVTYPE_STROFF	= hex2dec('00000102');
EVTYPE_SCALAR	= hex2dec('00000201');
EVTYPE_STREAM	= hex2dec('00008101');
EVTYPE_SNIP		= hex2dec('00008201');
EVTYPE_MARK		= hex2dec('00008801');
EVTYPE_HASDATA	= hex2dec('00008000');
EVTYPE_UCF		= hex2dec('00000010');
EVTYPE_PHANTOM	= hex2dec('00000020');
EVTYPE_MASK		= hex2dec('0000FF0F');
EVTYPE_INVALID_MASK	= hex2dec('FFFF0000');

EVMARK_STARTBLOCK	= hex2dec('0001');
EVMARK_STOPBLOCK	= hex2dec('0002');

global DFORM_FLOAT DFORM_LONG DFORM_SHORT DFORM_BYTE 
global DFORM_DOUBLE DFORM_QWORD DFORM_TYPE_COUNT
DFORM_FLOAT		 = 0;
DFORM_LONG		 = 1;
DFORM_SHORT		 = 2;
DFORM_BYTE		 = 3;
DFORM_DOUBLE	 = 4;
DFORM_QWORD		 = 5;
DFORM_TYPE_COUNT = 6;

ALLOWED_FORMATS = {'single','int32','int16','int8','double','int64'};
MAP = containers.Map(...
    0:length(ALLOWED_FORMATS)-1,...
    ALLOWED_FORMATS);

% % TTank event header structure
% tsqEventHeader = struct(...
%     'size', 0, ...
%     'type', 0, ...  % (long) event type: snip, pdec, epoc etc
%     'code', 0, ...  % (long) event name: must be 4 chars, cast as a long
%     'channel', 0, ... % (unsigned short) data acquisition channel
%     'sortcode', 0, ... % (unsigned short) sort code for snip data. See also OpenSorter .SortResult file.
%     'timestamp', 0, ... % (double) time offset when even occurred
%     'ev_offset', 0, ... % (int64) data offset in the TEV file OR (double) strobe data value
%     'format', 0, ... % (long) data format of event: byte, short, float (typical), or double
%     'frequency', 0 ... % (float) sampling frequency
% );

tsqList = dir([BLOCK_PATH '*.tsq']);
if length(tsqList) < 1
    error('no TSQ file found')
elseif length(tsqList) > 1
    error('multiple TSQ files found')
end

cTSQ = [BLOCK_PATH tsqList(1).name];
cTEV = [BLOCK_PATH strrep(tsqList(1).name, '.tsq', '.tev')];
%cTBK = [BLOCK_PATH strrep(tsqList(1).name, '.tsq', '.tbk')]

tsq = fopen(cTSQ, 'rb');
tev = fopen(cTEV, 'rb');
%tbk = fopen(cTBK, 'r');

if ~(tsq && tev)
    error('files could not be opened')
end

% read TBK notes to get event info
%s = fread(tbk, inf, '*char')'; fclose(tbk);
%sp = strsplit(s, '[USERNOTEDELIMITER]');
%notes = ParseNotes(sp{3})
%names = {notes.StoreName}

%codes = cellfun(@name2code, names)

% event type: snips, streams, epocs
%types = arrayfun(@code2type, cellfun(@str2num,{notes.TankEvType}), 'UniformOutput', false)

% single, int32, etc
%formats = arrayfun(@(x)MAP(x),cellfun(@str2num,{notes.DataFormat}), 'UniformOutput', false)

% byte size of each store
%bytes = arrayfun(@format2bytes, formats)

% number of channels and points, for preallocating
%nchans = cellfun(@str2num,{notes.NumChan})
%npts = cellfun(@str2num,{notes.NumPoints})

% read start time
fseek(tsq, 48, 'bof');  code1 = fread(tsq, 1, '*int32');
assert(code1 == EVMARK_STARTBLOCK);
fseek(tsq, 56, 'bof'); start_time = fread(tsq, 1, '*double');

% read stop time
fseek(tsq, -32, 'eof'); code2 = fread(tsq, 1, '*int32');
assert(code2 == EVMARK_STOPBLOCK);
fseek(tsq, -24, 'eof'); stop_time = fread(tsq, 1, '*double');

% total duration for data size estimation
duration_s = stop_time-start_time;

% read a few headers to get the relevant information we need to preallocate
% data arrays

data = struct('epocs', [], 'snips', [], 'streams', [], 'scalars', []);

tsqFileSize = fread(tsq, 1, '*int64');
fseek(tsq, 40, 'bof');

% get all possible store codes
%[i, c] = unique([bsq.code], 'stable')
%[i2, c2] = unique([bsq.code])

% get their names
%names = {bsq(c2).name}

% get their sizes
%sizes = double([bsq(c2).size])

% get their types
%types = [bsq(c2).type]

% get their header counts
%headerCounts = hist(double([bsq.code]), double(all_store_codes))

%estByteSizes = double([bsq(c2).size]).*headerCounts
% preallocate the arrays
%data = struct('epocs', [], 'snips', [], 'streams', []);
%estByteSizes = double([bsq(c2).size]).*headerCounts
%formats = {bsq(c2).format}
%bsq(ind).format = MAP(dform);

% use headers to read from tev files
% offset = 40;
% 
% bsq = memmapfile(cTSQ, ...
%     'Format', {...
%     'int32', 1, 'size';...
%     'int32', 1, 'type';...
%     'int32', 1, 'code';...
%     'uint16', 1, 'channel';...
%     'uint16', 1, 'sortcode';...
%     'double', 1, 'timestamp';...
%     'uint64', 1, 'ev_offset';...
%     'int32', 1, 'dform';...
%     'single', 1, 'frequency'}, 'Offset', offset, 'Repeat', inf);
% 

% read all headers into one giant array
heads = fread(tsq, Inf, '*int32');

% reshape so each column is one header
heads = reshape(heads, 10, numel(heads)/10);

% parse out the information we need
sizes = heads(1,2:end-1);
types = heads(2,2:end-1);
codes = heads(3,2:end-1);
x = typecast(heads(4, 2:end-1), 'uint16');
channels = x(1:2:end);
sortcodes = x(2:2:end);
clear x;

timestamps = typecast(reshape(heads(5:6, :), 1, numel(heads(5:6,:))), 'double');
starttime = timestamps(1);
timestamps = timestamps-starttime;
timestamps = timestamps(2:end); % throw out the first one

% which one you use depends on data type, cast both up front for speed
values = typecast(reshape(heads(7:8, :), 1, numel(heads(7:8,:))), 'double');
values = values(2:end); % throw out the first one
offsets = typecast(values, 'uint64');

names = char(typecast(codes, 'uint8'));
names = reshape(names, 4, numel(names)/4);
%access the name like this data.(type).(names(:,index)').data

dforms = heads(9,2:end-1); % I already know this information

freqs = typecast(heads(10,:), 'single');
freqs = freqs(2:end); % throw out first one

clear heads; % don't need this anymore

% get all possible codes, names, and types
[unique_codes, c] = unique(codes);
unique_names = names(:,c)';
unique_types = num2cell(types(c));
currentTypes = cellfun(@code2type, unique_types, 'UniformOutput', false);
currentDForms = dforms(c);

% loop through all possible stores
for i = 1:numel(unique_codes)
    
    % TODO: show similar verbose printout to TDT2mat
    % TODO: filter based on type
    % TODO: filter based on time
    currentCode = unique_codes(i);
    currentName = unique_names(i,:);
    currentType = currentTypes{i};
    currentDForm = currentDForms(i);
    fmt = 'unknown';
    sz = 4;
    switch currentDForm
        case DFORM_FLOAT
            fmt = 'single';
        case DFORM_LONG
            fmt = 'int32';
        case DFORM_SHORT
            fmt = 'int16';
            sz = 2;
        case DFORM_BYTE
            fmt = 'int8';
            sz = 1;
        case DFORM_DOUBLE
            fmt = 'double';
            sz = 8;
        case DFORM_QWORD
            fmt = 'int64';
            sz = 8;
    end
    
    % find the header indicies for this store
    ind = find(codes == currentCode);

    % load data struct based on the type
    if isequal(currentType, 'epocs')
        data.epocs.(currentName).data = values(ind)';
        if isoffset(currentType)
            % TODO: check this
            data.epocs.(currentName).offset = timestamps(ind)';
        else
            data.epocs.(currentName).onset = timestamps(ind)';
        end
        % make artificial offsets if there are none
        if ~isfield(data.epocs.(currentName), 'offset')
            data.epocs.(currentName).offset = [data.epocs.(currentName).onset(2:end); Inf];
        end
        data.epocs.(currentName).name = currentName;
    elseif isequal(currentType, 'scalars')
        nchan = double(max(channels(ind)));
        
        % preallocate data array
        data.scalars.(currentName).data = zeros(nchan, numel(ind)/nchan, fmt);
        
        % organize data array by channel
        for xx = 1:nchan
            data.scalars.(currentName).data(xx,:) = values(ind(channels(ind) == xx));
        end
        
        % only use channel 1 timestamps
        data.scalars.(currentName).ts = timestamps(ind(channels(ind) == 1));
        data.scalars.(currentName).name = currentName;
        %data.scalars.(currentName).fs = freqs(ind(1));
    elseif isequal(currentType, 'snips')
        all_offsets = double(offsets(ind));
        all_sizes = sizes(ind);
        
        % preallocate data array
        npts = (all_sizes(1)-10) * 4/sz;
        data.snips.(currentName).data = zeros(numel(ind), npts, fmt);
        
        % now fill it
        for f = 1:numel(ind)
            if fseek(tev, all_offsets(f), 'bof') == -1
                ferror(tev)
            end
            npts = (all_sizes(f)-10) * 4/sz;
            data.snips.(currentName).data(f,:) = fread(tev, npts, ['*' fmt]);
        end
        
        % load the rest of the info
        data.snips.(currentName).chan = channels(ind)';
        data.snips.(currentName).sortcode = sortcodes(ind)';
        data.snips.(currentName).ts = timestamps(ind)';
        data.snips.(currentName).name = currentName;
        data.snips.(currentName).sortname = 'TankSort'; % TODO add others
    elseif isequal(currentType, 'streams')
        all_offsets = double(offsets(ind));
        all_sizes = sizes(ind);
        
        nchan = double(max(channels(ind)));
        chan_index = ones(1,nchan);
        
        % preallocate data array
        npts = (all_sizes(1)-10) * 4/sz;
        data.streams.(currentName).data = zeros(nchan, npts*numel(ind)/nchan, fmt);

        % catch if the data is in SEV file
        sevList = dir([BLOCK_PATH '*.sev']);
        useSEVs = 0;
        for i = 1:length(sevList)
            if strfind(sevList(i).name, currentName) > 0
                useSEVs = 1;
            end
        end
        
        if useSEVs
            d = SEV2mat(BLOCK_PATH, 'VERBOSE', 0);
            data.streams.(currentName) = d.(currentName);
        else
                
            % now fill it
            for f = 1:numel(ind)
                if fseek(tev, all_offsets(f), 'bof') == -1
                    ferror(tev)
                end
                curr_chan = channels(ind(f));
                start = chan_index(curr_chan);
                npts = (all_sizes(f)-10) * 4/sz;
                try
                data.streams.(currentName).data(curr_chan,start:start+npts-1) = fread(tev, npts, ['*' fmt])';
                catch
                    tempval =[];
                end
                chan_index(curr_chan) = chan_index(curr_chan) + npts;
            end
        
            data.streams.(currentName).fs = freqs(ind(1));
            data.streams.(currentName).name = currentName;
        end
    end
end

if (tsq), fclose(tsq); end
if (tev), fclose(tev); end

end

function s = code2type(code)
%% given event code, return string 'epocs', 'snips', 'streams', or 'scalars'

global EVTYPE_STRON EVTYPE_STROFF EVTYPE_SCALAR EVTYPE_SNIP EVTYPE_MASK EVTYPE_STREAM;

strobeTypes = [EVTYPE_STRON EVTYPE_STROFF];
scalarTypes = [EVTYPE_SCALAR];
snipTypes = [EVTYPE_SNIP];

if ismember(code, strobeTypes)
    s = 'epocs';
elseif ismember(code, snipTypes)
    s = 'snips';
elseif bitand(code, EVTYPE_MASK) == EVTYPE_STREAM
    s = 'streams';
elseif ismember(code, scalarTypes)
    s = 'scalars';
else
    s = 'unknown';
end

end

function offset = isoffset(code)
    global EVTYPE_STROFF;
    offset = (code == EVTYPE_STROFF);
end