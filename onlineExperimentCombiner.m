%{
Concatenates multiple tasks built for the OPLab.barrios.io environment into
one long experiment with a break in between each.

This expects each task to be in a zip folder named as the task. If a task 
has multiple zip folders, they should be numbered at the end. For example:
Online_NOMT_Zigg1.zip, Online_NOMT_Zigg2.zip, Online_Matching_Shein.zip.
%}
clear all;

%% Generation parameters
% Task names and order
tasks = {'onlineSheinNOMT', 'onlineZiggMatching'};
transitionFile = 'transitionScreen.png';

%% Prepare
% Make the directory for full experiment if needed
if ~exist('fullExperiment', 'dir')
    mkdir('fullExperiment');
end

% Load transition image
transImg = imread(transitionFile);

% Delete tmp directory if it exist
if exist('tmp', 'dir')
    rmdir('tmp', 's');
end

%% Unzip the first task
taskFiles = dir(['tasks/' tasks{1} '*.zip']);
taskFiles = {taskFiles.name};
cellfun(@(x) {unzip(['tasks/' x], 'fullExperiment')}, taskFiles);

% Determine last trial number
experimentImgs = dir('fullExperiment/*.jpg');
experimentImgs = {experimentImgs.name};
experimentImgs = cellfun(@(x) {strsplit(x, '_')}, experimentImgs); 
experimentImgs = cellfun(@(x) {str2double(x{2})}, experimentImgs);
trialNum = max([experimentImgs{:}]);

%% Unzip and rename the rest of the tasks
for i = 2:numel(tasks)
    % Add an intervening screen
    trialNum = trialNum + 1;
    imgName = ['trial_', num2str(trialNum) ...
        '_block-0_sections-1_clickable-true_isi-250.jpg'];
    imwrite(transImg, ['fullExperiment/' imgName]);
    
    % Create temporary directory and unzip all files into it
    mkdir('tmp');
    taskFiles = dir(['tasks/' tasks{i} '*.zip']);
    taskFiles = {taskFiles.name};
    cellfun(@(x) {unzip(['tasks/' x], 'tmp')}, taskFiles);
    
    % Get each image name and new numbers
    experimentImgs = dir('tmp/*.jpg');
    experimentImgs = {experimentImgs.name};
    experimentImgs = cellfun(@(x) {strsplit(x, '_')}, experimentImgs); 
    experimentNums = cellfun(@(x) {str2double(x{2})}, experimentImgs);
    experimentNums = [experimentNums{:}] + trialNum;
    
    % Loop through images and save new images
    for j = 1:numel(experimentImgs)
        originalFile = ['tmp/', strjoin(experimentImgs{j}, '_')];
        experimentImgs{j}{2} = num2str(experimentNums(j));
        movefile(originalFile, ['fullExperiment/' ...
            strjoin(experimentImgs{j}, '_')])
    end
    
    % Remember new last trial number
    trialNum = max(experimentNums);
    
    % Remove temporary directory
    rmdir('tmp', 's');
end

%% Package images into zips for upload with workaround
allTrials = dir('fullExperiment/trial*');
allTrials = {allTrials.name};
packs = ceil(numel(allTrials)/250);

% Zip together sets of images for upload
for i = 1:packs
    if i == packs % Last pack
        zip(['fullExperiment' num2str(i) '.zip'], ...
            allTrials((((i-1)*250)+1):numel(allTrials)),...
            'fullExperiment')
    else
        zip(['fullExperiment' num2str(i) '.zip'], ...
            allTrials((((i-1)*250)+1):i*250), 'fullExperiment')
    end
end