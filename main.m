%% Show the map
clear; clc;
load signType; load signCoordinate; load boundaryPoints;
map = imread('fit6.jpg'); imshow(map); title('FIT6楼平面图');
saveas(gcf, 'output\1.png');
DrawSigns();
saveas(gcf, 'output\2.png');
%% Generate and show the path
[path pathLength frequency] = GeneratePath('database', 'route.mat');
% [path pathLength frequency] = GeneratePath('manaual', 50, 100);
hold on; scatter(path(:, 1), path(:, 2), 0.7, 'r', 'filled'); hold off;
saveas(gcf, 'output\3.png');
%% Add noise to the path data
noise = 0.5;
path_noise = GeneratePathWithError(path, noise);
%% Show the path with noise, the part out of the corridor is blue, inside is green
in=inpolygon(path_noise(:, 1), path_noise(:, 2), ...
        boundaryPoints(:, 1), boundaryPoints(:, 2));
inCorr = find(in == 1); outCorr = find(in == 0);
hold on; 
scatter(path_noise(inCorr, 1), path_noise(inCorr, 2), 0.7, 'g', 'filled'); 
scatter(path_noise(outCorr, 1), path_noise(outCorr, 2), 0.7, 'b', 'filled'); 
hold off;
saveas(gcf, 'output\4.png');
%% Canculate the 2 errors of the path with noise
[maxError_noise, accError_noise] = GetPositionError(path, path_noise);
%% Fuse construction to the path
prtcleNum = 100;              % 粒子个数
% initialOffset= 20;          % 撒粒子范围
prtcleWeight_cons = ones(1, prtcleNum) * 1 / prtcleNum;        % 粒子权值
distance = norm(path_noise(1, :) - path_noise(2, :)); Q = 5; theta = pi / length(path_noise);

% realOffset = -initialOffset + 2 * initialOffset * rand(particleNum, 2);
realOffset = distance * [-cos(1 * theta) sin(1 * theta)] + wgn(prtcleNum, 2, 10 * log10(Q));
prtcleSet_cons = repmat(path_noise(1,:), [prtcleNum 1]) + realOffset;
path_fuseCons(1, :) = sum(prtcleSet_cons) / prtcleNum;
for cnt = 2: length(path_noise)
    % realOffset = -initialOffset + 2 * initialOffset * rand(particleNum, 2);
    realOffset = distance * [-cos(cnt * theta) sin(cnt * theta)] + wgn(prtcleNum, 2, 10 * log10(Q));
    prtcleSet_cons = prtcleSet_cons + realOffset; 
    
    [prtcleWeight_cons prtcleSet_cons] = UpdateParticle(prtcleWeight_cons, prtcleSet_cons, ...
        path(cnt, :), path_noise(cnt, :), boundaryPoints, 0);
    path_fuseCons(cnt, 1) = prtcleWeight_cons * prtcleSet_cons(:, 1);
    path_fuseCons(cnt, 2) = prtcleWeight_cons * prtcleSet_cons(:, 2);
end
hold on;
scatter(path_fuseCons(:, 1), path_fuseCons(:, 2), 1, [1 0 1], 'filled');
hold off;
saveas(gcf, 'output\5.png');
%% Canculate the 2 errors of the path with noise cofused with construction
[maxError_cons, accError_cons] = GetPositionError(path, path_fuseCons);
maxErrorRate_cons = (maxError_noise - maxError_cons) / maxError_cons;
accErrorRate_cons = (accError_noise - accError_cons) / accError_cons;
%% Fuse signs to the path
prtcleNum = 100;            % 粒子个数
prtcleWeight_sign = ones(1, prtcleNum) * 1 / prtcleNum;   % 粒子权值
distance = norm(path_noise(1, :) - path_noise(2, :)); Q = 5; theta = pi / length(path_noise);
realOffset = distance * [-cos(1 * theta) sin(1 * theta)] + wgn(prtcleNum, 2, 10 * log10(Q));
prtcleSet_sign = repmat(path_noise(1,:), [prtcleNum 1]) + realOffset;
path_fuseSign(1, :) = path_noise(1, :);
for cnt = 2: length(path_noise)
    % realOffset = -initialOffset + 2 * initialOffset * rand(particleNum, 2);
    realOffset = distance * [-cos(cnt * theta) sin(cnt * theta)] + wgn(prtcleNum, 2, 10 * log10(Q));
    prtcleSet_sign = prtcleSet_sign + realOffset; 
    
    [prtcleWeight_sign prtcleSet_sign] = UpdateParticle(prtcleWeight_sign, prtcleSet_sign,...
        path(cnt, :), path_noise(cnt, :), boundaryPoints, 1, signType, signCoordinate);
    path_fuseSign(cnt, 1) = prtcleWeight_sign * prtcleSet_sign(:, 1);
    path_fuseSign(cnt, 2) = prtcleWeight_sign * prtcleSet_sign(:, 2);
end
hold on;
scatter(path_fuseSign(:, 1), path_fuseSign(:, 2), 1, [0 0 0], 'filled');
hold off;
saveas(gcf, 'output\6.png');
%% Canculate the 2 errors of the path with noise cofused with signs
[maxError_sign, accError_sign] = GetPositionError(path, path_fuseSign);
maxErrorRate_sign = (maxError_noise - maxError_sign) / maxError_sign;
accErrorRate_sign = (accError_noise - accError_sign) / accError_sign;
%% Show error
fprintf(['Path with noise:\nMax error: ' num2str(maxError_noise) ' Acc error: ' num2str(accError_noise) '\n']);
fprintf(['Path coufused construction:\nMax error: ' num2str(maxError_cons) ' Acc error: ' num2str(accError_cons) '\n']);
fprintf(['Max error decrease: ' num2str(maxErrorRate_cons) ' Acc error decrease: ' num2str(accErrorRate_cons) '\n']);
fprintf(['Path coufused sign:\nMax error: ' num2str(maxError_sign) ' Acc error: ' num2str(accError_sign) '\n']);
fprintf(['Max error decrease: ' num2str(maxErrorRate_sign) ' Acc error decrease: ' num2str(accErrorRate_sign) '\n']);