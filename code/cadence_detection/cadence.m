clear; close all; clc;
addpath('../toolbox/midi_lib/midi_lib')
addpath('../toolbox/MIDI tool/miditoolbox');
addpath('../')

for songIdx = 4%1:8
    clc
for thIdx = 1%:10
    close all
    songIdx
    thIdx
    clearvars -except songIdx thIdx Result Evaluation OOI_R OOI_P OOI_F IOI_R IOI_P IOI_F

filename = {'m_16_1', 'm_7_1', 'h_23_1', 'h_37_1', 'c_40_1', 'c_47_1','b_4_1','b_20_1'};
thOOI = thIdx*0.1;
thIOI = thIdx*0.1;
thIOI = 0.6;
thOOI = 0.6;

% TH_OOI = [0.1 0.4 0.4 0.3 0.6 0.1 0.6 0.6];
% TH_IOI = [0.3 0.6 0.4 0.3 0.2 0.6 0.6 0.6];
% thOOI = TH_OOI(songIdx)
% thIOI = TH_IOI(songIdx)
%% read midi & GT

% midi
[midiData, timeSig]  = midi_Preprocess(['../midi/pei/' filename{songIdx}]);
[barNote, barOnset, midiData] = bar_note_data(midiData, timeSig); % each bar's information


% GroundTruth :  chord and key
[~, ~, data] = xlsread(['../annotation/trans_' filename{songIdx} '.xlsx']);
%     load(['../key_analysis/key_result/pei/eva_' filename{songIdx} '.mat']);
%     data = evaKey;

% GroundTrurh :  cadence
[~, ~,  cadenceGT] = xlsread(['cadenceGT/cadence_' filename{songIdx} '.xlsx']);

%% 找樂段以及終止式的range
cadenceGT(1,:) = [];

periodName = strsplit(cat(2, cadenceGT{1:end,1}), '\0');    % 呈示部,發展部,再現部
if isempty(periodName{end}); periodName(end) = []; end
periodRange = zeros(length(periodName), 2);                 % 三部從哪小節開始與結束
periodStartIdx = zeros(length(periodName), 1);              % 三部在 cadenceGT 的哪個idx開始
period = struct();

cadenceName = {'完全正格','不完全正格','假','transition','半'};
cadenceIdx = [1 1 3 0 5];
cadenceColor = {'c', 'c', 'c', 'c', 'c'};%{'c', 'g', 'b', 'w', 'y'};
cadenceRangeGT = zeros(size(cadenceGT, 1), 2);
phrase = struct();
i = 1;
while i <= size(cadenceGT, 1)
    % 終止式的range以及哪個終止式
    if all(isnan(cat(2, cadenceGT{i,:})))
        cadenceGT(i, :) = [];
        cadenceRangeGT(i, :) = [];
    else
        if ischar(cadenceGT{i, 4})
            bar = split(cadenceGT{i, 4},'-');
            phrase(i).startBar = str2double(bar{1});
            phrase(i).endBar = str2double(bar{2});
        else
            phrase(i).startBar = cadenceGT{i, 4};
            phrase(i).endBar = cadenceGT{i, 4};
        end
        
        phrase(i).cadenceType = 0;
        for j = 1:length(cadenceName)
            if ~isempty(strfind(cadenceGT{i, 6}, cadenceName{j}))
                phrase(i).cadenceType = cadenceIdx(j);
            end
        end
    end
    % 樂段開始的rowIdx
    if i <= size(cadenceGT, 1) && any(strcmpi(cadenceGT{i,1}, periodName))
        period(strcmpi(cadenceGT{i,1}, periodName)).startIdx = i;
    end
    i = i + 1;
end

% 樂段的range
for i = 1:length(periodName)-1
    period(i).startBar = phrase(period(i).startIdx).startBar;
    period(i).endBar = phrase(period(i+1).startIdx-1).endBar;
    period(i).name = periodName{i};
