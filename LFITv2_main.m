%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Light Field Imaging Toolkit (LFIT) v2.40 - DEMO PROGRAM %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% AUTHORS:
%  Original Lead Developer:  Jeffrey Bolan
%  Current Lead Developer:   Mahyar Moaven
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

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


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
if startProgram % If not, the GUI was closed somehow without pressing "Run"
    
    % Initialization
    if runMode == 0 % single image (NOT batch) mode
        
        % Process a single image
        numImages           = 1;
        imageIndex          = 1;
        refocusedImageStack = 0;
        
        % Update command line
        fprintf('LFI_Toolkit Demonstration Program\n');
        fprintf('-------------------------------------------------\n');
        
        % Adds toolkit path to MATLAB search path. Checks first for subfolder LFITv2 then looks in user folder for LFITv2
        [LFI_path,progVersion] = toolkitpathv2(); % assumes default toolkit path unless function called with alternate path string; see documentation
        
        % Calibration
        if loadFlag ~= 3 % standard calibration
            calImagePath = imageavg(calFolderPath,'avgcal.tif'); % average calibration images
        else % load external calibration points
            calImagePath = 0; % doesn't matter since we're loading external points
        end
        cal = computecaldata(calFolderPath,calImagePath,loadFlag,saveFlag,imageSetName,sensorType,numMicroX,numMicroY,microPitch,pixelPitch);
        
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
            
            if ~strcmp(plenopticImagesPath,newPath)
                plenopticImagesPath = newPath; % if the user selects an image outside of the main plenoptic images directory.
                
                % Since the user chose an image in a different directory than was defined originally, prompt for a new output folder.
                directory_name = uigetdir([plenopticImagesPath filesep],'Select an output folder to hold all exported/processed images...');
                if directory_name ~= 0
                    outputPath = directory_name;
                else
                    outputPath = fullfile(plenopticImagesPath,'Output'); % if user didn't select a folder, make one in the same directory as the plenoptic images
                    fprintf('\nNo output directory selected. Output will be in: %s\n',outputPath);
                end
            end
            
            imagePath = fullfile(plenopticImagesPath,imageName(imageIndex).name);
            
            % Interpolate image data
            [radArray,sRange,tRange] = interpimage2(cal,imagePath,sensorType,microPitch,pixelPitch,numMicroX,numMicroY);
            
            % Open second GUI after processing the initially selected image
            LFITv2_GUI_SinglePanel;
        end
    else
        %%%%---------------------------%%%%
        %%%%---BATCH PROCESSING MODE---%%%%
        %%%%---------------------------%%%%
       
        % Batch process all images in plenopticImagesPath folder
        imageName = dir(fullfile(plenopticImagesPath,'*.tif'));
        
        numImages = size(imageName,1);
        refocusedImageStack = 0;
        
        fprintf('LFI_Toolkit Demonstration Program\n');
        fprintf('-------------------------------------------------\n');
        
        % Adds toolkit path to MATLAB search path. Checks first for subfolder LFITv2 then looks in user folder for LFITv2
        % LFI_path = toolkitpathv2(false,'<alt path string>'); % assumes default toolkit path unless function called with true and alternate path string; see documentation
        LFI_path = toolkitpathv2();
        % Calibration
        calImagePath = imageavg(calFolderPath,'avgcal.tif'); % average calibration images
        cal = computecaldata(calFolderPath,calImagePath,loadFlag,saveFlag,imageSetName,sensorType,numMicroX,numMicroY,microPitch,pixelPitch);
        
        %%%%---MAIN BATCH MODE LOOP---%%%%
        
        for imageIndex = 1:numImages % will run through all images in the imageName structure (defined above in runMode)
            
            % Update variables
            imageSpecificName = [imageSetName '_' imageName(imageIndex).name(1:end-4)]; %end-4 removes .tif
            imagePath = fullfile(plenopticImagesPath,imageName(imageIndex).name);
            
            % Interpolate image data
            [radArray,sRange,tRange] = interpimage2(cal,imagePath,sensorType,microPitch,pixelPitch,numMicroX,numMicroY);
            
            %%%%%%%%---------------------------------%%%%%%%%
            %%%%%%%%---USER EDITS BEGIN BELOW HERE---%%%%%%%%
            %%%%%%%%---------------------------------%%%%%%%%
            
            % ADVICE: Comment out functions that you don't want to execute. To only compute perspective shifts,
            %         comment out the non-perspective shift functions below for example.
            
            %%%%---PERSPECTIVE SHIFT---%%%%
            q               = lfiQuery( 'perspective' );
            q.pUV           = [0 0; -6 0; 6 0];         % List of (u,v) coordinates
            q.saveas        = 'jpg';
            q.quality       = 90;
            q.display       = 'fast';
            q.contrast      = 'slice';
            q.verify;       % Verify that all query parameters are good
            genperspective(q,radArray,sRange,tRange,outputPath,imageSpecificName);
            
            
            %%%%---IMAGE REFOCUSING---%%%%
            q               = lfiQuery( 'focus' );
            q.fMethod       = 'filt';
            q.fFilter       = [0 0.9];
            q.fZoom         = 'telecentric';
            q.fGridX        = linspace(-18,18,300);
            q.fGridY        = linspace(-12,12,200);
            q.fPlane        = [0 1 2 3 4 5];            % List of focal planes
            q.fLength       = 50;
            q.fMag          = -1;
            q.saveas        = 'jpg';
            q.quality       = 90;
            q.display       = 'fast';
            q.contrast      = 'slice';
            q.mask          = 'circ';
            q.verify;       % Verify that all query parameters are good
            refocusedImageStack = genrefocus(q,radArray,sRange,tRange,outputPath,imageSpecificName);
            
            %%%%---FOCAL STACK GENERATION---%%%%
            % Request Vector Format - Shorthand (see documentation for full details)
            %[alphaArray,SS_UV,SS_ST,saveFlag,displayFlag,contrastFlag,colormap,bgcolor,captionFlag,'A caption string',apertureFlag,refocusType,filterInfo,TelecentricInfo];
            requestVectorFS = {[0 5; .9 1.1;],1,1,4,2,3,'gray',[.8 .8 .8],0,'No caption',1,3,[0 0.9],[1 -18 18 -12 12 -12 12 300 200 10 50 -1 0]};
            q = lfiQuery('focus'); q = q.import(requestVectorFS); % Request vectors may be converted to queries for legacy support
            q.verify;       % Verify that all settings are good
            [focalStack] = genrefocus(q,radArray,sRange,tRange,outputPath,imageSpecificName); % has output argument (optional). [focalStack] = genfocalstack(...)
            
            %%%%---ANIMATION - PERSPECTIVES---%%%%
            q               = lfiQuery( 'perspective' );
            q.pUV           = gentravelvector( 2, size(radArray), 1, 1);
