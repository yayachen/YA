% description: 將midi的duration(unit:beat)正規化成跟譜一樣
% input     : midiData           -> 原始   的 midi data
% output    : normalizedMidiData -> 正規化後的 midi data
function [midiData] = normalize_midi_data (midiData)
    %            1   2+4   2    4+8    4+16     4    8+16      8      16    
    noteValue = [1  0.75 0.5  0.375  0.3125  0.25  0.1875  0.125  0.0625 0];
    repNoteValue = repmat(noteValue, size(midiData, 1), 1);

    durError = midiData(:, 2) - floor(midiData(:, 2)) - repNoteValue; % midi error與每個noteValue的差異
    durError(durError > 0) = -10; % midi誤差，midi音檔比實際的音符時值短，所以tmp>0就把他忽略，給予很小的值
    [~,idx] = max(durError, [], 2); % 找最接近0的值
    
    midiData(:,2) = noteValue(idx)' + floor(midiData(:,2));
    
    % onset 也要改變
%                1  2+4+8   2+4    2  4+8+16    4+8    4+16     4    8+16      8      16  
    noteValue = [1, 0.875, 0.75, 0.5, 0.4375, 0.375, 0.3125, 0.25, 0.1875, 0.125, 0.0625, 0];
    repNoteValue = repmat(noteValue, size(midiData,1), 1);

    durError = midiData(:, 1) - floor(midiData(:, 1)) - repNoteValue;
    durError(durError > 0) = -10;
    [~,idx] = max(durError, [], 2);
    
    midiData(:,1) = noteValue(idx)' + floor(midiData(:,1));
end