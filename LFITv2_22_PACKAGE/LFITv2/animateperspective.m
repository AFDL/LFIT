function animateperspective(radArray,outputPath,imageSpecificName,requestVector,sRange,tRange)
% animateperspective | Generates a perspective animation as defined by the request vector
%
%  requestVector:
%       {1} Edge buffer to keep the perspective sweep from pulling in poor data at image edge.
%       {2} supersamping factor in (u,v) is an integer by which to supersample for finer/slower movie sweeping. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {3} supersamping factor in (s,t) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {4} save flag is a vector: (typeFlag 0 0;parameters)
%               typeFlag:   0 for no saving, 1 for saving a GIF, 2 for saving a AVI, 3 for saving an MP4
%               parameters: for a GIF, (delay time between frames, # of loops [inf for unlimited], dithering [0 = none; 1 = yes]); for an AVI, (quality [# between 0 and 100], fps [frames per second], compression [0 = none; 1 = MSVC or Motion JPEG, 2 = RLE or Lossless Motion JPEG 2000, 3 = Cinepak or Compressed Motion JPEG 2000; (1st = MATLAB older than 2010b, 2nd = newer)]); for an MP4, (quality,fpsVal, 0 (placeholder));
%       {5} display flag is 0 for no display, 1 to display each perspective image with a pause, 2 to display each image without a pause
%       {6} imadjust flag is 0 for raw ouput, 1 is to apply the imadjust function to the perspective image (increases contrast)
%       {7} colormap is the colormap used in displaying the image, eg 'jet' or 'gray'
%       {8} background color is the background of the figure if the caption is enabled, eg [.8 .8 .8] or [1 1 1]
%       {9} caption flag is 0 for no caption, 1 for no caption w/border, 2 for caption string only, 3 for caption string + alpha value
%       {10} caption string is the string used in the caption for caption flag of 1 or 2.
%       {11} travelVectorIndex is 1 for square, 2 for circle, 3 for cross, 4 for load from file (WARNING: program will stop to open dialog prompt)


fprintf('\nBeginning perspective animation generation.\n');
fastTime = false;

for pInd = 1:size(requestVector,1) % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)
    fprintf('\nGenerating perspective animation (%i of %i)...',pInd,size(requestVector,1));
    timerVar=0; timeInd=0; 
    timeFlag = false; timeVector=[0]; timeAvg = .5; timeRate = ceil(requestVector{pInd,2}*1.5); % timing logic
    if requestVector{pInd,2} == 1
        fastTime = true;
    end
    travelVector = gentravelvector(requestVector{pInd,1},floor(size(radArray,1)/2),floor(size(radArray,1)/2),requestVector{pInd,2},requestVector{pInd,11});
    clear vidobj; vidobj = 0;
    try
        close(cF);
    catch err
        %figure already closed
    end
    cF = figure;
    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
    fprintf('\n   Time remaining:       ');
    for frameInd = 1:size(travelVector,1) % for each frame of a GIF (each specific u,v location as defined in travelVector)
        
        % Timer logic
        timeInd = timeInd + 1; %timing logic
        if fastTime == true
            tic;
        end
        if round(travelVector(frameInd,2)) ~= travelVector(frameInd,2) || round(travelVector(frameInd,1)) ~= travelVector(frameInd,1) %ie, if u0 or v0 is not an integer. That's the only way you can really 'supersample' uv, and even so, it's really just interpolation...
            % non integer value of u,v
            timeFlag = true;
            tic;
        end
        
        % Generate perspective image frame
        perspectiveImage = perspective(radArray,travelVector(frameInd,2),travelVector(frameInd,1),requestVector{pInd,3},sRange,tRange);
        
        if requestVector{pInd,6} == 1
            perspectiveImage = imadjust(perspectiveImage);
        end
        
        SS_ST = requestVector{pInd,3};
        
        switch requestVector{pInd,9} % captionFlag
            case 0 % no caption, direct output
                [expIm,expMap] = gray2ind(perspectiveImage,256);
                cMap = [requestVector{pInd,7} '(256)'];
                try
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                end
                frame = im2frame(expIm,colormap(cMap));
            case 1 % no caption with border
                try
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(perspectiveImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
                frame = getframe(1);
            case 2 % caption string only
                try
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(perspectiveImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
                frame = getframe(1);
            case 3 % caption string with position appended
                try
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(perspectiveImage,requestVector{pInd,9},[requestVector{pInd,10} ' --- ' '(' num2str(requestVector{pInd,1}) ',' num2str(requestVector{pInd,2}) ')'],requestVector{pInd,7},requestVector{pInd,8});
                frame = getframe(1);
            otherwise
                error('Incorrect setting of the caption flag in the requestVector input variable to the animateperspective function.');
        end
        
        switch requestVector{pInd,4}(1,1) % saveFlag
            case 0 % no saving
            case 1 % save GIF
                if exist([outputPath '\Animations'],'dir') ~= 7
                    mkdir([outputPath '\Animations']);
                end
                gifwrite(frame,requestVector{pInd,7},requestVector{pInd,4}(2,3),[outputPath '\Animations' '/' imageSpecificName '_' 'perspAnim' '_stSS' num2str(SS_ST) '_uvSS' num2str(requestVector{pInd,2}) '_cap' num2str(requestVector{pInd,9}) '.gif'],requestVector{pInd,4}(2,1),requestVector{pInd,4}(2,2),frameInd); %filename, delay, loop count, frame index
            case 2 % save AVI
                if exist([outputPath '\Animations'],'dir') ~= 7
                    mkdir([outputPath '\Animations']);
                end
                vidobj = aviwrite(frame,requestVector{pInd,7},requestVector{pInd,4}(2,3),vidobj,[outputPath '\Animations' '/' imageSpecificName '_' 'perspAnim' '_stSS' num2str(SS_ST) '_uvSS' num2str(requestVector{pInd,2}) '_cap' num2str(requestVector{pInd,9}) '.avi'],frameInd,requestVector{pInd,4}(2,1),requestVector{pInd,4}(2,2),size(travelVector,1));
            case 3 % save MP4
                if exist([outputPath '\Animations'],'dir') ~= 7
                    mkdir([outputPath '\Animations']);
                end
                vidobj=mp4write(frame,requestVector{pInd,7},vidobj,[outputPath '\Animations' '/' imageSpecificName '_' 'perspAnim' '_stSS' num2str(SS_ST) '_uvSS' num2str(requestVector{pInd,2}) '_cap' num2str(requestVector{pInd,9}) '.mp4'],frameInd,requestVector{pInd,4}(2,1),requestVector{pInd,4}(2,2),size(travelVector,1));
            otherwise
                error('Incorrect setting of the save flag in the requestVector input variable to the animateperspective function.');
        end
        
        switch requestVector{pInd,5} % displayFlag
            case 0 % no display (not really supported for animation export)
                try
                    close(cF);
                catch err
                    %figure already closed
                end
            case 1 % display with pauses (not recommended for animation export)
                if requestVector{pInd,9} == 1 || requestVector{pInd,9} == 2
                    pause; %image is already displayed
                else
                    if requestVector{pInd,9} == 0
                        try
                            set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                        catch
                            cF = figure;
                            set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                            set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                            set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                        end
                        displayimage(perspectiveImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
                    end
                    %image is already displayed
                    pause;
                end
            case 2 % display without pauses
                if requestVector{pInd,9} == 0
                    try
                        set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                    catch
                        cF = figure;
                        set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                        set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                        set(0, 'currentfigure', cF);  %make refocusing figure current figure (in case user clicked on another)
                    end
                    displayimage(perspectiveImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
                    drawnow;
                end
                % nothing required
            otherwise
                error('Incorrect setting of the display flag in the requestVector input variable to the animateperspective function.');
        end
        
        % Timer logic
        num=numel(num2str(timerVar));
        if timeFlag == true
            time=toc;
            timeVector(timeInd)=time;
            timeFlag = false;
        end
        if fastTime == true
            time=toc;
            timeVector(timeInd)=time;
        end
        timerVar=((timeAvg)/60)*(((size(travelVector,1))-frameInd));
        if timerVar >= 1
            timerVar=round(timerVar);
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g m',timerVar)
        else
            timerVar=round((timeAvg)*(((size(travelVector,1))-frameInd)));
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g s',timerVar)
        end
        if timeInd == timeRate
            timeAvg = max(timeVector);
            timeInd = 0;
        end
    end
    try
        %release focus
        set(cF,'WindowStyle','normal');
    catch
        %the figure couldn't be set to normal
    end
    fprintf('\n   Complete.\n');
end
fprintf('\nPerspective animation generation finished.\n');

end