function animaterefocus(q,radArray,sRange,tRange,outputPath,imageSetName)
%ANIMATEREFOCUS Generates a refocusing animation as defined by the request vector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nBeginning refocusing animation generation.\n');
progress(0);

% for pInd = 1:size(requestVector,1) % for each image format defined in request vector. (For example, to export a GIF with a caption and a GIF without a caption, use multiple lines in requestVector)

%     fprintf('\nGenerating refocusing animation (%i of %i)...',pInd,size(requestVector,1));

    % Preallocate focal stack
    switch q.fZoom
        case 'legacy'
            nFrames = length(q.fAlpha);
            refocusStack = zeros(size(radArray,4)*q.stFactor,size(radArray,3)*q.stFactor,nFrames,'single');

        case 'telecentric'
            nFrames = length(q.fPlane);
            refocusStack = zeros(length(q.fGridY),length(q.fGridX),nFrames,'single');

    end%switch

    for frameInd = 1:nFrames

        % Sub-query at single alpha value
        qi = q;
        switch q.fZoom
            case 'legacy',      qi.fAlpha = q.fAlpha(frameInd);
            case 'telecentric', qi.fPlane = q.fPlane(frameInd);
        end
        refocusStack(:,:,frameInd) = refocus(qi,radArray,sRange,tRange);

        % Timer logic
        progress(frameInd,nFrames+1);

    end

    % Normalize raw intensities by the MAX intensity of the entire focal stack
    if strcmpi( q.contrast, 'stack' )
        refocusStack = ( refocusStack - min(refocusStack(:)) )/( max(refocusStack(:)) - min(refocusStack(:)) );
    end

    fprintf('Saving video to file...');
    clear vidobj; vidobj = 0;

    try     close(cF);
    catch   % figure not yet opened
    end

    cF = figure;
    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
    set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)])

    for frameInd = 1:nFrames % for each frame of an animation

        refocusedImage = refocusStack(:,:,frameInd);
        switch q.contrast
            case 'simple',      refocusedImage = ( refocusedImage - min(refocusedImage(:)) )/( max(refocusedImage(:)) - min(refocusedImage(:)) );
            case 'imadjust',    refocusedImage = imadjust( refocusedImage );
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
                case 'annotation',  caption = sprintf( '[alpha = %g]', qi.fALpha );
                case 'both',        caption = sprintf( '%s --- [alpha = %g]', q.caption, qi.fAlpha );
            end%switch
            displayimage( refocusedImage, caption, q.colormap, q.background );

            frame = getframe(1);

        else

            expIm   = gray2ind(refocusedImage,256);
            cMap    = [q.colormap '(256)'];
            frame   = im2frame(expIm,colormap(cMap));

        end%if

        if q.saveas

            dout = fullfile(outputPath,'Animations');
            if ~exist(dout,'dir'), mkdir(dout); end

            fname = sprintf( '%s_refocusAnim_stSS%g_uvSS%g_ap%g', imageSetName, q.stFactor, q.uvFactor, strcmpi(q.mask,'circ') );
            switch q.saveas
                case 'gif'
                    fout = fullfile(dout,[fname '.gif']);
                    gifwrite(frame,q.colormap,fout,1/q.framerate,frameInd); % filename, delay, frame index

                case 'avi'
                    fout = fullfile(dout,[fname '.avi']);
                    vidobj = aviwrite(frame,q.colormap,q.codec,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);

                case 'mp4'
                    fout = fullfile(dout,[fname '.mp4']);
                    vidobj=mp4write(frame,q.colormap,vidobj,fout,frameInd,q.quality,q.framerate,nFrames);

            end%switch

        end%if

        if q.display

            if q.title
                % Already displayed, nothing to do
            else
                try
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                catch
                    cF = figure;
                    set(cF,'WindowStyle','modal'); % lock focus to window to prevent user from selecting main GUI
                    set(cF,'position', [0 0 q.stFactor*size(radArray,4) q.stFactor*size(radArray,3)]);
                    set(0, 'currentfigure', cF);  % make refocusing figure current figure (in case user clicked on another)
                end
                displayimage(refocusedImage,'',q.colormap,q.background);
            end

            switch q.display
                case 'slow',    pause;
                case 'fast',    drawnow;
            end%switch

        else

            try     close(cF);
            catch   % figure not yet opened
            end

        end%if

    end%for

    try set(cF,'WindowStyle','normal'); % release focus
    catch % the figure couldn't be set to normal
    end

    % Complete
    progress(1,1);

% end%for
fprintf('\nRefocusing animation generation finished.\n');

end%function
