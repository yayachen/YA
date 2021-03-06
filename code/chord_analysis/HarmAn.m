function [ optimalPath ] = HarmAn( scoreMatrix, partitionNum, vertex)
% HarmAn algorithm 找最佳路徑的方法
% input : scoreMatrix  -> 每個可能片段的分數
%         partitionNum -> 分割點數量
%         vertex       -> 路徑可能的vertex
% output: optimalPath      -> 最佳路徑
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

