function [ stack ] = lfiExtractPlane( query, lightfield )
%LFIEXTRACTPLANE

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nExtracting focal planes...');
progress(0);













global sizePixelAperture;  % (si*pixelPitch)/focLenMicro;





interpPadding = single(1);  % HARDCODED; if the padding in interpimage2.m changes, change this accordingly.
microRadius   = single( floor(size(radArray,1)/2) - interpPadding );  % since we've padded the extracted data by a pixel in interpimage2, subtract 1


%% Determine supersampling factor

if strcmpi( query.fZoom, 'telecentric' );
	SS_UV = 1;
	SS_ST = 1;
else
	SS_UV = query.uvFactor;
	SS_ST = query.stFactor;
end


%% Define aperture mask (if any)

if strcmpi( query.mask, 'circ' )
	% Circular mask
	mask = fspecial( 'disk', double(microRadius)*SS_UV );
	mask = ( mask - min(mask(:)) )/( max(mask(:)) - min(mask(:)) );
else
	% No mask
	mask = ones( 1 + 2*SS_UV*microRadius );
end


%% Create (u,v) and (s,t) arrays

sizeS  = length(lightfield.s)*SS_ST;
sizeT  = length(lightfield.t)*SS_ST;

uRange = linspace( microRadius, -microRadius, 1+2*microRadius );
vRange = linspace( microRadius, -microRadius, 1+2*microRadius );

uSlightfield.s = linspace( microRadius, -microRadius, 1+2*SS_UV*microRadius );
vSlightfield.s = linspace( microRadius, -microRadius, 1+2*SS_UV*microRadius );
sSlightfield.s = linspace( lightfield.s(1), lightfield.s(end), sizeS );
tSlightfield.s = linspace( lightfield.t(1), lightfield.t(end), sizeT );


%% Memory preallocation

switch query.fZoom
	case 'legacy'
		imageProduct  =  ones( sizeT, sizeS, 'single' );
		imageIntegral = zeros( sizeT, sizeS, 'single' );
		filterMatrix  = zeros( sizeT, sizeS, 'single' );

	case 'telecentric'
		imageProduct  =  ones( length(query.fGridY), length(query.fGridX), 'single' );
		imageIntegral = zeros( length(query.fGridY), length(query.fGridX), 'single' );
		filterMatrix  = zeros( length(query.fGridY), length(query.fGridX), 'single' );

end%switch


%% Determine which algorithm to use

if SS_ST == 1
	if SS_UV == 1, superSampling = 'none';
	else           superSampling = 'uv';
	end
else
	if SS_UV == 1, superSampling = 'st';
	else           superSampling = 'both';
	end
end


%% Primary loop