end
period(end).startBar = phrase(period(end).startIdx).startBar;
period(end).endBar = phrase(end).endBar;
period(end).name = periodName{end};
phrase([phrase.cadenceType]==0) = [];

%% 透過chord和key 找5到1的規則

load Key_DiatonicTriad_V7.mat keyFusion
keyName = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', ...
           'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'};
tempMaj = [1 1 1 2 3 3 4 3]; % MAJOR:    I IV V V7 ii vi viio iii
tempMin = [3 3 1 2 4 1 4 1]; % MINOR:    i iv V V7 iio VI viio III
keyScale = [1 4 5 5 2 6 7 3];
timesig = 2^timeSig(2);
% keyIdx = zeros(size(data, 1)-1, 1);
data{1,6} = {'和弦級數'};
data{1,7} = {'調index'};
for i = 2:size(data, 1)
    keySplit = split(data{i,3}, '/');
%     keyIdx(i-1) = find(strcmp(keyName, keySplit{1}));
    data{i,6} = 0;
    data{i,7} = find(strcmp(keyName, keySplit{1}));
%     if ~isempty(intersect(keyFusion(keyIdx(i-1)).keyChord, data{i,5}))
%         [~, idx, ~] = intersect(keyFusion(keyIdx(i-1)).keyChord, data{i,5});
%         data{i,6} = keyScale(idx); 
%     end
    if ~isempty(intersect(keyFusion(data{i,7}).keyChord, data{i,5}))
        [~, idx, ~] = intersect(keyFusion(data{i,7}).keyChord, data{i,5});
        data{i,6} = keyScale(idx); 
    end
end
scaleStr = num2str(cat(1,data{2:end,6}))';
keyIdx = cat(1,data{2:end,7});
%%   
    cadenceFlag = zeros(size(data, 1)-1, 1);
    V(:,1) = strfind(scaleStr, '5');
    V2I(:,1) = strfind(scaleStr, '51');
    % V2I
    i = 1;
    while i <= length(V2I)
        j = V2I(i, 1) + 1;
        if keyIdx(V2I(i,1)) ~= keyIdx(j)
            V2I(i,:) = [];
        else
            while j <= length(keyIdx) && scaleStr(j) == '1' && keyIdx(V2I(i,1)) == keyIdx(j)
%             while j <= length(keyIdx) && (scaleStr(j) == '1' || scaleStr(j) == '0') && keyIdx(V2I(i,1)) == keyIdx(j)
                V2I(i,2) = j;
                cadenceFlag(V2I(i,2)) = 1;
                j = j + 1;
            end
            i = i + 1;
        end
    end
    
    % 轉調的第一小節（看是否是前小節的V）
    modulateIdx = find(diff(keyIdx)~=0)+1;
    for m = 1:length(modulateIdx)
        if (data{modulateIdx(m)+1, 5} <= 12 && data{modulateIdx(m)+1, 5} > 0)
            preKeyIdx = find(strcmp(keyName, data{modulateIdx(m)+1, 3}));
            if strcmp(keyName(preKeyIdx), keyName(data{modulateIdx(m)+1, 5}))
                V = unique([V; modulateIdx]);
            end
        end
    end
%     V = unique([V; modulateIdx]);
    % V
