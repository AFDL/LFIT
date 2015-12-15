function [radArray,sRange,tRange] = interpimage2(calData,imagePath,calType,microPitch,pixelPitch,numMicroX,numMicroY)
%INTERPIMAGE2 Generates the plaid radArray of intensities for a given image
%
%	Uses input calibration data to extract microimages from the raw image,
%	interpolating them onto a plaid grid in a 4D matrix (radArray).

% From the calibration data set
% This should really be a structure --cjc
centers     = calData{1};
xPoints     = calData{2}; % used in visualization/debugging
yPoints     = calData{3}; % used in visualization/debugging
kMax        = calData{4};
lMax        = calData{5}; % note that the notation is lowercase letter "L" max, not the number "1" max

% Read in image data
imageData   = im2double(imread(imagePath));
imWidth     = size(imageData,2);
imHeight    = size(imageData,1);

% Calculate microlens radius in pixels
microRadius = floor((microPitch/pixelPitch)/2); % removed -1; should be 8 for rectangular and 7 for hexagonal now. Note that this is the 'x' microPitch.

% Calculate actual pitch between microlenses in x and y directions for (s,t) range calculations (especially hexagonal case)
microPitchX = size(imageData,2)/numMicroX*pixelPitch;
microPitchY = size(imageData,1)/numMicroY*pixelPitch;

% Define max extent of i and j

% Define u and v coordinate vectors in pixels
uVect       = (microRadius:-1:-microRadius);
vVect       = (microRadius:-1:-microRadius);

% Define padding
interpPadding = 1;

% Define u and v coordinate system vectors, padded by 1 pixel on each side.
uVectPad    = (microRadius+interpPadding:-1:-microRadius-interpPadding);
vVectPad    = (microRadius+interpPadding:-1:-microRadius-interpPadding);

[v,u]       = ndgrid(vVect,uVect);

% Preallocate matrix
radArrayRaw = zeros( numel(vVect),numel(uVect), kMax,lMax, 'single' );

% Initialize timer and update command line
num=0;
fprintf('\nInterpolating image data onto a uniform (u,v) grid...');
fprintf('\n   Time remaining:           ');

% Loop through each microlens
for k=1:kMax % column
    
    time=tic;
    
    for l=1:lMax % row % careful! It's for L = ONE : L MAX
        
        % Read in center in pixel coordinates at the current microlens from the calibration data
        xExact = centers(l,k,1);
        yExact = centers(l,k,2);
        
        % Round the centers in order to prepare vectors for extracting a small grid of image data.
        % These use the padded vectors to extract a slightly larger window to account for any NaN cropping
        % in the interpn step below, depending on the interpolation method used.
        xPixel = round(xExact) - uVectPad; %uVect is negative here so that Ihat below pulls from imageData from left to right (without flipping anything)
        yPixel = round(yExact) - vVectPad; %vVect is negative here so that Ihat below pulls from imageData from top to bottom (without flipping anything)
        
        % uhat and vhat are our known u,v coordinates which correspond to the u,v values of the small window of pixels we are extracting
        uKnown = xExact - xPixel;
        vKnown = yExact - yPixel;
        
        % Grid the coordinate vectors (via ndgrid as required for interpn)
        [vKnownGrid,uKnownGrid] = ndgrid(vKnown,uKnown);
        
        % Extract microimage (grid of pixels/intensities behind the given microlens)
        extractedI = imageData(yPixel,xPixel); % MATLAB indexing works via array(row,col) so be careful!
        
        % Window out data in square about circular aperture
        switch calType
            case 'rect',    apertureFlag = 0; %allow the full square in
            case 'hexa',    apertureFlag = 1; %allow only in the circular portion of the microimage to window out the overlap
        end
        
        switch apertureFlag
            case 0 % Square/Full aperture
                circMask = ones( 1 + 2*(microRadius+interpPadding) );
                
            case 1 % Circular mask close
                circMask = zeros( 1 + 2*(microRadius+interpPadding) );
                circMask(1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding) = fspecial( 'disk', double(microRadius) ); %interpPadding here makes circMask same size as u,v dimensions of radArray
                circMask = ( circMask - min(circMask(:)) )/( max(circMask(:)) - min(circMask(:)) );
                
            case 2 % Circular mask wider
                circMask = fspecial( 'disk', double(microRadius+interpPadding) ); %interpPadding here makes circMask same size as u,v dimensions of radArray
                circMask = ( circMask - min(circMask(:)) )/( max(circMask(:)) - min(circMask(:)) );
                
            otherwise
                error('Aperture flag defined incorrectly. Check request vector.');
                
        end
        
        extractedI = extractedI.*circMask;
        
        % Interpolate. 
        % We know the pixel intensities at (decimal) u,v locations. 
        % Thus, we interpolate to get intensities at uniform/integer u,v locations.
        I = interpn( vKnownGrid,uKnownGrid, extractedI, v,u, 'linear' );
        I( I<0 ) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.

        % Note generally how I is indexed I(v,u) or I(row,col).
        % Thus, if we're going to store this in a matrix indexed by (i,j,k,l), we must account for this.
        Ip = permute(I,[2 1]);
        
        % Store data in temporary raw radArray
        radArrayRaw(:,:,k,l) = single(Ip); %store as single
        
    end%for
    
    % Timer logic
    time=toc(time);
    timerVar=time/60*((kMax-k));
    
    if timerVar>=1
        timerVar=round(timerVar);
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g m',timerVar)
    else
        timerVar=round(time*((kMax-k)));
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g s',timerVar)
    end
    
