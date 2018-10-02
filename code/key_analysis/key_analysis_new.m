%%%% description : 分析key
%%%% input :  barNote -> 小節音符資訊
%%%%          chord   -> 和弦資訊
%%%%          para    -> 參數
%%%%                     slidWinSize : sliding window的size , 
%%%%                                    if 等於1表示當前小節的前後一小節
%%%%                     isABA       : 要不要做ABA
%%%%                     ABAsize     : if要ABA的話,B的size是小於等於多少
%%%% output :    -> 每個小節每個調的分數(和弦*音階)

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
    
    % 如果第一個chord 不是一小節的話，把他從第一小節開始計，后面小節也要調整
    if chord{2}~=1
        cutBarNum = chord{2}-1;
        for i = 2:length(chord)
            chord{i,1} = chord{i,1} - cutBarNum;
        end
    end
    
    % 檢查有沒有小節沒有音符，有此情況要刪掉
    i = 1;
    while i <= length(barNote)
        if isempty(barNote{i})
            barNote(i) = [];
        else
            i = i + 1;
        end
    end
    
    %% 紀錄key 分數
    result = chord;
    chord(1, :) = [];
    score = key_score_new(chord, barNote);
    
    scoreMerge         = score.finalScore;
    scoreNote          = score.note;
    scoreChord145     = score.chord145;
    scoreIChordNoteNum = score.chord1Note;
    scoreChord15       = score.chord15;
        
    barNum = size(scoreMerge, 2);
%     把分數矩陣轉為segment
    segment = create_segment(scoreMerge);
    %%
    
    [key.ori, ~] = segment2mat(segment, scoreMerge);  % 沒篩選的segment 
%     把長度為1得segment刪掉
    segment1 = segment(cat(1, segment.lens) > 1);  % 刪除長度為1的segment
%     再轉回分數矩陣
    [key.ori1, keyFlagHead] = segment2mat(segment1, ones(size(scoreNote)));
    scoreReserved = scoreMerge .* keyFlagHead;
    scoreReserved = patch(scoreReserved); % 補丁
    segReserved = create_segment(scoreReserved);
   
    scoreFlagOld = zeros(size(scoreMerge)); 
    
    %% 後處理
    keyFlagEnd = keyFlagHead;
    segInput = segReserved;
    scoreInput = keyFlagHead;
    count = 0;
    flag = 1;
    while(flag && count<=50)
        keyFlagHead = keyFlagEnd;
        flag = 0;
        count = count + 1;

