function [calData] = computecaldata(calFolderPath,calImagePath,loadFlag,saveFlag,imageSetName,calType,numMicroX,numMicroY,microPitch,pixelPitch)
% computecal | Generates calibration data matrix for the microlens array.
%
%  Finds microlens center locations and returns accompanying calibration data array.
%
%  For the rectangular case:
%  Runs efficient method developed by Kyle Johnson first. User is prompted
%  to accept/reject the result (when shown calibration image of microlens
%  locations). If rejected, an alternate calibration method is run. This method,
%  developed by Jeffrey Bolan, is slower, but implements a different algorithm
%  which might yield usable results if the primary calibration method
%  fails.
%
%  For the hexagonal case:
%  Follow the command line prompts.


switch loadFlag
    case 0
        % No load/save
        recompute = true;
    case 1
        % Auto load/save
        fprintf('Loading calibration data from file...');
        try
            load([calFolderPath '\' imageSetName '_' 'calData.mat'],'calData');
            fprintf('complete.\n');
            recompute = false;
        catch generror1
            %load failed
            recompute = true;
            warning('Calibration data failed to load. Recomputing calibration...');
        end
    case 2
        % Clear calibration and save new
        try
            delete([calFolderPath '\' imageSetName '_' 'calData.mat'],'calData');
            [warnmsg, msgid] = lastwarn;
            if strcmp(msgid,'MATLAB:DELETE:FileNotFound')
                fprintf('Previous calibration for the given Image Set Name not found. Recomputing calibration...\n');
            else
                fprintf('Successfully deleted old calibration. Recomputing calibration...\n');
            end
            recompute = true;
        catch generror1
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
            sIndMax = str2num(fgetl(fileIDX));
            tIndMax = str2num(fgetl(fileIDX));
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
            sIndMax = str2num(fgetl(fileIDY));
            tIndMax = str2num(fgetl(fileIDY));
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
        
        % Format imported data into the LFIT container, calData
        calibrationPoints(:,:,1) = cLocX';
        calibrationPoints(:,:,2) = cLocY';
        closestPoint(:,1) = c_x;
        closestPoint(:,2) = c_y;
        
        calData = {calibrationPoints,closestPoint(:,1),closestPoint(:,2),sIndMax,tIndMax};
        
        recompute = false;
    otherwise
        warning('Load flag defined incorrectly internally. Recomputing calibration...');
        recompute = true;
end


if recompute == true
    
    switch calType
        case 'rect'
            % Run fast method (Kyle's)
            [calData,tfAcceptCal] = calrect(calImagePath);
            
            % Check whether user accepted or rejected the fast calibration from above.
            while tfAcceptCal == false
                
                inputLoop = true;
                while inputLoop == true
                    userInput = input('Do you wish to reattempt the quick calibration method? Type Y for quick calibration or N for alternate algorithm: ','s');
                    switch userInput
                        case {'Y','y','yes','YES','Yes'}
                            tfReattemptQuick = true;
                            fprintf('Re.\n');
                            inputLoop = false;
                            % Run fast method (Kyle's)
                            [calData,tfAcceptCal] = calrect(calImagePath);
                        case {'N','n','no','NO','No'}
                            tfReattemptQuick = false;
                            fprintf('Calibration rejected. Now preparing alternate method...\n');
                            inputLoop = false;
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
                            [calData,tfAcceptCal] = calgeneral(calImagePath,calType,sens,numMicroX,numMicroY,microPitch,pixelPitch);
                        otherwise
                            disp('Please type Y or N and then press the <Enter> key.');
                    end
                end
            end
            
        case 'hexa'
            
            % Run fast method (Kyle's modified for hexagonal)
            [calData,tfAcceptCal] = calgeneral(calImagePath,'hexafast',0,numMicroX,numMicroY,microPitch,pixelPitch);
            
            % Check whether user accepted or rejected the fast calibration from above.
            while tfAcceptCal == false
                
                inputLoop = true;
                fprintf('\n|   CALIBRATION MENU   |\n');
                fprintf('-----------------------------------------------------------------\n');
                fprintf('[1] = Select new points to recompute fast hexagonal calibration. \n');
                fprintf('[2] = Use alternate hexagonal calibration method (slower). \n');
                fprintf('[3] = QUIT.\n');
                fprintf('\n');
                while inputLoop == true
                    userInput = input('Enter a number from the menu above to proceed: ','s');
                    switch userInput
                        case {'1','one','[1]','ONE','One',' 1'}
                            % Fast Hexagonal Calibration (modified rectangular algorithm)
                            fprintf('\nRecomputing calibration with fast algorithm...\n');
                            [calData,tfAcceptCal] = calgeneral(calImagePath,'hexafast',0,numMicroX,numMicroY,microPitch,pixelPitch);
                            inputLoop = false;
                        case {'2','two','[2]','TWO','Two',' 2'}
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
                            [calData,tfAcceptCal] = calgeneral(calImagePath,calType,sens,numMicroX,numMicroY,microPitch,pixelPitch);
                            inputLoop = false;
                            
                        case {'3','three','[3]','THREE','Three',' 3'}
                            error('PROGRAM EXECUTION ENDED BY USER.');
                        otherwise
                            disp('Please enter a number from the above menu then press the <Enter> key.');
                    end
                end
            end
        otherwise
            error('Incorrect calibration type indicated.');
    end
    
    if saveFlag == true
        if tfAcceptCal == true
            % Save matrix to file
            fprintf('Saving matrix to file...');
            save([calFolderPath '\' imageSetName '_' 'calData.mat'],'calData');
            fprintf('complete.\n');
        end
    end
    
end

end
