function gifwrite(frame,cMap,filename,delayTime,ind)
%GIFWRITE Use inside a loop to create a GIF file frame-by-frame
%
% frame     : image to write to GIF file
% cMap      : colormap used to display the image
% filename  : full file path (unless saving in the current directory)
% delayTime : delay between frames (0 default)
% ind       : which frame of the GIF that is currently being written (1 = first frame)

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


im = frame2im(frame);

% Colormap logic
try
    [imind,cm] = rgb2ind(im,256,'dither');
catch
    imind = im;
    cm = colormap([cMap '(256)']);
end

% On the first loop, create the file. In subsequent loops, append.
if ind==1
    imwrite(imind,cm,filename,'gif','DelayTime',delayTime,'LoopCount',Inf);
else
    imwrite(imind,cm,filename,'gif','DelayTime',delayTime,'WriteMode','append');
end

end%function