%             q.mask          = 'square'; %should corrspond to last gentravelvector input for appropriate file name
            q.stFactor      = 1;
            q.saveas        = 'gif';
            q.framerate     = 15;
            q.display       = 'fast';
            q.contrast      = 'stack';
            q.verify;       % Verify that all query parameters are good
            genperspective(q,radArray,sRange,tRange,outputPath,imageSpecificName);
            
            q.saveas        = 'mp4';
            q.quality       = 90;
            q.verify;       % Verify that all query parameters are good
            genperspective(q,radArray,sRange,tRange,outputPath,imageSpecificName);      % Same animation, different format
            
            %%%%---ANIMATION - REFOCUSING---%%%%
            q               = lfiQuery( 'focus' );
            q.fMethod       = 'add';
            q.fZoom         = 'legacy';
            q.fAlpha        = [0.9:0.01:1.1];            % List of focal planes
            q.fLength       = 50;
            q.fMag          = -1;
            q.saveas        = 'gif';
            q.quality       = 90;
            q.framerate     = 15; % Play as fast as possible (delay=0)
            q.display       = 'fast';
            q.contrast      = 'stack';
            q.verify;       % Verify that all query parameters are good
            genrefocus(q,radArray,sRange,tRange,outputPath,imageSpecificName);
            
            
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
