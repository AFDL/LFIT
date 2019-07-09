function obj = import( obj, vec, type )
%IMPORT Import a legacy requestVector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


%% GUESS THE IMPORT TYPE IF UNSPECIFIED

if nargin<3
    switch size(vec,2)
        case 10,                    type = 'perspectivegen';
        case 11,                    type = 'animateperspective';
        case 14,                    type = 'genrefocus';
%             if numel(vec{1,4})>1,   type = 'animaterefocus';
%             else                    type = 'genfocalstack';
%             end
%         case 15,                    type = 'genrefocus';
        otherwise,                  error('Unable to determine type of requestVector. You must manually specify.');
    end
end


%% CONSISTENTLY INDEXED PARAMETERS

obj.stFactor        = vec{1,3};

if vec{1,5} == 0
    obj.display = false;
else
    flags = {'slow','fast'};
    obj.display = flags{ vec{1,5} };
end

flags = {'none','slice','stack'};
obj.contrast = flags{ vec{1,6} };

obj.colormap        = vec{1,7};
obj.background      = vec{1,8};

obj.caption         = vec{:,10};


%% FILE TYPE AND FORMAT

if vec{1,4}(1) == 0
    obj.saveas = false;
else
    switch lower(type)
        case {'animateperspective','animaterefocus'}
            flags = {'gif','avi','mp4'};
            obj.saveas = flags{ vec{1,4}(1,1) };
            
            if vec{1,4}(1,1)==1
                obj.framerate   = 1/vec{1,4}(2,1);
            else
                obj.framerate   = vec{1,4}(2,2);
                obj.quality     = vec{1,4}(2,1);
                
                if vec{1,4}(1,1)==2
                    flags = {'uncompressed','jpeg','jpeg2000-lossless','jpeg2000'};
                    obj.codec = flags{ vec{1,4}(2,3) };
                end
            end

        otherwise
            flags = {'bmp','png','jpg','png16','tif16'};
            obj.saveas = flags{ vec{1,4} };

    end%switch
end%if


%% EVERYTHING ELSE

switch lower(type)
    case 'perspectivegen'
%         obj.adjust      = 'perspective';
        obj.pUV         = cell2mat( vec(:,1:2) );
        
    case 'animateperspective'
%         obj.adjust      = 'perspective';
        obj.pUV         = gentravelvector(vec{1,1},000,000,vec{1,2},vec{1,11});
        obj.uvFactor    = vec{1,2};
        
    case {'animaterefocus','genfocalstack'}
%         obj.adjust      = 'focus';
        obj.uvFactor    = vec{1,2};
        
        if vec{1,11} == 0
            obj.mask = false;
        else
            obj.mask = 'circ';
        end

        flags = {'add','mult','filt'};
        obj.fMethod = flags{ vec{1,12} };

        obj.fFilter     = vec{1,13};

        if vec{1,14}(1) == 0
            obj.fZoom   = 'legacy';
            if vec{1,1}(1,1),   obj.fAlpha = logspace( log10(vec{1,1}(2,1)), log10(vec{1,1}(2,2)), vec{1,1}(1,2) );
            else                obj.fAlpha = linspace( vec{1,1}(2,1), vec{1,1}(2,2), vec{1,1}(1,2) );
            end
            if strcmpi(type,'animaterefocus') && vec{1,1}(3,1)
                obj.fAlpha = [ obj.fAlpha(2:end-1) fliplr(obj.fAlpha) ];
            end
        else
            obj.fZoom   = 'telecentric';
            obj.fGridX  = linspace( vec{1,14}(2), vec{1,14}(3), vec{1,14}(8) );
            obj.fGridY  = linspace( vec{1,14}(4), vec{1,14}(5), vec{1,14}(9) );
            obj.fLength = vec{1,14}(11);
            obj.fMag    = vec{1,14}(12);
            obj.fPlane  = vec{1,14}(13);
        end
        
    case 'genrefocus'
%         obj.adjust      = 'focus';
        obj.uvFactor    = vec{1,2};
        
        if vec{1,11} == 0
            obj.mask = false;
        else
            obj.mask = 'circ';
        end
        
        if vec{1,12}
            obj.grouping = 'alpha';
        else
            obj.grouping = 'image';
        end

        flags = {'add','mult','filt'};
        obj.fMethod = flags{ vec{1,12} };

        obj.fFilter     = vec{1,13};

        if vec{1,14}(1) == 0
            obj.fZoom   = 'legacy';
            obj.fAlpha  = cell2mat( vec(:,1) );
        else
            obj.fZoom   = 'telecentric';
            obj.fGridX  = linspace( vec{1,14}(2), vec{1,14}(3), vec{1,14}(8) );
            obj.fGridY  = linspace( vec{1,14}(4), vec{1,14}(5), vec{1,14}(9) );
            obj.fLength = vec{1,14}(11);
            obj.fMag    = vec{1,14}(12);
            obj.fPlane  =linspace( vec{1,14}(6), vec{1,14}(7), vec{1,14}(10) );
        end
        
end%switch
