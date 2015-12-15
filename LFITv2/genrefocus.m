function refocusedImageStack = genrefocus(q,radArray,sRange,tRange,outputPath,imageSpecificName,imageIndex,numImages,refocusedImageStack)
%GENREFOCUS Generates a series of refocused images as defined by the request vector


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

    nPlanes = size(refocusedImageStack,4);
    for depthInd = 1:nPlanes % for each different raw plenoptic particle image at different depths
        
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
            
            refocusedImage = ( refocusedImage - lims(1) )/( lims(2) - lims(1) );
            if strcmpi(q.contrast,'imadjust'), refocusedImage = imadjust(refocusedImage); end
            
            switch q.fZoom
                case 'legacy',      key = 'alpha';  val = q.fAlpha(depthInd);
                case 'telecentric', key = 'plane';  val = q.fPlane(depthInd);
            end
            
            SS_UV = q.uvFactor;
            SS_ST = q.stFactor;
                
            if q.title % Title image?
                
                try     close(cF);
                catch   % figure already closed
                end
                
                cF = figure;
                switch q.title
                    case 'caption',     caption = q.caption;
                    case 'annotation',  caption = sprintf( '%s = %g', q.caption, key,val );
                    case 'both',        caption = sprintf( '%s --- [%s = %g]', q.caption, key,val );
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
                    fname = sprintf( '_z%4.5f', val );
                else
                    fname = sprintf( '_alp%4.5f_stSS%g_uvSS%g', val, SS_ST, SS_UV ); 
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
                            imwrite(imExp,fout,'tif','compression','lzw');
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
