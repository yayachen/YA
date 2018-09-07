function [ midiInfo, timeSig ] = midi_Preprocess( midi_fn )

%% 讀midi檔 & 計算 bpm & 拍號
    % input  : 歌曲編號
    % output : midi 資訊 
    
%      1       2        3        4        5        6       7      8
%    ONSET |  DUR  | CHANNEL | PITCH | VELOCITY | ONSET |  DUR | TRACK |
%   (BEATS)|(BEATS)|         |       |          | (SEC) | (SEC)|       |

%        9       10
%    | TIME SIGNATURE |
%    | (分子) | (分母)  |

%     addpath('toolbox/MIDI tool/miditoolbox');

    % 讀檔        
    midiInfo   = readmidi_java([midi_fn '.mid'], 1);
%     midiInfo   = readmidi([midi_fp '/' midi_fn '.mid']);
    midiInfo(midiInfo(:,2)==0,:) = [];
    
    % 計算 time signature
    timeSig     = get_time_signatures([midi_fn '.mid']);
    midiSize2   = size(midiInfo,2);
    
    for i=1:size(timeSig,1)
        index = find(midiInfo(:,1)>=timeSig(i,5));
        midiInfo(index, midiSize2+1)    = timeSig(i,1) / (2^timeSig(i,2)/4);% timeSig(i,1);
        midiInfo(index, midiSize2+2)    = 4;% 2^timeSig(i,2);
    end
    
    if sum(midiInfo(end,1:2)) < timeSig(end,5)
        timeSig(end,:)=[]; 
    end
end

