%% new
clear; clc; close all;
fpath = []; Accuracy = struct();

option = questdlg('Select a file directory or specific xlsx(s)', ...
	'Open file', ...
	'File directory','xlsx-file(s)', 'Cancel', 'Cancel');

% Handle response
switch option
    case 'File directory'
        fpath = uigetdir('annotation', 'Pick file dir');
        if fpath ~= 0
            fpath = [fpath '/']; 
            fileInfo = dir(fullfile([fpath '*.xlsx']));
            name = erase(cat(1, {fileInfo.name}), ".xlsx");
        end
        
    case 'xlsx-file(s)'
        [filename, fpath, filterindex] = uigetfile('*.xlsx', 'Pick midi files', 'MultiSelect', 'on', 'annotation');
        if fpath ~= 0 
            name = erase(cat(1, filename), ".xlsx");
        end
    
    case 'Cancel'
        fpath = 0;
end

if ~isempty(fpath) && any(fpath~=0)
    if ~iscell(name)
        Name{:} = name; 
    else
        Name = name;
    end
    f = waitbar(0,'Please wait...');
    pause(.5)
    
    for songNo = 1:length(Name)
        clearvars -except songNo Name fpath f
        
        fname = Name{songNo};
        disp(['Processing file "' fname '" ... '])
        waitbar(songNo/length(Name),f,['Running ' num2str(songNo) 'th song "' fname '"']);

        pitchName   = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
        pitchNumber = [  0,    1,   2,    3,   4,   5,    6,   7,    8,   9,   10,  11];
        scale   = {'I', 'II', 'III','IV', 'V', 'VI', 'VII','V7','viio','iio'};
        degree  = [  1,    2,     3,   4,   5,    6,     7,   5,    7 ,    2]; 
        tempName = {'maj','7','min','dim','xxx','X'};

        % 哪些組成音
        load('Key_DiatonicTriad_V7.mat')
        KEYN        = cat(1,keyN(:).consistNote);
        KEYH        = cat(1,keyH(:).consistNote);
        KEYF        = cat(1,keyFusion(:).consistNote);

        % 讀檔
        idx = strfind(fpath, 'code/annotation/');
        p1 = fpath(idx+16:end);
        [~, ~, rawData] = xlsread(['annotation/' p1 fname '.xlsx']);

        if all(isnan(cat(2,rawData{end,:}))); rawData(end, :) = []; end
        newChord = rawData; newChord(1,5) = {'和弦編號'};

        for i=2:length(rawData)
            %% 調資訊
            % 借用別的調和弦。 標記X/x -> X調但是借用了x調的和弦
            tmpkey = regexp(rawData{i,3}, '/', 'split');
            key = tmpkey{1};
            if length(tmpkey) == 2
                newChord{i,6} = ['borrowed:' tmpkey{2}];
                key = tmpkey{2};
            end
            % key
            keyTonicNo = pitchNumber(strcmpi(pitchName, key)) + 1;
            if key(1)>='a'&& key(1)<='z'
                keyTonicNo = keyTonicNo + 12;
            end

            %% 和弦資訊
            % 和弦級數 Degree
            tmpDegree = regexp(rawData{i,4}, '/', 'split');

            seven     = cell2mat(strfind(tmpDegree(1), '7'));
            dim       = cell2mat(strfind(tmpDegree(1), 'o'));
            halfDim   = cell2mat(strfind(tmpDegree(1), '%'));
            tmpDegree = strrep(tmpDegree, {'%'}, {''});   % 把減和弦刪掉
            tmpDegree = strrep(tmpDegree, {'o'}, {''});   % 把減和弦刪掉
            tmpDegree = strrep(tmpDegree, {'7'}, {''});   % 把7和弦刪掉

            chordDegree = degree(strcmpi(scale, tmpDegree(end)));   % 級數

            special = '';
            % 拿坡里和弦＆德國六和弦
            if strcmpi('N', tmpDegree(end))
                chordDegree = 2;
                special = 'N';
            elseif strcmpi('Ger', tmpDegree(end))
                chordDegree = 6;
                special = 'Ger';
            elseif strcmpi('Ita', tmpDegree(end))
                chordDegree = 1; % 暫時的
                special = 'Ita';
            elseif strcmpi('Fr', tmpDegree(end))
                chordDegree = 1; % 暫時的
                special = 'Fr';
            elseif strcmpi('NCT', tmpDegree(end))
                chordDegree = 1; % 暫時的
                special = 'NCT';
            elseif strcmpi('rest', tmpDegree(end))
                chordDegree = 1; % 暫時的
                special = 'rest';
            end

        %     newChord{i,4} = KeyH(keyTonicNo, chordDegree);
            newChord{i,4} = KEYF(keyTonicNo, chordDegree); % 小調的和弦->自然與和聲小調混合

            de = find(strcmpi(scale, tmpDegree(end)));
            if ~isempty(de) && de==7 && keyTonicNo>12      % 如果是VII代表用自然小調音階
                newChord{i,4} = KEYN(keyTonicNo, chordDegree);
            end
            newChord{i,5} = find(strcmpi(newChord{i,4}, pitchName)) - 1;

            % 拿坡里和弦＆德國六和弦
            if ~isempty(special)%strcmpi('N', tmpDegree(end)) || strcmpi('Ger', tmpDegree(end))
                newChord{i,5} = mod(newChord{i,5} - 1, 12);
                newChord{i,4} = pitchName(pitchNumber==newChord{i,5});
                newChord{i,6} = ['special: ' special];
            end

            % 副 屬/導 和弦
            if length(tmpDegree) == 2
                chordDegree = degree(strcmpi(scale, tmpDegree(1)));
                if chordDegree == 5
                    chordDegreeRe = 7;
                elseif chordDegree == 7
                    chordDegreeRe = 11;
                elseif chordDegree == 4
                    chordDegreeRe = 5;
                end
                newChord{i,5} = mod(newChord{i,5} + chordDegreeRe, 12);
                newChord{i,4} = pitchName(pitchNumber==newChord{i,5});
                newChord{i,6} = 'second';
            end

            %% 和弦樣版
            tempName = {'maj','7','min','dim'};
            add = [];
            if tmpDegree{1}(1)>='a' && tmpDegree{1}(1)<='z'
                tempNo = 3;
            else
                tempNo = 1;
            end
            if     dim; tempNo = 4; end
            if halfDim; tempNo = 4; end
            if strcmpi('Ger', tmpDegree(end)); tempNo = 2; end
            if seven
                if strcmpi(tmpDegree{1},'V')
                    tempNo = 2;
                else
                    add = '7';
                end
            end

            newChord{i,4} = [newChord{i,4}{:} ':' tempName{tempNo} add];
            newChord{i,5} = newChord{i,5} + 1 + 12 * (tempNo-1);
            % 特殊和弦
            if strcmpi('Ita', tmpDegree(end)) || strcmpi('Fr', tmpDegree(end)) || strcmpi('NCT', tmpDegree(end)) || strcmpi('rest', tmpDegree(end))
                newChord{i,5} = 0;
                newChord{i,4} = special;
                newChord{i,6} = ['special: ' special];
            end
        end
        cell2csv(['annotation/' p1 'trans_' fname '.csv'], newChord);
    end
    disp('Finishing!');
    waitbar(1,f,'Finishing');
    pause(1)
    close(f)
end