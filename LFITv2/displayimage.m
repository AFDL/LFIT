function displayimage(imageName,captionString,colormapType,backgroundColor)
%DISPLAYIMAGE Displays a scaled-intensity image via imagesc with colormap.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


set(gcf, 'color', backgroundColor);
imagesc(imageName);
colormap(colormapType);

if ~isempty(captionString)
    title(captionString);
end

axis image;
axis off;

end%function
