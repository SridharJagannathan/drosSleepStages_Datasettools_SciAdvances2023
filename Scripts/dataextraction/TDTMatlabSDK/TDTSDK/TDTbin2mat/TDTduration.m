function [lastTS , info] = TDTduration(BLOCK_PATH, varargin)
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
%   data.scalars    contains all scalar data (samples and timestamps)
%   data.info       contains additional information about the block
%
%   'parameter', value pairs
%        'T1'         scalar, retrieve data starting at T1 (default = 0 for
%                         beginning of recording)
%        'T2'         scalar, retrieve data ending at T2 (default = 0 for end
%                         of recording)
%        'SORTNAME'   string, specify sort ID to use when extracting snippets
%        'TYPE'       array of scalars or cell array of strings, specifies
%                         what type of data stores to retrieve from the tank
%                     1: all (default)
%                     2: epocs
%                     3: snips
%                     4: streams
%                     5: scalars
%                     TYPE can also be cell array of any combination of
%                         'epocs', 'streams', 'scalars', 'snips', 'all'
%                     examples:
%                         data = TDTbin2mat('MyTank','Block-1','TYPE',[1 2]);
%                             > returns only epocs and snips
%                         data = TDTbin2mat('MyTank','Block-1','TYPE',{'epocs','snips'});
%                             > returns only epocs and snips
%      'RANGES'     array of valid time range column vectors
%      'NODATA'     boolean, only return timestamps, channels, and sort 
%                       codes for snippets, no waveform data (default = false)
%      'STORE'      string, specify a single store to extract
%      'CHANNEL'    integer, choose a single channel, to extract from
%                       stream or snippet events. Default is 0, to extract
%                       all channels.
%      'BITWISE'    string, specify an epoc store or scalar store that 
%                       contains individual bits packed into a 32-bit 
%                       integer. Onsets/offsets from individual bits will
%                       be extracted.
%      'HEADERS'    var, set to 1 to return only the headers for this
%                       block, so that you can make repeated calls to read
%                       data without having to parse the TSQ file every
%                       time. Or, pass in the headers using this parameter.
%                   example:
%                       heads = TDTbin2mat(BLOCK_PATH, 'HEADERS', 1);
%                       data = TDTbin2mat(BLOCK_PATH, 'HEADERS', heads, 'TYPE', {'snips'});
%                       data = TDTbin2mat(BLOCK_PATH, 'HEADERS', heads, 'TYPE', {'streams'});
%      'COMBINE'    cell, specify one or more data stores that were saved 
%                       by the Strobed Data Storage gizmo in Synapse (or an
%                       Async_Stream_Store macro in OpenEx). By default,
%                       the data is stored in small chunks while the strobe
%                       is high. This setting allows you to combine these
%                       small chunks back into the full waveforms that were
%                       recorded while the strobe was enabled.
%                   example:
%                       data = TDTbin2mat(BLOCK_PATH, 'COMBINE', {'StS1'});
%

% defaults
BITWISE  = '';
CHANNEL  = 0;
COMBINE  = {};
HEADERS  = 0;
NODATA   = false;
RANGES   = [];
STORE    = '';
T1       = 0;
T2       = 0;
TYPE     = 1:5;
VERBOSE  = 0;
SORTNAME = 'TankSort';

VALID_PARS = {'BITWISE','CHANNEL','HEADERS','NODATA','RANGES','STORE', ...
    'T1','T2','TYPE','VERBOSE','SORTNAME','COMBINE'};

% parse varargin
for ii = 1:2:length(varargin)
    if ~ismember(upper(varargin{ii}), VALID_PARS)
        error('%s is not a valid parameter. See help TDTbin2mat.', upper(varargin{ii}));
    end
    eval([upper(varargin{ii}) '=varargin{ii+1};']);
end

ALLOWED_TYPES = {'ALL','EPOCS','SNIPS','STREAMS','SCALARS'};

