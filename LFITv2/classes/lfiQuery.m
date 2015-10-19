classdef lfiQuery
    %LFIQUERY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        adjust      = '';       % Reconstruction type: 'focus', 'perspective'
        
        % Focus-adjust parameters
        alpha       = [];       % alpha value used in refocusing; a=1 nominal focal plane; a<1 focuses further away; a>1 focuses closer to the camera
        refocus     = '';       % refocus type: 'add', 'mult', 'filt'
        filter      = [];       % filter parameters (does nothing if REFOCUS isn't 'filt')
                                %       1. threshold below which intensity will be disregarded as noise
                                %       2. filter intensity threshold
        magnification = '';     % magnification type: 'legacy', 'telecentric'. See documentation for more info.
        
        % Perspective-adjust parameters
        uv          = [];       % (u,v) position for which to generate a perspective view; non-integer values ARE indeed supported
        
        % Other processing parameters
        uvFactor    = 1;        % supersampling factor in (u,v) is an integer by which to supersample: 1 is none, 2 = 2x SS, 4 = 4x SS, etc
        stFactor    = 1;        % supersampling factor in (s,t) is an integer by which to supersample: 1 is none, 2 = 2x SS, 4 = 4x SS, etc
        contrast    = 'simple'; % contrast stretching style: 'simple', 'imadjust'
        aperture    = 'full';   % aperture enforcing of microlenses: 'full', 'circ'
        
        % Output configuration
        saveas      = false;    % output image format: false, 'bmp', 'png', 'jpg', 'png16', 'tif16'
        display     = false;    % image display speed: false, 'slow', 'fast'
        colormap    = 'jet';    % the colormap used in displaying the image, eg 'jet' or 'gray'
        background  = [1 1 1];  % background color of the figure if the title is enabled, eg [.8 .8 .8] or [1 1 1]
        title       = false;    % title flag: FALSE for no caption, 'caption' for caption string only, 'annotation' for alpha/uv value only, 'both' for caption string + alpha/uv value
        caption     = '';       % caption string is the string used in the title for title flag of 'caption' or 'both'
        grouping    = 'image';  % directory flag: 'image' to save refocused images on a per-image basis or 'alpha' to save on a per-alpha/uv basis
        
    end%properties
    
    methods
        
        %
        % Constructor
        %
        function q = lfiQuery( mode )
            if nargin==1
                switch lower(mode)
                    case 'focus'
                        % Set adjust-mode to 'focus' with sensible defaults
                        q.adjust        = 'focus';
                        q.alpha         = 1;
                        q.refocus       = 'add';
                        q.magnification = 'legacy';

                    case 'perspective'
                        % Set adjust-mode to 'perspective' with sensible defaults
                        q.adjust        = 'perspective';
                        q.uv            = [0 0];
                        
                    otherwise
                        error('Bad query type provided. Query type must be FOCUS or PERSPECTIVE.');

                end
            else
                error('No query type provided. Query type must be FOCUS or PERSPECTIVE.');
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
                obj.aperture = lower(val);
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
            if isstring(val)
                obj.caption = val;
            else
                error('CAPTION must be a string.');
            end
        end
        
        function obj = set.colormap( obj, val )
            if isstring(val)
                try
                    h = figure; colormap(val); close(h);
                    obj.colormap = lower(val);
                catch
                    error('COLORMAP must be a valid colormap.');
                end
            else
                error('COLORMAP must be a string.');
            end
        end
        
        function obj = set.contrast( obj, val )
            opts = {'simple','imadjust'};
            if istring(val) && any(strcmpi(val,opts))
                obj.contrast = lower(val);
            else
                error('CONTRAST must be one of: .');
            end
        end
        
        function obj = set.display( obj, val )
            opts = {'slow','fast'};
            if ~val
                obj.display = false;        % Enforce FALSE over 0
            elseif istring(val) && any(strcmpi(val,opts))
                obj.display = lower(val);
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
                obj.grouping = lower(val);
            else
                error('GROUPING must be one of: .');
            end
        end
           
        function obj = set.magnification( obj, val )
            opts = {'legacy','telecentric'};
            if istring(val) && any(strcmpi(val,opts))
                obj.magnification = lower(val);
            else
                error('MAGNIFICATION must be one of: .');
            end
        end
        
        function obj = set.refocus( obj, val )
            opts = {'add','mult','filt'};
            if istring(val) && any(strcmpi(val,opts))
                obj.caption = lower(val);
            else
                error('REFOCUS must be one of: .');
            end
        end


        function obj = set.saveas( obj, val )
            opts = {'bmp','png','jpg','png16','tif16'};
            if ~val
                obj.saveas = false;         % Enforce FALSE over 0
            elseif istring(val) && any(strcmpi(val,opts))
                obj.saveas = lower(val);
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
            opts = {'caption','annotation','both'};
            if ~val
                obj.title = false;          % Enforce FALSE over 0
            elseif istring(val) && any(strcmpi(val,opts))
                obj.title = lower(val);
            else
                error('CAPTION must be one of: .');
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
