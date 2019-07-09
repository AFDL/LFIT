function [  ] = genperspective(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%PERSPECTIVEGEN Generates a series of perspective images as defined by the request vector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nGenerating perspective views...');
progress(0);
clear vidobj; vidobj = 0;

nPerspectives = size( q.pUV, 1 );
for fIdx = 1:nPerspectives
    
    % Sub-query for single (u,v) pair
    qi      = q;
    qi.pUV  = q.pUV(fIdx,:);
    
    % Generate perspective image frame
    perspectiveImageStack(:,:,fIdx) = perspective(qi,radArray,sRange,tRange);
    
    % Timer logic
    progress(fIdx,nPerspectives);
end%for

limsStack=[min(perspectiveImageStack(:)) max(perspectiveImageStack(:))];

fprintf('\nDisplaying and/or saving perspective views...');
for fIdx = 1:nPerspectives
    
    perspectiveImage = perspectiveImageStack(:,:,fIdx);
    
    switch q.contrast
        case 'slice'
            limsSlice=[min(perspectiveImage(:)) max(perspectiveImage(:))];
            perspectiveImage = ( perspectiveImage - limsSlice(1) )/( limsSlice(2) - limsSlice(1) );
            perspectiveImage = imadjust(perspectiveImage,[q.intensity]);
        case 'stack'
            perspectiveImage = ( perspectiveImage - limsStack(1) )/( limsStack(2) - limsStack(1) );
            perspectiveImage = imadjust(perspectiveImage,[q.intensity]);
        otherwise           % Nothing to do
    end

    if q.title % Title image?
        
        cF = figure;
        switch q.title
            case 'caption',     caption = q.caption{fIdx};
            case 'annotation',  caption = sprintf( '(%g,%g)', qi.pUV(1), qi.pUV(2) );
            case 'both',        caption = sprintf( '%s --- (%g,%g)', q.caption(fIdx), qi.pUV(1), qi.pUV(2) );
        end%switch
        displayimage(perspectiveImage,caption,q.colormap,q.background);
        
        frame = getframe(1);
        expImage = frame2im(frame);
        
    else
        expImage = perspectiveImage;
    end%if
    
    if q.display % Display image?
        
        if q.title
            % Image already displayed, nothing to do
        else
            try
                set(0, 'currentfigure', cF);  % make perspective figure current figure (in case user clicked on another)
            catch
                cF = figure;
                set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
                set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
            end
            displayimage(perspectiveImage,'',q.colormap,q.background);
        end
        
        switch q.display
            case 'slow',    pause;
            case 'fast',    drawnow;
        end
        
    else
        
    end%if
    
    if q.saveas % Save image?
        dout = fullfile(outputPath,'Perspectives');
        if ~exist(dout,'dir'), mkdir(dout); end
        fname = sprintf( '%s_persp_stSS%g_uPos%g_vPos%g', imageSpecificName, q.stFactor, qi.pUV(1), qi.pUV(2) );
        
        switch q.saveas
            case 'bmp'
                fout = fullfile(dout,[fname '.bmp']);
                imwrite(gray2ind(expImage,256),colormap([q.colormap '(256)']),fout);
                
            case 'png'
                fout = fullfile(dout,[fname '.png']);
                imwrite(gray2ind(expImage,256),colormap([q.colormap '(256)']),fout,'png','BitDepth',8);
                
            case 'jpg'
                fout = fullfile(dout,[fname '.jpg']);
                imwrite(gray2ind(expImage,256),colormap([q.colormap '(256)']),fout,'jpg','Quality',90,'BitDepth',8);
                
            case 'png16'
                if ~q.title % write colormap with file if no caption; otherwise, it is implied
                    fout = fullfile(dout,[fname '_16bit.png']);
                    if strcmpi(q.colormap,'gray')
                        imwrite(expImage,fout,'png','BitDepth',16);
                    else
                        imwrite(ind2rgb(gray2ind(expImage,65536),colormap([q.colormap '(65536)'])),fout,'png','BitDepth',16);
                    end
                else
                    fprintf('\n');
                    warning('16-bit PNG export is not supported when captions are enabled. Image not exported.');
                end
                
            case 'tif16'
                if ~q.title % write colormap with file if no caption; otherwise, it is implied
                    fout = fullfile(dout,[fname '_16bit.tif']);
                    if strcmpi(q.colormap,'gray')
                        imwrite(gray2ind(expImage,65536),fout,'tif','compression','lzw');
                    else
                        imwrite(ind2rgb(gray2ind(expImage,65536),colormap([q.colormap '(65536)'])),fout,'tif','compression','lzw');
                    end
                else
                    fprintf('\n');
                    warning('16-bit TIFF export is not supported when captions are enabled. Image not exported.');
                end
                
            case 'gif'
                fname = sprintf( '%s_perspAnim_stSS%g_uvSS%g_aperMask%s', imageSpecificName, q.stFactor, q.uvFactor, q.mask );
                fout = fullfile(dout,[fname '.gif']);
                gifwrite(im2frame(gray2ind(expImage,256),colormap([q.colormap '(256)'])),q.colormap,fout,1/q.framerate,fIdx); % filename, delay, frame index
                
            case 'avi'
                fname = sprintf( '%s_perspAnim_stSS%g_uvSS%g_aperMask%s', imageSpecificName, q.stFactor, q.uvFactor, q.mask );
                fout = fullfile(dout,[fname '.avi']);
                vidobj = aviwrite(im2frame(gray2ind(expImage,256),colormap([q.colormap '(256)'])),q.colormap,q.codec,vidobj,fout,fIdx,q.quality,q.framerate,nPerspectives);
                
            case 'mp4'
                fname = sprintf( '%s_perspAnim_stSS%g_uvSS%g_aperMask%s', imageSpecificName, q.stFactor, q.uvFactor, q.mask );
                fout = fullfile(dout,[fname '.mp4']);
                vidobj = mp4write(im2frame(gray2ind(expImage,256),colormap([q.colormap '(256)'])),q.colormap,vidobj,fout,fIdx,q.quality,q.framerate,nPerspectives);
                
            otherwise
                error('Incorrect setting of the save flag in the requestVector input variable to the perspectivegen function.');
                
        end%switch
        
    end%if
    
end%for

try     set(cF,'WindowStyle','normal'); % release focus
catch   % the figure couldn't be set to normal
end

fprintf('\nPerspective generation finished.\n');
