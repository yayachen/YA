clear; clc; close all;
% addpath('../');
addpath('../toolbox/midi_lib/midi_lib');


isSave = 1;
% fpath = '../midi/pei/';
fpath = '../midi/kpcorpus_half/';
file = dir(fullfile([fpath '*.mid']));

for i = 1:length(file)
%     clearvars -except i isSave fpath file

%% INPUT : MIDI
    fname = erase(file(i).name, ".mid")
    [midiData, timeSig] = midi_Preprocess([fpath fname]);
    [barNote, barOnset, midiData] = bar_note_data(midiData, timeSig); % each bar's information
    [ly,info] = get_lyrics_as_text([fpath fname '.mid']);
    
    [GTdata] = getChordInfo(ly, midiData, timeSig, info(:,1))
%% 和弦分析
    if isSave
        save(['kpcorpus_half/' fname '.mat'], 'GTdata');
        cell2csv(['kpcorpus_half/' fname '.csv'], GTdata);
    end

end



function [chordGT] = getChordInfo(chordLabel, midiData, timeSig, onset)
%     CHORD_MAP   = {'M' 'M'  'M'  'M'  'V' 'm' 'm'  'm'  'd' 'd'  'd'};
    CHORD_L     = {'M' 'V' 'm' 'd'};
    
%     lyChordMap  = {  'M',   'V',   'm',   'd',    'd',    'd'};
    lyChordMap  = {  'maj',   'dom',   'min',   'fdim',    'hdim',    'dim'};%, 'Ger6', 'It6', 'Fr6'};
    lyChordTempIdx = [ 1,    2,     3,      4,      4,     4];%, 0, 0, 0];
    rootLetter  = {'C' 'B#' 'C#' 'Db' 'D' 'D#' 'Eb' 'E' 'Fb' 'F' 'E#' 'F#' 'Gb' 'G' 'G#' 'Ab' 'A' 'A#' 'Bb' 'B' 'Cb' 'X'};
    rootNum     = [ 1   1    2    2    3   4    4    5   5    6   6    7    7    8   9    9    10  11   11   12  12 0];

    typeNum = 1:size(CHORD_L, 2);
    chord = [];
    chordId = zeros(length(chordLabel), 1);
    chordTampIdx = zeros(length(chordLabel), 1);

    for i=1:length(chordLabel)
        chordPart = cell(1,3);
        chordp = strsplit(chordLabel{i}, '_');
        for j=1:length(chordp); chordPart(j) = chordp(j); end
        rL = chordPart(1);
        ml = chordPart(2)
        m = unique(lyChordTempIdx(strncmpi(lyChordMap, ml, 3)));
        if isempty(m); m = 0; end
        r = rootNum(strcmp(rootLetter,rL));
i
        chordId(i,1) = size(typeNum,2)*(r-1) + (m-1);
        chordTampIdx(i,1) = 12 * (m - 1) + r;
        chord
        chordPart
        chord = [chord; chordPart]
    end
%     onset = unique(midiData(:,1));
    GTtrans = find(diff(chordId)~=0) + 1;
    GTchordTampIdx = [chordTampIdx(1); chordTampIdx(GTtrans)];

    beatALL = [0; onset(GTtrans,1)];
    measure = floor(beatALL/(timeSig(1)/(2^timeSig(2)/4)))+1;
    beat = mod(beatALL,(timeSig(1)/(2^timeSig(2)/4)));
    change = find(diff(measure')) + 1;
    j = 1;
    chordGT = cell(1,6);%{'小節','拍數(onset)','調性','和弦','和弦編號','備註'};
    
    for i = 1:length(measure)
        chordGT{i,1} = measure(i);
        chordGT{i,2} = beat(i);
        if any(change == i) && beat(i)~=0
            temp{j,1} = measure(i);
            temp{j,2} = 0;
            temp{j,4} = chordGT{i-1,4};
            temp{j,5} = max(chordGT{i-1,5},0);
            j = j + 1;
        end
        if i == 1
            chordGT{i,4} = [chord{1,1} ':' chord{1,2}];
        else
            chordGT{i,4} = [chord{GTtrans(i-1),1} ':' chord{GTtrans(i-1),2}];
        end
        chordGT{i,5} = max(GTchordTampIdx(i),0);
    end
    temp{1,6}=[];
    chordGT = [chordGT; temp];
    [n, sortIdx] = sortrows(sum([cat(1,chordGT{:,1})*10 cat(1,chordGT{:,2})],2),1);
    chordGT = chordGT(sortIdx,:);

    lack = setdiff((1:midiData(end, 11))*10, n);
    for i=1:length(lack)
        tmp{i,1} = lack(i)/10;
        tmp{i,2} = 0;
        idx = find(n<lack(i));
        tmp{i,4} = chordGT{idx(end),4};
        tmp{i,5} = chordGT{idx(end),5};
    end
    tmp{1,6} = [];
    chordGT = [chordGT; tmp];
    [n, sortIdx] = sortrows(sum([cat(1,chordGT{:,1})*10 cat(1,chordGT{:,2})],2),1);
    chordGT = chordGT(sortIdx,:);
    
    if timeSig(2) ~= 2
        for i=2:length(chordGT)
            chordGT{i, 2} = chordGT{i, 2}*(2^timeSig(2)/4);
        end
    end
    
    word = {'小節','拍數(onset)','調性','和弦','和弦編號','備註'};
    chordGT = [word; chordGT];
end