if iscell(TYPE)
    types = zeros(1, numel(TYPE));
    for ii = 1:numel(TYPE)
        ind = find(strcmpi(ALLOWED_TYPES, TYPE{ii}));
        if isempty(ind)
            error('Unrecognized type: %s\nAllowed types are: %s', TYPE{ii}, sprintf('%s ', ALLOWED_TYPES{:}))
        end
        if ind == 1
            types = 1:5;
            break;
        end
        types(ii) = ind;
    end
    TYPE = unique(types);
else
    if ~isnumeric(TYPE), error('TYPE must be a scalar, number vector, or cell array of strings'), end
    if TYPE == 1, TYPE = 1:5; end
end

useOutsideHeaders = 0;
doHeadersOnly = 0;
if isa(HEADERS, 'struct')
    useOutsideHeaders = 1;
    headerStruct = HEADERS;
    clear HEADERS;
else
    headerStruct = struct();
    if HEADERS == 1
        doHeadersOnly = 1;
    end
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

if strcmp(BLOCK_PATH(end), '\') ~= 1 && strcmp(BLOCK_PATH(end), '/') ~= 1
    BLOCK_PATH = [BLOCK_PATH filesep];
end

if ~useOutsideHeaders
    tsqList = dir([BLOCK_PATH '*.tsq']);
    if length(tsqList) < 1
        if ~exist(BLOCK_PATH, 'dir')
            error('block path %s not found', BLOCK_PATH)
        end
        warning('no TSQ file found, attempting to read SEV files')
        data = SEV2mat(BLOCK_PATH, varargin{:});
        return
    elseif length(tsqList) > 1
        error('multiple TSQ files found')
    end
    
    cTSQ = [BLOCK_PATH tsqList(1).name];
    tsq = fopen(cTSQ, 'rb');
    if tsq < 0
        error('TSQ file could not be opened')
    end
    headerStruct.tevPath = [BLOCK_PATH strrep(tsqList(1).name, '.tsq', '.tev')];
end

if ~doHeadersOnly
    tev = fopen(headerStruct.tevPath, 'rb');
    if tev < 0
        error('TEV file could not be opened')
    end
end

% look for epoch tagged notes
tntPath = strrep(headerStruct.tevPath, '.tev', '.tnt');
noteStr = {};
try
    tnt = fopen(tntPath, 'rt');
    % get file version in first line
    fgetl(tnt);
    ind = 1;
    while ~feof(tnt)
        noteStr{ind} = fgetl(tnt);
        ind = ind + 1;
    end
    fclose(tnt);
catch
    %warning('TNT file could not be processed')
end

customSortEvent = '';
customSortChannelMap = zeros(1,1024);
customSortCodes = [];

% look for SortIDs
if ismember(3, TYPE) && ~strcmp(SORTNAME, 'TankSort')
    sortIDs = struct();
    sortIDs.fileNames = {};
    sortIDs.event = {};
    sortIDs.sortID = {};
    
    SORT_PATH = [BLOCK_PATH 'sort'];
    sortFolders = dir(SORT_PATH);
    
    ind = 1;
    for ii = 3:numel(sortFolders)
        if sortFolders(ii).isdir
            % parse sort result file name
            sortFile = dir([SORT_PATH filesep sortFolders(ii).name filesep '*.SortResult']);
            periodInd = strfind(sortFile(1).name, '.');
            sortIDs.event{ind} = '';
            if ~isempty(periodInd)
                sortIDs.event{ind} = sortFile(1).name(1:periodInd(end)-1);
            end
            sortIDs.fileNames{ind} = [[SORT_PATH filesep sortFolders(ii).name] filesep sortFile(1).name];
            sortIDs.sortID{ind} = sortFolders(ii).name;
            ind = ind + 1;
        end
    end
    
    % OpenSorter sort codes file structure
    % ------------------------------------
    % Sort codes saved by OpenSorter are stored in block subfolders such as
    % Block-3\sort\USERDEFINED\EventName.SortResult.
    %
    % .SortResult files contain sort codes for 1 to all channels within
    % the selected block.  Each file starts with a 1024 byte boolean channel
    % map indicating which channel's sort codes have been saved in the file.
    % Following this map, is a sort code field that maps 1:1 with the event
    % ID for a given block.  The event ID is essentially the Nth occurance of
    % an event on the entire TSQ file.
    
    % look for the exact one
    [lia, loc] = ismember(SORTNAME, sortIDs.sortID);
    if ~lia
        warning('SortID: %s not found\n', SORTNAME);
    else
        fprintf('Using SortID: %s for event: %s\n', SORTNAME, sortIDs.event{loc});
        customSortEvent = sortIDs.event{loc};
        fid = fopen(sortIDs.fileNames{loc}, 'rb');
        customSortChannelMap = fread(fid, 1024);
        customSortCodes = uint16(fread(fid, Inf, '*char'));
        fclose(fid);
    end
end

%{
 tbk file has block events information and on second time offsets
 to efficiently locate events if the data is queried by time.

 tsq file is a list of event headers, each 40 bytes long, ordered strictly
 by time.

 tev file contains event binary data

 tev and tsq files work together to get an event's data and attributes

 tdx file contains just information about epoc stores,
 is optionally generated after recording for fast retrieval
 of epoc information
%}

% read TBK notes to get event info
tbkPath = strrep(headerStruct.tevPath, '.tev', '.Tbk');
blockNotes = parseTBK(tbkPath);

if ~useOutsideHeaders
    % read start time
    file_size = fread(tsq, 1, '*int64');
    fseek(tsq, 48, 'bof');
    code1 = fread(tsq, 1, '*int32');
    assert(code1 == EVMARK_STARTBLOCK, 'Block start marker not found');
    fseek(tsq, 56, 'bof');
    headerStruct.startTime = fread(tsq, 1, '*double');
    
    % read stop time
    fseek(tsq, -32, 'eof');
    code2 = fread(tsq, 1, '*int32');
    if code2 ~= EVMARK_STOPBLOCK
        warning('Block end marker not found');
        headerStruct.stopTime = nan;
    else
        fseek(tsq, -24, 'eof');
        headerStruct.stopTime = fread(tsq, 1, '*double');
    end
end

data = struct('epocs', [], 'snips', [], 'streams', [], 'scalars', []);

% set info fields
[data.info.tankpath, data.info.blockname] = fileparts(BLOCK_PATH(1:end-1));
data.info.date = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.startTime]),'yyyy-mmm-dd');
if ~isnan(headerStruct.startTime)
    data.info.utcStartTime = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.startTime]),'HH:MM:SS');
    
    %change to brisbane/australia time zone.. %modified by Sri..
    tmpval = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.startTime]),'HH:MM:SS');
    d = datetime(tmpval,'TimeZone','UTC');
    d.TimeZone = 'Australia/Brisbane';
    data.info.utcStartTime = datestr(d,'HH:MM:SS');
    data.info.headerstarttime = headerStruct.startTime;
    
    
    
