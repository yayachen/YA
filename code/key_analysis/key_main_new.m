clear; clc; close all;
addpath('../');
addpath('../toolbox/midi_lib/midi_lib/');

isSave = 1;
name = {'m_16_1', 'm_7_1', 'b_4_1', 'b_20_1', 'c_40_1', 'c_47_1', 'h_37_1', 'h_23_1', ...
        'm_16_2', 'm_7_2', 'b_4_2', 'b_20_2', 'h_37_2'};
fpath = '../midi/pei/';
% fpath = '../midi/kpcorpus1/';
% file = dir(fullfile([fpath '*.mid']));

% for songNo = 1:length(file)
for songNo = 1:length(name)
    for chordSourceNo = 1:2 % chord來源
        clearvars -except songNo chordSourceNo isSave name fpath file 

%% INPUT : MIDI
%         fname = erase(file(songNo).name, ".mid")
        fname = name{songNo}
        [midiData, timeSig] = midi_Preprocess([fpath fname]);
        [barNote, barOnset] = bar_note_data(midiData, timeSig); % each bar's information

        if strcmp(fname, 'b_20_2'); timeSig(1) = 3; end % 特殊處理

        %% load 和絃結果
        if ~exist(['../chord_analysis/chord_result/pei/' fname '.mat'])
            addpath('../chord_analysis/');
            paraChord.isNowTemplate = 1;
            paraChord.isPartitionDBeat = 1;
            paraChord.isDurWeight = 1;
            chordPredict = choral_analysis_modify_new(barNote, barOnset, timeSig(1), paraChord);
   %         save(['../chord_analysis/chord_result/' fname '.mat'], 'predictChord');
        else
            load(['../chord_analysis/chord_result/pei/' fname '.mat']);
        end
        
        GTdata = csvimport(['../annotation/trans_' fname '.csv']);
%         [~, ~, GTdata] = xlsread(['../annotation/trans_' fname '.xlsx']);
%         [~, ~, GTdata] = xlsread(['../annotation/kpcorpus1/' fname '.xlsx']); 

        if chordSourceNo == 1
            chord = GTdata;
        else
            chord = chordPredict;
        end
        
%% key 分析        
        paraKey.slidWinSize = 1; % 自己＋前後slidWinSize的大小 = 2*songNo+1
        paraKey.isABA = 1; 
        paraKey.ABAsize = 4;
        [data, keyName] = key_analysis_new(barNote, chord, paraKey);   
        
        if isSave
            if chordSourceNo == 1
                save(['key_result/pei/chordGT/' fname '.mat'], 'data');
%                 cell2csv(['key_result/pei/chordGT/' filename '.csv'], data);
            else
                save(['key_result/pei/' fname '.mat'], 'data');
%                 cell2csv(['key_result/pei/' filename '.csv'], data);
            end
        end
%% 評估
        tolError = 3;
        [result, boundary, key, numRatio] = key_evaluation_new(data, GTdata, tolError);
    end
end
