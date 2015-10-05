function [imageArray] = readimseq(imFolderPath,tfAskUserForDir,fileTypeFlag,tfNorm)
% readimseq | Reads in a sequence of images in a folder into a 3D array
%
%   imFolderPath        =  path to directory containing image seqences (no trailing slash)
%   tfAskUserForDir     =  true or false; controls whether function prompts the user to select a directory
%   fileTypeExtension   =  string in this format: '*.tif' or '*.png' or '*.bmp' etc. to control what file type is read in
%   tfNorm              =  true or false; if true, normalizes the image array by the maximum intensity in the entire array
%
% Authored by: Jeffrey Bolan based on Kyle Johnson's code | 10/2/2014

if tfAskUserForDir == true
   imFolderPath = uigetdir(userpath,'Select a folder containing the image sequence to be read into MATLAB...'); 
end

switch fileTypeFlag
    case 0
        error('0 is not a valid fileTypeFlag for readImageSeq(..). Check function call.');
    case 1
        fileTypeExtension = '*.bmp';
    case 2
        fileTypeExtension = '*.png';
    case 3
        fileTypeExtension = '*.jpg';
    case 4
        fileTypeExtension = '*.png';
    case 5
        fileTypeExtension = '*.tif';
    otherwise
        error('Bad fileTypeFlag passed to readImageSeq. Check function call.');
end

disp('Reading in image sequence...');

num=0; %timer logic
fprintf('   Time remaining:           ');


imageName = dir([imFolderPath '\' fileTypeExtension]); %generate structure array of all TIFF files in directory
if size(imageName,1) < 1
    switch fileTypeFlag
        case 3
            imageName = dir([imFolderPath '\' '*.jpeg']);
        case 5
            imageName = dir([imFolderPath '\' '*.tiff']);
    end
    if size(imageName,1) < 1
        error('No images found with the extension %s in %s.',fileTypeExtension,imFolderPath);
    end
end

imageArray(:,:,1) = im2double(imread([imFolderPath '\' imageName(1).name])); % initialize I with the first image
for imInd = 2:size(imageName,1)
    time=tic;
    imageArray(:,:,imInd)=im2double(imread([imFolderPath '\' imageName(imInd).name]));
    time=toc(time);
    timerVar=time/60*((size(imageName,1)-imInd));
    if timerVar>=1
        timerVar=round(timerVar);
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g m',timerVar)
    else
        timerVar=round(time*((size(imageName,1)-imInd)));
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g s',timerVar)
    end
end
if tfNorm == true
    imageArray = imageArray./max(max(max(imageArray)));
end

fprintf('\n   Complete.\n');
end
