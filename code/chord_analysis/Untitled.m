
% load('Voicing\ALL_Voicing.mat');
% fields = fieldnames(Voicing);
% for i=1:numel(fields)
%     v = Voicing.(string(fields(i))) ;
%     %F = ceil(3 * tiedrank(v) / length(v));
%     %Voicing.(string(fields(i))) = discretize(v,4)
%     edge = [min(v):(max(v)-min(v))/2:max(v)];
%     bin = discretize(v,edge,[1,3]);
%     bin(bin==1) = discretize(v(bin==1),2);
%     Voicing.(string(fields(i))) = discretize(bin,3,[0.4,0.5,0.6]);
% end

tempName    = {    'maj',      '7',    'min',    'dim', 'xxx',  'X'};
for i = tempName
    V.i = [0]
    
end