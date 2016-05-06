function varargout = verify( obj )
%VERIFY Verify that all query parameters are sane.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


w = 0;

if strcmpi(obj.adjust,'focus')

    if strcmpi(obj.fMethod,'filt') && isempty(obj.fFilter)
        w=w+1; warning('Focus method is filter, but no filter is specified.');
    end

    if strcmpi(obj.fZoom,'legacy') && isempty(obj.fAlpha)
        w=w+1; warning('Focal zoom is legacy, but no alphas are specified.');
    end

    if strcmpi(obj.fZoom,'telecentric')
        if isempty(obj.fPlane),     w=w+1; warning('Focal zoom is telecentric, but no z-planes are specified.'); end
        if isempty(obj.fGridX),     w=w+1; warning('Focal zoom is telecentric, but no x-axis is specified.'); end
        if isempty(obj.fGridY),     w=w+1; warning('Focal zoom is telecentric, but no y-axis is specified.'); end
        if isempty(obj.fLength),    w=w+1; warning('Focal zoom is telecentric, but no focal length is specified.'); end
        if isempty(obj.fMag),       w=w+1; warning('Focal zoom is telecentric, but no magnification specified.'); end
    end

end%if

if strcmpi(obj.adjust,'perspective') && isempty(obj.pUV)
    w=w+1; warning('Query type is perspective-adjust, but no (u,v) coordinates are specified.');
end

if any(strcmpi(obj.saveas,{'jpg','mp4'})) && isempty(obj.quality)
    w=w+1; warning('File type is %s, but no quality is specified.',obj.saveas);
end

if strcmpi(obj.saveas,'avi') && isempty(obj.codec)
    w=w+1; warning('File type is avi, but no codec is specified.');
end

if any(strcmpi(obj.saveas,{'gif','avi','mp4'})) && isempty(obj.framerate)
    w=w+1; warning('File type is %s, but no framerate is specified.',obj.saveas);
end

if isequal(obj.saveas,obj.display)
    w=w+1; warning('Image save and display are both disabled, nothing will be output.');
end

if any(strcmpi(obj.title,{'caption','both'})) && isempty(obj.caption)
    w=w+1; warning('Title flag is %s, but no caption string is specified.',obj.title);
end

if nargout>0, varargout{1} = w; end
