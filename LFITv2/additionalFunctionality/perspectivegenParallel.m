function [perspectiveImage] = perspectivegenParallel(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%PERSPECTIVEGENPARALLEL Generates a series of perspective images as defined by the request vector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nGenerating perspective views...');
progress(0);

SS_ST = q.stFactor;

nPerspectives = size( q.pUV, 1 );
for pIdx = 1:nPerspectives

    qi      = q;
    qi.pUV  = q.pUV(pIdx,:);

    perspectiveImage = perspective(q,radArray,sRange,tRange);

    switch q.contrast
        case 'simple',      perspectiveImage = ( perspectiveImage - min(perspectiveImage(:)) )/( max(perspectiveImage(:)) - min(perspectiveImage(:)) );
        case 'imadjust',    perspectiveImage = imadjust(perspectiveImage);
        otherwise,          % Nothing to do
    end

    try     close(cF);
    catch   % figure not yet opened
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
                    imwrite(imExp,fout,'tif','compression','lzw');

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

    % Timer logic
    progress(pIdx,nPerspectives);

end%for

end%function
