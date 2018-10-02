%%%% description : ���Rkey
%%%% input :  barNote -> �p�`���Ÿ�T
%%%%          chord   -> �M����T
%%%%          para    -> �Ѽ�
%%%%                     slidWinSize : sliding window��size , 
%%%%                                    if ����1��ܷ�e�p�`���e��@�p�`
%%%%                     isABA       : �n���n��ABA
%%%%                     ABAsize     : if�nABA����,B��size�O�p�󵥩�h��
%%%% output :    -> �C�Ӥp�`�C�ӽժ�����(�M��*����)

%% debug
% clear; clc;
% addpath('../');
% addpath('../toolbox/midi_lib/midi_lib');
% 
% fname = 'b_4_1'
% [midiData, timeSig] = midi_Preprocess(['../midi/pei/' fname]);
% [barNote, ~] = bar_note_data(midiData, timeSig); 
% [~, ~, chord] = xlsread(['../annotation/trans_' fname '.xlsx']);
% 
% para.slidWinSize = 1;
% para.isABA = 1; 
% para.ABAsize = 4;

%%
function [result, keyNameEnd] = key_analysis_new(barNote, chord, para)
    if nargin < 4, para.slidWinSize = 1; end
    if nargin < 3, para = []; end
    if isfield(para,'slidWinSize')==0
        para.slidWinSize = 1;
    end
    if isfield(para,'isABA')==0
        para.isABA = 0;
    end
    if isfield(para,'ABAsize')==0
        para.ABAsize = 3;
    end 
    
    % �p�G�Ĥ@��chord ���O�@�p�`���ܡA��L�q�Ĥ@�p�`�}�l�p�A�Z���p�`�]�n�վ�
    if chord{2}~=1
        cutBarNum = chord{2}-1;
        for i = 2:length(chord)
            chord{i,1} = chord{i,1} - cutBarNum;
        end
    end
    
    % �ˬd���S���p�`�S�����šA�������p�n�R��
    i = 1;
    while i <= length(barNote)
        if isempty(barNote{i})
            barNote(i) = [];
        else
            i = i + 1;
        end
    end
    
    %% ����key ����
    result = chord;
    chord(1, :) = [];
    score = key_score_new(chord, barNote);
    
    scoreMerge         = score.finalScore;
    scoreNote          = score.note;
    scoreChord145     = score.chord145;
    scoreIChordNoteNum = score.chord1Note;
    scoreChord15       = score.chord15;
        
    barNum = size(scoreMerge, 2);
%     ����Ưx�}�ରsegment
    segment = create_segment(scoreMerge);
    %%
    
    [key.ori, ~] = segment2mat(segment, scoreMerge);  % �S�z�諸segment 
%     ����׬�1�osegment�R��
    segment1 = segment(cat(1, segment.lens) > 1);  % �R�����׬�1��segment
%     �A��^���Ưx�}
    [key.ori1, keyFlagHead] = segment2mat(segment1, ones(size(scoreNote)));
    scoreReserved = scoreMerge .* keyFlagHead;
    scoreReserved = patch(scoreReserved); % �ɤB
    segReserved = create_segment(scoreReserved);
   
    scoreFlagOld = zeros(size(scoreMerge)); 
    
    %% ��B�z
    keyFlagEnd = keyFlagHead;
    segInput = segReserved;
    scoreInput = keyFlagHead;
    count = 0;
    flag = 1;
    while(flag && count<=50)
        keyFlagHead = keyFlagEnd;
        flag = 0;
        count = count + 1;

