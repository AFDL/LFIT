function [vidobj] = mp4write(frame,cMap,vidobj,filename,frameInd,quality,fpsVal,totalFrames)
%MP4WRITE Writes the current frame to a new or existing MP4 file.
%   
% Checks against multiple MATLAB versions, but only versions R2010b or
% newer support MP4 export.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


if verLessThan('matlab', '7.11') % lower MATLAB versions than R2010b don't support VideoWriter, but do support avifile (which doesn't really support MP4 output).

    error('WARNING: MP4 export not supported on this version of MATLAB. Please use MATLAB 2010b or higher, or select an alternate export format.');

else
    
    % On the first loop, create the file. In subsequent loops, append.
    if frameInd==1
        warning('off','MATLAB:audiovideo:VideoWriter:mp4FramePadded'); % width and height frame padded for H.264 - MP4
        vidobj = VideoWriter(filename,'MPEG-4');
        vidobj.FrameRate=fpsVal;
        vidobj.Quality=quality;
        open(vidobj);
        writeVideo(vidobj,frame);
    else
        writeVideo(vidobj,frame);
    end
    
    if frameInd == totalFrames
        close(vidobj);
        warning('on','MATLAB:audiovideo:VideoWriter:mp4FramePadded');
    end
    
end%if

end%function
