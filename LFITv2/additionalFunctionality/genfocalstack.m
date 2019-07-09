function [focalStack] = genfocalstack(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%GENFOCALSTACK Generates a focal stack of refocused images as defined by the request vector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nBeginning focal stack generation.\n');
progress(0);

try     close(focFig);
catch   % figure not opened
end

focFig = figure;
set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
set(focFig,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);

% Preallocate focal stack
switch q.fZoom
    case 'legacy'
        nFrames = length(q.fAlpha);
        focalStack = zeros(size(radArray,4)*q.stFactor,size(radArray,3)*q.stFactor,nFrames,'single');

    case 'telecentric'
        nFrames = length(q.fPlane);
        focalStack = zeros(length(q.fGridY),length(q.fGridX),nFrames,'single');

end%switch

for frameIdx = 1:nFrames % for each frame of an animation

    % Sub-query at single alpha value
    qi = q;
    switch q.fZoom
        case 'legacy',      qi.fAlpha = q.fAlpha(frameIdx);
        case 'telecentric', qi.fPlane = q.fPlane(frameIdx);
    end
    focalStack(:,:,frameIdx) = refocus(qi,radArray,sRange,tRange);

    % Timer logic
    progress(frameIdx,nFrames+1);

end

if strcmpi( q.contrast, 'stack' )
    focalStack = ( focalStack - min(focalStack(:)) )/( max(focalStack(:)) - min(focalStack(:)) ); % normalize raw intensities by the MAX intensity of the entire focal stack.
end

if q.saveas % if we're going to save images, then apply captions, display, and/or save, otherwise skip this loop.

    for frameIdx = 1:nFrames % for each frame of an animation

        refocusedImage = focalStack(:,:,frameIdx);
        switch q.contrast
            case 'simple',      refocusedImage = ( refocusedImage - min(refocusedImage(:)) )/( max(refocusedImage(:)) - min(refocusedImage(:)) );
            case 'imadjust',    refocusedImage = imadjust( refocusedImage );
            otherwise,          % Nothing to do
        end

        switch q.fZoom
            case 'legacy',      key = 'alpha';  val = q.fAlpha(frameIdx);
            case 'telecentric', key = 'plane';  val = q.fPlane(frameIdx);
        end

        SS_UV = q.uvFactor;
        SS_ST = q.stFactor;

        if q.title % Image title?

            switch q.title
                case 'caption',     caption = q.caption;
                case 'annotation',  caption = sprintf( '[%s = %g]', key,val );
                case 'both',        caption = sprintf( '%s --- [%s = %g]', q.caption, key,val );
            end
            displayimage(expImage,caption,q.colormap,q.background);

            try
                set(0, 'currentfigure', focFig);  %make refocusing figure current figure (in case user clicked on another)
            catch
                focFig = figure;
                set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                set(focFig,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
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

        dout = fullfile(outputPath,'Focal Stack',imageSpecificName);
        if ~exist(dout,'dir'), mkdir(dout); end

        fname = sprintf( '_FS_alp%4.5f_stSS%g_uvSS%g', val, SS_ST, SS_UV );
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
                if ~q.title % write colormap with file if no caption; otherwise, it is implied
                    if strcmpi(q.colormap,'gray')
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

        if q.display % Display image?

            if q.title
                % Image already displayed, nothing to do
            else
                try
                    set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                catch
                    focFig = figure;
                    set(focFig,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(focFig,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
                    set(0, 'currentfigure', focFig);  % make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(expImage,'',q.colormap,q.background);
            end

            switch q.display
                case 'slow',     pause;
                case 'fast',     drawnow;
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

% Complete
progress(1,1);

fprintf('\nFocal stack generation finished.\n');

end%function
