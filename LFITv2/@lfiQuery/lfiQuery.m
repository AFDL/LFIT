classdef lfiQuery
%LFIQUERY Creates a light field image (lfi) reconstruction query.
%
% Use this function to craft a query to be used with GENREFOCUS or
% PERSPECTIVEGEN. The user must create a new query, selecting either focus
% or perspective as the reconstruction type. Then the user may (optionally)
% refine the query by specifying reconstruction parameters.
%
% Example:
%   q = lfiQuery('focus');
%   q.fMethod = 'add';
%   q.fAlpha  = 1.02;
%   q.verify();
%
% See also: GENREFOCUS, PERSPECTIVEGEN

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


    properties (SetAccess=immutable)

        adjust      = '';           % reconstruction type: 'focus', 'perspective', 'both'

    end%properties

    properties

        %
        %  Focus-adjust parameters (defaults set during construction)
        %
        fMethod     = '';           % focus-adjust method: 'add', 'mult', 'filt'
        fFilter     = [];           % filter parameters (does nothing if METHOD isn't 'filt')
                                    %       1. threshold below which intensity will be disregarded as noise
                                    %       2. filter intensity threshold

        fZoom       = '';           % zoom type: 'legacy', 'telecentric'. See documentation for more info.

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
        contrast    = 'none';       % contrast stretching style: false, 'none', 'slice', 'stack'
        intensity   = [0 1];        % imadjust limits
        mask        = 'circ';       % aperture masking of microlenses: false, 'circ'
        
        %
        %  Output configuration
        %
        saveas      = false;        % output image format: false, 'bmp', 'png', 'jpg', 'png16', 'tif16', 'gif', 'avi', 'mp4'
        quality     = [];           % output quality, only applies to JPG, AVI, and MP4
        codec       = '';           % output codec, only applies to AVI and MP4
        framerate   = [];           % output framerate, only applies to GIF, AVI, and MP4
        display     = false;        % image display speed: false, 'slow', 'fast'
        colormap    = 'gray';       % the colormap used in displaying the image, e.g. 'jet' or 'gray'
        background  = [1 1 1];      % background color of the figure if the title is enabled, e.g. [.8 .8 .8] or [1 1 1]
        title       = false;        % title flag: FALSE for no caption, 'caption' for caption string only, 'annotation' for alpha/uv value only, 'both' for caption string + alpha/uv value
        caption     = '';           % caption string is the string used in the title for title flag of 'caption' or 'both'
        grouping    = 'image';      % directory grouping: 'image' to save on a per-image basis or 'alpha' to save on a per-alpha basis

    end%properties

    methods

        %
        %  Constructor
        %
        function q = lfiQuery( mode )
            opts = {'focus','perspective','both'};
            if nargin==1
                switch lower(mode)
                    case {'focus','foc','f'}
                        % Set adjust-mode to 'focus' with sensible defaults
                        q.adjust        = 'focus';
                        q.fMethod       = 'add';
                        q.fZoom         = 'legacy';
                        q.fAlpha        = 1;

                    case {'perspective','persp','per','p'}
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
            if isnumeric(val) && isvector(val) && numel(val)==3
                obj.background = reshape(val,1,[]);     % Enforce row vector
            else
                error('BACKGROUND must a vector of length 3.');
            end
        end

        function obj = set.caption( obj, val )
            if ischar(val)
                obj.caption = strtrim(val);
            else
                error('CAPTION must be a string.');
            end
        end

        function obj = set.codec( obj, val )
            opts = {'uncompressed','jpeg','jpeg2000','jpeg2000-lossless','h264','gif'};
            if isempty(val)
                obj.codec = '';
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.codec = lower(val);
            else
                error(listOpts('CODEC',opts));
            end
        end

        function obj = set.colormap( obj, val )
            if ischar(val)
                try     feval(val,256);
                catch,  error('COLORMAP must be a valid colormap.');
                end
                obj.colormap = lower(val);
            else
                error('COLORMAP must be a string.');
            end
        end

        function obj = set.contrast( obj, val )
            opts = {'none','slice','stack'};
            if ~val
                obj.contrast = false;               % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.contrast = lower(val);
            else
                error(listOpts('CONTRAST',opts));
            end
        end
        
        function obj = set.intensity( obj, val )
            if isempty(val)
                obj.intensity = [];
            elseif isnumeric(val) && isvector(val)
                obj.intensity = reshape(val,[],1);     % Primary variable, enforce column vector
            else
                error('INTENSITY must be vector of length 2.');
            end
        end

        function obj = set.display( obj, val )
            opts = {'slow','fast'};
            if ~val
                obj.display = false;                % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.display = lower(val);
            else
                error(listOpts('DISPLAY',opts));
            end
        end

        function obj = set.fAlpha( obj, val )
            if isempty(val)
                obj.fAlpha = [];
            elseif isnumeric(val) && isvector(val) && all(val>0)
                obj.fAlpha = reshape(val,[],1);     % Primary variable, enforce column vector
            else
                error('FALPHA must be a vector of positive numbers.');
            end
        end

        function obj = set.fFilter( obj, val )
            if isempty(val)
                obj.fFilter = [];
            elseif isnumeric(val) && isvector(val) && numel(val)==2
                obj.fFilter = reshape(val,1,[]);    % Enforce row vector
            else
                error('FFILTER must be vector of length 2.');
            end
        end

        function obj = set.fGridX( obj, val )
            if isempty(val)
                obj.fGridX = [];
            elseif isnumeric(val) && isvector(val)
                obj.fGridX = reshape(val,1,[]);     % Enforce row vector
            else
                error('FGRIDX must be a vector.');
            end
        end

        function obj = set.fGridY( obj, val )
            if isempty(val)
                obj.fGridY = [];
            elseif isnumeric(val) && isvector(val)
                obj.fGridY = reshape(val,1,[]);     % Enforce row vector
            else
                error('FGRIDY must be a vector.');
            end
        end

        function obj = set.fMethod( obj, val )
            opts = {'add','mult','filt'};
            if isempty(val)
                obj.fMethod = '';
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.fMethod = lower(val);
            else
                error(listOpts('FMETHOD',opts));
            end
        end

        function obj = set.fLength( obj, val )
            if isempty(val)
                obj.fLength = [];
            elseif isnumeric(val) && numel(val)==1
                obj.fLength = val;
            else
                error('FLENGTH must be a number.');
            end
        end

        function obj = set.fMag( obj, val )
            if isempty(val)
                obj.fMag = [];
            elseif isnumeric(val) && numel(val)==1
                obj.fMag = val;
            else
                error('FMAG must be a number.');
            end
        end

        function obj = set.fPlane( obj, val )
            if isempty(val)
                obj.fPlane = [];
            elseif isnumeric(val) && isvector(val)
                obj.fPlane = reshape(val,[],1);     % Primary variable, enforce column vector
            else
                error('FPLANE must be a vector.');
            end
        end

        function obj = set.framerate( obj, val )
            if isnumeric(val) && numel(val)==1
                obj.framerate = val;
            else
                error('FRAMERATE must be a number.');
            end
        end

        function obj = set.fZoom( obj, val )
            opts = {'legacy','telecentric'};
            if isempty(val)
                obj.fZoom = '';
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.fZoom = lower(val);
            else
                error(listOpts('FZOOM',opts));
            end
        end

        function obj = set.grouping( obj, val )
            opts = {'image','alpha','stack'};
            if ischar(val) && any(strcmpi(val,opts))
                obj.grouping = lower(val);
            else
                error(listOpts('GROUPING',opts));
            end
        end

        function obj = set.mask( obj, val )
            opts = {'circ'};
            if ~val
                obj.mask = false;                   % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.mask = lower(val);
            else
                error(listOpts('MASK',opts));
            end
        end

        function obj = set.saveas( obj, val )
            opts = { ...
                'bmp','png','jpg','png16','tif16', ...      % Still images
                'gif','avi','mp4' ...                       % Animation/movie
                };
            if ~val
                obj.saveas = false;                 % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.saveas = lower(val);
            else
                error(listOpts('SAVEAS',opts));
            end
        end

        function obj = set.stFactor( obj, val )
            if isnumeric(val) && numel(val)==1 && val>=1
                obj.stFactor = round(val);
            else
                error('STFACTOR must be a positive integer.');
            end
        end

        function obj = set.title( obj, val )
            opts = {'caption','annotation','both'};
            if ~val
                obj.title = false;                  % Enforce FALSE over 0
            elseif ischar(val) && any(strcmpi(val,opts))
                obj.title = lower(val);
            else
                error(listOpts('TITLE',opts));
            end
        end

        function obj = set.pUV( obj, val )
            if isnumeric(val) && ismatrix(val) && size(val,2)==2
                obj.pUV = val;                      % Primary variable, two column vectors
            else
                error('PUV must be an M by 2 matrix.');
            end
        end

        function obj = set.quality( obj, val )
            if isnumeric(val) && numel(val)==1 && val>=0 && val<=100
                obj.quality = round(val);
            else
                error('QUALITY must be an integer between 0 and 100.')
            end
        end

        function obj = set.uvFactor( obj, val )
            if isnumeric(val) && numel(val)==1 && val>=1
                obj.uvFactor = round(val);
            else
                error('UVFACTOR must be a positive integer.');
            end
        end

    end%methods

end%classdef

function list = listOpts( var, opts )
    % Use sprintf so that error call leads to parent
    list = sprintf( '%s must be one of: %s.', var, strjoin( strcat('''',opts,''''), ', ' ) );
end