end%for
fprintf('\n   Complete.\n');

% Calculate sRange and tRange (in mm)
[sRange,tRange] = computestrange(calData,imagePath,microPitchX,microPitchY,pixelPitch);

% If it's a hexagonal array, resample onto a rectilinear grid
switch calType
    case 'rect'
        % Nothing to do
   
    case 'hexa'
        
        fprintf('\nResampling onto rectilinear grid from hexagonal array...');
        
        % Hypothetical s and t ranges for a rectangular array with the same number of microlenses as in the hexagonal
        sRange      = single(sRange);
        tRange      = single(tRange);
        
        lenS        = length(sRange);
        lenT        = length(tRange);
        
        % Create a rectilinear sampling grid with precisely double the
        % resolution in both s and t
        sSSRange    = linspace( sRange(1), sRange(end), 2*length(sRange) );
        tSSRange    = linspace( tRange(1), tRange(end), 2*length(tRange) );
        
        % Create supersampled radiance array
        radArray    = zeros( length(uVect),length(vVect), length(sSSRange),length(tSSRange), 'single' );

        % Interpolation weights
        wt4a        = 1/( 2 + 2*sqrt(3) );
        wt4b        = 1/( 2 + 2/sqrt(3) );
        wt3a        = 1/( 1 + 2*sqrt(3/7) );
        wt3b        = 1/( 2 + 1*sqrt(7/3) );
        
        % Loop through the raw grid, copying data to the supersampled grid
        % as appropriate
        ov = 1;     % First row should always overhang due to calibration
        for tInd = 2:lenT-1
            
            % Vectorize along s (no sense in looping)
            sInd = 1:lenS-1;
                
            % Center: perfect alignment, copy data from raw to SS
            radArray( :,:, 2*sInd-ov,2*tInd ) = ...
                radArrayRaw( :,:, sInd,tInd );

            % Right: between lenses, use four point interpolation
            radArray( :,:, 2*sInd-ov+1,2*tInd ) = ...
                radArrayRaw( :,:, sInd+1,tInd-1 )*wt4a + ...    % North
                radArrayRaw( :,:, sInd+1,tInd )*wt4b + ...      % East
                radArrayRaw( :,:, sInd+1,tInd+1 )*wt4a + ...    % South
                radArrayRaw( :,:, sInd,tInd )*wt4b;             % West

            % Bottom: below lens, use upward-pointing triangle
            radArray( :,:, 2*sInd-ov,2*tInd+1 ) = ...
                radArrayRaw( :,:, sInd,tInd )*wt3a + ...        % North
                radArrayRaw( :,:, sInd+1,tInd+1 )*wt3b + ...    % South-East
                radArrayRaw( :,:, sInd,tInd+1 )*wt3b;           % South-West

            % Bottom-right: above another lens, use downward-pointing triangle
            radArray( :,:, 2*sInd-ov+1,2*tInd+1 ) = ...
                radArrayRaw( :,:, sInd+1,tInd )*wt3b + ...      % North-East
                radArrayRaw( :,:, sInd+1,tInd+1 )*wt3a + ...    % South
                radArrayRaw( :,:, sInd,tInd )*wt3b;             % North-West
            
            ov = 1-ov;
            
        end

        % Overwrite s and t ranges with the appropriate supersampled s and t ranges (since we've supersampled up front in this function, we need to make the
        % other functions think that the supersampled ranges are normal. Of course, this means any supersampling applied in later functions will be in addition
        % to the supersampling already applied here.
        sRange = sSSRange;
        tRange = tSSRange;
        fprintf('\n   Complete.\n');
        
end%switch

end%function
