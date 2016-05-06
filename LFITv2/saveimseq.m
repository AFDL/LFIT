function [] = saveimseq(imageArray,imSavePath,tfAskUserForDir,fileTypeFlag,tfNorm)
%READIMSEQ Reads in a sequence of images in a folder into a 3D array.
%
% imageArray      : image stack to save slice by slice
% imSavePath      : path to save directory for image sequence (no trailing
%                   slash)
% tfAskUserForDir : true or false; controls whether function prompts the
%                   user to select a directory
% fileTypeFlag    : integer; 0 for no saving, 1 for saving a bmp, 2 for
%                   saving a png, 3 for saving a jpg of the image, 4 for a
%                   16-bit PNG, 5 for a 16-bit TIFF
% tfNorm          : true or false; if true, normalizes the image array by
%                   the maximum intensity in the entire array

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


if tfAskUserForDir == true
   imSavePath = uigetdir(userpath,'Select the folder to save the image sequence into...'); 
end

disp('Reading in image sequence...');
progress(0);

imageArray = im2double(imageArray);

if tfNorm
    imageArray = imageArray/max(imageArray(:));
end

nImages = size(imageArray,3);
for imInd = 1:nImages
    
    if ~exist(imSavePath,'dir'), mkdir(imSavePath); end
    
    fname = sprintf( '_%04.f', imInd );
    switch fileTypeFlag
        case 2
            fout = fullfile(imSavePath,[fname '.png']);
            imwrite(imageArray(:,:,imInd),fout);
            
        case 4
            imExp = uint16(imageArray(:,:,imInd)*65536);
            fout = fullfile(imSavePath,[fname '.png']);
            imwrite(imExp,fout);
            
        case 5
            imExp = uint16(imageArray(:,:,imInd)*65536);
            fout = fullfile(imSavePath,[fname '.tif']);
            imwrite(imExp,fout,'tif','compression','lzw');
            
        otherwise
            error('Not yet supported. Only PNG output (flag 2 and flag 4) and TIFF output (flag 5) supported currently.');
            
    end%switch
    
    % Timer logic
    progress(imInd,nImages);
    
end%for

end%function