else
    data.info.utcStartTime = nan;
end
if ~isnan(headerStruct.stopTime)
    data.info.utcStopTime = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.stopTime]),'HH:MM:SS');
    
    %change to brisbane/australia time zone.. %modified by Sri..
    tmpval = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.stopTime]),'HH:MM:SS');
    d = datetime(tmpval,'TimeZone','UTC');
    d.TimeZone = 'Australia/Brisbane';
    data.info.utcStopTime = datestr(d,'HH:MM:SS');
    data.info.headerstoptime = headerStruct.stopTime;
else
    data.info.utcStopTime = nan;
end

s1 = datenum([1970, 1, 1, 0, 0, headerStruct.startTime]);
s2 = datenum([1970, 1, 1, 0, 0, headerStruct.stopTime]);
if headerStruct.stopTime > 0
    data.info.duration = datestr(s2-s1,'HH:MM:SS');
end
data.info.streamChannel = CHANNEL;
data.info.snipChannel = CHANNEL;

% look for Synapse recording notes
notesTxtPath = [BLOCK_PATH 'Notes.txt'];
noteTxtLines = {};
try
    txt = fopen(notesTxtPath, 'rt');
    ind = 1;
    while ~feof(txt)
        noteTxtLines{ind} = fgetl(txt);
        ind = ind + 1;
    end
    fclose(txt);
    fprintf('Found Synapse note file: %s\n', notesTxtPath);
catch
    %warning('Synapse Notes file could not be processed')