%     i = 1;
%     while i <= length(V)
%         j = V(i, 1) + 1;
%         if ~(keyIdx(V(i,1)) == keyIdx(j))
%             V(i,:) = [];
%         else
%             while j <= length(keyIdx) && scaleStr(j) == '0' && keyIdx(V(i,1)) == keyIdx(j)
%                 V(i,2) = j;
%                 cadenceFlag(V(i,2)) = 5;
%                 j = j + 1;
%             end
%             i = i + 1;
%         end
%     end
    detectedCadence = struct();
    j = 1;
    cadenceFlag(V) = 5;
    for i=2:length(cadenceFlag)
        if cadenceFlag(i) ~= 0
            detectedCadence(j).startBar = data{i+1, 1} + data{i+1, 2} / timesig;
            detectedCadence(j).startBeat = barOnset(data{i+1, 1}) + data{i+1, 2};
            if i+2 <= size(data, 1)
                k = i+2;
                if sum(cat(2,data{k, 1:2})) == sum(cat(2,data{i+1, 1:2}))  % i+1和i+2的bar beat 一樣的話就往下看一行
                    k = k + 1;
                end
                detectedCadence(j).endBar = data{k, 1} + data{k, 2} / timesig;
                detectedCadence(j).endBeat = barOnset(data{k, 1}) + data{k, 2};
            else
                detectedCadence(j).endBar = data{i+1, 1} + 1;
                detectedCadence(j).endBeat = barOnset(data{i+1, 1}) + 4;
            end
            detectedCadence(j).cadenceType = cadenceFlag(i);
            
            if j~=1 && detectedCadence(j).startBar - detectedCadence(j-1).startBar == 0
                detectedCadence(j) = [];
                continue;
            end
% %             if j~=1 && detectedCadence(j).cadenceType == detectedCadence(j-1).cadenceType && detectedCadence(j).cadenceType == 1
% %                 detectedCadence(j-1).endBar = detectedCadence(j).endBar;
% %                 detectedCadence(j-1).endBeat = detectedCadence(j).endBeat;
% %                 continue;
% %             end
            if j == 1
                detectedCadence(j).no = 1;
            else
                detectedCadence(j).no = detectedCadence(j-1).no + 1;
                if cadenceFlag(i) == cadenceFlag(i-1) && cadenceFlag(i)==1
                    detectedCadence(j).no = detectedCadence(j-1).no;
                end
            end
            j = j + 1;
%             if j == 1
%                 detectedCadence(j).no = 1;
%             else
%                 detectedCadence(j).no = detectedCadence(j-1).no;
%                 if cadenceFlag(i)==5
%                     detectedCadence(j).no = detectedCadence(j-1).no + 1;
%                 end
%             end
%             j = j + 1;
        end
    end
    
%     detectedCadence(find(diff([detectedCadence.startBar])==0)+1) = [];
    
%% 把同小節的cadence合併
detectedCadence1 = detectedCadence;
c = 1;
while c < length(detectedCadence1) 
    if floor(detectedCadence1(c).startBar) == floor(detectedCadence1(c+1).startBar)
        detectedCadence1(c).endBar = detectedCadence1(c+1).endBar;
        detectedCadence1(c).endBeat = detectedCadence1(c+1).endBeat;
        detectedCadence1(c+1) = [];
    else
        c = c + 1;
    end
end
detectedCadence = detectedCadence1;

%% feature : OOI
    offset = sum(midiData(:,1:2), 2);
    iri = zeros(length(midiData)-1, 1);
    for i=1:length(midiData)-1
        iri(i) = max(midiData(i+1, 1) - max(offset(1:i)), 0);
    end

    [pkt,lct] = findpeaks(iri, [1:length(iri)],'Threshold', thOOI);
