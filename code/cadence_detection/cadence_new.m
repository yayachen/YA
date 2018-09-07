addpath('../toolbox/midi_lib/midi_lib')
addpath('../toolbox/MIDI tool/miditoolbox');
addpath('../')

chordSourceNo = 1; % 1:GT, 2:predict

for songIdx = 4%1:8
    for thIdx = 1%:10
        clc; close all;
        clearvars -except songIdx thIdx Result Evaluation chordSourceNo
        filename = {'m_16_1', 'm_7_1', 'h_23_1', 'h_37_1', 'c_40_1', 'c_47_1','b_4_1','b_20_1'};
    % IOI & OOI threshold
%         thOOI = thIdx*0.1;
%         thIOI = thIdx*0.1;
        
    % optimal threshold
        thIOI = 0.6;
        thOOI = 0.6;

%% read midi & GT
    % read midi
        [midiData, timeSig]  = midi_Preprocess(['../midi/pei/' filename{songIdx}]);
        [barNote, barOnset, midiData] = bar_note_data(midiData, timeSig); % each bar's information

    % read chord and key      
        if chordSourceNo == 1 % GroundTruth
%             [~, ~, data] = xlsread(['../annotation/pei/trans_' filename{songIdx} '.xlsx']);
            data = csvimport(['../annotation/pei/trans_' filename{songIdx} '.csv']);

        else % Prediect
            load(['../key_analysis/key_result/pei/eva_' filename{songIdx} '.mat']);
        end
        
    % read ground-trurh cadence
        [~, ~, cadenceGT] = xlsread(['cadenceGT/cadence_' filename{songIdx} '.xlsx']);

%% �ϥ�structure����GT���֥y&�֬q��T
        cadenceGT(1,:) = [];

        periodName = strsplit(cat(2, cadenceGT{1:end,1}), '\0');    % �e�ܳ�,�o�i��,�A�{��
        if isempty(periodName{end}); periodName(end) = []; end
        period = struct(); % �����֬q��T: startIdx, startBar, endBar, name

        cadenceName =  {'��������','����������','��','transition','�b'};
        cadenceType =  [        1,         1,  3,           0,  5 ];
        cadenceColor = {     'c',        'c','b',         'w', 'y'};
        phrase = struct(); % �O���֥y��T: startBar, endBar, cadenceType
        i = 1;
        while i <= size(cadenceGT, 1)
            % �פ��range�H�έ��Ӳפ
            if all(isnan(cat(2, cadenceGT{i,:})))
                cadenceGT(i, :) = [];
            else
                % ����GT�֥y���}�l�p�`,�����p�`(startBar, endBar)
                if ischar(cadenceGT{i, 4})
                    bar = split(cadenceGT{i, 4},'-');
                    phrase(i).startBar = str2double(bar{1});
                    phrase(i).endBar = str2double(bar{2});
                else
                    phrase(i).startBar = cadenceGT{i, 4};
                    phrase(i).endBar = cadenceGT{i, 4};
                end
                % ����GT�֥y������(cadenceType): 5��ܥb�פ�,1��ܥ���פ�
                phrase(i).cadenceType = 0;
                for j = 1:length(cadenceName)
                    if ~isempty(strfind(cadenceGT{i, 6}, cadenceName{j}))
                        phrase(i).cadenceType = cadenceType(j);
                    end
                end
            end
            % ����GT�֬q: �O�qcadenceGT���ĴXrow�}�l(rowIdx)
            if i <= size(cadenceGT, 1) && any(strcmpi(cadenceGT{i,1}, periodName))
                period(strcmpi(cadenceGT{i,1}, periodName)).startIdx = i;
            end
            i = i + 1;
        end

        % ����GT�֬q: �}�l�p�`,�����p�`,�W��(startBar, endBar, name)
        for i = 1:length(periodName)-1
            period(i).startBar = phrase(period(i).startIdx).startBar;
            period(i).endBar = phrase(period(i+1).startIdx-1).endBar;
            period(i).name = periodName{i};
        end
        period(end).startBar = phrase(period(end).startIdx).startBar;
        period(end).endBar = phrase(end).endBar;
        period(end).name = periodName{end};
        phrase([phrase.cadenceType]==0) = [];

%% �z�Lchord�Mkey => ��chord�নù���Ʀr
        load Key_DiatonicTriad_V7.mat keyFusion
        keyName = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', ...
                   'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'};
        tempMaj = [1 1 1 2 3 3 4 3]; % MAJOR:    I IV V V7 ii vi viio iii
        tempMin = [3 3 1 2 4 1 4 1]; % MINOR:    i iv V V7 iio VI viio III
        keyScale = [1 4 5 5 2 6 7 3];
        timesig = 2^timeSig(2);
        data(1,6:7) = [{'�M���ż�'}, {'��index'}];
        for i = 2:size(data, 1)
            keySplit = split(data{i,3}, '/');
            data{i,6} = 0;
            data{i,7} = find(strcmp(keyName, keySplit{1})); % keyIdx

            if ~isempty(intersect(keyFusion(data{i,7}).keyChord, data{i,5}))
                [~, idx, ~] = intersect(keyFusion(data{i,7}).keyChord, data{i,5});
                data{i,6} = keyScale(idx); % chord degree
            end
        end