end

NoteText = {};
if ~isempty(noteTxtLines)
    targets = {'Experiment','Subject','User','Start','Stop'};
    NoteText = cell(numel(noteTxtLines),1);
    noteInd = 1;
    for n = 1:numel(noteTxtLines)
        noteLine = noteTxtLines{n};
        if isempty(noteLine)
            continue
        end
        bTargetFound = false;
        for t = 1:length(targets)
            testStr = [targets{t} ':'];
            eee = length(testStr);
            if length(noteLine) >= eee + 2
                if strcmp(noteLine(1:eee), testStr)
                    data.info.(targets{t}) = noteLine(eee+2:end);
                    bTargetFound = true;
                    break
                end
            end
        end
        if bTargetFound
            continue
        end

        % look for actual notes
        testStr = 'Note-';
        eee = length(testStr);
        if length(noteLine) >= eee + 2
            if strcmp(noteLine(1:eee), testStr)
                noteInd = str2double(noteLine(strfind(noteLine,'-')+1:strfind(noteLine,':')-1));
                noteIdentifier = noteLine(strfind(noteLine, '[')+1:strfind(noteLine,']')-1);
                if strcmp(noteIdentifier, 'none')
                    quotes = strfind(noteLine, '"');
                    NoteText{noteInd} = noteLine(quotes(1)+1:quotes(2)-1);
                else
                    NoteText{noteInd} = noteIdentifier;
                end            
            end
        end
    end
    NoteText = NoteText(1:noteInd);
end

epocs = struct;
epocs.name = {};
epocs.buddies = {};
epocs.ts = {};
epocs.code = {};
epocs.type = {};
epocs.typeStr = {};
epocs.data = {};
epocs.dform = {};

notes = struct;
notes.name = {};
notes.index = {};
notes.ts = {};

