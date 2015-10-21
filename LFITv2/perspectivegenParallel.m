function [perspectiveImage] = perspectivegenParallel(q,radArray,sRange,tRange,outputPath,imageSpecificName)
% perspectivegen | Generates a series of perspective images as defined by the request vector
%
% Input Arguments:
%   radArray = matrix of intensity values for a given u,v,s, and t index
%   requestVector = defines the output; format given below
%   requestVector = [u value, v value, super sampling factor in (s,t), save flag, display flag, imadjust flag, caption flag, caption string]
%       {1} u value refers to the u position for which to generate a perspective view. Non-integer values ARE indeed supported, although any saved file names will have decimals.
%       {2} v value refers to the v position for which to generate a perspective view. Non-integer values ARE indeed supported, although any saved file names will have decimals.
%       {3} supersampling factor in (s,t) is an integer by which to supersample. 1 is none, 2 = 2x SS, 4 = 4x SS, etc..
%       {4} save flag is 0 for no saving, 1 for saving a bmp, 2 for saving a png, 3 for saving a jpg of the image, 4 for saving a 16-bit png, 5 for saving a 16-bit TIFFg
%       {5} display flag is 0 for no display, 1 to display each perspective image with a pause, 2 to display each image without a pause
%       {6} imadjust flag is 0 for raw output, 1 is to apply the imadjust function to the perspective image (increases contrast)
%       {7} colormap is the colormap used in displaying the image, eg 'jet' or 'gray'
%       {8} background color is the background of the figure if the caption is enabled, eg [.8 .8 .8] or [1 1 1]
%       {9} caption flag is 0 for no caption, 1 for caption string only, 2 for caption string + (u,v) coordinates appended
%       {10} caption string is the string used in the caption for caption flag of 1 or 2.


fprintf('\nGenerating perspective views...');
for pInd = 1:size(requestVector,1)
    
    perspectiveImage = perspective(radArray,requestVector{pInd,1},requestVector{pInd,2},requestVector{pInd,3},sRange,tRange);
    if requestVector{pInd,6} == 1
        perspectiveImage = ( perspectiveImage - min(perspectiveImage(:)) )/( max(perspectiveImage(:)) - min(perspectiveImage(:)) );
        perspectiveImage = imadjust(perspectiveImage);      % This makes the above line pointless --cjc
    end

    SS_ST = requestVector{pInd,3};
    u0 = requestVector{pInd,1};
    v0 = requestVector{pInd,2};
    
    try     close(cF);
    catch  % figure not yet opened
    end
    
    if requestVector{pInd,9} == 0
        
        if requestVector{pInd,4} == 4 || requestVector{pInd,4} == 5
            expImage16 = gray2ind(perspectiveImage,65536); % for 16bit output
        end
        expImage = gray2ind(perspectiveImage,256); %allows for colormap being used in output
        
    else
        
        cF = figure;
        switch requestVector{pInd,9}
            case 1 % caption string only
                displayimage(perspectiveImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
                
            case 2 % caption string with position appended
                caption = sprintf( '%s --- (%g,%g)', requestVector{pInd,10}, requestVector{pInd,1}, requestVector{pInd,2} );
                displayimage(perspectiveImage,requestVector{pInd,9},caption,requestVector{pInd,7},requestVector{pInd,8});

            otherwise
                error('Incorrect setting of the caption flag in the requestVector input variable to the perspectivegen function.');
                
        end%switch
        
        frame = getframe(1);
        expImage = frame2im(frame);

    end%if
    
    if requestVector{pInd,4} > 0
        
        dout = fullfile(outputPath,'Perspectives');
        if ~exist(dout,'dir'), mkdir(dout); end
        
        if requestVector{pInd,9} == 0 % write colormap with file if no caption; otherwise, it is implied
            
            fname = sprintf( '%s_persp_stSS%g_uPos%g_vPos%g', imageSpecificName, SS_ST, u0, v0 );
            switch requestVector{pInd,4}
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
                    if strcmp(requestVector{pInd,7},'gray') == 1
                        imExp = perspectiveImage; % no conversion needed to apply a colormap; just use the existing intensity image
                    else
                        imExp = ind2rgb(expImage16,colormap([requestVector{pInd,7} '(65536)']));
                    end
                    fout = fullfile(dout,[fname '_16bit.png']);
                    imwrite(imExp,fout,'png','BitDepth',16);
                   
                case 5 % save 16-bit TIFF
                    if strcmp(requestVector{pInd,7},'gray') == 1
                        imExp = uint16(perspectiveImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                    else
                        imExp = ind2rgb(expImage16,colormap([requestVector{pInd,7} '(65536)']));
                    end
                    fout = fullfile(dout,[fname '_16bit.tif']);
                    imwrite(imExp,fout,'tif');
                    
                otherwise
                    error('Incorrect setting of the save flag in the requestVector input variable to the perspectivegen function.');
                    
            end
            
        else
            
            switch requestVector{pInd,4}
                case 1 % save bmp
                    fout = fullfile(dout,[fname '.bmp']);
                    imwrite(expImage,fout);

                case 2 % save png
                    fout = fullfile(dout,[fname '.png']);
                    imwrite(expImage,fout);

                case 3 % save jpg
                    fout = fullfile(dout,[fname '.jpg']);
                    imwrite(expImage,fout,'jpg','Quality',90);

                case 4 % save 16-bit png
                    fprintf('\n');
                    warning('16-bit PNG export is not supported when captions are enabled. Image not exported.');

                case 5 % save 16-bit TIFF
                    fprintf('\n');
                    warning('16-bit TIFF export is not supported when captions are enabled. Image not exported.');

                otherwise
                    error('Incorrect setting of the save flag in the requestVector input variable to the perspectivegen function.');
                    
            end%switch
            
        end%if
        
    end%if
    
    if requestVector{pInd,5} == 0 % no display
        
        try     close(cF);
        catch   % figure not yet opened
        end
        
    else
        
        if requestVector{pInd,9} == 0
            
            cF = figure;
            displayimage(perspectiveImage,requestVector{pInd,9},requestVector{pInd,10},requestVector{pInd,7},requestVector{pInd,8});
            
        end

        switch requestVector{pInd,5}
            case 1 % display with pauses
                pause;

            case 2 % display without pauses
                drawnow;

            otherwise
                error('Incorrect setting of the display flag in the requestVector input variable to the perspectivegen function.');

        end%switch
        
    end%if
    
    fprintf('.');
    
end%for
fprintf('\n   Complete.\n');

end%function
