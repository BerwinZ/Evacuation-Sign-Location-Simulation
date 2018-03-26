function [particleWeight particleSet] = UpdateParticle(varargin)
%% Update particle's weight, then remove the low weight's particles, and copy the hight weight's particles
%% particleWeight is a 1 * N array, particleSet is a N * 2 array

%% Get elements from the varargin
particleWeight = cell2mat(varargin(1));
particleSet = cell2mat(varargin(2));
currentPos = cell2mat(varargin(3));
obserPos = cell2mat(varargin(4));
boundPos = cell2mat(varargin(5));
addSign = cell2mat(varargin(6));
if(addSign)
   signType = cell2mat(varargin(7));
   signPos = cell2mat(varargin(8));
end

%% Update particle's weight according to 
%% 1) whether this particle is in the boundary
%% 2) the distance between the particle and obserPos
R = 5;
distance = particleSet - repmat(obserPos, [length(particleSet) 1]);
distance = (sum(abs(distance).^2,2).^(1/2))';
particleWeight = (1 / sqrt(R) / sqrt(2 * pi)) * exp(-(distance).^2 / 2 / R);
in = inpolygon(particleSet(:, 1), particleSet(:, 2), ...
        boundPos(:, 1), boundPos(:, 2));
particleWeight(find(in == 0)) = 0;
%% 3) the information of the signs
if(addSign ~= 0)
    [type index distance] = GetEvacualationSignInfo(currentPos, signType, signPos);
    if(type ~= -1)
        dist = abs((sum(abs(particleSet - signPos(index, :)).^2,2).^(1/2)) ...
            - distance);
        particleWeight(find(dist > 3)) = 0;
    end
end
particleWeight = particleWeight / sum(particleWeight);
%% Update particles according to its weight
% lowThreshold = 0.1;
uselessParticleNum = length(find(particleWeight == 0));
if(uselessParticleNum == 0)
    return;
else
    largeParticleNum = 1;
    weightList = sort(particleWeight);
    weightList = weightList(end - (largeParticleNum - 1): end);
    for cnt = 1: largeParticleNum
        tempset = particleSet(find(particleWeight == weightList(cnt)), :);
        largeParticleSet(cnt, :) = tempset(1, :);
    end
    copyTime = ceil(uselessParticleNum / largeParticleNum);
    largeParticleSet = repmat(largeParticleSet, [copyTime, 1]);
    particleSet(find(particleWeight == 0), :) = largeParticleSet(1: uselessParticleNum, :);
end 
end
%{
%重采样（更新）
for i = 1 : length(particleWeight)
    wmax = 2 * max(particleWeight) * rand;  %另一种重采样规则
    index = randi(length(particleWeight), 1);
    while(wmax > particleWeight(index))
        wmax = wmax - particleWeight(index);
        index = index + 1;
        if index > length(particleWeight)
            index = 1;
        end          
    end
    particleSet(i, :) = particleSet(index, :);     %得到新粒子
end
%}