if ~useOutsideHeaders
    %tsqFileSize = fread(tsq, 1, '*int64');
    fseek(tsq, 40, 'bof');
    
    loopCt = 0;
    if T2 > 0
        % make the reads shorter if we are stopping early
        readSize = 10000000;
    else
        readSize = 50000000;
    end
    
    % map store code to other info
    headerStruct.stores = struct();
    while ~feof(tsq)
        loopCt = loopCt + 1;
        
        % read all headers into one giant array
        heads = fread(tsq, readSize*4, '*uint8');
        heads = typecast(heads, 'uint32');
        
        % reshape so each column is one header
        if mod(numel(heads), 10) ~= 0
            warning('block did not end cleanly, removing last %d headers', mod(numel(heads), 10))
            heads = heads(1:end-mod(numel(heads), 10));
        end
        heads = reshape(heads, 10, []);
        
        % check the codes first and build store maps and note arrays
        codes = heads(3,:);
        
        % find unique stores and a pointed to one of their headers
        sortedCodes = sort(codes);
        uniqueCodes = sortedCodes([true,diff(sortedCodes)>0]);
        temp = zeros(size(uniqueCodes));
        for ii = 1:numel(uniqueCodes)
            temp(ii) = find(codes == uniqueCodes(ii), 1);
        end
        [sortedCodes, y] = sort(temp);
        
        % process them in the order they appear in the block though
        uniqueCodes = uniqueCodes(y);
        
        storeTypes = cell(1, numel(uniqueCodes));
        goodStoreCodes = [];
        for x = 1:numel(uniqueCodes)
            if uniqueCodes(x) == EVMARK_STARTBLOCK || uniqueCodes(x) == EVMARK_STOPBLOCK
                continue;
            end
            if uniqueCodes(x) == 0
                warning('skipping unknown header code 0.')
                continue
            end
            
            name = char(typecast(uniqueCodes(x), 'uint8'));
            
            % if looking for a particular store and this isn't it, skip it
            if ~strcmp(STORE, '') && ~strcmp(STORE, name), continue; end
            
            varName = fixVarName(name);
            storeTypes{x} = code2type(heads(2,sortedCodes(x)));
            
            % do store type filter here
            bUseStore = false;
            if ~any(TYPE == 1)
                for ii = 1:numel(TYPE)
                    if strcmpi(ALLOWED_TYPES{TYPE(ii)}, storeTypes{x})
                        bUseStore = true;
                    end
                end
            else
                bUseStore = true;
            end
            if ~bUseStore
                continue;
            else
                goodStoreCodes = union(goodStoreCodes, uniqueCodes(x));
            end
            
            if strcmp(storeTypes{x}, 'epocs')
                if ~ismember(name, epocs.name)
                    temp = typecast(heads(4, sortedCodes(x)), 'uint16');
                    buddy1 = char(typecast(temp(1), 'uint8'));
                    buddy2 = char(typecast(temp(2), 'uint8'));
                    epocs.name = [epocs.name {name}];
                    epocs.buddies = [epocs.buddies {[buddy1 buddy2]}];
                    epocs.code = [epocs.code {uniqueCodes(x)}];
                    epocs.ts = [epocs.ts {[]}];
                    epocs.type = [epocs.type {epoc2type(heads(2,sortedCodes(x)))}];
                    epocs.typeStr = [epocs.typeStr storeTypes(x)];
                    epocs.typeNum = 2;
                    epocs.data = [epocs.data {[]}];
                    epocs.dform = [epocs.dform {heads(9,sortedCodes(x))}];
                end
            end
            
            % add store information to store map
            if ~isfield(headerStruct.stores, varName)
                if ~strcmp(storeTypes{x}, 'epocs')
                    headerStruct.stores.(varName) = struct();
                    headerStruct.stores.(varName).name = name;
                    headerStruct.stores.(varName).code = uniqueCodes(x);
                    headerStruct.stores.(varName).size = heads(1,sortedCodes(x));
                    headerStruct.stores.(varName).type = heads(2,sortedCodes(x));
                    headerStruct.stores.(varName).typeStr = storeTypes{x};
                    headerStruct.stores.(varName).typeNum = find(strcmpi(ALLOWED_TYPES, storeTypes{x}));
                    if ~strcmp(storeTypes{x}, 'scalars')
                        headerStruct.stores.(varName).fs = double(typecast(heads(10,sortedCodes(x)), 'single'));
                    end
                    headerStruct.stores.(varName).dform = heads(9,sortedCodes(x));
                end
            end
            
            validInd = find(codes == uniqueCodes(x));
            
            % look for notes in 'freqs' field for epoch or scalar events
            if numel(noteStr) > 0 && (strcmp(storeTypes{x}, 'scalars') || strcmp(storeTypes{x}, 'epocs'))
                
                % find all possible notes
                myNotes = typecast(heads(10,validInd), 'single');
                
                % find only where note field is non-zero and extract those
                noteInd = myNotes ~= 0;
                if any(noteInd)
                    if ~ismember(name, notes.name)
                        notes.name = [notes.name {name}];
                        notes.ts = [notes.ts {[]}];
                        notes.index = [notes.index {[]}];
                    end
                    tsInd = validInd(noteInd);
                    noteTS = typecast(reshape(heads(5:6, tsInd), 1, []), 'double') - headerStruct.startTime;
                    noteIndex = typecast(myNotes(noteInd),'uint32');
                    
                    [lia, loc] = ismember(name, notes.name);
                    notes.ts{loc} = [notes.ts{loc} noteTS];
                    notes.index{loc} = [notes.index{loc} noteIndex];
                end
            end
            
            temp = typecast(heads(4, validInd), 'uint16');
            if ~strcmp(storeTypes{x},'epocs')
                headerStruct.stores.(varName).ts{loopCt} = typecast(reshape(heads(5:6, validInd), 1, []), 'double') - headerStruct.startTime;
                if ~NODATA || strcmp(storeTypes{x},'streams')
                    headerStruct.stores.(varName).data{loopCt} = typecast(reshape(heads(7:8, validInd), 1, []), 'double');
                end
                headerStruct.stores.(varName).chan{loopCt} = temp(1:2:end);
                if strcmpi(headerStruct.stores.(varName).typeStr, 'snips')
                    if ~isempty(customSortCodes) && strcmp(headerStruct.stores.(varName).name, customSortEvent)
                        % apply custom sort codes
                        sortChannels = find(customSortChannelMap) - 1;
                        headerStruct.stores.(varName).sortcode{loopCt} = customSortCodes(validInd)';
                        headerStruct.stores.(varName).sortname = SORTNAME;
                        headerStruct.stores.(varName).sortchannels = sortChannels;
                    else
                        headerStruct.stores.(varName).sortcode{loopCt} = temp(2:2:end);
                        headerStruct.stores.(varName).sortname = 'TankSort';
                    end
                end
            else
                [lia, loc] = ismember(name, epocs.name);
                epocs.ts{loc} = [epocs.ts{loc} typecast(reshape(heads(5:6, validInd), 1, []), 'double') - headerStruct.startTime];
                epocs.data{loc} = [epocs.data{loc} typecast(reshape(heads(7:8, validInd), 1, []), 'double')];
            end
            
            clear temp;
        end
        clear codes;
        
        lastTS = typecast(reshape(heads(5:6, end), 1, []), 'double') - headerStruct.startTime;
        
        % break early if time filter
        if T2 > 0 && lastTS > T2
            break
        end
    end
    %fprintf('read up to t=%.2fs\n', lastTS);
   
