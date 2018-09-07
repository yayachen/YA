function [ resultNoteBar, haveTrill ] = trill_detection( noteBar )
%   把tri合併,tri：兩個音快速上下跳動
%   條件1 : 以32分音符為時值，最後一個音不是。
%   條件2 : 兩個音跳動，音高不會差很遠

    channel = unique(noteBar(:,8));
    resultNoteBar = [];
    haveTrill = 0;
    for ch = 1:length(channel)
        channelIdx = find(noteBar(:,8)==channel(ch));
        singleTrackData = noteBar(channelIdx, :);
        triNum = 0;
        triFlag = 0;
        tmp1 = [2, -2]; 
        for i=1:size(singleTrackData, 1) - 2
            pitchDiff = diff(singleTrackData(i : i + 2, 4))';
            if (all(pitchDiff == tmp1) && (i==1 || singleTrackData(i-1,4)~=singleTrackData(i+1,4))) || (all(pitchDiff == -tmp1) && (i==1 || singleTrackData(i-1,4)~=singleTrackData(i+1,4)))

                if singleTrackData(i, 2) == singleTrackData(i+1, 2)
                    triFlag = 1;
                    triNum = triNum + 1;
                    trill(triNum).index = i:i+2;
                    len = singleTrackData(i, 2);
                    loopIdx = i + 3;
                    deleteTri = 1;
                    while loopIdx <= size(singleTrackData, 1) && singleTrackData(loopIdx, 4) == singleTrackData(loopIdx - 2, 4) && singleTrackData(loopIdx, 2) >= len
                        trill(triNum).index = [trill(triNum).index loopIdx];
                        if singleTrackData(loopIdx, 2) > len
                            deleteTri = 0;
                            break
                        end
                        loopIdx = loopIdx + 1;
                    end
                    if deleteTri
                        trill(triNum) = [];
                        triNum = triNum - 1;
                        if isempty(trill)
                            triFlag = 0;
                        end
                    end
                end
            end
        end
        
        if triFlag
            haveTrillc = 1;
            deleteIdx = [];
            for i = 1:length(trill)
                deleteIdx = [deleteIdx trill(i).index(2:end)];
                modifyIdx = trill(i).index(1);
                singleTrackData(modifyIdx, 2) = sum(singleTrackData(trill(i).index,2));
                singleTrackData(modifyIdx, 7) = sum(singleTrackData(trill(i).index,7));
            end
            singleTrackData(deleteIdx, :) = [];
        end
        resultNoteBar = [resultNoteBar; singleTrackData];
    end
        resultNoteBar = sortrows(resultNoteBar);
end

