classdef lfiQuery
    %LFIQUERY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % Focus-adjustment parameters
        alpha       = 1;        % alpha value used in refocusing; a=1 nominal focal plane; a<1 focuses further away; a>1 focuses closer to the camera
        refocus     = 'add';    % refocus type: 'add', 'mult', 'filt'
        filter      = [0 0];    % filter parameters (does nothing if REFOCUS isn't 'filt')
                                %       1. threshold below which intensity will be disregarded as noise
                                %       2. filter intensity threshold
        
        % Perspective-adjustment parameters
        uv          = [0 0];    % (u,v) position for which to generate a perspective view; non-integer values ARE indeed supported
        
        % Other processing parameters
        uvFactor    = 1;        % supersampling factor in (u,v) is an integer by which to supersample: 1 is none, 2 = 2x SS, 4 = 4x SS, etc
        stFactor    = 1;        % supersampling factor in (s,t) is an integer by which to supersample: 1 is none, 2 = 2x SS, 4 = 4x SS, etc
        contrast    = 'simple'; % contrast stretching style: 'simple', 'imadjust'
        aperture    = 'full';   % aperture enforcing of microlenses: 'full', 'circ'
        magnification = 0;      % magnification type is 0 for legacy algorithm, 1 for constant magnification (aka telecentric). See documentation for more info.
        
        % Output configuration
        saveas      = false;    % output image format: false, 'bmp', 'png', 'jpg', 'png16', 'tif16'
        display     = false;    % image display speed: false, 'slow', 'fast'
        colormap    = jet;      % the colormap used in displaying the image, eg jet or gray (no quotes)
        background  = [1 1 1];  % background color of the figure if the caption is enabled, eg [.8 .8 .8] or [1 1 1]
        caption     = false;    % caption flag is 0 for no caption, 1 for caption string only, 2 for caption string + alpha value
        title       = '';       % caption string is the string used in the caption for caption flag of 1 or 2.
        grouping    = 'image';  % directory flag is 0 to save refocused images on a per-image basis or 1 to save on a per-alpha basis (must be constant across queries)
        
    end%properties
    
    methods
        
        %
        % Constructor
        %
        function q = query( type )
            if nargin==1
                switch lower(type)
                    case 'focus'
                        % Do things

                    case 'perspective'
                        % Do things

                    otherwise
                        % Do things

                end
            end
        end
        
        %
        % Object set methods (alphabetical)
        %
        function obj = set.alpha( obj, val )
            if isnumeric(val) && val>0
                obj.alpha = val;
            else
                error('ALPHA must be a positive number.');
            end
        end
        
        function obj = set.aperture( obj, val )
            opts = {'full','circ'};
            if istring(val) && any(strcmpi(val,opts))
                obj.aperture = val;
            else
                error('APERATURE must be one of: .');
            end
        end
        
        function obj = set.background( obj, val )
            if isnumeric(val) && isrow(val) && numel(val)==3
                obj.background = val;
            else
                error('BACKGROUND must be a 1 by 3 matrix.');
            end
        end
        
        function obj = set.caption( obj, val )
            % Saved for later
        end
        
        function obj = set.colormap( obj, val )
            if isnumeric(val) && ismatrix(val) && size(val,2)==3
                obj.colormap = val;
            else
                error('COLORMAP must be an M by 3 matrix.');
            end
        end
        
        function obj = set.contrast( obj, val )
            opts = {'simple','imadjust'};
            if istring(val) && any(strcmpi(val,opts))
                obj.contrast = val;
            else
                error('CONTRAST must be one of: .');
            end
        end
        
        function obj = set.display( obj, val )
            opts = {'slow','fast'};
            if ~val
                obj.display = false;        % Enforce FALSE over 0
            elseif istring(val) && any(strcmpi(val,opts))
                obj.display = val;
            else
                error('DISPLAY must be one of: .');
            end
        end
        
        function obj = set.filter( obj, val )
            if isnumeric(val) && isrow(val) && numel(val)==2
                obj.filter = val;
            else
                error('FILTER must be a 1 by 2 matrix.');
            end
        end
        
        function obj = set.grouping( obj, val )
            opts = {'image','alpha'};
            if istring(val) && any(strcmpi(val,opts))
                obj.grouping = val;
            else
                error('GROUPING must be one of: .');
            end
        end
           
        function obj = set.magnification( obj, val )
            % Saved for later
        end
        
        function obj = set.refocus( obj, val )
            opts = {'add','mult','filt'};
            if istring(val) && any(strcmpi(val,opts))
                obj.refocus = val;
            else
                error('REFOCUS must be one of: .');
            end
        end


        function obj = set.saveas( obj, val )
            opts = {'bmp','png','jpg','png16','tif16'};
            if ~val
                obj.saveas = false;
            elseif istring(val) && any(strcmpi(val,opts))
                obj.saveas = val;
            else
                error('SAVEAS must be one of: .');
            end
        end
        
        function obj = set.stFactor( obj, val )
            if isnumeric(val), 	obj.stFactor = uint8(val);
            else                error('STFACTOR must be a number.');
            end
        end
        
        function obj = set.title( obj, val )
            if isstring(val)
                obj.title = val;
            else
                error('TITLE must be a string.');
            end
        end
        
        function obj = set.uv( obj, val )
            if isnumeric(val) && isrow(val) && numel(val)==2
                obj.uv = val;
            else
                error('UV must be a 1 by 2 matrix.');
            end
        end
        
        function obj = set.uvFactor( obj, val )
            if isnumeric(val), 	obj.uvFactor = uint8(val);
            else                error('UVFACTOR must be a number.');
            end
        end
        
    end%methods
    
end%classdef
