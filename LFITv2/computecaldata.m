function cal = computecaldata(calFolderPath,calImagePath,loadFlag,saveFlag,imageSetName,calType,numMicroX,numMicroY,microPitch,pixelPitch)
%COMPUTECALDATA Generates calibration data matrix for the microlens array.
%
% For the rectangular case:
%   Runs efficient method developed by Kyle Johnson first. User is prompted
%   to accept/reject the result (when shown calibration image of microlens
%   locations). If rejected, an alternate calibration method is run. This
%   method, developed by Jeffrey Bolan, is slower, but implements a
%   different algorithm which might yield usable results if the primary
%   calibration method fails.
%
% For the hexagonal case:
%   Follow the command line prompts.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


switch loadFlag
    case 0 % No load/save
        recompute = true;
        
    case 1 % Auto load/save
        fprintf('Loading calibration data from file...');
        try
            load(fullfile(calFolderPath,[imageSetName '_calibration.mat']),'cal');
            fprintf('complete.\n');
            recompute = false;
        catch
            %load failed
            recompute = true;
            warning('Calibration data failed to load. Recomputing calibration...');
        end
        
    case 2 % Clear calibration and save new
        try
            delete(fullfile(calFolderPath,[imageSetName '_calibration.mat']));
            [warnmsg, msgid] = lastwarn;
            if strcmp(msgid,'MATLAB:DELETE:FileNotFound')
                fprintf('Previous calibration for the given Image Set Name not found. Recomputing calibration...\n');
            else
                fprintf('Successfully deleted old calibration. Recomputing calibration...\n');
            end
            recompute = true;
        catch
            %load failed
            recompute = true;
            warning('Calibration data unable to be deleted. Recomputing calibration...');
        end
        
    case 3
        % Load points from file
        
        % From Tim
        [xName,loadPathX] = uigetfile({'*.txt','Text files (*.txt)'},'Select the cLocX text file...',cd);
        fileIDX = fopen([loadPathX xName],'r');
        if fileIDX == -1
            errorStr = ['Failed to read ' loadPathX xName];
            error(errorStr);
        else
            sIndMax = str2double(fgetl(fileIDX));
            tIndMax = str2double(fgetl(fileIDX));
            c_x = fscanf(fileIDX,'%f',[1 inf]);
            cLocX = reshape(c_x,sIndMax,tIndMax);
            cLocX = cLocX + 1; % convert C coordinates to MATLAB coordinates
            fclose(fileIDX);
        end
        
        [yName,loadPathY] = uigetfile({'*.txt','Text files (*.txt)'},'Select the cLocY text file...',loadPathX);
        fileIDY = fopen([loadPathY yName],'r');
        if fileIDY == -1
            errorStr = ['Failed to read ' loadPathY yName];
            error(errorStr);
        else
            sIndMax = str2double(fgetl(fileIDY));
            tIndMax = str2double(fgetl(fileIDY));
            c_y = fscanf(fileIDY,'%f',[1 inf]);
            cLocY = reshape(c_y,sIndMax,tIndMax);
            cLocY = cLocY + 1; % convert C coordinates to MATLAB coordinates
            fclose(fileIDY);
        end
               
        % Crop data if necessary
        subRadX = floor((microPitch/pixelPitch)/2); %microlens radius
        % These cropping limits were selected intelligently, but somewhat arbitrarily. A more rigorous specification could be had.
        if cLocX(1,1) < 1.5*subRadX || cLocX(1,end)  < 1.5*subRadX
            % crop left edge
            cLocX = cLocX(2:end,:);
            cLocY = cLocY(2:end,:);
            sIndMax = sIndMax - 1;
        end
        if cLocX(end,1) > (numMicroX*microPitch/pixelPitch) || cLocX(end,end) > (numMicroX*microPitch/pixelPitch) %turns out this value is slightly lower than the 4904px (16MP) width of the sensor b/c the microlens array is physically slightly larger. Not the cleanest, but it's an acceptable way to define the cropping boundaries without adding more input arguments.
            % crop right edge
            cLocX = cLocX(1:end-1,:);
            cLocY = cLocY(1:end-1,:);
            sIndMax = sIndMax - 1;
        end
        if cLocY(1,1) < 1.5*subRadX || cLocY(end,1) < 1.5*subRadX
            % crop top row
            cLocY = cLocY(:,2:end);
            cLocX = cLocX(:,2:end);
            tIndMax = tIndMax - 1;
        end
        if cLocY(1,end) > (numMicroY*microPitch/pixelPitch) || cLocY(end,end) > (numMicroY*microPitch/pixelPitch) %turns out this value is slightly lower than the 3280px (16MP) height of the sensor b/c the microlens array is physically slightly larger
            % crop bottom of image
            cLocY = cLocY(:,1:end-1);
            cLocX = cLocX(:,1:end-1);
            tIndMax = tIndMax - 1;
        end
        
        % Create calibration structure for export
        cal.exactX  = permute(cLocX,[2 1]);     % x(s,t)  !!!
        cal.exactY  = permute(cLocY,[2 1]);     % y(s,t)  !!!
        cal.roundX  = round( cal.exactX );
        cal.roundY  = round( cal.exactY );
        cal.numS    = size(cal.exactX,1);
        cal.numT    = size(cal.exactX,2);
        
        recompute = false;
        
    otherwise
        warning('Load flag defined incorrectly internally. Recomputing calibration...');
        recompute = true;
        
