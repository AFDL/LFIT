function [radArray,sRange,tRange] = interpimage2(cal,imagePath,calType,microPitch,pixelPitch,numMicroX,numMicroY)
%INTERPIMAGE2 Generates the plaid radArray of intensities for a given image.
%
% Uses input calibration data to extract microimages from the raw image,
% interpolating them onto a plaid grid in a 4D matrix (radArray).

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


%% IMPORT DATA AND DEFINE CONSTANTS

% Read in image data
imageData   = im2double(imread(imagePath));

% Calculate microlens radius and padding
microRadius = floor((microPitch/pixelPitch)/2); % removed -1; should be 8 for rectangular and 7 for hexagonal now. Note that this is the 'x' microPitch.
microPad    = 1;

% Define (u,v) coordinate vectors in pixels
uVect       = single( microRadius : -1 : -microRadius );
vVect       = single( microRadius : -1 : -microRadius );

[v,u]       = ndgrid(vVect,uVect);

% Define (u,v) coordinate vectors with padding
uVectPad    = single( microRadius+microPad : -1 : -microRadius-microPad );
vVectPad    = single( microRadius+microPad : -1 : -microRadius-microPad );

% Define aperture mask
switch calType
    case 'rect',    apertureFlag = 0; %allow the full square in
    case 'hexa',    apertureFlag = 1; %allow only in the circular portion of the microimage to window out the overlap
end
switch apertureFlag
    case 0 % Square/Full aperture
        mask = ones( 1 + 2*(microRadius+microPad) );

    case 1 % Circular mask close
        mask = zeros( 1 + 2*(microRadius+microPad) );
        mask(1+microPad:end-microPad,1+microPad:end-microPad) = fspecial( 'disk', double(microRadius) ); %interpPadding here makes circMask same size as u,v dimensions of radArray
        mask = ( mask - min(mask(:)) )/( max(mask(:)) - min(mask(:)) );

    case 2 % Circular mask wider
        mask = fspecial( 'disk', double(microRadius+microPad) ); %interpPadding here makes circMask same size as u,v dimensions of radArray
        mask = ( mask - min(mask(:)) )/( max(mask(:)) - min(mask(:)) );

    otherwise
        error('Aperture flag defined incorrectly. Check request vector.');

end


%% RESHAPE IMAGE INTO 4D ARRAY OF MICROIMAGES

fprintf('\nReshaping image into microimage stack...');
progress(0);

imStack = zeros( cal.numS,cal.numT, length(uVectPad),length(vVectPad), 'single' );

numelST = cal.numS*cal.numT;
for k=1:numelST
    [s,t]   = ind2sub( [cal.numS cal.numT], k );
    
    xPixel  = round(cal.exactX(s,t)) - uVectPad;
    yPixel  = round(cal.exactY(s,t)) - vVectPad;
    
    imStack(s,t,:,:) = imageData( yPixel, xPixel ).*mask;
    
    progress(k,numelST);
end

clear imageData


%% INTERPOLATE 4D ARRAY FROM DECIMAL TO INTEGER INDICES

fprintf('\nInterpolating microlens data onto a uniform (u,v) grid...');
progress(0);

radArrayRaw = zeros( numel(uVect),numel(vVect), cal.numS,cal.numT, 'single' );

% Loop through each microlens
for s = 1:cal.numS
    
    % Slice variables to reduce parfor overhead
    calSliceX   = cal.exactX(s,:);
    calSliceY   = cal.exactY(s,:);
    imSlice     = squeeze( imStack(s,:,:,:) );
    
    parfor ( t = 1:cal.numT, Inf )
        
     	% Calculate the distance from microlens center to the nearest pixel
        xShift  = calSliceX(t) - round(calSliceX(t));
        yShift  = calSliceY(t) - round(calSliceY(t));
        
        % Create vector of decimal (u,v) values
        uKnown  = single( xShift+uVectPad );
        vKnown  = single( yShift+vVectPad );
        
        [vKnown,uKnown] = ndgrid(vKnown,uKnown);
        
        % Interpolate from decimal (u,v) to integer (u,v)
        I = interpn( vKnown,uKnown, squeeze(imSlice(t,:,:)), v,u, 'linear' );
        I( I<0 ) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.

        % Note generally how I is indexed I(v,u) or I(row,col).
        % Thus, if we're going to store this in a matrix indexed by (u,v,s,t), we must account for this.
        radArrayRaw(:,:,s,t) = permute(I,[2 1]);
        
    end%parfor
    
    % Timer logic
    progress(s,cal.numS);
    
