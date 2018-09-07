clear; clc; close all;
fpath = []; Accuracy = struct();

option = questdlg('Select a file directory or specific M-file(s)', ...
	'Open file', ...
	'File directory','M-file(s)', 'Cancel', 'Cancel');

% Handle response
switch option
    case 'File directory'
        fpath = uigetdir('../midi', 'Pick file dir');
        if fpath ~= 0
            fpath = [fpath '/']; 
            fileInfo = dir(fullfile([fpath '*.mid']));
            name = erase(cat(1, {fileInfo.name}), ".mid");
        end
        
    case 'M-file(s)'
        [filename, fpath, filterindex] = uigetfile('*.mid', 'Pick midi files', 'MultiSelect', 'on', '../midi');
        if fpath ~= 0 
            name = erase(cat(1, filename), ".mid");
        end
    
    case 'Cancel'
        fpath = 0;
end

if any(fpath~=0)
%% ���input chord �OGT�٬Opredicted
    chordSourceNo = 0;
    option = questdlg('��ܩM���ӷ�','Select chord source','Ground truth','Predicted','Predicted'); %??��?
    switch option
        case 'Ground truth'
            chordSourceNo = 1;
        case 'Predicted'
            chordSourceNo = 2;
    end
%% �O�_�s��
    if chordSourceNo
        isSave = 0;
        option = questdlg('�s��', 'Save file ?', 'Yes', 'No', 'No'); %??��?
        switch option
            case 'Yes'
                isSave = 1;
            case 'No'
                isSave = 0;
        end

        addpath('../');
        addpath('../toolbox/')
        addpath('../toolbox/midi_lib/midi_lib');
        if ~iscell(name)
            Name{:} = name; 
        else
            Name = name;
        end
        f = waitbar(0,'Please wait...');
        pause(.5)
        
        for songNo = 1:length(Name)
            clearvars -except songNo chordSourceNo isSave Name fpath Accuracy f
            fname = Name{songNo};
            waitbar(songNo/length(Name),f,['Running ' num2str(songNo) 'th song "' fname '"']);

%% INPUT : MIDI
            disp(['Processing file "' fname '" ... '])
            [midiData, timeSig] = midi_Preprocess([fpath fname]);
            [barNote, barOnset] = bar_note_data(midiData, timeSig); % each bar's information

            if strcmp(fname, 'b_20_2'); timeSig(1) = 3; end % �S��B�z

%% load �M�͵��G
            idx = strfind(fpath, 'code/midi/');
            p1 = fpath(idx+10:end);

            if ~exist(['../chord_analysis/chord_result/' p1 fname '.mat'])
                addpath('../chord_analysis/');
                paraChord.isNowTemplate = 1;
                paraChord.isPartitionDBeat = 1;
                paraChord.isDurWeight = 1;
                chordPredict = choral_analysis_modify_new(barNote, barOnset, timeSig(1), paraChord);
%                 save(['../chord_analysis/chord_result/' p1 fname '.mat'], 'chordPredict');
            else
                load(['../chord_analysis/chord_result/' p1 fname '.mat']);
            end

            GTdata = csvimport(['../annotation/' p1 'trans_' fname '.csv']);

            if chordSourceNo == 1
                chord = GTdata;
            else
                chord = chordPredict;
            end

%% key ���R        
            paraKey.slidWinSize = 1; % �ۤv�ϫe��slidWinSize���j�p = 2*songNo+1
            paraKey.isABA = 1; 
            paraKey.ABAsize = 4;
            [data, keyName] = key_analysis_new(barNote, chord, paraKey);   

%% save
            p2 = [];
            if chordSourceNo == 1; p2 = 'chordGT/'; end
            if isSave
                if ~exist(['key_result/' p1 p2])
                    mkdir(['key_result/' p1 p2]);
                end
                p = ['key_result/' p1 p2 fname '.mat'];
                save(p, 'data');
                disp(['File save in "' p '"'])
            end

%% ����
            tolError = 3;
            [result, boundary, key, numRatio] = key_evaluation_new(data, GTdata, tolError);
            Accuracy(songNo).name = fname;
            Accuracy(songNo).label = result.label;
            Accuracy(songNo).segR = result.segR;
            Accuracy(songNo).segP = result.segP;
            Accuracy(songNo).segF = result.segF;
        end
        waitbar(1,f,'Finishing');
        pause(1)
        close(f)
    end
end

struct2table(Accuracy)