%     figure;
%     ha = tight_subplot(2,1,0.05)
%     axes(ha(1)); findpeaks(iri, [1:length(iri)],'Threshold', thOOI);
%     axes(ha(2)); findpeaks(iri, [1:length(iri)],'Threshold', thOOI,'minpeakdistance',10);
%     set(ha,'XTickLabel',''); set(ha,'YTickLabel','')

    OOI = [];
    for i = 1:length(lct)
         peak = lct(i); % find(midiData(:,1) == offset(lct(i)));
         OOI(i).BarIdx = midiData(peak(1), 11) + (sum(midiData(peak(1), 1:2)) - barOnset(midiData(peak(1), 11))') / timesig;
         OOI(i).Beat = sum(midiData(peak(1), 1:2));
         OOI(i).value = iri(lct(i));
         OOI(i).Idx = peak(1);
    end
%% feature : IOI
    onset = unique(midiData(:, 1));
    ioi = onset(2:end, 1) - onset(1:end-1, 1);

%     idx = find(ioi(1:end-1) > thIOI);
%     tmp = find(ioi(idx+1) <=  ioi(idx)/2);
%     lct = idx(tmp);
    [pkt,lct] = findpeaks(ioi, [1:length(ioi)],'Threshold', thIOI);
    
%     figure;
%     plot(ioi); hold on 
%     plot(lct,ioi(lct),'x');

    IOI = [];
    for i = 1:length(lct)
         peak = find(midiData(:,1) == onset(lct(i)));
         IOI(i).BarIdx = midiData(peak(1), 11) + (sum(midiData(peak(1), 1:2)) - barOnset(midiData(peak(1), 11))') / timesig;
         IOI(i).Beat = sum(midiData(peak(1), 1:2));
         IOI(i).value = ioi(lct(i));
         IOI(i).Idx = peak(1);
    end
%     featureIOI(songIdx) = IOI;
   
%% feature : 動機
[ curve, pitchInfo ] = createCurve( midiData, timeSig, 'modifySkyline', 'top');
pattern  = curve2pattern( pitchInfo, curve, timeSig);
SSM  = similar_matrix(pattern.barPath, pattern.barPath, 'correlation');
SSM(SSM < 0.95) = 0;
% figure, imagesc(SSM);

similarBar1 = find(SSM(:,1)>0);
motif.BarIdx = similarBar1;  %% new
%     similarBar2 = find(SSM(:,2)>0);
%     motif.BarIdx = intersect(similarBar1, similarBar2 - 1);
motif.BarIdx(motif.BarIdx==1) = [];

matrix = eye(3); matrix(1) = 0;
j = length(motif.BarIdx)+1;
for i=3:length(SSM)-1
    if sum(sum(SSM(1:3,i-1:i+1).*matrix))/2 > 0.9
        BarIdx(j) = i - 1;
        j = j + 1;
    end
end
barIdxUni = unique(BarIdx);
for i = 1:length(barIdxUni)
     motif(i).BarIdx = barIdxUni(i);
     motif(i).Beat = (barIdxUni(i)-1) * timeSig(1);
end
motif([motif.BarIdx]==0) = [];
% motif.BarIdx = unique(BarIdx)';
% motif.Beat = BarIdx * timeSig(1);
% featureMotif(songIdx) = motif;
% motif.BarIdx(:) = [];
% motif.Beat(:) = [];


%% figure; ori    
color = [1.0 0.8 0.4];
colorChange = [-0.1 -0.05 0.1];
figure;
for plotI = 1:length(periodName) % 三個部分開畫
    subplot(length(periodName), 1, plotI);
    % OOI
    if ~isempty(OOI)
        colorTmp = [OOI.value];
        colorTmp(colorTmp>1) = 1;
        for i = 1:size(OOI, 2)
            plot(OOI(i).BarIdx, 2.5, 'o','MarkerSize', 5, 'color', 'b','MarkerFaceColor',[0 colorTmp(i) colorTmp(i)]); hold all;
        end
    end
    %IOI
    if ~isempty(IOI)
        colorTmp = [IOI.value];
        colorTmp(colorTmp>1) = 1;
        for i = 1:size(IOI, 2)
            plot(IOI(i).BarIdx, 1.5, 'o','MarkerSize', 5, 'color', 'r','MarkerFaceColor',[colorTmp(i) colorTmp(i) 0]); hold all;
        end
    end
%     % motif
%     if ~isempty(motif)
%         for i = 1:size(motif, 2)
%             plot(motif(i).BarIdx, 3.5, 'o','MarkerSize', 5, 'color', 'g','MarkerFaceColor','g'); hold all;
%         end
%     end
    % cadence GT 
    for i = 1:size(phrase, 2)
        patch([ phrase(i).endBar+1, phrase(i).endBar, phrase(i).endBar, phrase(i).endBar+1], [0,0,6,6], [180 180 180]/255, 'facealpha',0.4,'EdgeColor',[180 180 180]/255)
%         patch([cadenceRangeEva(i,1) cadenceRangeEva(i,2) cadenceRangeEva(i,2) cadenceRangeEva(i,1)], [0 0 1.5 1.5],cadenceColor{cadenceRangeEva(i,3)},'facealpha',0.4,'EdgeColor',[180 180 180]/255); 

%         rectangle('Position', [phrase(i).endBar, 5, 1, 1], 'FaceColor', 'r')%cadenceColor{phrase(i).cadenceType})%,'Curvature',[1,1],...'FaceColor','w','EdgeColor','g')
%         text(phrase(i).endBar+0.5, 4.5, cadenceName{phrase(i).cadenceType}, 'HorizontalAlignment', 'center', 'FontSize', 10); hold all
    end
    
    % cadence EVA
    for i = 1:size(detectedCadence, 2)
        rectangle('Position', [detectedCadence(i).startBar, 3, detectedCadence(i).endBar-detectedCadence(i).startBar, .8], 'FaceColor', cadenceColor{detectedCadence(i).cadenceType})%,'Curvature',[1,1],...'FaceColor','w','EdgeColor','g')
