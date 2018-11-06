%%%% motify : "Algorithms for Choral Analysis 2002"
%%%% date   : 18/01/22
%%%% content: 和弦分析演算法，以小節為單位進行分析。
%%%% input  : 1. barNote  -> 小節音符
%%%%          2. onsetBar -> 小節開始的拍子 beat
%%%%          3. timeSig  -> 拍號
%%%%          4. para     -> 修改Pardo演算法相關的參數
%%%%                 isNowTemplate :    新的樣板
%%%%                 isPartitionDBeat : 以拍點為切割點
%%%%                 isDurWeight :      音符長度為權重
%%%% output : predictChord -> 和弦結果

%% debug
%     clc; clear;
%     addpath('../');
%     addpath('../toolbox/midi_lib/midi_lib');
%     fpath = '../midi/pei/';
%     filename = 'b_4_1';
%     [midiData, timeSig]  = midi_Preprocess([fpath filename]);
%     [barNote, onsetBar] = bar_note_data(midiData, timeSig);
% 
%     para.isNowTemplate = 0;
%     para.isPartitionDBeat = 0;
%     para.isDurWeight = 0;
%%
function predictChord = choral_analysis_modify_new(barNote, onsetBar, timeSig, para)
    %if nargin < 4, para = []; end
    if isfield(para,'isNowTemplate')==0
        para.isNowTemplate = 1;
    end
    if isfield(para,'isPartitionDBeat')==0
        para.isPartitionDBeat = 1;
    end
    if isfield(para,'isDurWeight')==0
        para.isDurWeight = 1;
    end

    % para
    if para.isNowTemplate
        tempName    = {    'maj',      '7',    'min',    'dim', 'xxx',  'X'};
        template    = [ 0,4,7,-1; 0,4,7,10; 0,3,7,-1; 0,3,6,-1]; 
    else
        tempName    = {    'maj',       '7',      'min','Fully dim7', 'Half dim7',     'dim3',   'X'};
        template    = [ 0,4,7,-1;  0,4,7,10;   0,3,7,-1;    0,3,6, 9;    0,3,6,10;   0,3,6,-1 ];
    end
    pitchName   = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
     
    evaluationIdx = 1;
    predictChord = {'小節','拍數(onset)','調性','和弦名稱','和弦編號','備註'};
    refNextBarRoot = 0;
    
    for j = 1:length(barNote)
        noteBar = barNote{j};
        if ~isempty(noteBar)
%% 找到最小片段分割點有哪些音
            [pitchClass, minSeg] = min_seg_pitchclass(noteBar, onsetBar(j), para, timeSig(1));

%% 紀錄所有可能分段的分數 
            templateNum  = size(template, 1);
            partitionNum = size(pitchClass, 1) + 1;
            rootS  = -inf * ones(partitionNum, partitionNum, templateNum * 12); % 根音分數 當分數相同時會用它來比較
            P      = -inf * ones(partitionNum, partitionNum, templateNum * 12);
            N      = -inf * ones(partitionNum, partitionNum, templateNum * 12);
            M      = -inf * ones(partitionNum, partitionNum, templateNum * 12);
            S      = -inf * ones(partitionNum, partitionNum, templateNum * 12);

             for p1 = 1:partitionNum
                 for p2 = p1+1:partitionNum      
                     for t = 1:templateNum
                         for p = 1:12
                             templateNo = mod(template(t,(template(t,:)~=-1)) + p - 1 , 12);
                             Template = zeros(1,12); 
                             Template(1,templateNo + 1) = 1;

                             rootS(p1, p2, (t - 1) * 12 + p) = sum(sum(pitchClass(p1:p2-1, templateNo(1) + 1)));             % 根音的score
                             P(p1, p2, (t - 1) * 12 + p)     = sum(sum(pitchClass(p1:p2-1, templateNo + 1)));                % 片段 有, 和弦 有
                             N(p1, p2, (t - 1) * 12 + p)     = sum(sum(pitchClass(p1:p2-1, setdiff(1:12,templateNo+1))));    % 片段 有, 和弦沒有  
                             M(p1, p2, (t - 1) * 12 + p)     = sum((sum(pitchClass(p1:p2-1, :),1) == 0) .* Template);        % 片段沒有, 和弦 有
                             S(p1, p2, (t - 1) * 12 + p)     = ...
                                 P(p1, p2, (t - 1) * 12 + p) - (N(p1, p2, (t - 1) * 12 + p) + M(p1, p2, (t-1) * 12 + p));
                         end
                     end
                 end
             end
            [maxScoreMatrix, scoreMatrixIdx] = max(S, [], 3);

