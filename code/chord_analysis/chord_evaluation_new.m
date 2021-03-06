%%%% content: 和弦評估(chord_evaluation)
%%%% input  : 1. PredictChord  -> 演算法預測chord的結果
%%%%          2. GTChord  -> GT chord
%%%%          3. timeSig  -> 拍號資訊
%%%%          4. unit     -> 評估的單位beat(切成多細來算CSR)
%%%%
%%%% output : 1. CSR
%%%%          2. GTChordArray       -> 把GT chord，每小節每拍有的和弦名字(col:1~4拍, row:小節)
%%%%          3. predictChordArray  -> 把預測chord，每小節每拍有的和弦名字(col:1~4拍, row:小節)

% debug
%     GTFile  = 'b_4_1';%'';
%     evaFile = 'trans_b_4_1';
%     [~, ~,  GTChord] = xlsread(['../annotation/' GTFile '.xlsx']);
%     [~, ~, PredictChord] = xlsread(['chord_result/' evaFile '.xlsx']);

function [CSR, GTChordArray, predictChordArray] = chord_evaluation_new(PredictChord, GTChord, timeSig, unit)
    if nargin < 3, timeSig = 4; end
    if nargin < 4, unit = 1; end
    
    % want to structure
    [GTarray , ~ ] = toArray( GTChord, unit, timeSig);
    [EVAarray, ~ ] = toArray(PredictChord, unit, timeSig);
    CSR = sum(sum(GTarray-EVAarray==0)) / ( (size(GTarray,1)*size(GTarray,2)) - sum(sum(GTarray==0)) );

    % 為了要看 GTChordArray, predictChordArray
    unit = 1;
    [~ , GTChordArray     ] = toArray( GTChord, unit, timeSig);
    [~ , predictChordArray] = toArray(PredictChord, unit, timeSig);
end

function [chordNo, chordName] = toArray(data, unit, timeSig)
    barNum      = data{end,1};
    chordNo     = zeros(barNum, timeSig/unit);
    chordName   = repmat({'-'}, barNum, timeSig/unit);
    
    for i=2:length(data)
        on = floor(data{i,2}/unit)+1; 
        if i~=length(data)
            off = ceil(data{i+1,2}/unit);
            if data{i+1,2}==0; off = timeSig/unit; end
        else
            off = timeSig/unit;
        end
        %把原本演算法減七和弦 合併為減三和弦的idx
        if data{i,5} > 48
            warning('減七和弦合併為減三和弦，如果不要合併請把這裡的if註解');
            data{i,5} = mod(data{i,5}, 12) + 36;
        end
        chordNo  (data{i,1}, on:off) = data{i,5};
        chordName{data{i,1}, on}     = data{i,4};
    end
end