%% overlap : (1) ��� I IV V�M���`�M(�����׸�T), (2) ����դ���(ratio), (3) �ժ�I�M�����ƶq
         for methodI = 1:3
             
             candiKeyFlag = zeros(length(segInput), barNum);
             for i = 1:length(segInput)
                 candiKeyFlag(i, segInput(i).start:segInput(i).end) = 1;
             end
             
             for i = 1:length(segInput)
                 % �O�����ӭԿ�segment�P��i��segment���|
                 [x, ~] = find(candiKeyFlag(:, segInput(i).start:segInput(i).end) ~= 0);
                 overlapX = unique(x);
                 overlapX(overlapX == i) = [];

                 if ~isempty(overlapX)
                     for j = 1:length(overlapX)
                         if ~(segInput(i).start > segInput(overlapX(j)).end || segInput(i).end < segInput(overlapX(j)).start)
                             on = max(segInput(i).start, segInput(overlapX(j)).start); % ���|��onset
                             off = min(segInput(i).end, segInput(overlapX(j)).end);    % ���|��offset

                             if methodI == 1     % ����� 145�M������
                                 seg1Score = scoreChord145(segInput(i).keyIdx, on:off);
                                 seg2Score = scoreChord145(segInput(overlapX(j)).keyIdx, on:off);
                             elseif methodI == 2 % �A������Ť���
                                 seg1Score = scoreNote(segInput(i).keyIdx, on:off);
                                 seg2Score = scoreNote(segInput(overlapX(j)).keyIdx, on:off);
                             else                % �̫����@�M�����Ť���
                                 seg1Score = scoreIChordNoteNum(segInput(i).keyIdx, on:off);
                                 seg2Score = scoreIChordNoteNum(segInput(overlapX(j)).keyIdx, on:off);
                             end

                             % ���ر��p�����|�A�u�B�z&�վ� i-th segment
                             if segInput(i).start < on && segInput(i).end == off && segInput(i).end ~= segInput(overlapX(j)).end
                                 Case = 1; % i-th segment���X�{
                                 scoreOverlap = scanning(seg1Score, seg2Score, Case);
                                 scoreInput(segInput(i).keyIdx, on:off) = scoreInput(segInput(i).keyIdx, on:off).* scoreOverlap(1, :);
                             elseif segInput(i).start == on && segInput(i).end > off && segInput(i).start ~= segInput(overlapX(j)).start
                                 Case = 2; % i-th segment��X�{
                                 scoreOverlap = scanning(seg1Score, seg2Score, Case);
                                 scoreInput(segInput(i).keyIdx, on:off) = scoreInput(segInput(i).keyIdx, on:off).* scoreOverlap(1, :);
                             else
                                 Case = 3; % ��� segment �P�ɥX�{&����
                                 wSize = para.slidWinSize;
                                 nowBar = on;
                                 barKeyFlag = zeros(1, off-on+1);

                                 while nowBar <= off
                                     triangleWin    = triang(1+2*wSize)'; % �T��window
                                     triangleWinTmp = repmat(triangleWin,2,1);
                                     
                                     winOn  = max(1, nowBar-wSize);
                                     winOff = min(nowBar+wSize, size(scoreReserved,2));
                                     idx = find(nowBar == winOn:winOff); % �{�b�P�_��bar�bwindow���ĴX��
                                     
                                     % ��ثe�p�`����window��������
                                     winScore = zeros(2, 1+2*wSize);
                                     if idx < wSize+1
                                         winScore(:, end-(winOff-winOn+1)+1:end) = scoreReserved([segInput(i).keyIdx segInput(overlapX(j)).keyIdx], winOn:winOff);
                                     else
                                         winScore(:,1:winOff-winOn+1) = scoreReserved([segInput(i).keyIdx segInput(overlapX(j)).keyIdx], winOn:winOff);
                                     end   
                                     
                                     % ������Ť��ƩM�M�����Ƭۭ�
                                     twoKeyScoreSum = sum(triangleWinTmp .* winScore, 2) ./ sum(triangleWin);
                                     maxKeyIdx = find(twoKeyScoreSum==max(twoKeyScoreSum));
                                     
                                     % �����X�ӭt�N���145�M������
                                     if length(maxKeyIdx) > 1
                                         chord145num = mean(scoreChord145([segInput(i).keyIdx segInput(overlapX(j)).keyIdx], winOn:winOff), 2);
                                         maxKeyIdx = find(chord145num==max(chord145num)); 
                                         
                                         % �S�����X�ӭt���ܴN��window�ܦ�5�A����@��
                                         if length(maxKeyIdx) > 1 && wSize < para.slidWinSize + 1
                                             wSize = wSize + 1;
                                             continue; 
                                         end
                                     end
                                     % �p�Gi-th segment�b��nowBar�p�`����j�ɡA�O����1(��ܫO�d)
                                     if ~isempty(find(maxKeyIdx==1))
                                        barKeyFlag(nowBar-on+1) = 1;
                                     end
                                     % ����U�@�Ӥp�`�P�_
                                     nowBar = nowBar + 1;
                                     wSize = para.slidWinSize;
                                 end
                                 scoreInput(segInput(i).keyIdx, on:off) = scoreInput(segInput(i).keyIdx, on:off) .* barKeyFlag(1, :);
                             end
                         end
                     end
                 end
             end
             segInput = create_segment(scoreInput);
             [segInput, scoreInput, ~] = check_segment(segInput, scoreInput, scoreChord15);  
         end
