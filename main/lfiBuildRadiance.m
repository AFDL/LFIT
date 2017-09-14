function [ lightfield ] = lfiBuildRadiance( cal, imageFile )
%LFIBUILDRADIANCE converts a plenoptic image into a 4D radiance array using the provided calibration.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


global lfitPref__useDragon, lfitPref__numThreads

%% USE DRAGON IF AVAILABLE

if lfitPref__useDragon && libisloaded('Dragon')
	DRG_buildRadiance();
	return;
end


%% IMPORT DATA AND DEFINE CONSTANTS

% Read in image data
imageData = im2double(imread(imageFile));

% Calculate microlens radius and padding
mlRadius  = floor( microPitch/pixelPitch/2 );  % REPLACE WITH `cal` FIELD
mlPadding = 1;

% Define (u,v) coordinate vectors in pixels
uVec  = single( mlRadius : -1 : -mlRadius );
vVec  = single( mlRadius : -1 : -mlRadius );

[v,u] = ndgrid(vVec,uVec);  % !!! Should this be u,v instead? Want consistent variable ordering throughout

% Define (u,v) coordinate vectors with padding
uVectPad = single( mlRadius+mlPadding : -1 : -mlRadius-mlPadding );
vVectPad = single( mlRadius+mlPadding : -1 : -mlRadius-mlPadding );


%% RESHAPE IMAGE INTO 4D ARRAY OF MICROIMAGES

fprintf('\nReshaping image into microimage stack...');
progress(0);

imStack = zeros( cal.numS,cal.numT, length(uVectPad),length(vVectPad), 'single' );

numelST = cal.numS*cal.numT;
for k=1:numelST
	[s,t]  = ind2sub( [cal.numS cal.numT], k );

	xPixel = round(cal.exactX(s,t)) - uVectPad;
	yPixel = round(cal.exactY(s,t)) - vVectPad;

	imStack(s,t,:,:) = imageData( yPixel, xPixel ).*mask;

	progress(k,numelST);
end

clear imageData, xPixel, yPixel


%% INTERPOLATE 4D ARRAY FROM DECIMAL TO INTEGER INDICES

fprintf('\nInterpolating microlens data onto a uniform (u,v) grid...');
progress(0);

radArrayRaw = zeros( numel(uVect),numel(vVect), cal.numS,cal.numT, 'single' );

% Loop through each microlens
for s = 1:cal.numS

	% Slice variables to reduce parfor overhead
	calSliceX = cal.exactX(s,:);
	calSliceY = cal.exactY(s,:);
	imSlice   = squeeze( imStack(s,:,:,:) );

	parfor ( t = 1:cal.numT, lfitPref__numThreads )

		% Calculate the distance from microlens center to the nearest pixel
		xShift = calSliceX(t) - round(calSliceX(t));
		yShift = calSliceY(t) - round(calSliceY(t));

		% Create vector of decimal (u,v) values
		uKnown = single( xShift+uVectPad );
		vKnown = single( yShift+vVectPad );

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


%% CALCULATE (s,t) RANGE

imCenterX = size(imread(imageFile),2)/2;
imCenterY = size(imread(imageFile),1)/2;

% Create s and t ranges based on median row and column
calCenterX         = median( cal.exactX(:) );
calCenterY         = median( cal.exactY(:) );

calCenterXY        = [calCenterX calCenterY];
microlensesXY(:,1) = cal.exactX(:);
microlensesXY(:,2) = cal.exactY(:);
calCenterInd       = dsearchn( microlensesXY, calCenterXY );

% Find s and t indices for the microlens closest to the center
[calCenterS,calCenterT] = ind2sub( size(cal.exactX), calCenterInd );

calLimLeft   = min( cal.exactX(:,calCenterT) );  % find the minimum x pixel value from the center row
calLimTop    = min( cal.exactY(calCenterS,:) );  % find the minimum y pixel value from the center column
calLimRight  = max( cal.exactX(:,calCenterT) );  % find the maximum x pixel value from the center row
calLimBottom = max( cal.exactY(calCenterS,:) );  % find the maximum y pixel value from the center column

sRange = linspace( calLimLeft-imCenterX, calLimRight-imCenterX, cal.numS )*pixelPitch;
tRange = linspace( calLimTop-imCenterY, calLimBottom-imCenterY, cal.numT )*pixelPitch;

clear imCenter*, calCenter*, microlensesXY, calLim*


%% RESAMPLE TO RECTANGULAR GRID

switch calType
	case 'rect'
		radArray = radArrayRaw;
   
	case 'hexa'
		fprintf('\nResampling from hexagonal to rectangular grid...');
		progress(0);

		% Hypothetical s and t ranges for a rectangular array with the same number of microlenses as in the hexagonal
		sRange = single(sRange);
		tRange = single(tRange);

		lenS   = length(sRange);
		lenT   = length(tRange);

		% Create a rectilinear sampling grid with double the horizontal
		% resolution and a vertical resolution to maintain aspect ratio.
		sSSRange = linspace( sRange(1), sRange(end), 2*length(sRange) );
		tSSRange = tRange(1) : mean(diff(sSSRange)) : tRange(end);

		% Create supersampled radiance array
		radArray = zeros( length(uVect),length(vVect), length(sSSRange),length(tRange), 'single' );

%		% Interpolation weights for four-point method
%		wt4a     = 1/( 2 + 1*sqrt(3) );
%		wt4b     = 1/( 2 + 4/sqrt(3) );

		% Does the first row overhang?
		oh0      = ( cal.exactX(1,1) < cal.exactX(1,2) );

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
				radArrayRaw( :,:, sInd+1,tInd )*0.5 + ...  % East
				radArrayRaw( :,:, sInd,tInd )*0.5;         % West

%			% Right: between lenses, use four-point method
%			radArray( :,:, 2*sInd-oh+1,tInd ) = ...
%				radArrayRaw( :,:, sInd+1,tInd-1 )*wt4a + ...  % North
%				radArrayRaw( :,:, sInd+1,tInd )*wt4b + ...    % East
%				radArrayRaw( :,:, sInd+1,tInd+1 )*wt4a + ...  % South
%				radArrayRaw( :,:, sInd,tInd )*wt4b;           % West

			% Timer logic
			progress(tInd,lenT);

		end

		% Now supersample vertically to maintain aspect ratio
		[g1u g1v g1s g1t] = ndgrid( uVect,vVect, sSSRange,tRange );
		[g2u g2v g2s g2t] = ndgrid( uVect,vVect, sSSRange,tSSRange );
		radArray = interpn( g1u,g1v,g1s,g1t, radArray, g2u,g2v,g2s,g2t, 'linear',0 );

		% Complete
		progress(1,1);

		% Overwrite (s,t) with the newly supersampled (s,t). Any later
		% supersampling will be in addition to this.
		sRange = sSSRange;
		tRange = tSSRange;

end%switch


%% STRUCTURE OUTPUT DATA

% We can't use radArray without sRange and tRange, so they may as well be
% packaged together.

lightfield.rad = radArray;
lightfield.s   = sRange;
lightfield.t   = tRange;


end%function