%% 分段
            partitionPos = [minSeg(:,1)' - onsetBar(j), minSeg(end,2) - onsetBar(j)]; % partition 位置

            % 最佳路徑演算法 HarmAn
            partitionIdx = HarmAn(maxScoreMatrix, partitionNum);

            % 紀錄 Optimal path
            Optimal.partitionIdx(j, 1:length(partitionIdx)) = partitionIdx;
            Optimal.partitionPos(j, 1:length(partitionIdx)) = partitionPos(partitionIdx);
            
            Dim7Time = 1;
            
%% 最佳路徑的和弦標記
            for k = 2:length(partitionIdx)
                Optimal.sameScore(j,k-1) = -1;
                Optimal.chordIdx{j,k-1}    = scoreMatrixIdx(partitionIdx(k-1),partitionIdx(k));
                Optimal.tieBreaking(j,k-1) = {''};
                Optimal.score(j,k-1)       = maxScoreMatrix(partitionIdx(k-1),partitionIdx(k));

%% 分數一樣的話 比較
                highScoreChord = find(S(partitionIdx(k - 1), partitionIdx(k), :) == maxScoreMatrix(partitionIdx(k - 1), partitionIdx(k)));
                steps = 0;
                % steps 1 : highest root scoreMatrix
                if numel(unique(highScoreChord)) ~= 1
                    highScoreRootScore  = rootS(partitionIdx(k-1), partitionIdx(k), highScoreChord);
                    maxRootIdx          = find(highScoreRootScore == max(highScoreRootScore));
                    highScoreChord      = highScoreChord(maxRootIdx);
                    steps               = 1;
                    Optimal.tieBreaking(j, k - 1) = {'root'};
                end
                % steps 2 : highest probability of occurrence
                if numel(unique(highScoreChord)) ~= 1
                    chordSpecies    = floor(highScoreChord / 12) + 1;
                    maxProbIdx      = find(chordSpecies == min(chordSpecies));
                    highScoreChord  = highScoreChord(maxProbIdx); 
                    steps           = 2;
                    Optimal.tieBreaking(j, k - 1) = {'probability'};
                end
                % steps 3 : Diminished 7th resolution
                if numel(unique(highScoreChord)) ~= 1
                    if ~para.isNowTemplate
                        if all(ceil(highScoreChord/12) == 4)
                            Resolution_Dim7.idx(j,Dim7Time) = k-1;
                            Resolution_Dim7.chordIdx{j,k-1} = highScoreChord;
                            bar      = j;
                            steps    = 3;
                            Dim7Time = Dim7Time + 1;
                            AnsChord = Optimal.chordIdx(j,k-1);
                            Optimal.tieBreaking(j, k - 1) = {'Fdim7'};
                        else
                            Optimal.tieBreaking(j, k - 1) = {'no solve'};
                            bar      = j;
                            steps    = 4;
                        end
                    else
                        Optimal.tieBreaking(j, k - 1) = {'no solve'};
                        bar      = j;
                        steps    = 4;
                    end
                    highScoreChord = -1;
                end
                
                Optimal.sameScore(j,k-1) = steps;
                Optimal.chordIdx{j, k - 1} = highScoreChord;
                
                if highScoreChord ~= -1
                    Optimal.templateNo(j, k - 1) = ceil(Optimal.chordIdx{j, k-1}(1) / 12);
                    Optimal.pitchNo{j, k - 1} = ~(ceil(mod(Optimal.chordIdx{j, k - 1}, 12) / 12)) * 12 + mod(Optimal.chordIdx{j, k - 1}, 12);
                    Optimal.chordName{j, k - 1} = strcat(pitchName(Optimal.pitchNo{j, k - 1}), ':', tempName(Optimal.templateNo(j, k - 1)));
                else
                    Optimal.templateNo(j, k - 1)  = 0;
                    Optimal.pitchNo{j, k - 1}  = 0;
                    Optimal.chordName{j, k - 1} = {'X'};
                end
                
                % steps 3 : Diminished 7th resolution
                if ~para.isNowTemplate
                    if refNextBarRoot
                        idx               = find(Resolution_Dim7.idx(j-1)~=0);
                        nowRoot           = ~(ceil(mod(Resolution_Dim7.chordIdx{j-1,idx(end)},12)/12))*12 + mod(Resolution_Dim7.chordIdx{j-1,idx(end)},12);
                        nextRoot          = Optimal.pitchNo{j,k-1};
                        trueRoot          = ~(ceil(mod((nextRoot-1),12)/12))*12 + mod((nextRoot-1),12);
                        refNextBarRoot    = ~refNextBarRoot;

                        if  any(nowRoot == trueRoot)
                            Optimal.Chord(j-1, idx(end))     = Resolution_Dim7.chordIdx{j-1,idx(end)}(nowRoot == trueRoot);
                            Optimal.templateNo(j-1, idx(end))  = ceil(Optimal.Chord(j-1,idx(end))/12);
                            Optimal.pitchNo{j-1, idx(end)}  = ~(ceil(mod(Optimal.Chord(j-1,idx(end)),12)/12))*12 + mod(Optimal.Chord(j-1,idx(end)),12);
                            Optimal.ChordName{j-1, idx(end)} = strcat(pitchName(Optimal.pitchNo{j-1,idx(end)}), tempName(Optimal.templateNo(j-1,idx(end))));    

                            predictChord(evaluationIdx, 4) = Optimal.ChordName{j-1,idx(end)};
                            predictChord{evaluationIdx, 5} = Optimal.Chord(j-1,idx(end));
                        else
                            warning([ 'bar ' num2str(j) ', step3 : Fully Diminished 7th 沒有解決']);
                            Optimal.tieBreaking(j, k - 1) = {'no solve'};
                        end 
                    end
                end
                
                evaluationIdx = evaluationIdx + 1;
                predictChord{evaluationIdx, 1} = j;
                predictChord{evaluationIdx, 2} = partitionPos(partitionIdx(k - 1));
                predictChord(evaluationIdx, 4) = Optimal.chordName{j, k - 1};
                predictChord{evaluationIdx, 5} = highScoreChord;
            end
            
            % steps 3 : Diminished 7th resolution
            if ~para.isNowTemplate
                resolution_idx = find( Optimal.sameScore(j,:) == 3 );
                if resolution_idx
                    for t=1:numel(resolution_idx)        
                        nowRoot      = ~(ceil(mod(Resolution_Dim7.chordIdx{j,resolution_idx(t)},12)/12))*12 + mod(Resolution_Dim7.chordIdx{j,resolution_idx(t)},12);

                        if Optimal.chordIdx{j,resolution_idx(t)+1} ~= 0
                            nextRoot = ~(ceil(mod(Optimal.chordIdx{j,resolution_idx(t)+1},12)/12))*12 + mod(Optimal.chordIdx{j,resolution_idx(t)+1},12);
                            trueRoot = ~(ceil(mod((nextRoot-1),12)/12))*12 + mod((nextRoot-1),12);

                            if  any(nowRoot == trueRoot)
                                AnsChord = Resolution_Dim7.chordIdx{j,resolution_idx(t)}(nowRoot == trueRoot);

                                Optimal.Chord(j,resolution_idx(t))     = AnsChord;
                                Optimal.templateNo(j,resolution_idx(t))  = ceil(AnsChord/12); 
                                Optimal.pitchNo{j,resolution_idx(t)}  = ~(ceil(mod(AnsChord,12)/12))*12 + mod(AnsChord,12);
                                Optimal.ChordName{j,resolution_idx(t)} = strcat(pitchName(Optimal.pitchNo{j,resolution_idx(t)}), tempName(Optimal.templateNo(j,resolution_idx(t))));    

                                nowBarIdx = find(cell2mat(predictChord(2:end,1))==j);
                                predictChord(nowBarIdx(resolution_idx(t))+1,4) = Optimal.ChordName{j,resolution_idx(t)};
                                predictChord{nowBarIdx(resolution_idx(t))+1,5} = Optimal.Chord(j,resolution_idx(t));
                            else
                                warning([ 'bar ' num2str(j) ', step3 : Fully Diminished 7th 沒有解決']);
                                Optimal.tieBreaking(j, k - 1) = {'no solve'};
                            end 

                        else
                            refNextBarRoot = 1;
                        end   
                    end
                end
            end
            
        end
    end
end

%%
% description: 以拍點為partition point，紀錄每個minSeg內的音符權重，以及minSeg內最低音
% input:  noteBar      -> 小節音符
%         onsetBar     -> 小節開始的beat
%         para         -> 修改Pardo演算法相關的參數
%         timeSig      -> 拍號資訊
% output: pitchClass,  -> 每個minSeg有所有音，且weight為音符長度，大小為N*12 (N為minSeg數量,12為一個八度音的數量)
%         minSeg       -> 每個minSeg之onset offset的beat
function [pitchClass, minSeg] = min_seg_pitchclass(noteBar, onsetBar, para, timeSig)
    
    %% partition point設置
    if para.isPartitionDBeat
        % 以拍點為partition point
        beatInBar = noteBar(:,9);
        tmp = 0:beatInBar/timeSig:beatInBar;
        minSeg = [tmp(1:end-1); tmp(2:end)]';
    else 
        % 以note on/off為partition point
        minSeg = unique(round([noteBar(:, 1); sum(noteBar(:, 1:2), 2)], 4));
        minSeg(:, 2) = [minSeg(2:end, 1); round(sum(noteBar(end, 1:2)), 4)];
        if minSeg(end, 1) == minSeg(end, 2); minSeg(end, :)=[]; end
        minSeg(diff(minSeg, 1, 2) <= 0.025, :) = []; % 把minSeg太小的去掉
        minSeg = minSeg - onsetBar;
    end
    
    %% 紀錄所有miniSeg中每個pitch class的weight
    pitchClass = zeros(size(minSeg, 1), 12); % 紀錄每個miniSeg中pitch class

    for s = 1:size(minSeg, 1)
        for n = 1:size(noteBar, 1)
            noteOn = noteBar(n, 1) - onsetBar;
            noteOff = sum(noteBar(n,1:2)) - onsetBar;
            
            if noteOn <= minSeg(s, 1); noteOn = minSeg(s, 1); end
            if noteOff >= minSeg(s, 2); noteOff = minSeg(s, 2); end
            if noteOff - noteOn > 0   % 判斷落在minSeg內的音
                pitchNo = mod(noteBar(n, 4), 12) + 1;
                
                addScore = 1;
                if para.isDurWeight
                    addScore = noteOff - noteOn;
                end
                pitchClass(s, pitchNo) = pitchClass(s, pitchNo) + addScore;
            end
        end     
    end
    minSeg = minSeg + onsetBar;
end