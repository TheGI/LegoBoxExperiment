antinfo = struct(...
    'colnum', {}, ...
    'testnum', {},...
    'boxnum', {},...
    'pos',{},...
    'adjpos',{},...
    'major',{},...
    'time',{},...
    'adjtime',{},...
    'dist',{},...
    'vel',{},...
    'speed',{},...
    'angle',{});

threshold = 3; % move less than 5 mm, delete
count = 1;
for colnum = 4:6
    for testnum = 1:8
        load(['/Users/GailLee/Documents/GI2016_GEOMETRY_VIDEOS/exp'...
            num2str(colnum) '/exp' num2str(colnum) '_test' ...
            num2str(testnum) '/savedFiles/antDatanew.mat']);
        for boxnum = 1:8
            
            antinfo(count).colnum = colnum;
            antinfo(count).testnum = testnum;
            antinfo(count).boxnum = boxnum;
            antinfo(count).pos = [trueX(boxnum,:)',trueY(boxnum,:)'];
            antinfo(count).time = linspace(0,size(trueX,2),size(trueX,2))'/2.997;
            idx = find(sqrt(sum(diff(antinfo(count).pos).^2,2)) < threshold);
            antinfo(count).pos(idx,:) = [];
            antinfo(count).time(idx) = [];
            antinfo(count).adjtime = linspace(0,size(antinfo(count).pos,1),...
                size(antinfo(count).pos,1))'/2.997;
            count = count +1;
        end
    end
end

for i = 1:4
    for j = 1:24
        antinfo(temp(i,j)).major = 1;
    end
end
for i = 5:8
    for j = 1:24
        antinfo(temp(i,j)).major = 0;
    end
end

for i = 1:length(antinfo)
    if size(antinfo(i).pos,1) > 2
        antinfo(i).vel = ...
            bsxfun(@rdivide,diff(antinfo(i).pos),...
            diff(antinfo(i).time));
        antinfo(i).speed = ...
            sqrt(sum(diff(antinfo(i).pos).^2,2))./...
            diff(antinfo(i).time);
        antinfo(i).dist = ...
            cumsum(sqrt(sum(diff(antinfo(i).pos).^2,2)));
        
        for j = 2:length(antinfo(i).vel)
            pdot = dot(antinfo(i).vel(j-1,:),antinfo(i).vel(j,:));
            pdet = det([antinfo(i).vel(j-1,:);antinfo(i).vel(j,:)]);
            antinfo(i).angle(j-1) = atan2(pdet,pdot)*180/pi;
        end
%         vec = diag(antinfo(i).vel(2:end,:) * ...
%             antinfo(i).vel(1:end-1,:)');
%         absvec = sqrt(sum(antinfo(i).vel(2:end,:).^2,2)).*...
%             sqrt(sum(antinfo(i).vel(1:end-1,:).^2,2));
%         antinfo(i).angle = abs(acos(vec./absvec))*180/pi;
    else
        antinfo(i).vel = [nan, nan];
        antinfo(i).speed = nan;
        antinfo(i).dist = nan;
        antinfo(i).angle = nan;
    end
    i
end

save('rawdata.mat','antinfo','temp');

test = [];
for i = 1:length(antinfo)
    test(end+1) = antinfo(i).dist(end);
end

antinfo(find(test < 1000)) = [];

test = [];
for i = 1:length(antinfo)
if size(antinfo(i).dist,1) < 3
test(end+1) = i;
end
end
antinfo(test) = [];

%%
fid = fopen('antdata.csv','w');
fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n','antnum','colnum','testnum','boxnum',...
    'xpos','ypos','time','adjtime','major','dist','xvel','yvel','speed','angle');
for i = 1:length(antinfo)
    fprintf(fid,'%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',i, antinfo(i).colnum, antinfo(i).testnum,...
        antinfo(i).boxnum,antinfo(i).pos(1,1),antinfo(i).pos(1,2),...
        antinfo(i).time(1),antinfo(i).adjtime(1),antinfo(i).major,0,0,0,0,0);
    fprintf(fid,'%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',i, antinfo(i).colnum, antinfo(i).testnum,...
        antinfo(i).boxnum,antinfo(i).pos(1,1),antinfo(i).pos(1,2),...
        antinfo(i).time(1),antinfo(i).adjtime(1),antinfo(i).major,antinfo(i).dist(1),...
        antinfo(i).vel(1,1),antinfo(i).vel(1,2),antinfo(i).speed(1),...
        0);
    for ii = 3:size(antinfo(i).pos,1)
        fprintf(fid,'%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',i, antinfo(i).colnum, antinfo(i).testnum,...
            antinfo(i).boxnum,antinfo(i).pos(ii,1),antinfo(i).pos(ii,2),...
            antinfo(i).time(ii),antinfo(i).adjtime(ii),antinfo(i).major,antinfo(i).dist(ii-1),...
            antinfo(i).vel(ii-1,1),antinfo(i).vel(ii-1,2),antinfo(i).speed(ii-1),...
            antinfo(i).angle(ii-2));
    end
    disp(['Current Process: ' num2str(i)]);