%         text(detectedCadence(i).startBar+0.2, 5.5, num2str(detectedCadence(i).cadenceType), 'HorizontalAlignment', 'center', 'FontSize', 10)
        hold all
    end

    period(plotI).startBar = phrase(period(plotI).startIdx).startBar;
    if plotI ~= size(period, 2)
        period(plotI).endBar = phrase(period(plotI+1).startIdx).startBar;
    else
        period(plotI).endBar = phrase(end).endBar + 1;
    end
    axis([period(plotI).startBar period(plotI).endBar 0, 5]); grid on
    set(gca,'xTick', [1:1:phrase(end).endBar]);%,'yTick', [1:1:5]);
    t=0:0:0; set(gca,'yTick',t);
    set(gca,'Layer','top');
    title(periodName{plotI});

end
%{

% cadenceColor = {[128 128 128]/255, 'g', 'b', 'w', [220 220 220]/255};
% gcf = figure;
% for plotI = 1
% 
%     for i = 1:size(detectedCadence, 2)
%         if i~=1% & cadenceRangeEva(i-1)~=cadenceRangeEva(i)  % 啥意思？
%         patch([detectedCadence(i).startBar detectedCadence(i).endBar detectedCadence(i).endBar detectedCadence(i).startBar], [0 0 1.5 1.5],cadenceColor{detectedCadence(i).cadenceType},'facealpha',0.2,'EdgeColor',[220 220 220]/255); 
%         if detectedCadence(i).cadenceType == 1
%             Ctext = 'I';
%         else
%             Ctext = 'V';
%         end
%         text(detectedCadence(i).startBar+(detectedCadence(i).endBar-detectedCadence(i).startBar)/2, 1.3, Ctext, 'HorizontalAlignment', 'center', 'FontSize', 20, 'fontname' , 'Times New Roman')
%         hold all
%         end
%     end
% 
%     period(plotI).startBar = phrase(period(plotI).startIdx).startBar;
%     if plotI ~= size(period,2)
%         period(plotI).endBar = phrase(period(plotI+1).startIdx).startBar;
%     else
%         period(plotI).endBar = phrase(end).endBar + 1;
%     end
%     axis([period(plotI).startBar period(plotI).endBar 0, 1.5]);% grid on
%     axis([10 14 0, 1.5]);
%     set(gca,'xTick', [1:1:phrase(end).endBar], 'FontSize', 20, 'fontname' , 'Times New Roman');%,'yTick', [1:1:5]);
% %     t=0:0:0; set(gca,'yTick',t);
%     set(gca,'Layer','top');
% %     title(periodName{plotI});
%     tmp = offset(1:end-1)/4+1;
%     hold on;   [PKS,LOCS]= findpeaks(iri,[1:length(iri)],'Threshold', thOOI);
%     tmp_pre = midiData(2:end,1)/4+1;
%     plot(tmp_pre(LOCS), PKS+0.05, 'v', 'markersize', 10,'color',[230, 46, 0]/255,'MarkerFaceColor',[230, 46, 0]/255); hold on;
%     idx = find(and(tmp>=period(plotI).startBar, tmp<period(plotI).endBar));
%     
%     plot(tmp_pre(idx),iri(idx),'color',[0, 71, 179]/255, 'linewidth', 1.5); hold on; 
%     line([period(plotI).startBar period(plotI).endBar],[thOOI thOOI],'color',[230, 46, 0]/255,'linewidth', 1.5); hold on;
%     for b=1:73
%         line([b b],[0 2],'color','k', 'linestyle','--'); hold on;
%     end
%     xlabel('Time (Bar)', 'FontSize', 20, 'fontname' , 'Times New Roman'); 
%     ylabel('Value'     , 'FontSize', 20, 'fontname' , 'Times New Roman');
% end
%}

