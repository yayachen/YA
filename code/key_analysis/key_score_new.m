%%%% description : 計算每個小節中每一個調的分數
%%%% input :  chord   -> 和弦資訊
%%%%          barNote -> 小節音符資訊
%%%% output : score   -> 每個小節每個調的分數(和弦*音階)

%% debug
% clear; clc; close all;
% addpath('../');
% addpath('../toolbox/midi_lib/midi_lib');
% 
% fname = 'm_16_1'
% [midiData, timeSig] = midi_Preprocess(['../midi/pei/' fname]);
% [barNote, ~] = bar_note_data(midiData, timeSig); 
% [~, ~, chord] = xlsread(['../annotation/trans_' fname '.xlsx']);
% chord1 = chord;
% chord(1, :) = [];

%%
function [score] = key_score_new(chord, barNote)
    load Key_DiatonicTriad_V7.mat keyFusion
    
    for barI = 1:cell2mat(chord(end, 1))      
        barIdx = cell2mat(chord(:, 1)) == barI;        
        [score.chord(:, barI), score.chordNormal(:, barI), score.chord145(:, barI), score.chord15(:, barI), score.chord1Note(:,barI)] = calculate_bar_scoreChord(chord(barIdx,:), barNote{barI}, keyFusion);
        score.note(:, barI) = calculate_bar_scoreNote(barNote{barI}, keyFusion);
        score.finalScore(:, barI) = score.chordNormal(:, barI).* score.note(:, barI);
    end  
end

%% function 
% description: 計算每個小節所有的大小調組成音比例
% input     : chord            -> 小節的和弦資訊
%             barNote          -> 小節音符資訊
%             keyFusion        -> 所有key的資訊
%
% output    : scoreChord       -> 小節和弦分數
%             scoreChordNormal -> normalize scoreChord
%             scoreChord145    -> 145和弦分數
%             scoreChord15     -> 15和弦分數
%             scoreChord1Note  -> 一和弦組合音分數
function [scoreChord, scoreChordNormal, scoreChord145, scoreChord15, scoreChord1Note] = calculate_bar_scoreChord(chord, barNote, keyInfo)
    
    barChordNo = cell2mat(chord(:, 5));
    barChordOnset = cell2mat(chord(:, 2));
    
    scoreChord = zeros(24, 1);
    scoreChordNormal = zeros(24, 1);
    scoreChord145 = zeros(24, 1);
    scoreChord15 = zeros(24, 1);
    scoreChord1Note = zeros(24, 1);
    
    allKeyDiatonicChordNo = reshape([keyInfo.keyChord],8,24)';
    
    % 把屬七當作大三和弦
    barChordNo(and(barChordNo>12, barChordNo<=24)) = barChordNo(and(barChordNo>12, barChordNo<=24)) - 12;
   % warning('把屬７當作大三和弦');
            
    for keyI = 1:24
        
        chord145num = 0;
        chord15num = 0;
        for chordIdx = 1:size(chord, 1)
            if chordIdx == size(chord, 1)
                lens = barNote(1, 9) - barChordOnset(chordIdx);
            else
                lens = barChordOnset(chordIdx+1) - barChordOnset(chordIdx);
            end
            chord145num = chord145num + numel(intersect(keyInfo(keyI).keyChord(1:4), cell2mat(chord(chordIdx, 5)))) * lens;
            chord15num = chord15num + numel(intersect(keyInfo(keyI).keyChord([1 3 4]), cell2mat(chord(chordIdx, 5)))) * lens;
        end
        scoreChord145(keyI) = chord145num / barNote(1, 9);
        scoreChord15(keyI) = chord15num / barNote(1, 9);
        
        
        %%
        pitchI = keyInfo(keyI).diatonicTriad(1:3, 1)'; 
        barPitch = mod(barNote(:,4), 12);
        num = 0;
        for i = 1:length(pitchI)
            num = num + sum(barNote(barPitch==pitchI(i),2)); %length(find(barPitch==pitchI(i)));
        end
        scoreChord1Note(keyI) = num / sum(barNote(:,2)); %size(barNote{barI}, 1);    
            
        %%
        chordIntersect = intersect(barChordNo, allKeyDiatonicChordNo(keyI, :));
        chordScore = 0;
        for c = 1:length(chordIntersect)
            chordScore = chordScore + numel(find(barChordNo == chordIntersect(c)));
        end
        scoreChord(keyI) = chordScore;
        scoreChordNormal(keyI) = chordScore/numel(barChordNo);
    end
end

% description: 計算每個小節所有的大小調組成音比例
% input     : barNote   -> 小節的音符資訊
%             keyFusion -> 所有key的資訊
% output    : scoreNote -> 音符分數
function [scoreNote] = calculate_bar_scoreNote(barNote, keyInfo)

    barPitchClass = zeros(1, 12);
    keyRatio = zeros(24, 12);
    scoreNote = zeros(1, 12);
    pitchTabulate = tabulate(mod(barNote(:,4), 12) + 1);
    barPitchClass(1:size(pitchTabulate, 1)) = pitchTabulate(:, 2);
    
    for i = 1:24
        keyRatio(i, keyInfo(i).consistNumber(:) + 1) = 1;
        
        % keyFusion中，小調的音階為和聲小調，這裡把旋律小調的七音也算進去
        if i > 12
            keyRatio(i, mod(keyInfo(i).consistNumber(end) - 1, 12) + 1) = 1;
        end
%         warning('keyFusion中，小調的音階為和聲小調，這裡把旋律小調的七音也算進去');
        
        scoreNote(i) = sum(keyRatio(i, :) .* barPitchClass) / size(barNote, 1);
    end
end