%% hollow        
        scoreInput = patch(scoreInput);  % �ɤB
        segInput = create_segment(scoreInput);
        [keyNameEnd, ~] = segment2mat(segInput, ones(size(scoreInput))); 

        if ~all(sum(scoreInput))
            segHollow = create_segment(~sum(scoreInput));
            
            for i = 1:length(segHollow)
                if segHollow(i).start > 1 && segHollow(i).end < barNum % �Ŭ}���b�Ĥ@�p�`�γ̫�@�p�`�A���y�k
                    seg1keyIdx = segInput((cat(1, segInput.end)==(segHollow(i).start - 1))).keyIdx;
                    seg2keyIdx = segInput((cat(1, segInput.start)==(segHollow(i).end + 1))).keyIdx;
                    for j = 1:length(seg1keyIdx)
                        seg1Score = scoreNote(seg1keyIdx(j), segHollow(i).start:segHollow(i).end);
                        for k = 1:length(seg2keyIdx)
                            seg2Score = scoreNote(seg2keyIdx(k), segHollow(i).start:segHollow(i).end);
                            scoreHollowTmp = scanning(seg1Score, seg2Score, 1);

                            scoreInput(seg1keyIdx(j), segHollow(i).start:segHollow(i).end) = scoreHollowTmp(1, :);
                            scoreInput(seg2keyIdx(k), segHollow(i).start:segHollow(i).end) = scoreHollowTmp(2, :);                           
                        end
                    end
                elseif segHollow(i).start == 1 % �Ŭ}�b�Ĥ@�p�`�A�����ɰ_��
                    segkeyIdx = segInput((cat(1, segInput.start)==(segHollow(i).end + 1))).keyIdx;
                    for j = 1:length(segkeyIdx)
                        scoreInput(segkeyIdx(j), segHollow(i).start:segHollow(i).end) = 1;
                    end
                elseif segHollow(i).end == barNum % �Ŭ}�b�̫�@�p�`�A�����ɰ_��
                    segkeyIdx = segInput((cat(1, segInput.end)==(segHollow(i).start - 1))).keyIdx;
                    for j = 1:length(segkeyIdx)
                        scoreInput(segkeyIdx(j), segHollow(i).start:segHollow(i).end) = 1;
                    end
                end
            end
        end
        segInput = create_segment(scoreInput);
        [segInput, scoreInput, keyFlagEnd] = check_segment(segInput, scoreInput, scoreChord15);
             
        if ~all(all(keyFlagEnd == keyFlagHead)); flag = 1; end % �p�G���ܰʴN�~��P�_���|�M�Ŭ}

            