switch superSampling
	case {'none','st'}

		% Crop and reshape 4D-array to optimize parfor performance
		radArray = radArray( 1+interpPadding:end-interpPadding, 1+interpPadding:end-interpPadding, :, : );
		radArray = permute( radArray, [2 1 4 3] );
		radArray = reshape( radArray, size(radArray,1)*size(radArray,2), size(radArray,3), size(radArray,4) );

		[sActual,tActual] = meshgrid( lightfield.s, lightfield.t );
		[uActual,vActual] = meshgrid( uRange*sizePixelAperture, vRange*sizePixelAperture );

		numelUV = numel(uActual);

		parfor ( uvIdx = 1:numelUV, Inf )

			if mask(uvIdx) > 0  % if mask pixel is not zero, calculate.

				sQuery=0; tQuery=0;  % To avoid warnings

				switch query.fZoom
					case 'legacy'
						sQuery  = sActual + uActual(uvIdx)*(query.fAlpha - 1);
						tQuery  = tActual + vActual(uvIdx)*(query.fAlpha - 1);

					case 'telecentric'
						si      = ( 1 - query.fMag )*query.fLength;
						so      = -si/query.fMag;
						soPrime = so + query.fPlane;
						siPrime = (1/query.fLength - 1/soPrime)^(-1);
						MPrime  = siPrime/soPrime;

						alpha   = siPrime/si;

						sQuery  = query.fGridX*MPrime/alpha + uActual(uvIdx)*(1 - 1/alpha);
						tQuery  = query.fGridY*MPrime/alpha + vActual(uvIdx)*(1 - 1/alpha);
						[sQuery,tQuery] = meshgrid( sQuery, tQuery );

				end%switch

				extractedImageTemp = interp2( lightfield.s,lightfield.t, squeeze(radArray(uvIdx,:,:)), sQuery,tQuery, '*linear',0 );

				switch query.fMethod
					case 'add'
						extractedImageTemp = extractedImageTemp*mask(uvIdx);
						imageIntegral      = imageIntegral + extractedImageTemp;

					case 'mult'
						extractedImageTemp = gray2ind(extractedImageTemp,65536);
						extractedImageTemp = double(extractedImageTemp) + .0001;
						extractedImageTemp = extractedImageTemp.^(1/numelUV*mask(uvIdx));
						imageProduct       = imageProduct .* extractedImageTemp;

					case 'filt'
						extractedImageTemp = gray2ind(extractedImageTemp,65536);
						extractedImageTemp = double(extractedImageTemp);
						extractedImageTemp = extractedImageTemp*mask(uvIdx);
						filterMatrix       = filterMatrix + ( extractedImageTemp>query.fFilter(1) );
						imageIntegral      = imageIntegral + extractedImageTemp;

				end%switch

			end%if

		end%parfor

		switch query.fMethod  % PARFOR requires two reduction variables, here we choose which to keep
			case 'mult', syntheticImage(:,:,fIdx) = imageProduct;
			otherwise,   syntheticImage(:,:,fIdx) = imageIntegral;
		end
		syntheticImage(syntheticImage<0) = 0;  % positivity constraint. Set negative values to 0 since they are non-physical.


	case {'uv','both'}

		[tActual,sActual,vActual,uActual] = ndgrid( lightfield.t, lightfield.s, vRange*sizePixelAperture, uRange*sizePixelAperture );

		if verLessThan('matlab', '7.13')  % lower MATLAB versions don't support gridded interpolant, but do support *linear
			oldMethod = true;
			I = permute(radArray,[4,3,2,1]);
			I = I(:,:,1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding);
		else
			oldMethod = false;
			V = permute(radArray,[4,3,2,1]);
			V = V(:,:,1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding);
 
			% From MATLAB's built-in `makemonotonic` (see `interpn`)
			idim = 4;
			if isvector(uActual) && length(uActual) > 1 && uActual(1) > uActual(2)
				uActualM = uActual(end:-1:1);
				VM = flipdim(V,idim);
			elseif size(uActual,idim) > 1
				sizeX = size(uActual);
				if uActual(1) > uActual(prod(sizeX(1:(idim-1)))+1)
					uActualM = flipdim(uActual,idim);
					VM = flipdim(V,idim);
				end
			end

			% From MATLAB's built-in `makemonotonic` (see `interpn`)
			idim = 3;
			if isvector(vActual) && length(vActual) > 1 && vActual(1) > vActual(2)
				vActualM = vActual(end:-1:1);
				VM = flipdim(VM,idim);
			elseif size(vActual,idim) > 1
				sizeX = size(vActual);
				if vActual(1) > vActual(prod(sizeX(1:(idim-1)))+1)
					vActualM = flipdim(vActual,idim);
					VM = flipdim(VM,idim);
				end
			end

			if verLessThan('matlab', '8.0')  % if MATLAB version is 7.13? (2011b) and definitely 7.14 (2012a), griddedInterpolant doesn't support 'none' flag
				Fimg = griddedInterpolant( tActual,sActual, vActualM,uActualM, VM, 'linear' );
			else
				Fimg = griddedInterpolant( tActual,sActual, vActualM,uActualM, VM, 'linear','none' );
			end
		end%if

		sizeUV = [length(vSlightfield.s) length(uSlightfield.s)];
		numelUV = prod(sizeUV);

		for uvIdx = 1:numelUV

			[uIdx,vIdx] = ind2sub( sizeUV, uvIdx );

			if mask(uvIdx) > 0  % if mask pixel is not zero, calculate.

				uPrime = uSlightfield.s(uIdx)*sizePixelAperture;  % u and v converted to millimeters here
				vPrime = vSlightfield.s(vIdx)*sizePixelAperture;  % u and v converted to millimeters here

				% Shift-Invariant (Paul)
				sQuery = uPrime*(query.fAlpha - 1) + sSlightfield.s;
				tQuery = vPrime*(query.fAlpha - 1) + tSlightfield.s;

				[tQuery,sQuery,vQuery,uQuery] = ndgrid( tQuery,sQuery, vPrime,uPrime );

				if oldMethod
					extractedImageTemp = interpn( tActual,sActual, vActual,uActual, I, tQuery,sQuery, vQuery,uQuery, '*linear',0 );
				else
					extractedImageTemp = Fimg( tQuery,sQuery, vQuery,uQuery );
				end

				extractedImageTemp(extractedImageTemp<0) = 0;  % positivity constraint. Set negative values to 0 since they are non-physical.
				extractedImageTemp(isnan(extractedImageTemp)) = 0;

				switch query.fMethod
					case 'add'
						extractedImageTemp = extractedImageTemp*mask(uvIdx);
						imageIntegral      = imageIntegral + extractedImageTemp;

					case 'mult'
						extractedImageTemp = gray2ind(extractedImageTemp,65536);
						extractedImageTemp = double(extractedImageTemp) + .0001;
						extractedImageTemp = extractedImageTemp.^(1/numelUV*mask(uvIdx));
						imageProduct       = imageProduct .* extractedImageTemp;

					case 'filt'
						extractedImageTemp = gray2ind(extractedImageTemp,65536);
						extractedImageTemp = double(extractedImageTemp);
						extractedImageTemp = extractedImageTemp*mask(uvIdx);
						filterMatrix       = filterMatrix + ( extractedImageTemp>query.fFilter(1) );
						imageIntegral      = imageIntegral + extractedImageTemp;

				end%switch

			end%if

		end%for

	switch query.fMethod  % PARFOR requires two reduction variables, here we choose which to keep
		case 'mult', syntheticImage(:,:,fIdx) = imageProduct;
		otherwise,   syntheticImage(:,:,fIdx) = imageIntegral;
	end

end%switch


%% Output conditioning

switch query.fMethod
	case 'add'
		% Nothing to do
		  
	case 'mult'
		syntheticImage( syntheticImage==2 ) = 0;

	case 'filt'
		filterMatrix = filterMatrix/sum( mask(:)>0 );
		syntheticImage( filterMatrix<query.fFilter(2) ) = 0;

end%switch

end%function