%%   ��5��1���W�h
        scaleStr = num2str(cat(1,data{2:end,6}))';
        keyIdx = cat(1,data{2:end,7}); %each row �� chord, �թ�idx
        cadenceFlag = zeros(size(data, 1)-1, 1);
        V(:,1) = strfind(scaleStr, '5');
        V2I(:,1) = strfind(scaleStr, '51'); % �ŦXV2I���a��,idx����V�O�ĴX��chord

        i = 1;
        while i <= length(V2I)
            j = V2I(i, 1) + 1; % V2I��I�M��index
            if keyIdx(V2I(i,1)) ~= keyIdx(j) %  1. �P�_V2I�O�_�O�@�˪��աA���@�˴N�R��
                V2I(i,:) = [];
            else
                % 2. ����V2I�}�l�M�����b����idx, V2I(i,1:2)=[����V��idx, ����������I��idx]
                while j <= length(keyIdx) && scaleStr(j) == '1' && keyIdx(V2I(i,1)) == keyIdx(j)
                    V2I(i,2) = j; % V2I��I�����b����idx
                    cadenceFlag(V2I(i,2)) = 1;
                    j = j + 1;
                end
                i = i + 1;
            end
        end
        
%% �ϥ�structure�����Կ�פ
        detectedCadence = struct();
        j = 1;
        cadenceFlag(V) = 5;
        for i=1:length(cadenceFlag)
            if cadenceFlag(i) ~= 0
                detectedCadence(j).startBar = data{i+1, 1} + data{i+1, 2} / timesig;
                detectedCadence(j).startBeat = barOnset(data{i+1, 1}) + data{i+1, 2};

                if i+2 <= size(data, 1)
                    k = i+2;
                    if sum(cat(2,data{k, 1:2})) == sum(cat(2,data{i+1, 1:2}))  % i+1�Mi+2��bar beat �@�˪��ܴN���U�ݤ@��
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
                if j == 1
                    detectedCadence(j).no = 1;
                else
                    detectedCadence(j).no = detectedCadence(j-1).no + 1;
                    if cadenceFlag(i) == cadenceFlag(i-1) && cadenceFlag(i)==1
                        detectedCadence(j).no = detectedCadence(j-1).no;
                    end
                end
                j = j + 1;
            end
        end

    %     detectedCadence(find(diff([detectedCadence.startBar])==0)+1) = [];

