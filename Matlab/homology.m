clear all;
load('/Users/GailLee/Documents/GI2016_GEOMETRY_VIDEOS/exp6/exp6_test8/savedFiles/antData.mat');
img = imread('/Users/GailLee/Documents/GI2016_GEOMETRY_VIDEOS/exp6/exp6_test8/00001.jpg');
imshow(img);

[refX, refY] = ginput(4);

movingPoints = [refX, refY];
fixedPoints = [refX(1) refY(1); refX(1) refY(2);...
               refX(3) refY(1); refX(3) refY(2)];
tform = fitgeotrans(movingPoints,fixedPoints,'projective');

for i = 1:8
    U = squeeze(mouseData.coord(:,i,1:2));
    X = transformPointsForward(tform,U);
    imgX(i,:) = X(:,1);
    imgY(i,:) = X(:,2);
    mouseData.coord(:,i,1:2) = X;
end
newimg = imwarp(img,tform);
figure;
imshow(newimg);
[refX, refY] = ginput(3);
movingPoints = [refX, refY];
for i = 1:8
    trueX(i,:) = (mouseData.coord(:,i,1)-refX(1))*352/(refX(2)-refX(1));
    trueY(i,:) = (mouseData.coord(:,i,2)-refY(1))*352/(refY(3)-refY(1));
end

trueY(2,:) = trueY(2,:) - 16;
trueY(3,:) = trueY(3,:) - 40;
trueY(4,:) = trueY(4,:) - 9*8;
trueY(5,:) = trueY(5,:) - 14*8;
trueY(6,:) = trueY(6,:) - 20*8;
trueY(7,:) = trueY(7,:) - 27*8;
trueY(8,:) = trueY(8,:) - 36*8;

hold on;
for i = 1:8
plot(imgX(i,:), imgY(i,:), 'r.');
end
hold off;

save('/Users/GailLee/Documents/GI2016_GEOMETRY_VIDEOS/exp6/exp6_test8/savedFiles/antDatanew.mat',...
    'mouseData','imgX','imgY','trueX','trueY');