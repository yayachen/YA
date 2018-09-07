clear; clc; close all;
fpath = []; CSR = struct();
PWD = pwd;
PWD = PWD(end-18:end);

if ~strcmp(PWD, 'code/chord_analysis')
    errordlg('Please change the MATLAB current folder to "code/chord_analysis".', 'Path Error');
    error('Path Error.');
end

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

if ~isempty(fpath) && any(fpath~=0)
%% 是否存檔
    option = questdlg('存檔', 'Save file ?', 'Yes', 'No', 'No'); %??按?
    switch option
        case 'Yes'
            isSave = 1;
        case 'No'
            isSave = 0;
    end

    addpath('../');
    addpath('../toolbox/midi_lib/midi_lib');
    if ~iscell(name)
        Name{:} = name; 
    else
        Name = name;
    end
    
    f = waitbar(0,'Please wait...');
    pause(.5)
    for songNo = 1:length(Name)
        clearvars -except songNo isSave Name fpath CSR f

%% INPUT : MIDI
        fname = Name{songNo};
        
        disp(['Processing file "' fname '" ... '])
        waitbar(songNo/length(Name),f,['Running ' num2str(songNo) 'th song "' fname '"']);
        [midiData, timeSig] = midi_Preprocess([fpath fname]);
        [barNote, barOnset] = bar_note_data(midiData, timeSig); % each bar's information

        if strcmp(fname, 'b_20_2'); timeSig(1,:) = []; end % 特殊處理

%% 和弦分析
        idx = strfind(fpath, 'code/midi/');
        p1 = fpath(idx+10:end);

        paraChord.isNowTemplate = 1;
        paraChord.isPartitionDBeat = 1;
        paraChord.isDurWeight = 1;
        chordPredict = choral_analysis_modify_new(barNote, barOnset, timeSig(1), paraChord);
%% GT data
        addpath('../toolbox');
        GTdata = csvimport(['../annotation/' p1 'trans_' fname '.csv']);
%% save
        if isSave
            if ~exist(['chord_result/' p1])
                mkdir(['chord_result/' p1]);
            end
            p = ['chord_result/' p1 fname '.mat'];
            save(p, 'chordPredict');
            disp(['File save in "' p '"'])
        end

%% 評估        
        if timeSig(2) ~= 2 % 因為note陣列會自動把拍號 map到 X/4拍，所以不是X/4的要轉換一下才可以跟GT比較。
            for t=2:length(chordPredict)
                chordPredict{t, 2} = chordPredict{t, 2}*(2^timeSig(2)/4);
            end
        end

        unit = 0.1; % 評估的單位
        [csr, chordNameGT, chordNamePredict] = chord_evaluation_new(chordPredict, GTdata, timeSig(1), unit);
        CSR(songNo).name = fname;
        CSR(songNo).CSR = csr;
        
    end
    waitbar(1,f,'Finishing');
    pause(1)
    close(f)
end
struct2table(CSR)