%% overlap : (1) 比較 I IV V和弦總和(有長度資訊), (2) 比較調分數(ratio), (3) 調的I和弦音數量
         for methodI = 1:3
             
             candiKeyFlag = zeros(length(segInput), barNum);
             for i = 1:length(segInput)
                 candiKeyFlag(i, segInput(i).start:segInput(i).end) = 1;
             end
             
             for i = 1:length(segInput)
                 % 記錄哪個候選segment與第i個segment重疊
                 [x, ~] = find(candiKeyFlag(:, segInput(i).start:segInput(i).end) ~= 0);
                 overlapX = unique(x);
                 overlapX(overlapX == i) = [];

                 if ~isempty(overlapX)
                     for j = 1:length(overlapX)
                         if ~(segInput(i).start > segInput(overlapX(j)).end || segInput(i).end < segInput(overlapX(j)).start)
                             on = max(segInput(i).start, segInput(overlapX(j)).start); % 重疊的onset
                             off = min(segInput(i).end, segInput(overlapX(j)).end);    % 重疊的offset

                             if methodI == 1     % 先比較 145和弦分數
                                 seg1Score = scoreChord145(segInput(i).keyIdx, on:off);
                                 seg2Score = scoreChord145(segInput(overlapX(j)).keyIdx, on:off);
                             elseif methodI == 2 % 再比較音符分數
                                 seg1Score = scoreNote(segInput(i).keyIdx, on:off);
                                 seg2Score = scoreNote(segInput(overlapX(j)).keyIdx, on:off);
                             else                % 最後比較一和弦音符分數
                                 seg1Score = scoreIChordNoteNum(segInput(i).keyIdx, on:off);
                                 seg2Score = scoreIChordNoteNum(segInput(overlapX(j)).keyIdx, on:off);
                             end

                             % 哪種情況的重疊，只處理&調整 i-th segment
                             if segInput(i).start < on && segInput(i).end == off && segInput(i).end ~= segInput(overlapX(j)).end
                                 Case = 1; % i-th segment先出現
                                 scoreOverlap = scanning(seg1Score, seg2Score, Case);
                                 scoreInput(segInput(i).keyIdx, on:off) = scoreInput(segInput(i).keyIdx, on:off).* scoreOverlap(1, :);
                             elseif segInput(i).start == on && segInput(i).end > off && segInput(i).start ~= segInput(overlapX(j)).start
                                 Case = 2; % i-th segment後出現
                                 scoreOverlap = scanning(seg1Score, seg2Score, Case);
                                 scoreInput(segInput(i).keyIdx, on:off) = scoreInput(segInput(i).keyIdx, on:off).* scoreOverlap(1, :);
                             else
                                 Case = 3; % 兩個 segment 同時出現&結束
                                 wSize = para.slidWinSize;
                                 nowBar = on;
                                 barKeyFlag = zeros(1, off-on+1);

                                 while nowBar <= off
                                     triangleWin    = triang(1+2*wSize)'; % 三角window
                                     triangleWinTmp = repmat(triangleWin,2,1);
                                     
                                     winOn  = max(1, nowBar-wSize);
                                     winOff = min(nowBar+wSize, size(scoreReserved,2));
                                     idx = find(nowBar == winOn:winOff); % 現在判斷的bar在window的第幾格
                                     
                                     % 把目前小節移到window中間那格
                                     winScore = zeros(2, 1+2*wSize);
                                     if idx < wSize+1
                                         winScore(:, end-(winOff-winOn+1)+1:end) = scoreReserved([segInput(i).keyIdx segInput(overlapX(j)).keyIdx], winOn:winOff);
                                     else
                                         winScore(:,1:winOff-winOn+1) = scoreReserved([segInput(i).keyIdx segInput(overlapX(j)).keyIdx], winOn:winOff);
                                     end   
                                     
                                     % 比較音符分數和和弦分數相乘
                                     twoKeyScoreSum = sum(triangleWinTmp .* winScore, 2) ./ sum(triangleWin);
                                     maxKeyIdx = find(twoKeyScoreSum==max(twoKeyScoreSum));
                                     
                                     % 分不出勝負就比較145和弦分數
                                     if length(maxKeyIdx) > 1
                                         chord145num = mean(scoreChord145([segInput(i).keyIdx segInput(overlapX(j)).keyIdx], winOn:winOff), 2);
                                         maxKeyIdx = find(chord145num==max(chord145num)); 
                                         
                                         % 又分不出勝負的話就把window變成5再比較一次
                                         if length(maxKeyIdx) > 1 && wSize < para.slidWinSize + 1
                                             wSize = wSize + 1;
                                             continue; 
                                         end
                                     end
                                     % 如果i-th segment在第nowBar小節比較大時，記錄為1(表示保留)
                                     if ~isempty(find(maxKeyIdx==1))
                                        barKeyFlag(nowBar-on+1) = 1;
                                     end
                                     % 移到下一個小節判斷
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
        scoreInput = patch(scoreInput);  % 補丁
        segInput = create_segment(scoreInput);
        [keyNameEnd, ~] = segment2mat(segInput, ones(size(scoreInput))); 

        if ~all(sum(scoreInput))
            segHollow = create_segment(~sum(scoreInput));
            
            for i = 1:length(segHollow)
                if segHollow(i).start > 1 && segHollow(i).end < barNum % 空洞不在第一小節或最後一小節，掃描法
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
                elseif segHollow(i).start == 1 % 空洞在第一小節，直接補起來
                    segkeyIdx = segInput((cat(1, segInput.start)==(segHollow(i).end + 1))).keyIdx;
                    for j = 1:length(segkeyIdx)
                        scoreInput(segkeyIdx(j), segHollow(i).start:segHollow(i).end) = 1;
                    end
                elseif segHollow(i).end == barNum % 空洞在最後一小節，直接補起來
                    segkeyIdx = segInput((cat(1, segInput.end)==(segHollow(i).start - 1))).keyIdx;
                    for j = 1:length(segkeyIdx)
                        scoreInput(segkeyIdx(j), segHollow(i).start:segHollow(i).end) = 1;
                    end
                end
            end
        end
        segInput = create_segment(scoreInput);
        [segInput, scoreInput, keyFlagEnd] = check_segment(segInput, scoreInput, scoreChord15);
             
        if ~all(all(keyFlagEnd == keyFlagHead)); flag = 1; end % 如果有變動就繼續判斷重疊和空洞

            