%% 要記錄哪個候選終止式有feature

time = timeSig(1); if songIdx == 7; time = 3; end
cadenceRangeGT = [[phrase.endBar]-1; [phrase.endBar]]'*time;
cadenceNoGT = 1:size(phrase,2)-1;

if any([phrase.cadenceType]==2)
    phrase([phrase.cadenceType]==2).cadenceType = 1; % 不完全正格終止 也是正格終止
end
candidateCadence = struct();

for i = 1:size(detectedCadence,2)
    % GT cadence
    
    candidateCadence(detectedCadence(i).no).isTrueCadence = 0;
    candidateCadence(detectedCadence(i).no).OOI = 0;
    candidateCadence(detectedCadence(i).no).IOI = 0;
    candidateCadence(detectedCadence(i).no).motif = 0;
    detectedCadence(i).isTrueCadence = 0;
    detectedCadence(i).OOI = 0;
    detectedCadence(i).IOI = 0;
    detectedCadence(i).motif = 0;
    
    % GT
    idx1 = (cadenceRangeGT(:,1) <= detectedCadence(i).startBeat) .* (cadenceRangeGT(:,2) > detectedCadence(i).startBeat);
    idx2 = (cadenceRangeGT(:,1) < detectedCadence(i).endBeat) .* (cadenceRangeGT(:,2) >= detectedCadence(i).endBeat);
    idx = find(and(idx1, idx2));
    cadenceNoGT(cadenceNoGT==idx) = [];
    warning('here debug')
    if ~isempty(idx) %&& phrase(idx).cadenceType == detectedCadence(i).cadenceType
        candidateCadence(detectedCadence(i).no).isTrueCadence = 1;
        detectedCadence(i).isTrueCadence = 1;
        if idx == size(phrase, 2)
            candidateCadence(detectedCadence(i).no).isTrueCadence = 2;
            detectedCadence(i).isTrueCadence = 2;
        end
    end 
    % rest
    if ~isempty(OOI) & any(([OOI.Beat] >= detectedCadence(i).startBeat) .* ([OOI.Beat] <= detectedCadence(i).endBeat))
        candidateCadence(detectedCadence(i).no).OOI = 1;
        detectedCadence(i).OOI = 1;
    end
    % ioi
    if ~isempty(IOI) & any(([IOI.Beat] >= detectedCadence(i).startBeat) .* ([IOI.Beat] <= detectedCadence(i).endBeat))
        candidateCadence(detectedCadence(i).no).IOI = 1;
        detectedCadence(i).IOI = 1;
    end
    % motif
    motifpreBeat = [motif.Beat]-timeSig(1);
    idx1 = (motifpreBeat <= detectedCadence(i).startBeat) .* ([motif.Beat] > detectedCadence(i).startBeat);
    idx2 = (motifpreBeat < detectedCadence(i).endBeat) .* ([motif.Beat] >= detectedCadence(i).endBeat);
    idx = find(and(idx1, idx2));
    if ~isempty(idx)
        candidateCadence(detectedCadence(i).no).motif = 1;
        detectedCadence(i).motif = 1;
    end
    
