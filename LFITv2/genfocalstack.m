function [focalStack] = genfocalstack(radArray,outputPath,imageSpecificName,requestVector,sRange,tRange)
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
for pInd = 1:size(requestVector,1) % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)
    
    magTypeFlag = requestVector{pInd,14}(1); % 0 = legacy, 1 = constant magnification
    
    fprintf('\nGenerating refocused slices set (%i of %i)...',pInd,size(requestVector,1));
    switch requestVector{pInd,1}(1,1)
        case 0 % linear
            alphaRange = requestVector{pInd,1}(2,1):((requestVector{pInd,1}(2,2)-requestVector{pInd,1}(2,1))/(requestVector{pInd,1}(1,2)-1)):requestVector{pInd,1}(2,2);
        case 1 % log space
            alphaRange = logspace(log10(requestVector{pInd,1}(2,1)),log10(requestVector{pInd,1}(2,2)),requestVector{pInd,1}(1,2));
        otherwise
            error('Alpha range space improperly defined in requestVector input to genfocalstack function.');
    end
    
    try     close(focFig);
    catch   % figure not opened
    end
    
    fprintf('\n   Time remaining:       ');
    
    focFig = figure;
    set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(focFig,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
    
    %%%new
    switch magTypeFlag
        case 1
            %%% user inputs
            zmin    = requestVector{pInd,14}(6);
            zmax    = requestVector{pInd,14}(7);
            nVoxX   = requestVector{pInd,14}(8);
            nVoxY   = requestVector{pInd,14}(9);
            nVoxZ   = requestVector{pInd,14}(10);
            f       = requestVector{pInd,14}(11);
            M       = requestVector{pInd,14}(12);
            %%%
            si      = (1-M)*f;
            so      = -si/M;
            z       = linspace(zmin, zmax, nVoxZ);
            soPrime = so + z;
            siPrime = (1/f - 1./soPrime).^(-1);
            MPrime  = siPrime./soPrime;
            alphaRange = siPrime/si;

            % Preallocate focal stack
            rawImageArray = zeros(nVoxY,nVoxX,length(alphaRange));
        case 0
            rawImageArray = zeros(size(radArray,4).*requestVector{pInd,3},size(radArray,3).*requestVector{pInd,3},size(alphaRange,2));
    end
    %%%
   
    for frameInd = 1:size(alphaRange,2) % for each frame of an animation
        time=tic;
        rawImageArray(:,:,frameInd) = refocus(radArray,alphaRange(frameInd),requestVector{pInd,2},requestVector{pInd,3},sRange,tRange,requestVector{pInd,11},requestVector{pInd,12},requestVector{pInd,13},requestVector{pInd,14});
        
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
    
    lims = [ min(rawImageArray(:)) max(rawImageArray(:)) ]; %set max intensity based on max intensity slice from entire FS; this keeps intensities correct relative to each slice
    
    focalStack = ( rawImageArray - lims(1) )/( lims(2) - lims(1) ); %normalize raw intensities by the MAX intensity of the entire focal stack.
    
    if requestVector{pInd,4} ~=0 % if we're going to save images, then apply captions, display, and/or save, otherwise skip this loop.
        
        for frameInd = 1:size(alphaRange,2) % for each frame of an animation
            
            refocusedImage = rawImageArray(:,:,frameInd);
            if requestVector{pInd,6} == 1
                refocusedImage = ( refocusedImage - lims(1) )/( lims(2) - lims(1) );
                refocusedImage = imadjust(refocusedImage);
            else
                refocusedImage = ( refocusedImage - lims(1) )/( lims(2) - lims(1) );
            end
            
            alphaVal = alphaRange(frameInd);
            SS_UV = requestVector{pInd,2};
            SS_ST = requestVector{pInd,3};
            
            if requestVector{pInd,9} == 0
                
                if requestVector{pInd,4} == 4 || requestVector{pInd,4} == 5
                    expImage16 = gray2ind(refocusedImage,65536); % for 16bit output
                end
                expImage = gray2ind(refocusedImage,256); %allows for colormap
                
            else
            
                switch requestVector{pInd,9} % caption flag
                    case 1 % caption string only
                        set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                        displayimage(expImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});

                    case 2 % caption string with position appended
                        caption = sprintf( '%s --- [alpha = %g]', requestVector{pInd,10}, alphaVal );
                        displayimage(expImage,requestVector{pInd,9},caption,requestVector{pInd,7},requestVector{pInd,8});                      
                        
                    otherwise
                        error('Incorrect setting of the caption flag in the requestVector input variable to the genfocalstack function.');
                        
                end%switch
                
                try
                    set(0, 'currentfigure', focFig);  %make refocusing figure current figure (in case user clicked on another)
                catch
                    focFig = figure;
                    set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(focFig,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                    set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                end
                
                frame = getframe(1);
                expImage = frame2im(frame);
                
            end%if
            
            if requestVector{pInd,4} > 0
                
                dout = fullfile(outputPath,'Focal Stack',imageSpecificName);
                if ~exist(dout,'dir'), mkdir(dout); end
                
                fname = sprintf( '_FS_alp%4.5f_stSS%g_uvSS%g', alphaVal, SS_ST, SS_UV );
                switch requestVector{pInd,4} % save flag
                    case 1 % save bmp
                        fout = fullfile(dout,[fname '.bmp']);
                        imwrite(expImage,colormap([requestVector{pInd,7} '(256)']),fout);

                    case 2 % save png
                        fout = fullfile(dout,[fname '.png']);
                        imwrite(expImage,colormap([requestVector{pInd,7} '(256)']),fout);

                    case 3 % save jpg
                        fout = fullfile(dout,[fname '.jpg']);
                        imwrite(expImage,colormap([requestVector{pInd,7} '(256)']),fout,'jpg','Quality',90);

                    case 4 % save 16-bit png
                        if requestVector{pInd,9} == 0 % write colormap with file if no caption; otherwise, it is implied
                            if strcmp(requestVector{pInd,7},'gray') == 1
                                imExp = uint16(refocusedImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                            else
                                imExp = ind2rgb(expImage16,colormap([requestVector{pInd,7} '(65536)']));
                            end
                            fout = fullfile(dout,[fname '_16bit.png']);
                            imwrite(imExp,fout);
                        else
                            fprintf('\n');
                            warning('16-bit PNG export is not supported when captions are enabled. Image not exported.');
                        end
                        
                    case 5 % save 16-bit TIFF
                        if requestVector{pInd,9} == 0 % write colormap with file if no caption; otherwise, it is implied
                            if strcmp(requestVector{pInd,7},'gray') == 1
                                imExp = uint16(refocusedImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                            else
                                imExp = ind2rgb(expImage16,colormap([requestVector{pInd,7} '(65536)']));
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
            
            if requestVector{pInd,5} == 0 % no display
                
                try     close(focFig);
                catch   % figure already closed
                end
                
            else
                
                if requestVector{pInd,9} == 0
                    try
                        set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                    catch
                        focFig = figure;
                        set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                        set(focFig,'position', [0 0 requestVector{pInd,3}*size(radArray,4) requestVector{pInd,3}*size(radArray,3)]);
                        set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                    end
                    displayimage(expImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
                end
                
                switch requestVector{pInd,5} % display flag
                    case 1 % display with pauses
                        pause;
                        
                    case 2 % display without pauses
                        drawnow;
                        
                    otherwise
                        error('Incorrect setting of the display flag in the requestVector input variable to the genfocalstack function.');
                        
                end%switch
                
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