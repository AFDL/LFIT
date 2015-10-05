function [] = saveimseq(imageArray,imSavePath,tfAskUserForDir,fileTypeFlag,tfNorm)
% readimseq | Reads in a sequence of images in a folder into a 3D array
%
%   imageArray          =  image stack to save slice by slice
%   imSavePath          =  path to save directory for image sequence (no trailing slash)
%   tfAskUserForDir     =  true or false; controls whether function prompts the user to select a directory
%   fileTypeFlag   =  integer; 0 for no saving, 1 for saving a bmp, 2 for saving a png, 3 for saving a jpg of the image, 4 for a 16-bit PNG, 5 for a 16-bit TIFF
%   tfNorm              =  true or false; if true, normalizes the image array by the maximum intensity in the entire array
%
% Authored by: Jeffrey Bolan based on Kyle Johnson's code | 10/2/2014

if tfAskUserForDir == true
   imSavePath = uigetdir(userpath,'Select the folder to save the image sequence into...'); 
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

imageArray = im2double(imageArray);

if tfNorm == true
    imageArray = imageArray./max(max(max(imageArray)));
end

num=0; %timer logic
fprintf('   Time remaining:           ');



for imInd = 1:size(imageArray,3)
    if exist(imSavePath,'dir') ~= 7
        mkdir(imSavePath);
    end
    time=tic;
    switch fileTypeFlag
        case 2
            imwrite(imageArray(:,:,imInd),[imSavePath '/' '_' num2str(imInd,'%04.f') '.png']);
        case 4
            imExp = uint16(imageArray(:,:,imInd)*65536);
            imwrite(imExp,[imSavePath '/' '_' num2str(imInd,'%04.f') '.png']);
        case 5
            imExp = uint16(imageArray(:,:,imInd)*65536);
            imwrite(imExp,[imSavePath '/' '_' num2str(imInd,'%04.f') '.tif'],'tif');
        otherwise
            error('Not yet supported. Only PNG output (flag 2 and flag 4) and TIFF output (flag 5) supported currently.');
    end
    
    % Timer logic
    time=toc(time);
    timerVar=time/60*((size(imageArray,3)-imInd));
    if timerVar>=1
        timerVar=round(timerVar);
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g m',timerVar)
    else
        timerVar=round(time*((size(imageArray,3)-imInd)));
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g s',timerVar)
    end
end


fprintf('\n   Complete.\n');
end
