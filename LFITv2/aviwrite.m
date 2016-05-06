function [vidobj] = aviwrite(frame,cMap,codec,vidobj,filename,frameInd,quality,fpsVal,totalFrames)
%AVIWRITE Writes the current frame to a new or existing AVI file
%   
% Supports multiple MATLAB versions, but be careful of
% codec/compression/output format differences between versions of MATLAB
% older than R2010b and newer versions.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


if verLessThan('matlab', '7.11') % lower MATLAB versions don't support VideoWriter, but do support avifile
    
    switch codec
        case 'uncompressed',        comp='None';
        case 'jpeg',                comp='MSVC';
        case 'jpeg2000',            comp='Cinepak';
        case 'jpeg2000-lossless',	comp='RLE';
        otherwise,  error('Invalid codec/compression selection in requestVector input to movie generating function.');
    end
    
    if frameInd==1
        try
            vidobj = avifile(filename,'compression',comp);
        catch
            warning('Program was improperly closed during last AVI write.');
            clear mex % this may have greater scope than intended; uncertain of extent of behavior when calling this. It should close any open AVI files though.
            try
                vidobj = avifile(filename,'compression',comp);
            catch err2
                rethrow(err);
            end
        end
        vidobj.colormap = colormap(cMap);        
        vidobj.fps=fpsVal;
        vidobj.quality=quality;
    end
    vidobj = addframe(vidobj,frame);
    
    if frameInd == totalFrames
        vidobj = close(vidobj);
    end
    
else
    
    switch codec
        case 'uncompressed'
            comp='Uncompressed AVI';
        case 'jpeg'
            comp='Motion JPEG AVI';
        case 'jpeg2000'
            comp='Motion JPEG 2000';
            filename = filename(1:end-4); % removes the .avi from the extension so MATLAB can append a .mp2
            frame = frame2im(frame);
        case 'jpeg2000-lossless'
            comp='Archival';
            filename = filename(1:end-4); % removes the .avi from the extension so MATLAB can append a .mp2
            frame = frame2im(frame); % mp2 files need the input data structured not from 0 to 1
        otherwise
            error('Invalid codec/compression selection in requestVector input to movie generating function.');
    end
    
    if frameInd==1
        try
            vidobj = VideoWriter(filename,comp);
        catch
            warning('Incorrect codec setting for AVI file export. Using default Motion JPEG AVI profile...');
            vidobj = VideoWriter(filename);
        end
        vidobj.FrameRate=fpsVal;
        if codec == 1
            vidobj.Quality=quality;
        end
        open(vidobj);
        writeVideo(vidobj,frame);
    else
        writeVideo(vidobj,frame);
    end
    
    if frameInd == totalFrames
        close(vidobj);
    end
    
end%if

end%function