end
fclose(fid);


%% Test 0
% binomial test for turning direction (left or right)
resultB = [];
resultAstd = [];
resultAmean = [];
resultBox = [];
resultSstd = [];
resultSmean = [];
resultDmean = [];
for i = 1:length(antinfo)
resultB(end+1) = myBinomTest(numel(find(antinfo(i).angle > 0)),numel(antinfo(i).angle),0.5);
resultAstd(end+1) = std(antinfo(i).angle);
resultAmean(end+1) = mean(antinfo(i).angle);
resultBox(end+1) = antinfo(i).boxnum;
resultDmean(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
resultSmean(end+1) = mean(antinfo(i).speed);
resultSstd(end+1) = std(antinfo(i).speed);
end
lmAstd = fitlm(resultBox,resultAstd,'linear');
lmAmean = fitlm(resultBox,resultAmean,'linear');
lmSstd = fitlm(resultBox,resultSstd,'linear');
lmSmean = fitlm(resultBox,resultSmean,'linear');
lmDmean = fitlm(resultBox,resultDmean,'linear');
% hold on;
% for i = 1:length(antinfo)
%     plot(antinfo(i).boxnum,resultSTD(i),'o');
% end
% hold off;

[rAstd, pAstd] = corr(resultBox', resultAstd','type', 'Spearman')
[rAmean, pAmean] = corr(resultBox', resultAmean','type', 'Spearman')
[rSstd, pSstd] = corr(resultBox', resultSstd','type', 'Spearman')
[rSmean, pSmean] = corr(resultBox', resultSmean','type', 'Spearman')
[rDmean, pDmean] = corr(resultBox', resultDmean','type', 'Spearman')


%% Test 1
% For each colony and for each box, compare average speed,
% average turning angle
resultD = [];
resultS = [];
resultA = [];
for i = [4 5 6]
    for j = [1 2 3 4 5 6 7 8]
        idxcol = [antinfo(:).colnum] == i;
        idxbox = [antinfo(:).boxnum] == j;
        testD = [];
        testS = [];
        testA = [];
        for k = find(idxcol & idxbox)
            if isempty(testS) && isempty(testA)
                testS = antinfo(k).speed;
                testA = antinfo(k).angle';
            else
                testS = catpad(2,testS,antinfo(k).speed);
                testA = catpad(2,testA,antinfo(k).angle');
            end
        end
        [p,tbl,stats] = kruskalwallis(testS,[],'off');
        resultS(i-3,j) = p;
        [p,tbl,stats] = kruskalwallis(testA,[],'off');
        resultA(i-3,j) = p;
        if p < 0.05
            kruskalwallis(testA);
        end
    end
end

%% Test 2
% For each box, compare between major and minor individual average distance
% per time, average speed and average turning angle using ranksum test

% results: distance significant = box 2 & 5
% results: speed significant = box 5

resultD = [];
resultS = [];
resultA = [];
for i = [1 2 3 4 5 6 7 8]
    testD = [];
    testS = [];
    testA = [];
    for j = [0 1]
        idxbox = [antinfo(:).boxnum] == i;
        idxmajor = [antinfo(:).major] == j;
        idx = 1;
        for k = find(idxbox & idxmajor)
            testD(idx,j+1) = antinfo(k).dist(end)/antinfo(k).time(end);
            testS(idx,j+1) = nanmean(antinfo(k).speed);
            testA(idx,j+1) = nanmean(antinfo(k).angle);
            idx = idx + 1;
        end
    end
    [p,h,stats] = ranksum(testD(:,1),testD(:,2));
    resultD(i) = p;
    [p,h,stats] = ranksum(testS(:,1),testS(:,2));
    resultS(i) = p;
    [p,h,stats] = ranksum(testA(:,1),testA(:,2));
    resultA(i) = p;
    
end

%% Test 3
% For each colony and for each box, compare between major and minor
% individual average distance per time, average speed and average turning
% angle

% results: significant distance = colony 4 at box 7
% results: significant speed = colony 6 at box 5
resultD = [];
resultS = [];
resultA = [];
for i = [1 2 3 4 5 6 7 8]
    for c = [4 5 6]
        testD = [];
        testS = [];
        testA = [];
        for j = [0 1]
            idxbox = [antinfo(:).boxnum] == i;
            idxcol = [antinfo(:).colnum] == c;
            idxmajor = [antinfo(:).major] == j;
            idx = 1;
            
            if isempty(find(idxbox & idxmajor & idxcol))
                
            else
                for k = find(idxbox & idxmajor & idxcol)
                    testD(idx,j+1) = antinfo(k).dist(end)/antinfo(k).time(end);
                    testS(idx,j+1) = nanmean(antinfo(k).speed);
                    testA(idx,j+1) = nanmean(antinfo(k).angle);
                    idx = idx + 1;
                end
            end
        end
        if isempty(find(idxbox & idxmajor & idxcol))
            resultD(c-3,i) = nan;
            resultS(c-3,i) = nan;
            resultA(c-3,i) = nan;
        else
            [p,h,stats] = ranksum(testD(:,1),testD(:,2));
            resultD(c-3,i) = p;
            [p,h,stats] = ranksum(testS(:,1),testS(:,2));
            resultS(c-3,i) = p;
            [p,h,stats] = ranksum(testA(:,1),testA(:,2));
            resultA(c-3,i) = p;
        end
    end
end


%% Test 2 : Comparison among different boxes per colony
% For each colony, compare among different boxes' average distance per
% time, average speed and average turning angle
resultD = [];
resultS = [];
resultA = [];
for i = [4 5 6]
    testD = [];
    testS = [];
    testA = [];
    for j = [1 2 3 4 5 6 7 8]
        idxbox = [antinfo(:).boxnum] == j;
        idxcol = [antinfo(:).colnum] == i;
        idx = 1;
        for k = find(idxbox & idxcol)
            testD(idx,j) = antinfo(k).dist(end)/antinfo(k).time(end);
            testS(idx,j) = nanmean(antinfo(k).speed);
            testA(idx,j) = nanmean(antinfo(k).angle);
            idx = idx + 1;
        end
    end
    
    for j = 1:8
        for k = 1:8
            [p,h,stats] = ranksum(testD(:,j),testD(:,k));
            resultD(i-3,j,k) = p;
            [p,h,stats] = ranksum(testS(:,j),testS(:,k));
            resultS(i-3,j,k) = p;
            [p,h,stats] = ranksum(testA(:,j),testA(:,k));
            resultA(i-3,j,k) = p;
        end
    end
end

csvwrite('test2_D.csv',[squeeze(resultD(1,:,:));squeeze(resultD(2,:,:));...
    squeeze(resultD(3,:,:))]);
csvwrite('test2_S.csv',[squeeze(resultS(1,:,:));squeeze(resultS(2,:,:));...
    squeeze(resultS(3,:,:))]);
csvwrite('test2_A.csv',[squeeze(resultA(1,:,:));squeeze(resultA(2,:,:));...
    squeeze(resultA(3,:,:))]);




%%


test1 = [];
test2 = [];
test3 = [];
test4 = [];
test5 = [];
test6 = [];
test7 = [];
test8 = [];
idxcol = [antinfo(:).colnum] == 6;
idxtest = [antinfo(:).testnum] == 1;
idxbox = [antinfo(:).boxnum] == 8;

for i = find(idxcol)%1:length(antinfo)
    if antinfo(i).boxnum == 1
        test1(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test1(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 2
        test2(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test2(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 3
        test3(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test3(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 4
        test4(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test4(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 5
        test5(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test5(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 6
        test6(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test6(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 7
        test7(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test7(end+1) = nanmean(antinfo(i).angle);
    else
        test8(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test8(end+1) = nanmean(antinfo(i).angle);
    end
end

testmatrix = [];
testmatrix = [test1',test2',test3',test4',test5',test6',test7',test8'];
anova1(testmatrix);
kruskalwallis(testmatrix);

% For each colony and for each major/minor, compare among different boxes'
% average distance per time, average speed and average turning angle

test1 = [];
test2 = [];
test3 = [];
test4 = [];
test5 = [];
test6 = [];
test7 = [];
test8 = [];
idxcol = [antinfo(:).colnum] == 6;
idxtest = [antinfo(:).testnum] == 1;
idxbox = [antinfo(:).boxnum] == 8;

for i = find(idxcol & idxmajor)%1:length(antinfo)
    if antinfo(i).boxnum == 1
        test1(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test1(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 2
        test2(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test2(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 3
        test3(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test3(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 4
        test4(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test4(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 5
        test5(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test5(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 6
        test6(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test6(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).boxnum == 7
        test7(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test7(end+1) = nanmean(antinfo(i).angle);
    else
        test8(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        % test8(end+1) = nanmean(antinfo(i).angle);
    end
end

testmatrix = [];
testmatrix = [test1',test2',test3',test4',test5',test6',test7',test8'];
anova1(testmatrix);
kruskalwallis(testmatrix);

% For each box, compare among different colonies' average distance per
% time, average speed and average turning angle

testmatrix = [];
test1 = [];
test2 = [];
test3 = [];

for i = find(idxbox)
    if antinfo(i).colnum == 4
        test1(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        %               test1(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).colnum == 5
        test2(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        %               test2(end+1) = nanmean(antinfo(i).angle);
    else
        test3(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        %               test3(end+1) = nanmean(antinfo(i).angle);
    end
end
testmatrix = [test1',test2',test3'];
anova1(testmatrix);
kruskalwallis(testmatrix);

% For each box and for each major/minor, compare among different colonies'
% average distance per time, average speed and average turning angle

testmatrix = [];
test1 = [];
test2 = [];
test3 = [];

for i = find(idxbox & idxmajor)
    if antinfo(i).colnum == 4
        test1(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        %               test1(end+1) = nanmean(antinfo(i).angle);
    elseif antinfo(i).colnum == 5
        test2(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        %               test2(end+1) = nanmean(antinfo(i).angle);
    else
        test3(end+1) = antinfo(i).dist(end)/antinfo(i).time(end);
        %               test3(end+1) = nanmean(antinfo(i).angle);
    end
end
testmatrix = [test1',test2',test3'];
anova1(testmatrix);
kruskalwallis(testmatrix);

%%


count = 1;
testmatrix = [];
for i = find(idxbox & idxmajor)
    %     if mod(i,8) == 1
    %         figure;
    %     end
    %
    %     if mod(i,8) == 0
    %         subplot(2,4,8);
    %     else
    %         subplot(2,4,mod(i,8));
    %     end
    %
    %     plot(antinfo(i).dist);
    
    if isempty(testmatrix)
        %             testmatrix = antinfo(i).speed;
        testmatrix = antinfo(i).dist;
    else
        %             testmatrix = catpad(2,testmatrix,antinfo(i).speed);
        testmatrix = catpad(2,testmatrix,antinfo(i).dist);
    end
end

anova1(testmatrix);
kruskalwallis(testmatrix);


%%
for i = 1:8
    for j = 1:8
        [p,tbl,stats] = kruskalwallis(testmatrix(:,[i j]),[],'off');
        results(i,j) = p
    end
end

%% Test 1 : Comparison among different boxes
% Compare among different boxes' average distance per time, average speed
% and average turning angle
resultD = [];
resultS = [];
resultA = [];
testD = [];
testS = [];
testA = [];
for i = [1 2 3 4 5 6 7 8]
    idxbox = [antinfo(:).boxnum] == i;
    idx = 1;
    for k = find(idxbox)
        testD(idx,i) = antinfo(k).dist(end)/antinfo(k).time(end);
        testS(idx,i) = nanmean(antinfo(k).speed);
        testA(idx,i) = nanmean(antinfo(k).angle);
        idx = idx + 1;
    end
end

testD(testD == 0) = nan;
testS(testS == 0) = nan;
testA(testA == 0) = nan;

for j = 1:8
    for k = 1:8
        [p,h,stats] = ranksum(testD(:,j),testD(:,k));
        resultD(j,k) = p;
        [p,h,stats] = ranksum(testS(:,j),testS(:,k));
        resultS(j,k) = p;
        [p,h,stats] = ranksum(testA(:,j),testA(:,k));
        resultA(j,k) = p;
    end
end

csvwrite('test1_D.csv', resultD);
csvwrite('test1_S.csv', resultS);
csvwrite('test1_A.csv', resultA);

[p,tbl,stats] = kruskalwallis(testD);
title('Avg. Distance per Time');
saveas(gcf,'test1_D1.png');
close gcf;
saveas(gcf,'test1_D2.png');
close gcf;

[p,tbl,stats] = kruskalwallis(testS);
title('Avg. Speed')
saveas(gcf,'test1_S1.png');
close gcf;
saveas(gcf,'test1_S2.png');
close gcf;

[p,tbl,stats] = kruskalwallis(testA);
title('Avg. Turning Angle')
saveas(gcf,'test1_A1.png');
close gcf;
saveas(gcf,'test1_A2.png');
close gcf;

%% Test 2: Comparison among different boxes per colony
resultD = [];
resultS = [];
resultA = [];
for i = [4 5 6]
    testD = [];
    testS = [];
    testA = [];
    for j = [1 2 3 4 5 6 7 8]
        idxbox = [antinfo(:).boxnum] == j;
        idxcol = [antinfo(:).colnum] == i;
        idx = 1;
        for k = find(idxbox & idxcol)
            testD(idx,j) = antinfo(k).dist(end)/antinfo(k).time(end);
            testS(idx,j) = nanmean(antinfo(k).speed);
            testA(idx,j) = nanmean(antinfo(k).angle);
            idx = idx + 1;
        end
    end
    
    testD(testD == 0) = nan;
    testS(testS == 0) = nan;
    testA(testA == 0) = nan;
    
    for j = find(~all(isnan(testD)))
        for k = find(~all(isnan(testD)))
            [p,h,stats] = ranksum(testD(:,j),testD(:,k));
            resultD(i-3,j,k) = p;
            [p,h,stats] = ranksum(testS(:,j),testS(:,k));
            resultS(i-3,j,k) = p;
            [p,h,stats] = ranksum(testA(:,j),testA(:,k));
            resultA(i-3,j,k) = p;
        end
    end
    
    [p,tbl,stats] = kruskalwallis(testD);
    title(['Avg. Distance per Time | Colony: ' num2str(i - 3)]);
    saveas(gcf,['test2_Colony' num2str(i-3) '_D1.png']);
    close gcf;
    saveas(gcf,['test2_Colony' num2str(i-3) '_D2.png']);
    close gcf;
    
    [p,tbl,stats] = kruskalwallis(testS);
    title(['Avg. Speed | Colony: ' num2str(i-3)])
    saveas(gcf,['test2_Colony' num2str(i-3) '_S1.png']);
    close gcf;
    saveas(gcf,['test2_Colony' num2str(i-3) '_S2.png']);
    close gcf;
    
    [p,tbl,stats] = kruskalwallis(testA);
    title(['Avg. Turning Angle | Colony: ' num2str(i-3)])
    saveas(gcf,['test2_Colony' num2str(i-3) '_A1.png']);
    close gcf;
    saveas(gcf,['test2_Colony' num2str(i-3) '_A2.png']);
    close gcf;
    
end

csvwrite('test2_D.csv',[squeeze(resultD(1,:,:));squeeze(resultD(2,:,:));...
    squeeze(resultD(3,:,:))]);
csvwrite('test2_S.csv',[squeeze(resultS(1,:,:));squeeze(resultS(2,:,:));...
    squeeze(resultS(3,:,:))]);
csvwrite('test2_A.csv',[squeeze(resultA(1,:,:));squeeze(resultA(2,:,:));...
    squeeze(resultA(3,:,:))]);

%% Test 3: Comparison among different colonies

resultD = [];
resultS = [];
resultA = [];
testD = [];
testS = [];
testA = [];
for i = [4 5 6]
    
    
    idxcol = [antinfo(:).colnum] == i;
    idx = 1;
    for k = find(idxcol)
        testD(idx,i-3) = antinfo(k).dist(end)/antinfo(k).time(end);
        testS(idx,i-3) = nanmean(antinfo(k).speed);
        testA(idx,i-3) = nanmean(antinfo(k).angle);
        idx = idx + 1;
    end
end

testD(testD == 0) = nan;
testS(testS == 0) = nan;
testA(testA == 0) = nan;

[p,tbl,stats] = kruskalwallis(testD);
title('Avg. Distance per Time');
saveas(gcf,'test3_D1.png');
close gcf;
saveas(gcf,'test3_D2.png');
close gcf;

[p,tbl,stats] = kruskalwallis(testS);
title('Avg. Speed')
saveas(gcf,'test3_S1.png');
close gcf;
saveas(gcf,'test3_S2.png');
close gcf;

[p,tbl,stats] = kruskalwallis(testA);
title('Avg. Turning Angle')
saveas(gcf,'test3_A1.png');
close gcf;
saveas(gcf,'test3_A2.png');
close gcf;

%% Test 4: Comparison between major / minor

resultD = [];
resultS = [];
resultA = [];
testD = [];
testS = [];
testA = [];
for i = [0 1]
    
    
    idxmajor = [antinfo(:).major] == i;
    idx = 1;
    for k = find(idxmajor)
        testD(idx,i+1) = antinfo(k).dist(end)/antinfo(k).time(end);
        testS(idx,i+1) = nanmean(antinfo(k).speed);
        testA(idx,i+1) = nanmean(antinfo(k).angle);
        idx = idx + 1;
    end
end

testD(testD == 0) = nan;
testS(testS == 0) = nan;
testA(testA == 0) = nan;
% 
% [p,tbl,stats] = kruskalwallis(testD);
% title('Avg. Distance per Time');
% saveas(gcf,'test4_D1.png');
% close gcf;
% saveas(gcf,'test4_D2.png');
% close gcf;
% 
% [p,tbl,stats] = kruskalwallis(testS);
% title('Avg. Speed')
% saveas(gcf,'test4_S1.png');
% close gcf;
% saveas(gcf,'test4_S2.png');
% close gcf;
% 
% [p,tbl,stats] = kruskalwallis(testA);
% title('Avg. Turning Angle')
% saveas(gcf,'test4_A1.png');
% close gcf;
% saveas(gcf,'test4_A2.png');
% close gcf;

%% Test 5: Comparison between major / minor per colonies

resultD = [];
resultS = [];
resultA = [];


for j = [4 5 6]
testD = [];
testS = [];
testA = [];
    for i = [0 1]
        idxcol = [antinfo(:).colnum] == j;
        idxmajor = [antinfo(:).major] == i;
        idx = 1;
        for k = find(idxmajor & idxcol)
            testD(idx,i+1) = antinfo(k).dist(end)/antinfo(k).time(end);
            testS(idx,i+1) = nanmean(antinfo(k).speed);
            testA(idx,i+1) = nanmean(antinfo(k).angle);
            idx = idx + 1;
        end
    end
    testD(testD == 0) = nan;
    testS(testS == 0) = nan;
    testA(testA == 0) = nan;
    
    [p,tbl,stats] = kruskalwallis(testD);
    resultD(j-3) = p;
    title(['Avg. Distance per Time | Colony: ' num2str(j - 3)]);
    saveas(gcf,['test5_Colony' num2str(j-3) '_D1.png']);
    close gcf;
    saveas(gcf,['test5_Colony' num2str(j-3) '_D2.png']);
    close gcf;
    
    [p,tbl,stats] = kruskalwallis(testS);
    resultS(j-3) = p;
    title(['Avg. Speed | Colony: ' num2str(j - 3)]);
    saveas(gcf,['test5_Colony' num2str(j-3) '_S1.png']);
    close gcf;
    saveas(gcf,['test5_Colony' num2str(j-3) '_S2.png']);
    close gcf;
    
    [p,tbl,stats] = kruskalwallis(testA);
    resultA(j-3) = p;
    title(['Avg. Turning Angle | Colony: ' num2str(j - 3)]);
    saveas(gcf,['test5_Colony' num2str(j-3) '_A1.png']);
    close gcf;
    saveas(gcf,['test5_Colony' num2str(j-3) '_A2.png']);
    close gcf;
end
csvwrite('test5_DSA.csv', [resultD;resultS;resultA]);

%% Test 6: Comparison between major / minor per boxes

resultD = [];
resultS = [];
resultA = [];


for j = [1 2 3 4 5 6 7 8]
testD = [];
testS = [];
testA = [];
    for i = [0 1]
        idxbox = [antinfo(:).boxnum] == j;
        idxmajor = [antinfo(:).major] == i;
        idx = 1;
        for k = find(idxmajor & idxbox)
            testD(idx,i+1) = antinfo(k).dist(end)/antinfo(k).time(end);
            testS(idx,i+1) = nanmean(antinfo(k).speed);
            testA(idx,i+1) = nanmean(antinfo(k).angle);
            idx = idx + 1;
        end
    end
    testD(testD == 0) = nan;
    testS(testS == 0) = nan;
    testA(testA == 0) = nan;
    
    resultD(j) = kruskalwallis(testD,[],'off');
    resultS(j) = kruskalwallis(testS,[],'off');
    resultA(j) = kruskalwallis(testA,[],'off');

end

csvwrite('test6_DSA.csv', [resultD;resultS;resultA]);
