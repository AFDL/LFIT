%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Light Field Imaging Toolkit (LFIT) v2.23 - DEMO PROGRAM %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHORS:
%  Original Lead Developer:  Jeffrey Bolan
%  Current Lead Developer:   Elise Munz
%
% NOTE:
%  First read the included documentation PDF.
%
% QUESTIONS/COMMENTS:
%  Please direct questions/comments regarding LFIT to Dr. 
%  Brian Thurow at his email address: Thurow@auburn.edu
%
% COMMENTS: 
%  This script file is a demonstration implementation of
%  the various functions contained within LFIT. As such,
%  all the functionality can be accessed by running this
%  script in accordance with the documentation. However, 
%  you may desire to write your own implementation of the
%  functions within LFIT; this script shows the necessary
%  function calls. Note that much of this script's code
%  is simply for the GUI. A much more condensed script
%  sans GUI could be written for a specific application.
%
% LICENSING:
%  Licensed under:  GNU General Public License, version 3 (GPL-3.0)
%     Copyright (C) 2015 Brian Thurow
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%% Prepare MATLAB Workspace
clc; 
close all; 
clear variables;
% clear global sizePixelAperture;
global sizePixelAperture; % Conversion from aperture pixels to millimeters as defined by (si*pixelPitch)/focLenMicro;

%% Open First GUI
% File paths and camera parameters are defined in this GUI
LFITv2_GUI_Prerun;

