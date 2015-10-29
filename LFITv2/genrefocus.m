function refocusedImageStack = genrefocus(q,radArray,sRange,tRange,outputPath,imageSpecificName,imageIndex,numImages,refocusedImageStack)
%GENREFOCUS Generates a series of refocused images as defined by the request vector
%
%   requestVector = [alpha value, supersampling factor in (u,v), supersampling factor in (s,t), save flag, display flag, imadjust flag, colormap, background color, caption flag, caption string]
%       {1} alpha value used in refocusing; a=1 nominal focal plane; a<1 focuses further away; a>1 focuses closer to the camera
%       {2} supersampling factor in (u,v) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {3} supersampling factor in (s,t) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {4} save flag is 0 for no saving, 1 for saving a bmp, 2 for saving a png, 3 for saving a jpg of the image, 4 for a 16-bit PNG, 5 for a 16-bit TIFF
%       {5} display flag is 0 for no display, 1 to display each refocused image with a pause, 2 to display each image without a pause
%       {6} contrast flag is 0 for basic contrast stretching, 1 is to apply the imadjust function
%       {7} colormap is the colormap used in displaying the image, eg 'jet' or 'gray'
%       {8} background color is the background of the figure if the caption is enabled, eg [.8 .8 .8] or [1 1 1]
%       {9} caption flag is 0 for no caption, 1 for caption string only, 2 for caption string + alpha value
%       {10} caption string is the string used in the caption for caption flag of 1 or 2.
%       {11} aperture flag is 0 for full aperture or 1 to enforce a circular aperture for microimages
%       {12} directory flag is 0 to save refocused images on a per-image basis or 1 to save on a per-alpha basis (must be constant across requestVector lines)
%       {13} refocusType is 0 for additive, 1 for multiplicative, 2 for filtered
%       {14} filterInfo
%               noiseThreshold = threshold below which intensity will be disregarded as noise
%               filterThreshold = filter intensity threshold
%       {15} magTypeFlag is 0 for legacy algorithm, 1 for constant magnification (aka telecentric). See documentation for more info. 


% Check to see if saving on a per-image basis (normal) or per-alpha basis (some types of PSF experiments)
if strcmpi( q.grouping, 'image' )
    % start refocusedImageStack over from scratch
    imageIndex = 1;
end

% Build up the refocused image stack without saving until the whole array is built
if imageIndex == 1
    clear refocusedImageStack
    refocusedImageStack = genrefocusraw(q,radArray,sRange,tRange);
else
    refocusedImageStack(:,:,:,imageIndex) = genrefocusraw(q,radArray,sRange,tRange);
end

% if the last image in the folder is processed or if processing on a per image basis (typical)
if imageIndex == numImages || strcmpi( q.grouping, 'image' )
    for depthInd = 1:size(refocusedImageStack,4) % for each different raw plenoptic particle image at different depths
        
        if strcmpi( q.grouping, 'image' ) % as in typical plenoptic processing
            subdir = imageSpecificName;
            lims=[min(min(min(refocusedImageStack(:,:,:,imageIndex)))) max(max(max(refocusedImageStack(:,:,:,imageIndex))))]; %set max intensity based on a per-image basis
        end
        
        for fIdx = 1:size(refocusedImageStack,3)
            
            refocusedImage = refocusedImageStack(:,:,fIdx,depthInd);
            
            if strcmpi( q.grouping, 'alpha' )
                subdir = num2str(alphaList(fIdx),'%4.5f');
                lims=[min(min(min(refocusedImageStack(:,:,fIdx,:)))) max(max(max(refocusedImageStack(:,:,fIdx,:))))]; %set max intensity based on max intensity slice from entire FS at a given alpha; this keeps intensities correct relative to each slice
            end
            
            switch q.contrast
                case 'simple',      refocusedImage = ( refocusedImage - lims(1) )/( lims(2) - lims(1) );
                case 'imadjust',    refocusedImage = imadjust(refocusedImage);
            end
            
            SS_UV = q.uvFactor;
            SS_ST = q.stFactor;
                
            if q.title % Title image?
                
                try     close(cF);
                catch   % figure already closed
                end
                
                cF = figure;
                switch q.title % caption flag
                    case 'caption',     caption = q.caption;
                    case 'annotation',  caption = sprintf( 'alpha = %g', q.caption, q.fAlpha(fIdx) );
                    case 'both',        caption = sprintf( '%s --- [alpha = %g]', q.caption, q.fAlpha(fIdx) );
                end
                displayimage(refocusedImage,caption,q.colormap,q.background);
                
                frame = getframe(1);
                expImage = frame2im(frame);
                
            else % no title
                
                if any(strcmpi( q.saveas, {'png16','tif16'} ))
                    expImage16 = gray2ind(refocusedImage,65536); % for 16-bit output
                end
                expImage = gray2ind(refocusedImage,256); % allows for colormap
                
            end%if
            
            if q.saveas % Save image?
                
                dout = fullfile(outputPath,'Refocused',subdir);
                if ~exist(dout,'dir'), mkdir(dout); end
                
                if strcmpi( q.fZoom, 'telecentric' ) %telecentric flag
                    fname = sprintf( '_alp%4.5f_stSS%g_uvSS%g', q.fAlpha(fIdx), SS_ST, SS_UV );
                else
                    fname = sprintf( '_z%4.5f', q.fPlane(fIdx) );
                end
                
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
                        if ~q.title % write colormap with file if no caption; otherwise, it is implied
                            if strcmp(q.colormap,'gray')
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
                        if ~q.title % write colormap with file if no caption; otherwise, it is implied
                            if strcmp(q.colormap,'gray')
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
                    cF = figure;
                    displayimage(expImage,'',q.colormap,q.background);
                end
                    
                switch q.display % How fast?
                    case 'slow',   pause;
                    case 'fast',   drawnow;
                end
                
            else
                 
                try     close(cF);
                catch   % figure already closed
                end
                
            end%if
            
        end%for
        
    end%for
    
end%if