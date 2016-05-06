function [imageArray] = readimseq(imFolderPath,tfAskUserForDir,fileTypeFlag,tfNorm)
%READIMSEQ Reads in a sequence of images in a folder into a 3D array.
%
% imFolderPath      : path to directory containing image seqences (no
%                     trailing slash)
% tfAskUserForDir   : true or false; controls whether function prompts the
%                     user to select a directory
% fileTypeExtension : string in this format: '*.tif' or '*.png' or '*.bmp'
%                     etc. to control what file type is read in
% tfNorm            : true or false; if true, normalizes the image array by
%                     the maximum intensity in the entire array

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.

if tfAskUserForDir == true
   imFolderPath = uigetdir(userpath,'Select a folder containing the image sequence to be read into MATLAB...'); 
end

switch fileTypeFlag
    case 0,     error('0 is not a valid fileTypeFlag for readImageSeq(..). Check function call.');
    case 1,     fileTypeExtension = '*.bmp';
    case 2,     fileTypeExtension = '*.png';
    case 3,     fileTypeExtension = '*.jpg';
    case 4,     fileTypeExtension = '*.png';
    case 5,     fileTypeExtension = '*.tif';
    otherwise,  error('Bad fileTypeFlag passed to readImageSeq. Check function call.');
end

disp('Reading in image sequence...');
progress(0);

imageName = dir(fullfile(imFolderPath,fileTypeExtension)); %generate structure array of all TIFF files in directory
imageName = {imageName.name};

nImages = length(imageName);

if nImages < 1
    error('No images found with the extension %s in %s.',fileTypeExtension,imFolderPath);
end

imageArray(:,:,1) = im2double(imread(fullfile(imFolderPath,imageName{1}))); % initialize I with the first image
for imInd = 2:nImages
    imageArray(:,:,imInd) = im2double(imread(fullfile(imFolderPath,imageName{imInd})));
    
    % Timer logic
    progress(imInd,nImages+1);
end

if tfNorm
    imageArray = imageArray/max(imageArray(:));
end

% Complete
progress(1,1);

end%function
