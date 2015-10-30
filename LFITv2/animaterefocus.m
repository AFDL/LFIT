function animaterefocus(q,radArray,sRange,tRange,outputPath,imageSetName)
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
% for pInd = 1:size(requestVector,1) % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)
    
%     fprintf('\nGenerating refocusing animation (%i of %i)...',pInd,size(requestVector,1));
    timerVar=0;
    
    switch q.fZoom
        case 'legacy'
            alphaRange = q.fAlpha;
            
            % Preallocate focal stack
            refocusStack = zeros(size(radArray,4)*q.stFactor,size(radArray,3)*q.stFactor,length(alphaRange),'single');

        case 'telecentric'
            si      = ( 1 - q.fMag )*q.fLength;
            so      = -si/q.fMag;
            soPrime = so + q.fPlane;
            siPrime = (1/q.fLength - 1./soPrime).^(-1);
            
            alphaRange = siPrime/si;

            % Preallocate focal stack
            refocusStack = zeros(length(q.fGridY),length(q.fGridX),length(alphaRange),'single');

    end%switch
    
    fprintf('\n   Time remaining:       ');
    
    nFrames = length(alphaRange);
    for frameInd = 1:nFrames
        time=tic;
        
        % Sub-query at single alpha value
        qi          = q;
        qi.fAlpha   = alphaRange(frameInd);
        if strcmpi(q.fZoom,'telecentric'), qi.fPlane = q.fPlane(frameInd); end
        
        refocusStack(:,:,frameInd) = refocus(qi,radArray,sRange,tRange);
        
        % Timer logic
        num=numel(num2str(timerVar));
        time=toc(time);
        timerVar=(time/60)*(nFrames-frameInd);
        if timerVar>=1
            timerVar=round(timerVar);
            for count=1:num+2
                fprintf('\b')
            end
            
            fprintf('%g m',timerVar)
        else
            timerVar=round( time*(nFrames-frameInd) );
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g s',timerVar)
        end
    end
    fprintf('\n   Complete.\n');
    
    % Normalize raw intensities by the MAX intensity of the entire focal stack (regardless of contrast choice)
    refocusStack = ( refocusStack  - min(refocusStack(:)) )/( max(refocusStack(:)) - min(refocusStack(:)) );
    
    fprintf('Saving video to file...');
    clear vidobj; vidobj = 0;
    
    try     close(cF);
    catch   % figure not yet opened
    end
    
    cF = figure;
    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)])
    
    for frameInd = 1:nFrames % for each frame of an animation
        
        refocusedImage = refocusStack(:,:,frameInd);
        switch q.contrast
            case 'simple',      refocusedImage = ( refocusedImage - min(refocusedImage(:)) )/( max(refocusedImage(:)) - min(refocusedImage(:)) );
            case 'imadjust',    refocusedImage = imadjust( refocusedImage );
            case 'stack',       % Nothing to do
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
                case 'annotation',  caption = sprintf( '[alpha = %g]', qi.fALpha );
                case 'both',        caption = sprintf( '%s --- [alpha = %g]', q.caption, qi.fAlpha );
            end%switch
            displayimage( refocusedImage, caption, q.colormap, q.background );
            
            frame = getframe(1);
            
        else
            
            expIm   = gray2ind(refocusedImage,256);
            cMap    = [q.colormap '(256)'];
            frame   = im2frame(expIm,colormap(cMap));
            
        end%if
        
        if q.saveas
            
            dout = fullfile(outputPath,'Animations');
            if ~exist(dout,'dir'), mkdir(dout); end
            
            fname = sprintf( '%s_refocusAnim_stSS%g_uvSS%g_ap%g', imageSetName, q.stFactor, q.uvFactor, strcmpi(q.mask,'circ') );
            switch q.saveas
                case 'gif'
                    fout = fullfile(dout,[fname '.gif']);
                    gifwrite(frame,q.colormap,fout,1/q.framerate,frameInd); % filename, delay, frame index

                case 'avi'
                    fout = fullfile(dout,[fname '.avi']);
                    vidobj = aviwrite(frame,q.colormap,q.codec,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);

                case 'mp4'
                    fout = fullfile(dout,[fname '.mp4']);
                    vidobj=mp4write(frame,q.colormap,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);

            end%switch
            
        end%if
            
        if q.display
            
            if q.title
                % Already displayed, nothing to do
            else
                try
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(refocusedImage,'',q.colormap,q.background);
            end
            
            switch q.display
                case 'slow',    pause;
                case 'fast',    drawnow;
            end%switch
            
        else
            
            try     close(cF);
            catch   % figure not yet opened
            end
            
        end%if
        
    end%for
    
    try set(cF,'WindowStyle','normal'); % release focus
    catch % the figure couldn't be set to normal
    end
    
    fprintf('complete.\n');
    
% end%for
fprintf('\nRefocusing animation generation finished.\n');

end%function