%     if ~isempty(motif) & any(([motif.Beat] >= detectedCadence(i).startBeat) .* ([IOI.Beat] <= detectedCadence(i).endBeat))
%     end
%         if ~isempty(motif) & any(([motif.Beat] > detectedCadence(i).startBeat) .* ([motif.Beat] <= detectedCadence(i).endBeat))
%         candidateCadence(detectedCadence(i).no).motif = 1;
%         detectedCadence(i).motif = 1;
%     end
%     if ~isempty(motif) & any(([motif.Beat] >= detectedCadence(i).startBeat) .* ([motif.Beat] < detectedCadence(i).endBeat))
%         candidateCadence(detectedCadence(i).no).motif = 1;
%         detectedCadence(i).motif = 1;
%     end
end

% 最後一個終止式不算 
detectedCadence([detectedCadence.isTrueCadence] == 2) = [];

%% 最後一個終止式還沒處理 不要算～！！！！！
% 沒偵測到，但"是終止式"
Evaluation.detectedFall(songIdx) = length(cadenceNoGT);

% 偵測到，是終止式，但是沒有feature
eachCan_featureSum = [detectedCadence.OOI] + [detectedCadence.IOI] + [detectedCadence.motif];
Evaluation.GT_noFeature(songIdx) = sum(and([detectedCadence.isTrueCadence], ~eachCan_featureSum));
% dT_C_xxx = sum(isTC .* ~sum(feva,2));
% dT_C_xxxNM = sum(isTC .* ~sum(feva(:,1:2),2));

% 不是GT x
% 是GT   C 
% 偵測到，有feature
Evaluation.anyFeature_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], eachCan_featureSum));
Evaluation.anyFeature_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], eachCan_featureSum));

% 偵測到，有feature 除了 motif
eachCan_twofeatureSum = [detectedCadence.OOI] + [detectedCadence.IOI];
Evaluation.twoFeature_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], eachCan_twofeatureSum));
Evaluation.twoFeature_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], eachCan_twofeatureSum));
Evaluation.GT_noTwoFeature(songIdx) = sum(and([detectedCadence.isTrueCadence], ~eachCan_twofeatureSum));

% 偵測到，有rest feature (R)
Evaluation.OOI_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], [detectedCadence.OOI]));
Evaluation.OOI_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], [detectedCadence.OOI]));
Evaluation.GT_noOOI(songIdx) = sum(and([detectedCadence.isTrueCadence], ~[detectedCadence.OOI]));

% 偵測到，有IOI feature (O)
Evaluation.IOI_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], [detectedCadence.IOI]));
Evaluation.IOI_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], [detectedCadence.IOI]));
Evaluation.GT_noIOI(songIdx) = sum(and([detectedCadence.isTrueCadence], ~[detectedCadence.IOI]));


% 偵測到，有動機 (M)
Evaluation.motif_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], [detectedCadence.motif]));
Evaluation.motif_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], [detectedCadence.motif]));
Evaluation.GT_noMotif(songIdx) = sum(and([detectedCadence.isTrueCadence], ~[detectedCadence.motif]));

% 偵測到，有 IOI OOI (RO)
% 偵測到，有 IOI 動機 (OM)
% 偵測到，有 OOI 動機 (RM)
% 偵測到，有 IOI OOI 動機 (ROM)

