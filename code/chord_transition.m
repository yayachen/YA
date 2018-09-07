clear; clc; close all;
fpath = 'annotation/pei/';
file = dir(fullfile([fpath '*.xlsx']));

for songI = 3%1:length(file)
    clearvars -except songI file fpath

    xlsName = {'m_16_1', 'm_7_1', 'b_4_1', 'b_20_1', 'c_40_1', 'c_47_1', 'h_37_1', 'h_23_1', ...
               'm_16_2', 'm_7_2', 'b_4_2', 'b_20_2', 'c_40_2', 'c_47_2', 'h_37_2'};
    xlsFile = xlsName{songI};
    % xlsFile = erase(file(songI).name, ".xlsx")
    
    pitchName   = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
    pitchNumber = [  0,    1,   2,    3,   4,   5,    6,   7,    8,   9,   10,  11];
    scale   = {'I', 'II', 'III','IV', 'V', 'VI', 'VII','V7','viio','iio'};
    degree  = [  1,    2,     3,   4,   5,    6,     7,   5,    7 ,    2]; 
    tempName = {'maj','7','min','dim','xxx','X'};
    
    % ���ǲզ���
    load('Key_DiatonicTriad_V7.mat')
    KEYN        = cat(1,keyN(:).consistNote);
    KEYH        = cat(1,keyH(:).consistNote);
    KEYF        = cat(1,keyFusion(:).consistNote);
    
    % Ū��
    [number, text, rawData] = xlsread([fpath xlsFile '.xlsx']);
    
    if all(isnan(cat(2,rawData{end,:}))); rawData(end, :) = []; end
    newChord = rawData; newChord(1,5) = {'�M���s��'};
    
    for i=2:length(rawData)
        %% �ո�T
        % �ɥΧO���թM���C �аOX/x -> X�զ��O�ɥΤFx�ժ��M��
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
        
        %% �M����T
        % �M���ż� Degree
        tmpDegree = regexp(rawData{i,4}, '/', 'split');

        seven     = cell2mat(strfind(tmpDegree(1), '7'));
        dim       = cell2mat(strfind(tmpDegree(1), 'o'));
        halfDim   = cell2mat(strfind(tmpDegree(1), '%'));
        tmpDegree = strrep(tmpDegree, {'%'}, {''});   % ���M���R��
        tmpDegree = strrep(tmpDegree, {'o'}, {''});   % ���M���R��
        tmpDegree = strrep(tmpDegree, {'7'}, {''});   % ��7�M���R��

        chordDegree = degree(strcmpi(scale, tmpDegree(end)));   % �ż�
        
        special = '';
        % ���Y���M�����w�ꤻ�M��
        if strcmpi('N', tmpDegree(end))
            chordDegree = 2;
            special = 'N';
        elseif strcmpi('Ger', tmpDegree(end))
            chordDegree = 6;
            special = 'Ger';
        elseif strcmpi('Ita', tmpDegree(end))
            chordDegree = 1; % �Ȯɪ�
            special = 'Ita';
        elseif strcmpi('Fr', tmpDegree(end))
            chordDegree = 1; % �Ȯɪ�
            special = 'Fr';
        elseif strcmpi('NCT', tmpDegree(end))
            chordDegree = 1; % �Ȯɪ�
            special = 'NCT';
        elseif strcmpi('rest', tmpDegree(end))
            chordDegree = 1; % �Ȯɪ�
            special = 'rest';
        end

    %     newChord{i,4} = KeyH(keyTonicNo, chordDegree);
        newChord{i,4} = KEYF(keyTonicNo, chordDegree); % �p�ժ��M��->�۵M�P�M�n�p�ղV�X

        de = find(strcmpi(scale, tmpDegree(end)));
        if ~isempty(de) && de==7 && keyTonicNo>12      % �p�G�OVII�N��Φ۵M�p�խ���
            newChord{i,4} = KEYN(keyTonicNo, chordDegree);
        end
        newChord{i,5} = find(strcmpi(newChord{i,4}, pitchName)) - 1;

        % ���Y���M�����w�ꤻ�M��
        if ~isempty(special)%strcmpi('N', tmpDegree(end)) || strcmpi('Ger', tmpDegree(end))
            newChord{i,5} = mod(newChord{i,5} - 1, 12);
            newChord{i,4} = pitchName(pitchNumber==newChord{i,5});
            newChord{i,6} = ['special: ' special];
        end

        % �� ��/�� �M��
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

        %% �M���˪�
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
        % �S��M��
        if strcmpi('Ita', tmpDegree(end)) || strcmpi('Fr', tmpDegree(end)) || strcmpi('NCT', tmpDegree(end)) || strcmpi('rest', tmpDegree(end))
            newChord{i,5} = 0;
            newChord{i,4} = special;
            newChord{i,6} = ['special: ' special];
        end
    end
end

cell2csv([fpath 'trans_' xlsFile '.csv'], newChord);
