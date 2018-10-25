function [ midiInfo, timeSig ] = xml_Preprocess( midi_fn)

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

%     設定附檔名 - 預設 .mat
    % 讀檔        
    if ~exist([midi_fn '.mat'],'file')
        warning(['缺少' midi_fn '.mat' ' 執行 ''cd ../ & python readmusicxml.py ' midi_fn '.xml'])
        command = ['cd ../ & python readmusicxml.py ', midi_fn(4:end) ,'.xml']
        [status,cmdout] = system(command)
    end 
    load([midi_fn '.mat']) ;  %load matrix
    midiInfo(:,[1,2,4,8,9,10]) = matrix;
    
    % 以下拍號部分還是用學姊的程式碼
    midiInfo(midiInfo(:,2)==0,:) = [];
    
    % 計算 time signature
    timeSig     = get_time_signatures([midi_fn '.mid']);
    
    if sum(midiInfo(end,1:2)) < timeSig(end,5)
        timeSig(end,:)=[]; 
    end
end

