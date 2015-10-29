function animateperspective(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%ANIMATEPERSPECTIVE Generates a perspective animation as defined by the request vector
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
% for pInd = 1:size(requestVector,1) % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)

%     fprintf('\nGenerating perspective animation (%i of %i)...',pInd,size(requestVector,1));
    timerVar=0; timeInd=0; 
    timeFlag = false; timeVector=[0]; timeAvg = .5; timeRate = ceil(q.uvFactor*1.5); % timing logic
    if q.uvFactor == 1
        fastTime = true;
    end
%     travelVector = gentravelvector(requestVector{pInd,1},floor(size(radArray,1)/2),floor(size(radArray,1)/2),requestVector{pInd,2},requestVector{pInd,11});
    clear vidobj; vidobj = 0;
    
    try     close(cF);
    catch   % figure already closed
    end
    
    cF = figure;
    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
    
    fprintf('\n   Time remaining:       ');
    
    nFrames = size(q.pUV,1);
    for frameInd = 1:nFrames
        
        % Sub-query for single (u,v) pair
        qi      = q;
        qi.pUV  = q.pUV(frameInd,:);
        
        % Timer logic
        timeInd = timeInd + 1; %timing logic
        if fastTime, tic; end
        if mod(qi.pUV(1),1) || mod(qi.pUV(2),1) %ie, if u0 or v0 is not an integer. That's the only way you can really 'supersample' uv, and even so, it's really just interpolation...
            % non integer value of u,v
            timeFlag = true;
            tic;
        end
        
        % Generate perspective image frame
        perspectiveImage = perspective(qi,radArray,sRange,tRange);
        
        if strcmpi( q.contrast, 'imadjust' )
            perspectiveImage = imadjust(perspectiveImage);
        end
        
        try
            set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
        catch
            cF = figure;
            set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
            set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
            set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
        end
        
        if q.title % Title image?
            
            switch q.title
                case 'caption',     caption = q.caption;
                case 'annotation',  caption = sprintf( '(%g,%g)', qi.pUV(1), qi.pUV(2) );
                case 'both',        caption = sprintf( '%s --- (%g,%g)', q.caption, qi.pUV(1), qi.pUV(2) );
                    
            end%switch
            displayimage( perspectiveImage, caption, q.colormap, q.background );
            
            frame = getframe(1);
            
        else
            
            expIm   = gray2ind(perspectiveImage,256);
            cMap    = [q.colormap '(256)'];
            frame   = im2frame(expIm,colormap(cMap));
            
        end%if
        
        if q.saveas
            
            dout = fullfile(outputPath,'Animations');
            if ~exist(dout,'dir'), mkdir(dout); end

            fname = sprintf( '%s_perspAnim_stSS%g_uvSS%g_cap%g', imageSpecificName, q.stFactor, strcmpi(q.mask,'circ') );
            switch q.saveas
                case 'gif'
                    fout = fullfile(dout,[fname '.gif']);
                    gifwrite(frame,q.colormap,fout,1/q.framerate,frameInd); % filename, delay, frame index

                case 'avi'
                    fout = fullfile(dout,[fname '.avi']);
                    vidobj = aviwrite(frame,q.colormap,q.codec,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);
 
                case 'mp4'
                    fout = fullfile(dout,[fname '.mp4']);
                    vidobj = mp4write(frame,q.colormap,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);
 
            end%switch
            
        end%if
        
        if q.display
            
            if q.title
                % Image already displayed, nothing to do
            else
                try
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(perspectiveImage,'',q.colormap,q.background);
            end
            
            switch q.display
                case 'slow',    pause;
                case 'fast',    drawnow;
            end%switch
            
        else
            
            try     close(cF);
            catch   % figure already closed
            end
            
        end%if
        
        % Timer logic
        num=numel(num2str(timerVar));
        if timeFlag
            time=toc;
            timeVector(timeInd)=time;
            timeFlag = false;
        end
        if fastTime
            time=toc;
            timeVector(timeInd)=time;
        end
        timerVar=(timeAvg/60)*(nFrames-frameInd);
        if timerVar >= 1
            timerVar=round(timerVar);
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g m',timerVar)
        else
            timerVar=round( timeAvg*(nFrames-frameInd) );
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g s',timerVar)
        end
        if timeInd == timeRate
            timeAvg = max(timeVector);
            timeInd = 0;
        end
        
    end%for
    
    try     set(cF,'WindowStyle','normal'); % release focus
    catch   % the figure couldn't be set to normal
    end
    
    fprintf('\n   Complete.\n');
    
% end%for
fprintf('\nPerspective animation generation finished.\n');

end%function