%% �S�ܰʫ᪺�B�z ---------------------------------------------
        if ~flag 
            % 1. �Y�٦�overlap�S�ѨM�A�l�����p��overlap�����Ϊ��קR��
            [segInput, scoreInput] = overlapLen(segInput, scoreInput);
            
            % 2. ABA�B�z�A������B�ܦ�A
            if para.isABA 
                [~, idx] = sort(cat(1, segInput.start)); % �̷�onset�Ƨ�
                segInput = segInput(idx);
                
                [~, ABAflag] = segment2mat(segInput, ones(size(scoreInput)));
                
                for keyI = 1:24
                     idx = find(cat(1, segInput.keyIdx) == keyI);
                     if length(idx) >= 2
                         for i = 1:length(idx)-1
                            on = segInput(idx(i)).end + 1;
                            off = segInput(idx(i+1)).start - 1;
                            if off-on+1 <= para.ABAsize
                                ABAflag(keyI, on:off) = 1;
                            end
                        end
                    end
                end
                segInput = create_segment(ABAflag);  
                [segInput, scoreInput] = overlapLen(segInput, scoreInput);
            end
            
            [segInput, scoreInput, keyFlagEnd] = check_segment(segInput, scoreInput, scoreChord15);
            [keyNameEnd, ~] = segment2mat(segInput, ones(size(scoreInput)));
            scoreInput(scoreInput==0) = 0.0001;
            scoreInput = scoreInput .* keyFlagEnd;

            if ~all(all(keyFlagEnd == keyFlagHead)); flag = 1; end
        end
    end
    
%% result
    % �⵲�G�s�^result��
    barInfo = cat(1,result{2:end,1});
    for i = 1:length(barInfo)
        result{i+1, 3} = keyNameEnd{find(keyFlagEnd(:, barInfo(i))==1), barInfo(i)};
    end
    
    % �٦�overlap���p�`�o�Xwarning����
    keyIdx = find(sum(keyFlagEnd)~=1);
    if sum(sum(keyFlagEnd)) ~= barNum
        warning(['�S���B�z�n�����|bar : ' num2str(keyIdx)]);
    end
end


%% function

% description : �����C��segment��T
% input  : score    -> ���Ưx�} (24*�p�`��)
% output : segment  -> �ͦ���segment��T�A����onset offset score ... ����
function segment = create_segment(score)
    keyName     = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', ...
                   'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'};
    keyNum = size(score, 1);
    barNum = size(score, 2);
    % ����qonset
    % case 1 : find 0 to 1 -> start
    zero = find(score == 0);
    one  = find(score ~= 0);
    zero(zero > keyNum * (barNum - 1)) = []; % �̫�@row��0�R��
    segOnset = intersect(zero + keyNum, one); % ��0�Ჾ�@row���1����A��m�@�˪��a�謰0->1
    % case 2 : bar = 1, have 1
    segOnset = reshape(segOnset, length(segOnset), 1);
    segOnset = sort([segOnset; one(one <= keyNum)]);
    
    % �����C�Ӥ��q
    segment = struct();
    for i = 1:length(segOnset)
        start = ceil(segOnset(i) / keyNum);
        segment(i).keyIdx = segOnset(i) - (start - 1) * keyNum;
        segment(i).key = keyName{segment(i).keyIdx};
        segment(i).start = ceil(segOnset(i) / keyNum);
        
        segment(i).end = segment(i).start;
        segment(i).lens = 1;
        nowI = segment(i).keyIdx;
        nowJ = segment(i).start;
        segment(i).score = score(nowI, nowJ);
        
        while score(nowI, nowJ) && nowJ ~= barNum
            nowJ = nowJ + 1;
            if score(nowI, nowJ)
                segment(i).lens = segment(i).lens + 1;
                segment(i).score = segment(i).score + score(nowI, nowJ);
                segment(i).end = nowJ;
            end
        end
        segment(i).score = segment(i).score / segment(i).lens;
    end
    
    % �̷Ӫ��ױƧ�
    [~, idx] = sort(cat(1, segment.lens), 'descend');
    segment = segment(idx);
end

% description : �ˬd�C�@��segment 1.����>1, 2.���@�ũM���ũM��
% input  : segment    -> �M����T
%          score      -> ���Ưx�}
%          score15    -> �@���M�������Ưx�}
% output : segment    -> �ˬd�᪺segment
%          score      -> ���Ưx�}(�M��*����)
%          keyFlagEnd -> 
function [segment, score, keyFlagEnd] = check_segment(segment, score, score15)
    [~, keyFlagEnd] = segment2mat(segment, ones(size(score15)));
    score15(score15==0) = 0.0001;
    score15 = (keyFlagEnd .* score15);
    segment = create_segment(score15);
    
    segment(cat(1, segment.score) < 0.05) = [];
    segment(cat(1, segment.lens) == 1) = [];
    
    [~, score] = segment2mat(segment, score);
    [~, keyFlagEnd] = segment2mat(segment, ones(size(score)));
