function obj = autoremove( obj )
%AUTOREMOVE Automatically remove unused parameters.
%
% This method will automatically clear parameters which are set, but not
% used. It will not affect the functionality of any reconstruction. It is
% merely a cleaning tool to keep queries tidy.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


switch obj.adjust
    case 'focus'
        obj.pUV = [];

        if ~strcmpi( obj.fMethod, 'filt' )
            obj.fFilter = [];
        end

        switch obj.fZoom
            case 'legacy'
                obj.fPlane  = [];
                obj.fGridX  = [];
                obj.fGridY  = [];
                obj.fLength = [];
                obj.fMag    = [];

            case 'telecentric'
                obj.fAlpha  = [];

        end%switch
        
    case 'perspective'
        obj.fMethod = '';
        obj.fFilter = [];
        obj.fZoom   = '';
        obj.fAlpha  = [];
        obj.fPlane  = [];
        obj.fGridX  = [];
        obj.fGridY  = [];
        obj.fLength = [];
        obj.fMag    = [];
                
end%switch

switch obj.saveas
    case {'bmp','png','png16','tif16'}
        obj.quality = [];
        obj.codec = '';
        
    case {'jpg','mp4'}
        obj.codec = '';
        
    case 'gif'
        obj.quality = [];
        
end%switch

if ~obj.title
    obj.caption = '';
end
