clear; clc; close all;
addpath('../');
addpath('../toolbox/midi_lib/midi_lib');

isSave = 1;
name = {'m_16_1', 'm_7_1', 'b_4_1', 'b_20_1', 'c_40_1', 'c_47_1', 'h_37_1', 'h_23_1', ...
        'm_16_2', 'm_7_2', 'b_4_2', 'b_20_2', 'h_37_2'};
name = {'m_16_1', 'm_7_1', 'b_4_1', 'b_20_1', 'c_40_1', 'c_47_1', 'h_37_1', 'h_23_1'}
<<<<<<< Updated upstream
=======
%name = {'m_16_1', 'm_7_1', 'b_4_1',  'c_40_1', 'c_47_1', 'h_37_1', 'h_23_1'}


>>>>>>> Stashed changes
fpath = '../midi/pei/';
% file = dir(fullfile([fpath '*.mid']));
CSR = zeros(size(name))';
% for i = 1:length(file)
for i = 1:length(name)
    clearvars -except i isSave name fpath file CSR

%% INPUT : MIDI
%     fname = erase(file(i).name, ".mid")
    fname = name{i};
    
    %[midiData, timeSig] = midi_Preprocess([fpath fname]);
    [midiData, timeSig] = xml_Preprocess([fpath fname]);
    [barNote, barOnset] = bar_note_data(midiData, timeSig); % each bar's information
      
    if strcmp(fname, 'b_20_2'); timeSig(1,:) = []; end % 特殊處理
    
%% 和弦分析
    parameter.isNowTemplate = 1;
    parameter.isPartitionDBeat = 1;
    parameter.isDurWeight = 1;
<<<<<<< Updated upstream

    chordPredict = choral_analysis_modify_new(barNote, barOnset, timeSig(1), parameter);
=======
    parameter.isVoicing  =  0;
    chordPredict = choral_analysis_modify_new(fname,barNote, barOnset, timeSig(1), parameter);
>>>>>>> Stashed changes

%% 評估
    if timeSig(2) ~= 2 % 因為note陣列會自動把拍號 map到 X/4拍，所以不是X/4的要轉換一下才可以跟GT比較。
        for t=2:length(chordPredict)
            chordPredict{t, 2} = chordPredict{t, 2}*(2^timeSig(2)/4);
        end
    end

    unit = 0.1; % 評估的單位
    GTdata = csvimport(['../annotation/trans_' fname '.csv']);
    [CSR(i), chordNameGT, chordNamePredict] = chord_evaluation_new(chordPredict, GTdata, timeSig(1), unit);
    disp([fname,num2str(CSR(i))])
% 存檔
    if isSave
        save(['chord_result/pei/' fname '.mat'], 'chordPredict');
        %csvwrite(['chord_result/pei/' fname '.csv'], chordPredict)
    end
end