%% 沒變動後的處理 ---------------------------------------------
        if ~flag 
            % 1. 若還有overlap沒解決，子集情況的overlap直接用長度刪減
            [segInput, scoreInput] = overlapLen(segInput, scoreInput);
            
            % 2. ABA處理，直接把B變成A
            if para.isABA 
                [~, idx] = sort(cat(1, segInput.start)); % 依照onset排序
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
    % 把結果存回result中
    barInfo = cat(1,result{2:end,1});
    for i = 1:length(barInfo)
        result{i+1, 3} = keyNameEnd{find(keyFlagEnd(:, barInfo(i))==1), barInfo(i)};
    end
    
    % 還有overlap的小節發出warning提醒
    keyIdx = find(sum(keyFlagEnd)~=1);
    if sum(sum(keyFlagEnd)) ~= barNum
        warning(['沒有處理好的重疊bar : ' num2str(keyIdx)]);
    end
end


%% function

% description : 紀錄每個segment資訊
% input  : score    -> 分數矩陣 (24*小節數)
% output : segment  -> 生成的segment資訊，紀錄onset offset score ... 等等
function segment = create_segment(score)
    keyName     = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', ...
                   'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'};
    keyNum = size(score, 1);
    barNum = size(score, 2);
    % 找片段onset
    % case 1 : find 0 to 1 -> start
    zero = find(score == 0);
    one  = find(score ~= 0);
    zero(zero > keyNum * (barNum - 1)) = []; % 最後一row的0刪掉
    segOnset = intersect(zero + keyNum, one); % 把0後移一row後跟1比較，位置一樣的地方為0->1
    % case 2 : bar = 1, have 1
    segOnset = reshape(segOnset, length(segOnset), 1);
    segOnset = sort([segOnset; one(one <= keyNum)]);
    
    % 紀錄每個片段
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
    
    % 依照長度排序
    [~, idx] = sort(cat(1, segment.lens), 'descend');
    segment = segment(idx);
end

% description : 檢查每一個segment 1.長度>1, 2.有一級和五級和弦
% input  : segment    -> 和弦資訊
%          score      -> 分數矩陣
%          score15    -> 一五和弦的分數矩陣
% output : segment    -> 檢查後的segment
%          score      -> 分數矩陣(和弦*音階)
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

% description : segment(struct)轉為分數矩陣
% input : segment -> 片段
%         score   -> 分數矩陣
% ouput : key     -> 候選調的cell矩陣
%         score   -> 分數矩陣
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

% description : 該小節得分數是0，而前後小節不是0時，補洞。 補洞＝把要補洞的分數由0變為0.01分
% input  : score   -> 分數矩陣
% output : score   -> 補洞後的分數矩陣
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

% description : 在hollow及overlap時，找到一個boundary
% input : score1       -> segment 1 的 hollow或overlap分數
%         score2       -> segment 2 的 hollow或overlap分數
%         Case         -> 屬於哪種hollow或者overlap
% ouput : maxScoreFlag -> 保留最高分時的位置
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
    
    % 知道最大分數的分割點後，把留下來的小節記住
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

% description : 以重疊的長度來刪segment
% input :  segment
%          score   -> 分數矩陣
% output:  segment -> 刪除後的segment
%          score   -> 刪除後的分數矩陣
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