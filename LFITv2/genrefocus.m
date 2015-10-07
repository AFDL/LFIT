function refocusedImageStack = genrefocus(radArray,outputPath,imageSpecificName,requestVector,sRange,tRange,imageIndex,numImages,refocusedImageStack)
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
directoryFlag = requestVector{1,12}; %it only really matters what the first directory flag is; they all must be the same, so we just take the first.
if directoryFlag == 0
    % start refocusedImageStack over from scratch
    imageIndex = 1;
end

% Build up the refocused image stack without saving until the whole array is built
if imageIndex == 1
    clear refocusedImageStack
    refocusedImageStack = genrefocusraw(radArray,requestVector,sRange,tRange);
else
    refocusedImageStack(:,:,:,imageIndex) = genrefocusraw(radArray,requestVector,sRange,tRange);
end

% if the last image in the folder is processed or if processing on a per image basis (typical)
if imageIndex == numImages || directoryFlag == 0
    for i = 1:size(requestVector(:,1),1)
        alphaList(i,1) = requestVector{i,1};
    end
    for depthInd = 1:size(refocusedImageStack,4) % for each different raw plenoptic particle image at different depths
        if directoryFlag == 0 %as in typical plenoptic processing
            subdir = imageSpecificName;
            lims=[min(min(min(refocusedImageStack(:,:,:,imageIndex)))) max(max(max(refocusedImageStack(:,:,:,imageIndex))))]; %set max intensity based on a per-image basis
        end
        for alphaInd = 1:size(refocusedImageStack,3)
            refocusedImage = refocusedImageStack(:,:,alphaInd,depthInd);
            if directoryFlag == 1
                subdir = num2str(alphaList(alphaInd),'%4.5f');
                lims=[min(min(min(refocusedImageStack(:,:,alphaInd,:)))) max(max(max(refocusedImageStack(:,:,alphaInd,:))))]; %set max intensity based on max intensity slice from entire FS at a given alpha; this keeps intensities correct relative to each slice
            end
            if requestVector{alphaInd,6} == 1
                refocusedImage=(refocusedImage-lims(1))./(lims(2) - lims(1));
                refocusedImage = imadjust(refocusedImage);
            else
                refocusedImage=(refocusedImage-lims(1))./(lims(2) - lims(1));
            end
            
            alphaVal = alphaList(alphaInd);
            
            SS_UV = requestVector{alphaInd,2};
            SS_ST = requestVector{alphaInd,3};
            
            if requestVector{alphaInd,9} == 0 % no caption
                
                if requestVector{alphaInd,4} == 4 || requestVector{alphaInd,4} == 5
                    expImage16 = gray2ind(refocusedImage,65536); % for 16bit output
                end
                expImage = gray2ind(refocusedImage,256); %allows for colormap
                
            else
                
                try     close(cF);
                catch   % figure already closed
                end
                
                cF = figure;
                switch requestVector{alphaInd,9} % caption flag
                    case 1 % caption string only
                        displayimage(refocusedImage,requestVector{alphaInd,9},requestVector{alphaInd,10},requestVector{alphaInd,7},requestVector{alphaInd,8});
                        
                        
                    case 2 % caption string with position appended
                        caption = sprintf( '%s --- [alpha = %g]', requestVector{alphaInd,10}, alphaVal );
                        displayimage(refocusedImage,requestVector{alphaInd,9},caption,requestVector{alphaInd,7},requestVector{alphaInd,8});
                        
                    otherwise
                        error('Incorrect setting of the caption flag in the requestVector input variable to the genfocalstack function.');
                        
                end%switch
                
                frame = getframe(1);
                expImage = frame2im(frame);
                
            end%if
            
            if requestVector{alphaInd,4}>0
                
                dout = fullfile(outputPath,'Refocused',subdir);
                if ~exist(dout,'dir'), mkdir(dout); end
                
                if requestVector{alphaInd,15}(1) == 0 %telecentric flag
                    fname = sprintf( '_alp%4.5f_stSS%g_uvSS%g', alphaList(alphaInd), SS_ST, SS_UV );
                else
                    fname = sprintf( '_z%4.5f', requestVector{alphaInd,15}(13) );
                end
                
                switch requestVector{alphaInd,4} % save flag
                    case 1 % save bmp
                        fout = fullfile(dout,[fname '.bmp']);
                        imwrite(expImage,colormap([requestVector{alphaInd,7} '(256)']),fout);

                    case 2 % save png
                        fout = fullfile(dout,[fname '.png']);
                        imwrite(expImage,colormap([requestVector{alphaInd,7} '(256)']),fout);

                    case 3 % save jpg
                        fout = fullfile(dout,[fname '.jpg']);
                        imwrite(expImage,colormap([requestVector{alphaInd,7} '(256)']),fout,'jpg','Quality',90);

                    case 4 % save 16-bit png
                        if requestVector{alphaInd,9} == 0 % write colormap with file if no caption; otherwise, it is implied
                            if strcmp(requestVector{alphaInd,7},'gray') == 1
                                imExp = uint16(refocusedImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                            else
                                imExp = ind2rgb(expImage16,colormap([requestVector{alphaInd,7} '(65536)']));
                            end
                            fout = fullfile(dout,[fname '_16bit.png']);
                            imwrite(imExp,fout);
                        else
                            fprintf('\n');
                            warning('16-bit PNG export is not supported when captions are enabled. Image not exported.');
                        end

                    case 5 % save 16-bit TIFF
                        if requestVector{alphaInd,9} == 0 % write colormap with file if no caption; otherwise, it is implied
                            if strcmp(requestVector{alphaInd,7},'gray') == 1
                                imExp = uint16(refocusedImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                            else
                                imExp = ind2rgb(expImage16,colormap([requestVector{alphaInd,7} '(65536)']));
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
            
            if requestVector{alphaInd,5} == 0
                
                try     close(cF);
                catch   % figure already closed
                end
                
            else
                
                if requestVector{alphaInd,9} == 0
                    cF = figure;
                    displayimage(expImage,requestVector{alphaInd,9},requestVector{alphaInd,10},requestVector{alphaInd,7},requestVector{alphaInd,8});
                end
                    
                switch requestVector{alphaInd,5} % display flag
                    case 1 % display with pauses
                        pause;
                        
                    case 2 % display without pauses
                        drawnow;
                        
                    otherwise
                        error('Incorrect setting of the display flag in the requestVector input variable to the genrefocus function.');
                        
                end%switch
                
            end%if
            
        end%for
    end%for
    
end%if