%% 
% cNum = size(cadenceRangeGT,1);
phraseSize = size(phrase,2) - 1; % 最後一個不算
Result(songIdx).R_OOI(thIdx)   = Evaluation.OOI_isGT(songIdx)/phraseSize;%(phraseSize-length(cadenceNoGT)); % size(phrase,2)
Result(songIdx).P_OOI(thIdx)   = Evaluation.OOI_isGT(songIdx)/(Evaluation.OOI_isGT(songIdx)+Evaluation.OOI_noGT(songIdx)); % sum([detectedCadence.OOI])
Result(songIdx).F_OOI(thIdx)   = 2 * Result(songIdx).R_OOI(thIdx) * Result(songIdx).P_OOI(thIdx)/(Result(songIdx).R_OOI(thIdx) + Result(songIdx).P_OOI(thIdx));
OOI_R(songIdx, thIdx) = Result(songIdx).R_OOI(thIdx);
OOI_P(songIdx, thIdx) = Result(songIdx).P_OOI(thIdx);
OOI_F(songIdx, thIdx) = Result(songIdx).F_OOI(thIdx);

Result(songIdx).R_IOI(thIdx)   = Evaluation.IOI_isGT(songIdx)/phraseSize;%(phraseSize-length(cadenceNoGT)); % size(phrase,2)
Result(songIdx).P_IOI(thIdx)   = Evaluation.IOI_isGT(songIdx)/(Evaluation.IOI_isGT(songIdx)+Evaluation.IOI_noGT(songIdx)); % sum([detectedCadence.IOI])
Result(songIdx).F_IOI(thIdx)   = 2 * Result(songIdx).R_IOI(thIdx) * Result(songIdx).P_IOI(thIdx)/(Result(songIdx).R_IOI(thIdx) + Result(songIdx).P_IOI(thIdx));
IOI_R(songIdx, thIdx) = Result(songIdx).R_IOI(thIdx);
IOI_P(songIdx, thIdx) = Result(songIdx).P_IOI(thIdx);
IOI_F(songIdx, thIdx) = Result(songIdx).F_IOI(thIdx);

Result(songIdx).R_motif(thIdx) = Evaluation.motif_isGT(songIdx)/phraseSize;%(phraseSize-length(cadenceNoGT)); % size(phrase,2)
Result(songIdx).P_motif(thIdx) = Evaluation.motif_isGT(songIdx)/(Evaluation.motif_isGT(songIdx)+Evaluation.motif_noGT(songIdx)); % sum([detectedCadence.motif])
Result(songIdx).F_motif(thIdx) = 2 * Result(songIdx).R_motif(thIdx) * Result(songIdx).P_motif(thIdx)/(Result(songIdx).R_motif(thIdx) + Result(songIdx).P_motif(thIdx));

Evaluation.twoFeature_isGT(songIdx)
Result(songIdx).R_twofeature(thIdx) = Evaluation.twoFeature_isGT(songIdx)/phraseSize;%(phraseSize-length(cadenceNoGT));
Result(songIdx).P_twofeature(thIdx) = Evaluation.twoFeature_isGT(songIdx)/(Evaluation.twoFeature_isGT(songIdx)+Evaluation.twoFeature_noGT(songIdx));
Result(songIdx).F_twofeature(thIdx) = 2 * Result(songIdx).R_twofeature(thIdx) * Result(songIdx).P_twofeature(thIdx)/(Result(songIdx).R_twofeature(thIdx) + Result(songIdx).P_twofeature(thIdx));

Result(songIdx).R(thIdx) = Evaluation.anyFeature_isGT(songIdx)/phraseSize;%(phraseSize-length(cadenceNoGT));
Result(songIdx).P(thIdx) = Evaluation.anyFeature_isGT(songIdx)/(Evaluation.anyFeature_isGT(songIdx)+Evaluation.anyFeature_noGT(songIdx));
Result(songIdx).F(thIdx) = 2 * Result(songIdx).R(thIdx) * Result(songIdx).P(thIdx)/(Result(songIdx).R(thIdx) + Result(songIdx).P(thIdx));

end
end
