% description: �Nmidi��duration(unit:beat)���W�Ʀ����Ф@��
% input     : midiData           -> ��l   �� midi data
% output    : normalizedMidiData -> ���W�ƫ᪺ midi data
function [midiData] = normalize_midi_data (midiData)
    %            1   2+4   2    4+8    4+16     4    8+16      8      16    
    noteValue = [1  0.75 0.5  0.375  0.3125  0.25  0.1875  0.125  0.0625 0];
    repNoteValue = repmat(noteValue, size(midiData, 1), 1);

    durError = midiData(:, 2) - floor(midiData(:, 2)) - repNoteValue; % midi error�P�C��noteValue���t��
    durError(durError > 0) = -10; % midi�~�t�Amidi���ɤ��ڪ����Ůɭȵu�A�ҥHtmp>0�N��L�����A�����ܤp����
    [~,idx] = max(durError, [], 2); % ��̱���0����
    
    midiData(:,2) = noteValue(idx)' + floor(midiData(:,2));
    
    % onset �]�n����
%                1  2+4+8   2+4    2  4+8+16    4+8    4+16     4    8+16      8      16  
    noteValue = [1, 0.875, 0.75, 0.5, 0.4375, 0.375, 0.3125, 0.25, 0.1875, 0.125, 0.0625, 0];
    repNoteValue = repmat(noteValue, size(midiData,1), 1);

    durError = midiData(:, 1) - floor(midiData(:, 1)) - repNoteValue;
    durError(durError > 0) = -10;
    [~,idx] = max(durError, [], 2);
    
    midiData(:,1) = noteValue(idx)' + floor(midiData(:,1));
end