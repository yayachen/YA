function [ midiInfo, timeSig ] = xml_Preprocess( midi_fn)

%% Ūmidi�� & �p�� bpm & �縹
    % input  : �q���s��
    % output : midi ��T 
    
%      1       2        3        4        5        6       7      8
%    ONSET |  DUR  | CHANNEL | PITCH | VELOCITY | ONSET |  DUR | TRACK |
%   (BEATS)|(BEATS)|         |       |          | (SEC) | (SEC)|       |

%        9       10
%    | TIME SIGNATURE |
%    | (���l) | (����)  |

%     addpath('toolbox/MIDI tool/miditoolbox');

%     �]�w���ɦW - �w�] .mat
    % Ū��        
    if ~exist([midi_fn '.mat'],'file')
        warning(['�ʤ�' midi_fn '.mat' ' ���� ''cd ../ & python readmusicxml.py ' midi_fn '.xml'])
        command = ['cd ../ & python readmusicxml.py ', midi_fn(4:end) ,'.xml']
        [status,cmdout] = system(command)
    end 
    load([midi_fn '.mat']) ;  %load matrix
    midiInfo(:,[1,2,4,8,9,10]) = matrix;
    
    % �H�U�縹�����٬O�ξǩn���{���X
    midiInfo(midiInfo(:,2)==0,:) = [];
    
    % �p�� time signature
    timeSig     = get_time_signatures([midi_fn '.mid']);
    
    if sum(midiInfo(end,1:2)) < timeSig(end,5)
        timeSig(end,:)=[]; 
    end
end