end

   info = data.info;

end

function blockNotes = parseTBK(tbkPath)

blockNotes = struct();
tbk = fopen(tbkPath, 'rb');
if tbk < 0
    warning('TBK file %s not found', tbkPath);
    return
end

s = fread(tbk, inf, '*char')';
fclose(tbk);

% create array of structs with store information %
% split block notes into rows
delimInd = strfind(s, '[USERNOTEDELIMITER]');
try
    s = s(delimInd(2):delimInd(3));
catch
    warning('Bad TBK file, try running the TankRestore tool to correct. See http://www.tdt.com/technotes/#0935.htm')
    return;
end
lines = textscan(s, '%s', 'delimiter', sprintf('\n'));
lines = lines{1};

% loop through rows
storenum = 0;
for i = 1:length(lines)-1
    
    % check if this is a new store
    if(~isempty(strfind(lines{i},'StoreName')))
        storenum = storenum + 1;
    end
    
    % find delimiters
    equals = strfind(lines{i},'=');
    semi = strfind(lines{i},';');
    
    % grab field and value between the '=' and ';'
    fieldstr = lines{i}(equals(1)+1:semi(1)-1);
    value = lines{i}(equals(3)+1:semi(3)-1);
    
    % insert new field and value into store struct
    blockNotes(storenum).(fieldstr) = value;
end

% print out store information
%for i = 1:storenum
%    disp(blockNotes(i))
%end
end

function varname = fixVarName(name, varargin)
if nargin == 1
    VERBOSE = 0;
else
    VERBOSE = varargin{1};
end
varname = name;
for ii = 1:numel(varname)
    if ii == 1
        if isstrprop(varname(ii), 'digit')
            varname(ii) = 'x';
        end
    end
    if ~isstrprop(varname(ii), 'alphanum')
        varname(ii) = '_';
    end
end
%TODO: use this instead in 2014+
%varname = matlab.lang.makeValidName(name);
if ~isvarname(name) && VERBOSE
    fprintf('info: %s is not a valid Matlab variable name, changing to %s\n', name, varname);
end
end

function s = code2type(code)
%% given event code, return string 'epocs', 'snips', 'streams', or 'scalars'

global EVTYPE_STRON EVTYPE_STROFF EVTYPE_SCALAR EVTYPE_SNIP EVTYPE_MARK EVTYPE_MASK EVTYPE_STREAM;

strobeTypes = [EVTYPE_STRON EVTYPE_STROFF EVTYPE_MARK];
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

function t = epoc2type(code)
%% given epoc event code, return if it is 'onset' or 'offset' event

global EVTYPE_STRON EVTYPE_STROFF EVTYPE_MARK;

strobeOnTypes = [EVTYPE_STRON EVTYPE_MARK];
strobeOffTypes = [EVTYPE_STROFF];
t = 'unknown';
if ismember(code, strobeOnTypes)
    t = 'onset';
elseif ismember(code, strobeOffTypes)
    t = 'offset';
end
end