end%for

% Calculate sRange and tRange (in mm)
[sRange,tRange] = computestrange(cal,imagePath,pixelPitch);


%% RESAMPLE TO RECTANGULAR GRID

switch calType
    case 'rect'
        radArray    = radArrayRaw;
   
    case 'hexa'
        
        fprintf('\nResampling from hexagonal to rectangular grid...');
        progress(0);
        
        % Hypothetical s and t ranges for a rectangular array with the same number of microlenses as in the hexagonal
        sRange      = single(sRange);
        tRange      = single(tRange);
        
        lenS        = length(sRange);
        lenT        = length(tRange);
        
        % Create a rectilinear sampling grid with double the horizontal
        % resolution and a vertical resolution to maintain aspect ratio.
        sSSRange    = linspace( sRange(1), sRange(end), 2*length(sRange) );
        tSSRange    = tRange(1) : mean(diff(sSSRange)) : tRange(end);
        
        % Create supersampled radiance array
        radArray    = zeros( length(uVect),length(vVect), length(sSSRange),length(tRange), 'single' );

%         % Interpolation weights for four-point method
%         wt4a        = 1/( 2 + 1*sqrt(3) );
%         wt4b        = 1/( 2 + 4/sqrt(3) );
        
        % Does the first row overhang?
        oh0         = ( cal.exactX(1,1) < cal.exactX(1,2) );
        
        % Loop through the raw grid, supersampling horizontally
        for tInd = 2:lenT-1
            
            % Does this row overhang?
            oh = 1-mod(oh0+tInd,2);
            
            % Vectorize along s (no reason to loop)
            sInd = 1:lenS-1;
                
            % Center: perfect alignment, copy data from raw to SS
            radArray( :,:, 2*sInd-oh,tInd ) = ...
                radArrayRaw( :,:, sInd,tInd );
            
            % Right: between lenses, use two-point method
            radArray( :,:, 2*sInd-oh+1,tInd ) = ...
                radArrayRaw( :,:, sInd+1,tInd )*0.5 + ...   	% East
                radArrayRaw( :,:, sInd,tInd )*0.5;              % West

%             % Right: between lenses, use four-point method
%             radArray( :,:, 2*sInd-oh+1,tInd ) = ...
%                 radArrayRaw( :,:, sInd+1,tInd-1 )*wt4a + ...    % North
%                 radArrayRaw( :,:, sInd+1,tInd )*wt4b + ...      % East
%                 radArrayRaw( :,:, sInd+1,tInd+1 )*wt4a + ...    % South
%                 radArrayRaw( :,:, sInd,tInd )*wt4b;             % West
            
            % Timer logic
            progress(tInd,lenT);
            
        end
        
        % Now supersample vertically to maintain aspect ratio
        [g1u g1v g1s g1t] = ndgrid( uVect,vVect, sSSRange,tRange );
        [g2u g2v g2s g2t] = ndgrid( uVect,vVect, sSSRange,tSSRange );
        radArray = interpn( g1u,g1v,g1s,g1t, radArray, g2u,g2v,g2s,g2t, 'linear',0 );
        
        % Complete
        progress(1,1);

        % Overwrite s and t ranges with the appropriate supersampled s and t ranges (since we've supersampled up front in this function, we need to make the
        % other functions think that the supersampled ranges are normal. Of course, this means any supersampling applied in later functions will be in addition
        % to the supersampling already applied here.
        sRange = sSSRange;
        tRange = tSSRange;
        
end%switch

end%function
