function [ optimalPath ] = HarmAn( scoreMatrix, partitionNum, vertex)
% HarmAn algorithm т程ㄎ隔畖よ猭
% input : scoreMatrix  -> –琿だ计
%         partitionNum -> だ澄翴计秖
%         vertex       -> 隔畖vertex
% output: optimalPath      -> 程ㄎ隔畖
    if nargin < 3; vertex = 1:partitionNum;   end

    now         = 2; 
    MARK        = 1; 
    DEL         = [];
    optimalPath(1)  = 1;
    
    while vertex(now) < partitionNum
        if scoreMatrix(vertex(now-1),vertex(now))+scoreMatrix(vertex(now),vertex(now+1)) > scoreMatrix(vertex(now-1),vertex(now+1))
            MARK = [MARK, vertex(now)];
            optimalPath(1,now) = vertex(now);
            now = now + 1;
        else
            DEL = [DEL vertex(now)];
            vertex(now) = [];
        end
    end
    MARK = [MARK partitionNum];
    optimalPath(1,now) = partitionNum;


end

