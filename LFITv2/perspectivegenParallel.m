function [perspectiveImage] = perspectivegenParallel(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%PERSPECTIVEGENPARALLEL Generates a series of perspective images as defined by the request vector
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

SS_ST = q.stFactor;

nPerspectives = size( q.pUV, 1 );
for pIdx = 1:nPerspectives
    
    qi      = q;
    qi.pUV  = q.pUV(pIdx,:);
    
    perspectiveImage = perspective(q,radArray,sRange,tRange);
    
    switch q.contrast
        case 'simple',      % THIS FUNCTIONALITY WAS NOT PREVIOUSLY HERE, SHOULD IT HAVE BEEN? --cjc    %perspectiveImage = ( perspectiveImage - min(perspectiveImage(:)) )/( max(perspectiveImage(:)) - min(perspectiveImage(:)) );
        case 'imadjust',    perspectiveImage = imadjust(perspectiveImage);
    end
    
    try     close(cF);
    catch  % figure not yet opened
    end
    
    if q.title
        
        cF = figure;
        switch q.title
            case 'caption',     caption = q.caption{pIdx};
            case 'annotation',  caption = sprintf( '(%g,%g)', qi.pUV(1), qi.pUV(2) );
            case 'both',        caption = sprintf( '%s --- (%g,%g)', q.caption(pIdx), qi.pUV(1), qi.pUV(2) );
        end
        displayimage(perspectiveImage,caption,q.colormap,q.background);
        
        frame = getframe(1);
        expImage = frame2im(frame);
        
    else
        
        if any(strcmpi( q.saveas, {'png16','tif16'} ))
            expImage16 = gray2ind(perspectiveImage,65536); % for 16-bit output
        end
        expImage = gray2ind(perspectiveImage,256); % allows for colormap being used in output

    end%if
    
    if q.saveas % Save image?
        
        dout = fullfile(outputPath,'Perspectives');
        if ~exist(dout,'dir'), mkdir(dout); end
        
        fname = sprintf( '%s_persp_stSS%g_uPos%g_vPos%g', imageSpecificName, SS_ST, qi.pUV(1), qi.pUV(2) );
        
        if q.title
            
            switch q.saveas
                case 'bmp'
                    fout = fullfile(dout,[fname '.bmp']);
                    imwrite(expImage,fout);

                case 'png'
                    fout = fullfile(dout,[fname '.png']);
                    imwrite(expImage,fout);

                case 'jpg'
                    fout = fullfile(dout,[fname '.jpg']);
                    imwrite(expImage,fout,'jpg','Quality',90);

                case 'png16'
                    fprintf('\n');
                    warning('16-bit PNG export is not supported when captions are enabled. Image not exported.');

                case 'tif16'
                    fprintf('\n');
                    warning('16-bit TIFF export is not supported when captions are enabled. Image not exported.');

                otherwise
                    error('Incorrect setting of the save flag in the requestVector input variable to the perspectivegen function.');
                    
            end%switch
            
        else
            
            % If no title is enabled, export colormap
            
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
                    if strcmp(q.colormap,'gray')
                        imExp = perspectiveImage; % no conversion needed to apply a colormap; just use the existing intensity image
                    else
                        imExp = ind2rgb(expImage16,colormap([q.colormap '(65536)']));
                    end
                    fout = fullfile(dout,[fname '_16bit.png']);
                    imwrite(imExp,fout,'png','BitDepth',16);
                   
                case 'tif16'
                    if strcmp(q.colormap,'gray')
                        imExp = uint16(perspectiveImage*65536); % no conversion needed to apply a colormap; just use the existing intensity image
                    else
                        imExp = ind2rgb(expImage16,colormap([q.colormap '(65536)']));
                    end
                    fout = fullfile(dout,[fname '_16bit.tif']);
                    imwrite(imExp,fout,'tif');
                    
                otherwise
                    error('Incorrect setting of the save flag in the requestVector input variable to the perspectivegen function.');
                    
            end
            
        end%if
        
    end%if
    
    if q.display % Display Image?
  
        if q.title
            % Image already displayed, nothing to do
        else
            cF = figure;
            displayimage(perspectiveImage,'',q.colormap,q.background);
        end

        switch q.display
            case 'slow',    pause;
            case 'fast',    drawnow;
        end
        
    else
        
        try     close(cF);
        catch   % figure not yet opened
        end
        
    end%if
    
    fprintf('.');
    
end%for
fprintf('\n   Complete.\n');

end%function