end

% description : segment(struct)�ର���Ưx�}
% input : segment -> ���q
%         score   -> ���Ưx�}
% ouput : key     -> �Կ�ժ�cell�x�}
%         score   -> ���Ưx�}
function [key, score] = segment2mat(segment, score)
    flag = zeros(size(score));
    key  = cell(size(score));
    
    for i = 1:length(segment)
         for j = segment(i).start:segment(i).end
             key{segment(i).keyIdx, j} = segment(i).key;
         end
         flag(segment(i).keyIdx, segment(i).start:segment(i).end) = 1;
    end
    score = score .* flag;
end

% description : �Ӥp�`�o���ƬO0�A�ӫe��p�`���O0�ɡA�ɬ}�C �ɬ}�ק�n�ɬ}�����ƥ�0�ܬ�0.01��
% input  : score   -> ���Ưx�}
% output : score   -> �ɬ}�᪺���Ưx�}
function score = patch(score)
    barNum = size(score, 2);
    for keyI = 1:24
        isHollow = zeros(1, barNum);
        isHollow(1) = all(xor(score(keyI, 1:2), [1 0])); % 0 1
        for j =  2:barNum - 1
            isHollow(j) = all(xor(score(keyI, j-1:j+1), [0 1 0])); % 1 0 1
        end
        isHollow(end) = all(xor(score(keyI, end-1:end), [0 1])); % 1 0 
        if ~isempty(score(keyI, isHollow == 1))
            score(keyI, isHollow == 1) = 0.01; 
        end
    end
end

% description : �bhollow��overlap�ɡA���@��boundary
% input : score1       -> segment 1 �� hollow��overlap����
%         score2       -> segment 2 �� hollow��overlap����
%         Case         -> �ݩ����hollow�Ϊ�overlap
% ouput : maxScoreFlag -> �O�d�̰����ɪ���m
function maxScoreFlag = scanning(score1, score2, Case)
    score1 = [0 score1 0];
    score2 = [0 score2 0];
    partitionNum = length(score1) - 1;
    partitionScore = zeros(2, partitionNum);

    for i = 1:length(score1) - 1
        partitionScore(1, i) = sum([score1(1:i) score2(i+1:end)]);
        partitionScore(2, i) = sum([score1(i+1:end) score2(1:i)]);
    end
    
    if Case == 1
        partitionScore(2, :) = 0;
    elseif Case == 2
        partitionScore(1, :) = 0;
    end
    
    [x, y] = find(max(max(partitionScore)) == partitionScore);
    
    % ���D�̤j���ƪ������I��A��d�U�Ӫ��p�`�O��
    maxScoreFlag = zeros(2, size(partitionScore, 2) - 1);
    for i = 1:length(x)
        if x(i) == 1
            if y(i) ~= 1; maxScoreFlag(x(i), 1:y(i)-1) = 1; end
            if y(i) ~= size(partitionScore, 2)
                maxScoreFlag(x(i) + 1, y(i):end) = 1; 
            end
        else
            if y(i) ~= 1; maxScoreFlag(x(i), 1:y(i)-1) = 1; end
            if y(i) ~= size(partitionScore, 2)
                maxScoreFlag(x(i) - 1, y(i):end) = 1; 
            end
        end
    end
end

% description : �H���|�����רӧRsegment
% input :  segment
%          score   -> ���Ưx�}
% output:  segment -> �R���᪺segment
%          score   -> �R���᪺���Ưx�}
function [segment, score] = overlapLen(segment, score)
    i = 1;
    while i <= length(segment)
        idx = find(and(and(cat(1,segment.start) >= segment(i).start, cat(1,segment.end) <= segment(i).end), cat(1,segment.lens) < segment(i).lens));
        if isempty(idx)
            i = i + 1;
        else
            segment(idx) = [];
        end
    end
    [~,score] = segment2mat(segment, score);
end