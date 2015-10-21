function [focalStack] = genfocalstack(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%GENFOCALSTACK Generates a focal stack of refocused images as defined by the request vector
%
%   requestVector:
%       {1} alpha values vector used in refocusing; [spaceType # steps; alphaStart alphaEnd;] note: 1 = nominal focal plane
%               spaceType [0 for linear, 1 for log], # of steps [integer];
%               alphaStart [starting alpha value], alphaEnd [ending alpha value];
%       {2} supersamping factor in (u,v) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {3} supersamping factor in (s,t) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {4} save flag is 0 for no saving, 1 for saving a bmp, 2 for saving a png, 3 for saving a jpg of the image, 4 for a 16-bit PNG, 5 for a 16-bit TIFF
%       {5} display flag is 0 for no display, 1 to display each refocused image with a pause, 2 to display each image without a pause
%       {6} imadjust flag is 0 for raw output, 1 is to apply the imadjust function to the refocused image (increases contrast)
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


num=0;
timerVar = 0;
fprintf('\nBeginning focal stack generation.\n');

nFormats = 0;   % FIX ME
for fIdx = 1:nFormats % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)
    
    fprintf('\nGenerating refocused slices set (%i of %i)...',fIdx,nFormats);
    switch requestVector{fIdx,1}(1,1)
        case 0 % linear
            alphaRange = requestVector{fIdx,1}(2,1):((requestVector{fIdx,1}(2,2)-requestVector{fIdx,1}(2,1))/(requestVector{fIdx,1}(1,2)-1)):requestVector{fIdx,1}(2,2);
        case 1 % log space
            alphaRange = logspace(log10(requestVector{fIdx,1}(2,1)),log10(requestVector{fIdx,1}(2,2)),requestVector{fIdx,1}(1,2));
        otherwise
            error('Alpha range space improperly defined in requestVector input to genfocalstack function.');
    end
    
    try     close(focFig);
    catch   % figure not opened
    end
    
    fprintf('\n   Time remaining:       ');
    
    focFig = figure;
    set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(focFig,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
    
    %%%new
    switch q.fZoom
        case 'legacy'
            rawImageArray = zeros(size(radArray,4)*q.stFactor,size(radArray,3)*q.stFactor,size(alphaRange,2));
            
        case 'telecentric'
            si      = ( 1 - q.fMag )*q.fLength;
            so      = -si/q.fMag;
            soPrime = so + q.fPlane;
            siPrime = (1/f - 1./soPrime).^(-1);
            
            alphaRange = siPrime/si;

            % Preallocate focal stack
            rawImageArray = zeros([ size(q.fGridX) length(alphaRange) ]);
            
    end%switch
    %%%
   
    for frameIdx = 1:size(alphaRange,2) % for each frame of an animation
        
        time=tic;
        
        qi          = q;
        qi.fAlpha   = alphaRange(frameIdx);
        
        rawImageArray(:,:,frameIdx) = refocus(q,radArray,sRange,tRange);
        
        % Timer logic
        num=numel(num2str(timerVar));
        time=toc(time);
        timerVar=time/60*(size(alphaRange,2)-frameIdx );
        if timerVar>=1
            timerVar=round(timerVar);
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g m',timerVar)
        else
            timerVar=round(time*(size(alphaRange,2)-frameIdx ));
            for count=1:num+2
                fprintf('\b')
            end
            fprintf('%g s',timerVar)
        end
        
    end
    
    lims = [ min(rawImageArray(:)) max(rawImageArray(:)) ]; % set max intensity based on max intensity slice from entire FS; this keeps intensities correct relative to each slice
    
    focalStack = ( rawImageArray - lims(1) )/( lims(2) - lims(1) ); % normalize raw intensities by the MAX intensity of the entire focal stack.
    
    if requestVector{fIdx,4} ~=0 % if we're going to save images, then apply captions, display, and/or save, otherwise skip this loop.
        
        for frameIdx = 1:size(alphaRange,2) % for each frame of an animation
            
            refocusedImage = rawImageArray(:,:,frameIdx);
            switch q.contrast
                case 'simple',      refocusedImage = ( refocusedImage - lims(1) )/( lims(2) - lims(1) );
                case 'imadjust',    refocusedImage = imadjust(refocusedImage);
            end
            
            alphaVal = alphaRange(frameIdx);
            
            SS_UV = q.uvFactor;
            SS_ST = q.stFactor;
            
               
            if q.title % Image title?
            
                switch q.title
                    case 'caption',     caption = q.caption{fIdx};
                    case 'annotation',  caption = sprintf( '[alpha = %g]', alphaVal );
                    case 'both',        caption = sprintf( '%s --- [alpha = %g]', q.caption{fIdx}, alphaVal );
                    otherwise,          error('Incorrect setting of the caption flag in the requestVector input variable to the genfocalstack function.'); 
                end
                displayimage(expImage,caption,q.colormap,q.background);  
                
                try
                    set(0, 'currentfigure', focFig);  %make refocusing figure current figure (in case user clicked on another)
                catch
                    focFig = figure;
                    set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(focFig,'position', [0 0 requestVector{fIdx,3}*size(radArray,4) requestVector{fIdx,3}*size(radArray,3)]);
                    set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                end
                
                frame = getframe(1);
                expImage = frame2im(frame);
                
            else
                
                if any(strcmpi( q.saveas, {'png16','tif16'} ))
                    expImage16 = gray2ind(refocusedImage,65536); % for 16-bit output
                end
                expImage = gray2ind(refocusedImage,256); % allows for colormap
                
            end%if
            
            if q.saveas % Save image?
                
                dout = fullfile(outputPath,'Focal Stack',imageSpecificName);
                if ~exist(dout,'dir'), mkdir(dout); end
                
                fname = sprintf( '_FS_alp%4.5f_stSS%g_uvSS%g', alphaVal, SS_ST, SS_UV );
                switch q.saveas
                    case 'bmp'
                        fout = fullfile(dout,[fname '.bmp']);
                        imwrite(expImage,colormap([q.colormap '(256)']),fout);

                    case 'png'
                        fout = fullfile(dout,[fname '.png']);
                        imwrite(expImage,colormap([q.colormap '(256)']),fout);

                    case 'jpg'
                        fout = fullfile(dout,[fname '.jpg']);
                        imwrite(expImage,colormap([q.colormap '(256)']),fout,'jpg','Quality',90);

                    case 'png16'
                        if requestVector{fIdx,9} == 0 % write colormap with file if no caption; otherwise, it is implied
                            if strcmpi(q.colormap,'gray')
                                imExp = uint16(refocusedImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                            else
                                imExp = ind2rgb(expImage16,colormap([q.colormap '(65536)']));
                            end
                            fout = fullfile(dout,[fname '_16bit.png']);
                            imwrite(imExp,fout);
                        else
                            fprintf('\n');
                            warning('16-bit PNG export is not supported when captions are enabled. Image not exported.');
                        end
                        
                    case 'tif16'
                        if requestVector{fIdx,9} == 0 % write colormap with file if no caption; otherwise, it is implied
                            if strcmpi(q.colormap,'gray')
                                imExp = uint16(refocusedImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                            else
                                imExp = ind2rgb(expImage16,colormap([q.colormap '(65536)']));
                            end
                            fout = fullfile(dout,[fname '_16bit.tif']);
                            imwrite(imExp,fout,'tif');
                        else
                            fprintf('\n');
                            warning('16-bit TIFF export is not supported when captions are enabled. Image not exported.');
                        end
                        
                    otherwise
                        error('Incorrect setting of the save flag in the requestVector input variable to the genfocalstack function.');
                        
                end%switch
                
            end%if
            
            if q.display % Display image?
                
                if q.title
                    % Image already displayed, nothing to do
                else
                    try
                        set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                    catch
                        focFig = figure;
                        set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                        set(focFig,'position', [0 0 requestVector{fIdx,3}*size(radArray,4) requestVector{fIdx,3}*size(radArray,3)]);
                        set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                    end
                    displayimage(expImage,'',q.colormap,q.background);
                end
                
                switch q.display
                    case 'slow',     pause;
                    case 'fast',     drawnow;
                    otherwise,       error('Incorrect setting of the display flag in the requestVector input variable to the genfocalstack function.');  
                end
                
            else
                
                try     close(focFig);
                catch   % figure already closed
                end
                
            end%if
            
        end%for
        
    end%if
    
    try     set(focFig,'WindowStyle','normal'); % release focus
    catch   % the figure couldn't be set to normal
    end
    
    fprintf('\n   Complete.\n');
    
end%for
fprintf('\nFocal stack generation finished.\n');

end%function