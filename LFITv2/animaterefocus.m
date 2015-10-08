function animaterefocus(radArray,outputPath,imageSetName,requestVector,sRange,tRange)
%ANIMATEREFOCUS Generates a refocusing animation as defined by the request vector
%
%   requestVector:
%       {1} alpha values vector used in refocusing; [spaceType # steps; alphaStart alphaEnd; palindrome 0;]note: 1 = nominal focal plane
%               spaceType [0 for linear, 1 for log], # of steps [integer];
%               alphaStart [starting alpha value], alphaEnd [ending alpha value];
%               palindrome [0 for no loop mirroring, 1 to make the loop play backwards after reaching the end of the range];
%       {2} supersamping factor in (u,v) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {3} supersamping factor in (s,t) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {4} save flag is a vector: (typeFlag 0 0;parameters)
%               typeFlag:   0 for no saving, 1 for saving a GIF, 2 for saving a AVI, 3 for saving a jpg of the image
%               parameters: for a GIF, (delay time between frames, # of loops [inf for unlimited], dithering [0 = none; 1 = yes]); for an AVI, (quality [# between 0 and 100], fps [frames per second], compression [0 = none; 1 = MSVC or Motion JPEG, 2 = RLE or Lossless Motion JPEG 2000, 3 = Cinepak or Compressed Motion JPEG 2000; (1st = MATLAB older than 2010b, 2nd = newer)]); for an MP4, (quality,fpsVal, 0 (placeholder));
%       {5} display flag is 0 for no display, 1 to display each refocused image with a pause, 2 to display each image without a pause
%       {6} imadjust flag is 0 for quasi-raw output with contrast normalized on a per slice basis, 1 is to apply the imadjust function to the refocused image (increases contrast), 2 normalizes contrast on a per entire focal stack basis (more accurate)
%       {7} colormap is the colormap used in displaying the image, eg 'jet' or 'gray'
%       {8} background color is the background of the figure if the caption is enabled, eg [.8 .8 .8] or [1 1 1]
%       {9} caption flag is 0 for no caption, 1 for no caption w/border, 2 for caption string only, 3 for caption string + alpha value
%       {10} caption string is the string used in the caption for caption flag of 1 or 2.
%       {11} aperture flag is 0 for full aperture or 1 to enforce a circular aperture for microimages
%       {12} refocusType is 0 for additive, 1 for multiplicative, 2 for filtered
%       {13} filterInfo
%               noiseThreshold = threshold below which intensity will be disregarded as noise
%               filterThreshold = filter intensity threshold
%       {14} magTypeFlag is 0 for legacy algorithm, 1 for constant magnification (aka telecentric). See documentation for more info. 


fprintf('\nBeginning refocusing animation generation.\n');
for pInd = 1:size(requestVector,1) % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)
    
    magTypeFlag = requestVector{pInd,14}(1);% 0 = legacy, 1 = constant magnification
    
    fprintf('\nGenerating refocusing animation (%i of %i)...',pInd,size(requestVector,1));
    timerVar=0;
    switch requestVector{pInd,1}(1,1)
        case 0 % linear
            alphaRange = requestVector{pInd,1}(2,1):((requestVector{pInd,1}(2,2)-requestVector{pInd,1}(2,1))/(requestVector{pInd,1}(1,2)-1)):requestVector{pInd,1}(2,2);
        case 1 % log space
            alphaRange = logspace(log10(requestVector{pInd,1}(2,1)),log10(requestVector{pInd,1}(2,2)),requestVector{pInd,1}(1,2));
        otherwise
            error('Alpha range space improperly defined in requestVector input to animaterefocus function.');
    end
     %%%new
    switch magTypeFlag
        case 1
            %%% user inputs
            zmin = requestVector{pInd,14}(6);
            zmax = requestVector{pInd,14}(7);
            nVoxX = requestVector{pInd,14}(8);
            nVoxY = requestVector{pInd,14}(9);
            nVoxZ = requestVector{pInd,14}(10);
            f = requestVector{pInd,14}(11);%
            M = requestVector{pInd,14}(12);%
            %%%
            si = (1-M)*f;
            so = -si/M;
            z = linspace(zmin, zmax, nVoxZ);
            soPrime = so + z;
            siPrime = (1/f - 1./soPrime).^(-1);
            MPrime = siPrime./soPrime;
            alphaRange = siPrime/si;

            % Preallocate focal stack
            rawImageArray = zeros(nVoxY,nVoxX,length(alphaRange));
        case 0
            % Preallocate refocus stack
            refocusStack = zeros(size(radArray,4).*requestVector{pInd,3},size(radArray,3).*requestVector{pInd,3},size(alphaRange,2));
    end
    
    fprintf('\n   Time remaining:       ');
    for frameInd = 1:size(alphaRange,2)
        time=tic;
        
        refocusStack(:,:,frameInd) = refocus(radArray,alphaRange(frameInd),requestVector{pInd,2},requestVector{pInd,3},sRange,tRange,requestVector{pInd,11},requestVector{pInd,12},requestVector{pInd,13},requestVector{pInd,14});
        
        % Timer logic
        num=numel(num2str(timerVar));
        time=toc(time);
        timerVar=time/60*(size(alphaRange,2)-frameInd );
        if timerVar>=1
            timerVar=round(timerVar);
            for count=1:num+2
                fprintf('\b')
            end
            
            fprintf('%g m',timerVar)
        else
            timerVar=round(time*(size(alphaRange,2)-frameInd ));
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g s',timerVar)
        end
    end
    fprintf('\n   Complete.\n');
    
    if requestVector{pInd,6} == 2
        lims = [ min(refocusStack(:)) max(refocusStack(:)) ]; %set max intensity based on max intensity slice from entire FS; this keeps intensities correct relative to each slice
        refocusStack = ( refocusStack - lims(1) )/( lims(2) - lims(1) ); %normalize raw intensities by the MAX intensity of the entire focal stack.
    end
    
    
    if requestVector{pInd,1}(3,1) == 0 % no mirror
        frameVector = linspace(1,size(alphaRange,2),size(alphaRange,2));
    else
        frameVector = linspace(1,size(alphaRange,2),size(alphaRange,2));
        if numel(frameVector) > 1 % prevents error if only 1 frame
            frameVector = [frameVector(2:end-1) fliplr(frameVector)];
        end
    end
    
    fprintf('Saving video to file...');
    clear vidobj; vidobj = 0;
    
    try     close(cF);
    catch   % figure not yet opened
    end
    
    cF = figure;
    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)])
    
    frameLit = 0;
    for frameInd = frameVector % for each frame of an animation
        frameLit = frameLit + 1;
        
        refocusedImage = refocusStack(:,:,frameInd);
        if requestVector{pInd,6} ~= 2 % if NOT doing intensities on a per focal stack basis
            lims = [ min(refocusedImage(:)) max(refocusedImage(:)) ]; %refocusing movie does intensities on a slice-by-slice basis
            refocusedImage = ( refocusedImage - lims(1) )/( lims(2) - lims(1) );
            if requestVector{pInd,6} == 1
                refocusedImage = imadjust(refocusedImage);
            end
        end
        
        SS_ST = requestVector{pInd,3};
        
        try
            set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
        catch
            cF = figure;
            set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
            set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
            set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
        end
        
        if requestVector{pInd,9} == 0
            
            [expIm,expMap] = gray2ind(refocusedImage,256);
            cMap = [requestVector{pInd,7} '(256)'];
            frame = im2frame(expIm,colormap(cMap));
            
        else
            
            switch requestVector{pInd,9}
                case {1,2}
                    displayimage(refocusedImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});

                case 3 % caption string with position appended
                    caption = sprintf( '%s --- [alpha = %g]', requestVector{pInd,10}, alphaVal );
                    displayimage(refocusedImage,requestVector{pInd,9},caption,requestVector{pInd,7},requestVector{pInd,8});
                    
                otherwise
                    error('Incorrect setting of the caption flag in the requestVector input variable to the animaterefocus function.');
                    
            end%switch
            
            frame = getframe(1);
            
        end%if
        
        if requestVector{pInd,4}(1,1) > 0
            
            dout = fullfile(outputPath,'Animations');
            if ~exist(dout,'dir'), mkdir(dout); end
            
            fname = sprintf( '%s_refocusAnim_stSS%g_uvSS%g_ap%g', iamgeSetName, SS_ST, requestVector{pInd,2}, requestVector{pInd,11} );
            switch requestVector{pInd,4}(1,1)
                case 1 % save GIF
                    fout = fullfile(dout,[fname '.gif']);
                    gifwrite(frame,requestVector{pInd,7},requestVector{pInd,4}(2,3),fout,requestVector{pInd,4}(2,1),requestVector{pInd,4}(2,2),frameLit); %filename, delay, loop count, frame index

                case 2 % save AVI
                    fout = fullfile(dout,[fname '.avi']);
                    vidobj = aviwrite(frame,requestVector{pInd,7},requestVector{pInd,4}(2,3),vidobj,fout,frameLit,requestVector{pInd,4}(2,1),requestVector{pInd,4}(2,2),size(frameVector,2));

                case 3 % save MP4
                    fout = fullfile(dout,[fname '.mp4']);
                    vidobj=mp4write(frame,requestVector{pInd,7},vidobj,fout,frameLit,requestVector{pInd,4}(2,1),requestVector{pInd,4}(2,2),size(frameVector,2));

                otherwise
                    error('Incorrect setting of the save flag in the requestVector input variable to the animaterefocus function.');

            end%switch
            
        end%if
        
        
        if requestVector{pInd,5} == 0 % no display (not really supported for animation export)
            
            try     close(cF);
            catch   % figure not yet opened
            end
            
        else
            
            if requestVector{pInd,9} == 0
                try
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(refocusedImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
            end
            
            switch requestVector{pInd,5}
                case 1 % display with pauses (not recommended for animation export)
                    pause;
                    
                case 2 % display without pauses
                    drawnow;
                    
                otherwise
                    error('Incorrect setting of the display flag in the requestVector input variable to the animaterefocus function.');
                    
            end%switch
            
        end%if
        
    end%for
    
    try set(cF,'WindowStyle','normal'); % release focus
    catch % the figure couldn't be set to normal
    end
    
    fprintf('complete.\n');
    
end%for
fprintf('\nRefocusing animation generation finished.\n');

end%function