%% Main Program
if startProgram == true % If not, the GUI was closed somehow without pressing "Run"
    
    % Initialization
    if runMode == 0 % single image (NOT batch) mode
        
        % Process a single image
        numImages = 1;
        imageIndex = 1;
        refocusedImageStack = 0;
        
        % Update command line
        fprintf('LFI_Toolkit Demonstration Program\n');
        fprintf('-------------------------------------------------\n');
        
        % Adds toolkit path to MATLAB search path. Checks first for subfolder LFITv2 then looks in user folder for LFITv2
        [LFI_path,progVersion] = toolkitpathv2(false,'<alt path string>'); % assumes default toolkit path unless function called with true and alternate path string; see documentation
        
        % Calibration
        if loadFlag ~= 3 % standard calibration
            calImagePath = imageavg(calFolderPath,'avgcal.tif'); % average calibration images
        else % load external calibration points
            calImagePath = 0; % doesn't matter since we're loading external points
        end
        [calData] = computecaldata(calFolderPath,calImagePath,loadFlag,saveFlag,imageSetName,sensorType,numMicroX,numMicroY,microPitch,pixelPitch);
        
        %%%%---MAIN PROGRAM---%%%%
        
        % Load initial image for processing
        [firstImage,newPath] = uigetfile({'*.tiff; *.tif','TIFF files (*.tiff, *.tif)'},'Select a single raw plenoptic image to begin processing...',plenopticImagesPath);
        newPath = newPath(1:end-1); % removes trailing slash from path
        
        if firstImage == 0
            % Program is over. User did NOT select a file to import.
            warning('File not selected for import. Program execution ended.');
        else
            % Place image name in expected format.
            imageName = struct('name',firstImage);
            
            % Update variables
            imageSpecificName = [imageSetName '_' imageName(imageIndex).name(1:end-4)]; %end-4 removes .tif
            
            if strcmp(plenopticImagesPath,newPath) == false
                plenopticImagesPath = newPath; % if the user selects an image outside of the main plenoptic images directory.
                
                % Since the user chose an image in a different directory than was defined originally, prompt for a new output folder.
                directory_name = uigetdir([plenopticImagesPath '\'],'Select an output folder to hold all exported/processed images...');
                if directory_name ~= 0
                    outputPath = directory_name;
                else
                    outputPath = [plenopticImagesPath '\' 'Output']; % if user didn't select a folder, make one in the same directory as the plenoptic images
                    fprintf('\nNo output directory selected. Output will be in: %s \n',outputPath);
                end
            end
            
            imagePath = [plenopticImagesPath '\' imageName(imageIndex).name];
            
            % Interpolate image data
            [radArray,sRange,tRange] = interpimage2(calData,imagePath,sensorType,microPitch,pixelPitch,numMicroX,numMicroY);
            
            % Open second GUI after processing the initially selected image
            LFITv2_GUI_SinglePanel;
        end
    else
        %%%%---------------------------%%%%
        %%%%---BATCH PROCESSING MODE---%%%%
        %%%%---------------------------%%%%
        
        % Batch process all images in plenopticImagesPath folder
        imageName = dir([plenopticImagesPath '\' '*.tif']);
        
        numImages = size(imageName,1);
        refocusedImageStack = 0;
        
        fprintf('LFI_Toolkit Demonstration Program\n');
        fprintf('-------------------------------------------------\n');
        
        % Adds toolkit path to MATLAB search path. Checks first for subfolder LFITv2 then looks in user folder for LFITv2
        LFI_path = toolkitpathv2(false,'<alt path string>'); % assumes default toolkit path unless function called with true and alternate path string; see documentation
        
        % Calibration
        calImagePath = imageavg(calFolderPath,'avgcal.tif'); % average calibration images
        [calData] = computecaldata(calFolderPath,calImagePath,loadFlag,saveFlag,imageSetName,sensorType,numMicroX,numMicroY,microPitch,pixelPitch);
        
        %%%%---MAIN BATCH MODE LOOP---%%%%
        
        for imageIndex = 1:numImages % will run through all images in the imageName structure (defined above in runMode)
            
            % Update variables
            imageSpecificName = [imageSetName '_' imageName(imageIndex).name(1:end-4)]; %end-4 removes .tif
            imagePath = [plenopticImagesPath '\' imageName(imageIndex).name];
            
            % Interpolate image data
            [radArray,sRange,tRange] = interpimage2(calData,imagePath,sensorType,microPitch,pixelPitch,numMicroX,numMicroY);
            
            %%%%%%%%---------------------------------%%%%%%%%
            %%%%%%%%---USER EDITS BEGIN BELOW HERE---%%%%%%%%
            %%%%%%%%---------------------------------%%%%%%%%
            
            % ADVICE: Comment out functions that you don't want to execute. To only compute perspective shifts,
            %         just comment out the non-perspective shift functions below for example.
            
            %%%%---PERSPECTIVE SHIFT---%%%%
            % Request Vector Format - Shorthand (see documentation for full details)
            %[u,v,SS_ST,saveFlag,displayFlag,imadjustFlag,colormap,backgroundColor,captionFlag,'A caption string'];
            requestVectorP = {0.0, 0.0,1,4,2,1,'gray',[.8 .8 .8],0,'No caption';
                             -6.0, 0.0,1,4,2,1,'gray',[.8 .8 .8],0,'No caption';
                              6.0, 0.0,1,4,2,1,'gray',[.8 .8 .8],0,'No caption';};
            perspectivegen(radArray,outputPath,imageSpecificName,requestVectorP,sRange,tRange);
            
            
            %%%%---IMAGE REFOCUSING---%%%%
            % Request Vector Format - Shorthand (see documentation for full details)
            %[alpha,SS_UV,SS_ST,saveFlag,displayFlag,contrastFlag,colormap,bgcolor,captionFlag,'A caption string',apertureFlag,directoryFlag,refocusType,filterInfo,TelecentricInfo];
            % MUST CHOOSE SAME SS_ST for each image!
            requestVectorR = {0.9500,1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,0,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 200 50 -1 0];
                              0.9528,1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,0,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 200 50 -1 1];
                              1.0000,1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,0,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 200 50 -1 2];
                              1.0710,1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,0,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 200 50 -1 3];
                              1.1354,1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,0,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 200 50 -1 4];
                              1.0700,1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,0,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 200 50 -1 5];};
            %(x,y,alphaIndex,imageIndex)
            refocusedImageStack = genrefocus(radArray,outputPath,imageSpecificName,requestVectorR,sRange,tRange,imageIndex,numImages,refocusedImageStack);
            
            %%%%---FOCAL STACK GENERATION---%%%%
            % Request Vector Format - Shorthand (see documentation for full details)
            %[alphaArray,SS_UV,SS_ST,saveFlag,displayFlag,contrastFlag,colormap,bgcolor,captionFlag,'A caption string',apertureFlag,refocusType,filterInfo,TelecentricInfo];
            requestVectorFS = {[0 5; .9 1.1;],1,1,4,2,0,'gray',[.8 .8 .8],0,'No caption',1,3,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 10 50 -1 0];};
            [focalStack] = genfocalstack(radArray,outputPath,imageSpecificName,requestVectorFS,sRange,tRange); % has output argument (optional). [focalStack] = genfocalstack(...)
            
            %%%%---ANIMATION - PERSPECTIVES---%%%%
            % Request Vector Format - Shorthand (see documentation for full details)
            %[edgeBuffer,SS_UV, SS_ST, saveFlag, displayFlag, imadjustFlag, captionFlag, caption string,travelVectorIndex]
            requestVectorPM = {3,1,2,[1 0 0; 0 inf 1;],2,1,'gray',[.8 .8 .8],0,'No caption',2; %GIF example
                               3,1,2,[3 0 0; 95 30 1;],2,1,'gray',[0 0 0],0,'No caption',2;}; %MP4 example
            animateperspective(radArray,outputPath,imageSpecificName,requestVectorPM,sRange,tRange);
            
            %%%%---ANIMATION - REFOCUSING---%%%%
            % Request Vector Format - Shorthand (see documentation for full details)
            %[alphaArray,SS_UV,SS_ST,saveFlag,displayFlag,imadjustFlag,colormap,background color,caption flag,caption string,apertureFlag,refocusType,filterInfo,TelecentricInfo]
            requestVectorRM = {[1 5; .8 1.2; 1 0;],1,1,[1 0 0; 0 inf 1;],2,1,'gray',[.8 .8 .8],0,'No caption',1,2,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 10 50 -1 0]}; %GIF example
%                                [1 280; .6 1.4; 1 0;],1,1,[3 0 0; 95 30 1;],2,1,'gray',[0 0 0],0,'No caption',1,2,[0 0.9]}; %MP4 example
            animaterefocus(radArray,outputPath,imageSpecificName,requestVectorRM,sRange,tRange);
            
            
            %%%%%%%%-------------------------------%%%%%%%%
            %%%%%%%%---USER EDITS END ABOVE HERE---%%%%%%%%
            %%%%%%%%-------------------------------%%%%%%%%
        end
        % Program complete
        disp('PROGRAM EXECUTION COMPLETE.');
    end
else
    % User exited the initial pre-run GUI
    warning('User closed GUI without pressing Continue. Program execution ended.');
end