%%%% content: 調性評估
%%%% input  : 1. predictKey  -> 演算法預測key的結果
%%%%          2. GTdata      -> ground truth
%%%%          3. w           -> 容忍誤差 w = 2 or 3
%%%%
%%%% output : 1. accuracy    -> 評估結果，label & segmentation accuracy
%%%%          2. boundary    -> GT , predict & tolRange 邊界
%%%%          3. key         -> GT & predict key name
%%%%          4. numRatio    -> TP, predict boundary, GT boundary 個數比


%%  debug
% clc; clear;
% fname = 'm_16_1'
%     fileEva = 'eva_mz_545_1_pro_GTmodify';
%     fileGT  = 'trans_chord_k545_m1';%''; trans_chord_k309_m1, trans_chord_k545_m1
% %     [number, text, predictKey] = xlsread(['chordEva/' fileEva '.xlsx']);
%     load(['key_result/pei/chordGT/eva_' fname '.mat']); 
%     predictKey = evaKey;
%     [~, ~, GTdata] = xlsread(['../annotation/trans_' fname '.xlsx']);
% w = 3

function [accuracy, boundary, key, numRatio] = key_evaluation_new(predictKey, GTdata, w)
    
    if w ~= 2 && w ~= 3
        error('w必須要等於2或3');
    end
    keyName     = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', ...
                   'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'};
    
    barNum = GTdata{end, 1};
    
    % predict key
    predictKeyNo = zeros(1, barNum);
    predictKeyName = cell(1, barNum);
    for i = 2:size(predictKey, 1)
        predictKeyNo(predictKey{i, 1}) = find(strcmp(predictKey{i, 3}, keyName));
        predictKeyName{predictKey{i, 1}} = keyName{predictKeyNo(predictKey{i, 1})};
    end

    % groundtruth key
    GTKeyName = cell(1, barNum);
    GTKeyNo = zeros(1, barNum);
    for i = 2:size(GTdata,1)
        splitGT = split(GTdata{i, 3}, '/');
        GTKeyName{GTdata{i,1}} = splitGT{1};
        GTKeyNo(GTdata{i,1}) = find(strcmp(GTKeyName{GTdata{i,1}}, keyName));
    end
    
    key = [GTKeyName; predictKeyName];
    
%% Label accuracy
    keyDiff = GTKeyNo - predictKeyNo;
    accuracy.label = sum(keyDiff==0)/barNum;

%% Segmentation accuracy
    boundary.predict = find(diff(predictKeyNo)~=0) + 1;
    boundary.GT = find(diff(GTKeyNo)~=0) + 1;
    
    boundary.tolRange = boundary.GT;
    if w == 3
        boundary.tolRange = unique([boundary.GT boundary.GT-1 boundary.GT+1]);
    elseif w == 2
        boundary.tolRange = unique([boundary.GT boundary.GT-1]);
    end
    
    TP = intersect(boundary.predict, boundary.tolRange);
    accuracy.segR = length(TP)/length(boundary.GT);
    accuracy.segP = length(TP)/length(boundary.predict);
    accuracy.segF = 2*accuracy.segR*accuracy.segP/(accuracy.segR+accuracy.segP);
    
    numRatio = [length(TP), length(boundary.predict), length(boundary.GT)]; % 個數比
end