%% ��ۦP�p�`��cadence�X��
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
        ooi = zeros(length(midiData)-1, 1);
        for i=1:length(midiData)-1
            ooi(i) = max(midiData(i+1, 1) - max(offset(1:i)), 0);
        end

        [~,lct] = findpeaks(ooi, 1:length(ooi),'Threshold', thOOI);

        OOI = struct();
        for i = 1:length(lct)
             peak = lct(i);
             OOI(i).BarIdx = midiData(peak(1), 11) + (sum(midiData(peak(1), 1:2)) - barOnset(midiData(peak(1), 11))') / timesig;
             OOI(i).Beat = sum(midiData(peak(1), 1:2));
             OOI(i).value = ooi(lct(i));
             OOI(i).Idx = peak(1);
        end
        
%% feature : IOI
        onset = unique(midiData(:, 1));
        ioi = onset(2:end, 1) - onset(1:end-1, 1);
        [pkt,lct] = findpeaks(ioi, 1:length(ioi),'Threshold', thIOI);

        IOI = struct;
        for i = 1:length(lct)
             peak = find(midiData(:,1) == onset(lct(i)));
             IOI(i).BarIdx = midiData(peak(1), 11) + (sum(midiData(peak(1), 1:2)) - barOnset(midiData(peak(1), 11))') / timesig;
             IOI(i).Beat = sum(midiData(peak(1), 1:2));
             IOI(i).value = ioi(lct(i));
             IOI(i).Idx = peak(1);
        end

%% figure
        color = [1.0 0.8 0.4];
        colorChange = [-0.1 -0.05 0.1];
        figure;
        for plotI = 1:length(periodName) % ��q������ �e�ܳ��B�o�i���B�A�{�� �e��
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
            set(gca,'xTick', 1:phrase(end).endBar);%,'yTick', [1:1:5]);
            t=0:0:0; set(gca,'yTick',t);
            set(gca,'Layer','top');
            title(periodName{plotI});

        end

%% �O�����ӭԿ�פ������feature => �إ� detectedCadence
        time = timeSig(1); 
        if songIdx == 7; time = 3; end % �S��B�z
        cadenceRangeGT = [[phrase.endBar]-1; [phrase.endBar]]'*time;
        detectedFallIdx = 1:size(phrase,2)-1;

        for i = 1:size(detectedCadence,2)
            % GT cadence
            detectedCadence(i).isTrueCadence = 0;
            detectedCadence(i).OOI = 0;
            detectedCadence(i).IOI = 0;

            % GT
            idx1 = (cadenceRangeGT(:,1) <= detectedCadence(i).startBeat) .* (cadenceRangeGT(:,2) > detectedCadence(i).startBeat);
            idx2 = (cadenceRangeGT(:,1) < detectedCadence(i).endBeat) .* (cadenceRangeGT(:,2) >= detectedCadence(i).endBeat);
            idx = find(and(idx1, idx2));
            detectedFallIdx(detectedFallIdx==idx) = [];
            
            warning('�u�Ҽ{����S���P�_��פ�A���Ҽ{�P�_����Ӳפ')
            if ~isempty(idx) % && phrase(idx).cadenceType == detectedCadence(i).cadenceType
                detectedCadence(i).isTrueCadence = 1;
                if idx == size(phrase, 2) % �̫�@�Ӳפ��������A���ڭ̤��Ҽ{�A�ҥH�᭱�|�R��
                    detectedCadence(i).isTrueCadence = 2;
                end
            end 
            % OOI
            if ~isempty(OOI) && any(([OOI.Beat] >= detectedCadence(i).startBeat) .* ([OOI.Beat] <= detectedCadence(i).endBeat))
                detectedCadence(i).OOI = 1;
            end
            % IOI
            if ~isempty(IOI) && any(([IOI.Beat] >= detectedCadence(i).startBeat) .* ([IOI.Beat] <= detectedCadence(i).endBeat))
                detectedCadence(i).IOI = 1;
            end
        end

        detectedCadence([detectedCadence.isTrueCadence] == 2) = []; % �̫�@�Ӳפ���Ҽ{

%% ����precision, recall, f-score�|�Ψ쪺 TP, FP, FN�U�ر��p���Ӽ�
        % �S������A��"�O�פ"
        Evaluation.detectedFail(songIdx) = length(detectedFallIdx);

        % ������A�O�פ�A���O�S��feature
        eachCan_featureSum = [detectedCadence.OOI] + [detectedCadence.IOI];
        Evaluation.GT_noFeature(songIdx) = sum(and([detectedCadence.isTrueCadence], ~eachCan_featureSum));

        % IOI & OOI �@�_��
        Evaluation.anyFeature_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], eachCan_featureSum));
        Evaluation.anyFeature_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], eachCan_featureSum));

        % �u��OOI������
        Evaluation.OOI_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], [detectedCadence.OOI]));
        Evaluation.OOI_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], [detectedCadence.OOI]));
        Evaluation.GT_noOOI(songIdx) = sum(and([detectedCadence.isTrueCadence], ~[detectedCadence.OOI]));

        % �u��IOI������
        Evaluation.IOI_isGT(songIdx) = sum(and([detectedCadence.isTrueCadence], [detectedCadence.IOI]));
        Evaluation.IOI_noGT(songIdx) = sum(and(~[detectedCadence.isTrueCadence], [detectedCadence.IOI]));
        Evaluation.GT_noIOI(songIdx) = sum(and([detectedCadence.isTrueCadence], ~[detectedCadence.IOI]));

%% �p�� precision, recall, f-score
        phraseSize = size(phrase,2) - 1; % �̫�@�Ӥ���
        
        Result = struct(); 
        %�u��OOI������
        Result(songIdx).R_OOI(thIdx) = Evaluation.OOI_isGT(songIdx)/phraseSize;
        Result(songIdx).P_OOI(thIdx) = Evaluation.OOI_isGT(songIdx)/(Evaluation.OOI_isGT(songIdx)+Evaluation.OOI_noGT(songIdx)); % sum([detectedCadence.OOI])
        Result(songIdx).F_OOI(thIdx) = 2 * Result(songIdx).R_OOI(thIdx) * Result(songIdx).P_OOI(thIdx)/(Result(songIdx).R_OOI(thIdx) + Result(songIdx).P_OOI(thIdx));

        %�u��IOI������
        Result(songIdx).R_IOI(thIdx) = Evaluation.IOI_isGT(songIdx)/phraseSize;
        Result(songIdx).P_IOI(thIdx) = Evaluation.IOI_isGT(songIdx)/(Evaluation.IOI_isGT(songIdx)+Evaluation.IOI_noGT(songIdx)); % sum([detectedCadence.IOI])
        Result(songIdx).F_IOI(thIdx) = 2 * Result(songIdx).R_IOI(thIdx) * Result(songIdx).P_IOI(thIdx)/(Result(songIdx).R_IOI(thIdx) + Result(songIdx).P_IOI(thIdx));

        %OOI�MIOI������
        Result(songIdx).R(thIdx) = Evaluation.anyFeature_isGT(songIdx)/phraseSize;
        Result(songIdx).P(thIdx) = Evaluation.anyFeature_isGT(songIdx)/(Evaluation.anyFeature_isGT(songIdx)+Evaluation.anyFeature_noGT(songIdx));
        Result(songIdx).F(thIdx) = 2 * Result(songIdx).R(thIdx) * Result(songIdx).P(thIdx)/(Result(songIdx).R(thIdx) + Result(songIdx).P(thIdx));

    end
end
