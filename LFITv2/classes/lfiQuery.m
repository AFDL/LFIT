classdef lfiQuery
    %LFIQUERY Creates a light field image (lfi) reconstruction query.
    %   Detailed explanation goes here
    
    properties
        
        adjust      = '';           % reconstruction type: 'focus', 'perspective', 'both'
        
        %
        %  Focus-adjust parameters (defaults set during construction)
        %
        fMethod     = '';           % refocus method: 'add', 'mult', 'filt'
        fFilter     = [];           % filter parameters (does nothing if METHOD isn't 'filt')
                                    %       1. threshold below which intensity will be disregarded as noise
                                    %       2. filter intensity threshold
        
        fSlice      = '';           % slice type: 'legacy', 'telecentric'. See documentation for more info.
        
        fAlpha      = [];           % alpha value(s) used in legacy focus-adjust: a=1 nominal focal plane, a<1 focuses further away, a>1 focuses closer to the camera
        
        fPlane      = [];           % z-plane(s) used in telecentric focus-adjust
        fGridX      = [];           % (x,y) grid x-axis
        fGridY      = [];           % (x,y) grid y-axis
        fLength     = [];           % main focal length
        fMag        = [];           % magnification
        
        %
        %  Perspective-adjust parameters (defaults set during construction)
        %
        pUV         = [];           % (u,v) position(s) for which to generate a perspective view; non-integer values ARE indeed supported
        
        %
        %  Other processing parameters
        %
        uvFactor    = 1;            % (u,v) supersampling factor: 1 is none, 2 = 2x SS, 4 = 4x SS, etc
        stFactor    = 1;            % (s,t) supersampling factor: 1 is none, 2 = 2x SS, 4 = 4x SS, etc
        contrast    = 'simple';     % contrast stretching style: 'simple', 'imadjust'
        mask        = 'circ';       % aperture masking of microlenses: false, 'circ'
        
        %
        %  Output configuration
        %
        saveas      = false;        % output image format: false, 'bmp', 'png', 'jpg', 'png16', 'tif16'
        display     = false;        % image display speed: false, 'slow', 'fast'
        colormap    = 'jet';        % the colormap used in displaying the image, e.g. 'jet' or 'gray'
        background  = [1 1 1];      % background color of the figure if the title is enabled, e.g. [.8 .8 .8] or [1 1 1]
        title       = false;        % title flag: FALSE for no caption, 'caption' for caption string only, 'annotation' for alpha/uv value only, 'both' for caption string + alpha/uv value
        caption     = '';           % caption string is the string used in the title for title flag of 'caption' or 'both'
        grouping    = 'image';      % directory flag: 'image' to save refocused images on a per-image basis or 'alpha' to save on a per-alpha/uv basis
        
    end%properties
    
    methods
        
        %
        %  Constructor
        %
        function q = lfiQuery( mode )
            opts = {'focus','perspective','both'};
            if nargin==1
                switch lower(mode)
                    case 'focus'
                        % Set adjust-mode to 'focus' with sensible defaults
                        q.adjust        = 'focus';
                        q.fMethod       = 'add';
                        q.fSlice        = 'legacy';
                        q.fAlpha        = 1;

                    case 'perspective'
                        % Set adjust-mode to 'perspective' with sensible defaults
                        q.adjust        = 'perspective';
                        q.pUV           = [0 0];
                        
                    case 'both'
                        error('Combined focus and perspective adjustment is currently unsupported.');
                        
                    otherwise
                        error('Bad query type provided. %s',listOpts('Query',opts));

                end
            else
                error('No query type provided. %s',listOpts('Query',opts));
            end
        end
        
        %
        %  Object set methods (alphabetical)
        %
        function obj = set.background( obj, val )
            if isnumeric(val) && isrow(val) && numel(val)==3
                obj.background = val;
            else
                error('BACKGROUND must be a 1 by 3 matrix.');
            end
        end
        
        function obj = set.caption( obj, val )
            if ischar(val)
                obj.caption = strtrim(val);
            else
                error('CAPTION must be a string.');
            end
        end
        
        function obj = set.colormap( obj, val )
            if ischar(val)
                try     feval(val);
                catch,  error('COLORMAP must be a valid colormap.');
                end
                obj.colormap = lower(val);
            else
                error('COLORMAP must be a string.');
            end
        end
        
        function obj = set.contrast( obj, val )
            opts = {'simple','imadjust'};
            if ischar(val) && any(strcmpi(val,opts))
                obj.contrast = lower(val);
            else
                error(listOpts('CONTRAST',opts));
            end
        end
        
        function obj = set.display( obj, val )
            opts = {'slow','fast'};
            if ~val
                obj.display = false;        % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.display = lower(val);
            else
                error(listOpts('DISPLAY',opts));
            end
        end
        
        function obj = set.fAlpha( obj, val )
            if isnumeric(val) && isvector(val) && all(val>0)
                obj.fAlpha = val;
            else
                error('FALPHA must be a vector of positive numbers.');
            end
        end
        
        function obj = set.fFilter( obj, val )
            if isnumeric(val) && isrow(val) && numel(val)==2
                obj.fFilter = val;
            else
                error('FFILTER must be a 1 by 2 matrix.');
            end
        end
        
        function obj = set.fGridX( obj, val )
            if isnumeric(val),  obj.fGridX = val;
            else                error('FGRIDX must be a vector or matrix.');
            end
        end
        
        function obj = set.fGridY( obj, val )
            if isnumeric(val),  obj.fGridY = val;
            else                error('FGRIDY must be a vector or matrix.');
            end
        end
        
        function obj = set.fMethod( obj, val )
            opts = {'add','mult','filt'};
            if ischar(val) && any(strcmpi(val,opts))
                obj.fMethod = lower(val);
            else
                error(listOpts('FMETHOD',opts));
            end
        end
        
        function obj = set.fLength( obj, val )
            if isnumeric(val) && numel(val)==1
                obj.fLength = val;
            else
                error('FLENGTH must be a number.');
            end
        end
        
        function obj = set.fMag( obj, val )
            if isnumeric(val) && numel(val)==1
                obj.fMag = val;
            else
                error('FMAG must be a number.');
            end
        end
        
        function obj = set.fPlane( obj, val )
            if isnumeric(val) && isvector(val)
                obj.fPlane = val;
            else
                error('FPLANE must be a vector of numbers.');
            end
        end
        
        function obj = set.fSlice( obj, val )
            opts = {'legacy','telecentric'};
            if ischar(val) && any(strcmpi(val,opts))
                obj.fSlice = lower(val);
            else
                error(listOpts('FSLICE',opts));
            end
        end
        
        function obj = set.grouping( obj, val )
            opts = {'image','alpha'};
            if ischar(val) && any(strcmpi(val,opts))
                obj.grouping = lower(val);
            else
                error(listOpts('GROUPING',opts));
            end
        end
        
        function obj = set.mask( obj, val )
            opts = {'circ'};
            if ~val
                obj.mask = false;           % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.mask = lower(val);
            else
                error(listOpts('MASK',opts));
            end
        end

        function obj = set.saveas( obj, val )
            opts = {'bmp','png','jpg','png16','tif16'};
            if ~val
                obj.saveas = false;         % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.saveas = lower(val);
            else
                error(listOpts('SAVEAS',opts));
            end
        end
        
        function obj = set.stFactor( obj, val )
            if isnumeric(val) && numel(val)==1
                obj.stFactor = uint8(val);
            else
                error('STFACTOR must be a number.');
            end
        end
        
        function obj = set.title( obj, val )
            opts = {'caption','annotation','both'};
            if ~val
                obj.title = false;          % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.title = lower(val);
            else
                error(listOpts('TITLE',opts));
            end
        end
        
        function obj = set.pUV( obj, val )
            if isnumeric(val) && size(val,2)==2
                obj.pUV = val;
            else
                error('PUV must be an M by 2 matrix.');
            end
        end
        
        function obj = set.uvFactor( obj, val )
            if isnumeric(val) && numel(val)==1
                obj.uvFactor = uint8(val);
            else
                error('UVFACTOR must be a number.');
            end
        end
        
    end%methods
    
end%classdef

function list = listOpts( var, opts )
    % Use sprintf to that error call leads to parent
    list = sprintf( '%s must be one of: %s.', var, strjoin( strcat('''',opts,''''), ', ' ) );
end
