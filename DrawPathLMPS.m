clear;
lmpsdata = ReadDataFromLMPS('lee5_12.csv'); 
dt = lmpsdata.time(2) - lmpsdata.time(1);

alpha = 0.1;
smoacc(:, 1) = smoothData(lmpsdata.linacc(:, 1), alpha);
smoacc(:, 2) = smoothData(lmpsdata.linacc(:, 2), alpha);
smoacc(:, 3) = smoothData(lmpsdata.linacc(:, 3), alpha);
alpha = 0.1;
smoeuler(:, 1) = smoothData(lmpsdata.euler(:, 1), alpha);
smoeuler(:, 2) = smoothData(lmpsdata.euler(:, 2), alpha);
smoeuler(:, 3) = smoothData(lmpsdata.euler(:, 3), alpha);

for cnt = 1: length(lmpsdata.time)
    phi = smoeuler(cnt, 1);
    theta = smoeuler(cnt, 2);
    psi = smoeuler(cnt, 3);

    R = Rxb(phi) * Ryb(theta) * Rd(psi);
    newacc(:, cnt) = inv(R) * smoacc(cnt, :)';
end
newacc = newacc';

figure(1); title('old acclerate');
subplot(3,1,1); plot(lmpsdata.acc(:, 1));
subplot(3,1,2); plot(lmpsdata.acc(:, 2));
subplot(3,1,3); plot(lmpsdata.acc(:, 3)); 

figure(2); title('smoothy acclerate');
subplot(3,1,1); plot(smoacc(:, 1));
subplot(3,1,2); plot(smoacc(:, 2));
subplot(3,1,3); plot(smoacc(:, 3)); 

figure(3); title('transfer acclerate');
subplot(3,1,1); plot(newacc(:, 1));
subplot(3,1,2); plot(newacc(:, 2));
subplot(3,1,3); plot(newacc(:, 3)); 

dt = lmpsdata.time(2) - lmpsdata.time(1);
path = GeneratePath(newacc, dt);
figure(4); title('path');
scatter(path(:, 1), path(:, 2), 1, 'filled');

figure(5); title('euler');
subplot(3,1,1); plot(smoeuler(:, 1));
subplot(3,1,2); plot(smoeuler(:, 2));
subplot(3,1,3); plot(smoeuler(:, 3)); 

function path = GeneratePath(acc, dt)
% Get Speed and Path
speed(1, :) = [0 0 0];
path(1, :) = [0 0 0];
for cnt = 2: length(acc)
   speed(cnt, :) = speed(cnt-1, :) + (acc(cnt-1, :) + acc(cnt, :)) / 2;
   path(cnt, :) = path(cnt-1, :) + (speed(cnt-1, :) + speed(cnt, :)) / 2;
end
end

function matrix = Rxb(phi)
matrix = [1 0 0;
          0 cosd(phi) sind(phi);
          0 -sind(phi) cosd(phi)];
end

function matrix = Ryb(theta)
matrix = [cosd(theta) 0 -sind(theta);
          0 1 0;
          sind(theta) 0 cosd(theta)];
end

function matrix = Rd(psi)
matrix = [cosd(psi) sind(psi) 0;
          -sind(psi) cosd(psi) 0;
          0 0 1];
end

function newData=smoothData(oldData, arfa)
newData(1) = oldData(1);
length = size(oldData,1);
for i=2:length 
 newData(i)=arfa*oldData(i-1)+(1-arfa)*newData(i-1);
end
end