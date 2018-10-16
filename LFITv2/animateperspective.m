function animateperspective(q,radArray,sRange,tRange,outputPath,imageSpecificName)
%ANIMATEPERSPECTIVE Generates a perspective animation as defined by the request vector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nBeginning perspective animation generation.\n');
progress(0);

vidobj = 0;

cF = figure;
set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);

nFrames = size(q.pUV,1);
for frameInd = 1:nFrames

    % Sub-query for single (u,v) pair
    qi      = q;
    qi.pUV  = q.pUV(frameInd,:);

    % Generate perspective image frame
    perspectiveImage = perspective(qi,radArray,sRange,tRange);

    switch q.contrast
        case 'simple',      perspectiveImage = ( perspectiveImage - min(perspectiveImage(:)) )/( max(perspectiveImage(:)) - min(perspectiveImage(:)) );
        case 'imadjust',    perspectiveImage = imadjust(perspectiveImage);
        otherwise,          % Nothing to do
    end

    try
        set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
    catch
        cF = figure;
        set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
        set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
        set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
    end

    if q.title % Title image?

        switch q.title
            case 'caption',     caption = q.caption;
            case 'annotation',  caption = sprintf( '(%g,%g)', qi.pUV(1), qi.pUV(2) );
            case 'both',        caption = sprintf( '%s --- (%g,%g)', q.caption, qi.pUV(1), qi.pUV(2) );
        end%switch
        displayimage( perspectiveImage, caption, q.colormap, q.background );

        frame = getframe(1);

    else

        expIm   = gray2ind(perspectiveImage,256);
        cMap    = [q.colormap '(256)'];
        frame   = im2frame(expIm,colormap(cMap));

    end%if

    if q.saveas

        dout = fullfile(outputPath,'Animations');
        if ~exist(dout,'dir'), mkdir(dout); end

        fname = sprintf( '%s_perspAnim_stSS%g_uvSS%g_cap%g', imageSpecificName, q.stFactor, strcmpi(q.mask,'circ') );
        switch q.saveas
            case 'gif'
                fout = fullfile(dout,[fname '.gif']);
                gifwrite(frame,q.colormap,fout,1/q.framerate,frameInd); % filename, delay, frame index

            case 'avi'
                fout = fullfile(dout,[fname '.avi']);
                vidobj = aviwrite(frame,q.colormap,q.codec,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);

            case 'mp4'
                fout = fullfile(dout,[fname '.mp4']);
                vidobj = mp4write(frame,q.colormap,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);

        end%switch

    end%if

    if q.display

        if q.title
            % Image already displayed, nothing to do
        else
            try
                set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
            catch
                cF = figure;
                set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
                set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
            end
            displayimage(perspectiveImage,'',q.colormap,q.background);
        end

        switch q.display
            case 'slow',    pause;
            case 'fast',    drawnow;
        end%switch

    else

        try     close(cF);
        catch   % figure already closed
        end

    end%if

    % Timer logic
    progress(frameInd,nFrames);

end%for

try     set(cF,'WindowStyle','normal'); % release focus
catch   % the figure couldn't be set to normal
end

fprintf('\nPerspective animation generation finished.\n');

end%function