end%switch


if recompute
    
    switch calType
        case 'rect'
            % Run fast method (Kyle's)
            [cal,tfAcceptCal] = calrect(calImagePath);
            
            % Check whether user accepted or rejected the fast calibration from above.
            while ~tfAcceptCal
                
                while true
                    userInput = input('Do you wish to reattempt the quick calibration method? Type Y for quick calibration or N for alternate algorithm: ','s');
                    switch lower(userInput)
                        case {'y','yes'}
                            tfReattemptQuick = true;
                            fprintf('Re.\n');
                            
                            % Run fast method (Kyle's)
                            [cal,tfAcceptCal] = calrect(calImagePath);
                            break
                            
                        case {'n','no'}
                            tfReattemptQuick = false;
                            fprintf('Calibration rejected. Now preparing alternate method...\n');
                            fprintf('\nAlternate Calibration Method\n');
                            fprintf('  Setting a threshold value between 0 and 1:\n');
                            fprintf('   Lower values increase sensitivity, but are more likely to pick up noise/artifacts as well.\n');
                            fprintf('   Higher values reduce sensitivity and filter out more artifacts, but can result in a less accurate calibration.\n');
                            fprintf('   The recommended value for this calibration image set is %.2f\n\n',graythresh(im2double(imadjust(imread(calImagePath)))));
                            sens = -1;
                            while sens < 0 || sens > 1
                                sens = input('Enter a threshold value between 0 and 1: ');
                                if sens < 0 || sens > 1
                                    fprintf('This number is not between 0 and 1.\n');
                                end
                            end
                            
                            % Call alternate calibration method (slower fallback/Jeffrey's)
                            [cal,tfAcceptCal] = calgeneral(calImagePath,calType,sens,numMicroX,numMicroY,microPitch,pixelPitch);
                            break
                            
                        otherwise
                            disp('Please type Y or N and then press the <Enter> key.');
                            
                    end%switch
                    
                end%while
                
            end%while
            
        case 'hexa'
            
            % Run fast method (Kyle's modified for hexagonal)
            [cal,tfAcceptCal] = calgeneral(calImagePath,'hexafast',0,numMicroX,numMicroY,microPitch,pixelPitch);
            
            % Check whether user accepted or rejected the fast calibration from above.
            while ~tfAcceptCal
                
                fprintf('\n|   CALIBRATION MENU   |\n');
                fprintf('-----------------------------------------------------------------\n');
                fprintf('[1] = Select new points to recompute fast hexagonal calibration. \n');
                fprintf('[2] = Use alternate hexagonal calibration method (slower). \n');
                fprintf('[3] = QUIT.\n');
                fprintf('\n');
                
                while true
                    userInput = input('Enter a number from the menu above to proceed: ','s');
                    switch lower(strtrim(userInput))
                        case {'1','one'}
                            % Fast Hexagonal Calibration (modified rectangular algorithm)
                            fprintf('\nRecomputing calibration with fast algorithm...\n');
                            [cal,tfAcceptCal] = calgeneral(calImagePath,'hexafast',0,numMicroX,numMicroY,microPitch,pixelPitch);
                            break
                            
                        case {'2','two'}
                            fprintf('\nRecomputing calibration with alternate algorithm...\n');
                            % Old/Legacy Hexagonal Calibration Method
                            fprintf('\nAlternate Hexagonal Calibration Method\n');
                            fprintf('  Setting a threshold value between 0 and 1:\n');
                            fprintf('   Lower values increase sensitivity, but are more likely to pick up noise/artifacts as well.\n');
                            fprintf('   Higher values reduce sensitivity and filter out more artifacts, but can result in a less accurate calibration.\n');
                            fprintf('   The recommended value for this calibration image set is %.2f\n\n',graythresh(im2double(imadjust(imread(calImagePath)))));
                            sens = -1;
                            while sens < 0 || sens > 1
                                sens = input('Enter a threshold value between 0 and 1: ');
                                if sens < 0 || sens > 1
                                    fprintf('This number is not between 0 and 1.\n');
                                end
                            end
                            [cal,tfAcceptCal] = calgeneral(calImagePath,calType,sens,numMicroX,numMicroY,microPitch,pixelPitch);
                            break
                            
                        case {'3','three'}
                            error('PROGRAM EXECUTION ENDED BY USER.');
                            
                        otherwise
                            disp('Please enter a number from the above menu then press the <Enter> key.');
                            
                    end%switch
                    
                end%while
                
            end%while
            
        otherwise
            error('Incorrect calibration type indicated.');
            
    end%switch
    
    if saveFlag && tfAcceptCal
        % Save matrix to file
        fprintf('Saving matrix to file...');
        save(fullfile(calFolderPath,[imageSetName '_calibration.mat']),'cal');
        fprintf('complete.\n');
    end
    
end%if

end%function
