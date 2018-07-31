function [ calImagePath ] = imageavg(calFolderPath,saveName)
%IMAGEAVG Takes multiple images and averages them together.
%
% Function will write a new image 'avgcal.tif' in the same directory as the
% input directory. Input the full path of the folder containing
% all of the calibration files which should be labeled 0000 to 0099.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


if exist(fullfile(calFolderPath,'avgcal.tif'),'file') == 2 % if averaged calibration image already exists, just give the string back.
    calImagePath=fullfile(calFolderPath,'avgcal.tif');
    disp('Averaged calibration image found.');
    
else % averaged image does not exist, so compute it.
    disp('Averaging calibration images...');
    progress(0);
    
    imageName = dir(fullfile(calFolderPath,'*.tif')); %generate structure array of all TIFF files in directory
    imageName = {imageName.name};
    
    nImages = length(imageName);
    
    if nImages == 0 % Make sure there are actually files to average.
        error('No calibration images with extension *.tif found. Check calibration path. Program execution ended prematurely.');
    else
        I = im2double(imread(fullfile(calFolderPath,imageName{1}))); % initialize I with the first image
        for imageIndex = 2:nImages
            i=im2double(imread(fullfile(calFolderPath,imageName{imageIndex})));
            I=I+i;
            
            % Timer logic
            progress(imageIndex,nImages+1);
        end
        I=I/length(imageName);
        imwrite(uint16(I*65536),fullfile(calFolderPath,saveName),'compression','lzw') %16bit output
        calImagePath=fullfile(calFolderPath,saveName);
        
        % Complete
        progress(1,1);
    end
end
