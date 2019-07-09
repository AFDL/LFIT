function [syntheticImage] = refocus(q,radArray,sRange,tRange)
%REFOCUS Refocuses a plenoptic image to a given value of alpha.
%
% Requires global variable sizePixelAperture, which is the conversion
% factor for u and v to millimeters (mm).

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


global sizePixelAperture; % (si*pixelPitch)/focLenMicro;


%% Typecast variables as single to conserve memory

radArray        = single(radArray);
sRange          = single(sRange);
tRange          = single(tRange); % double for consistency/program won't run otherwise
interpPadding   = single(1); % HARDCODED; if the padding in interpimage2.m changes, change this accordingly.
microRadius     = single( floor(size(radArray,1)/2) - interpPadding ); % since we've padded the extracted data by a pixel in interpimage2, subtract 1


%% Determine supersampling factor

if strcmpi( q.fZoom, 'telecentric' );
    SS_UV = 1;
    SS_ST = 1;
else
    SS_UV = q.uvFactor;
    SS_ST = q.stFactor;
end


%% Define aperture mask (if any)

if strcmpi( q.mask, 'circ' )
    % Circular mask
    mask = fspecial( 'disk', double(microRadius)*SS_UV );
    mask = ( mask - min(mask(:)) )/( max(mask(:)) - min(mask(:)) );
else
    % No mask
    mask = ones( 1 + 2*SS_UV*microRadius );
end


%% Create (u,v) and (s,t) arrays

sizeS       = length(sRange)*SS_ST;
sizeT       = length(tRange)*SS_ST;

uRange      = linspace( microRadius, -microRadius, 1+2*microRadius );
vRange      = linspace( microRadius, -microRadius, 1+2*microRadius );

uSSRange    = linspace( microRadius, -microRadius, 1+2*SS_UV*microRadius );
vSSRange    = linspace( microRadius, -microRadius, 1+2*SS_UV*microRadius );
sSSRange    = linspace( sRange(1), sRange(end), sizeS );
tSSRange    = linspace( tRange(1), tRange(end), sizeT );


%% Memory preallocation

switch q.fZoom
    case 'legacy'
        imageProduct    = ones( sizeT, sizeS, 'single' );
        imageIntegral   = zeros( sizeT, sizeS, 'single' );
        filterMatrix    = zeros( sizeT, sizeS, 'single' );

    case 'telecentric'
        imageProduct    = ones( length(q.fGridY), length(q.fGridX), 'single' );
        imageIntegral   = zeros( length(q.fGridY), length(q.fGridX), 'single' );
        filterMatrix    = zeros( length(q.fGridY), length(q.fGridX), 'single' );

end%switch


%% Determine which algorithm to use

if SS_ST == 1
    if SS_UV == 1,  superSampling = 'none';
    else            superSampling = 'uv';
    end
else
    if SS_UV == 1,  superSampling = 'st';
    else            superSampling = 'both';
    end
end


%% Primary loop
 
switch superSampling
    case 'none'

        % Crop and reshape 4D-array to optimize parfor performance
        radArray = radArray( 1+interpPadding:end-interpPadding, 1+interpPadding:end-interpPadding, :, : );
        radArray = permute( radArray, [2 1 4 3] );
        radArray = reshape( radArray, size(radArray,1)*size(radArray,2), size(radArray,3), size(radArray,4) );

        [sActual,tActual] = meshgrid( sRange, tRange );
        [uActual,vActual] = meshgrid( uRange*sizePixelAperture, vRange*sizePixelAperture );

        numelUV = numel(uActual);

        parfor ( uvIdx = 1:numelUV, Inf )
           
            if mask(uvIdx) > 0 % if mask pixel is not zero, calculate.
                
                sQuery=0; tQuery=0; % To avoid warnings

                switch q.fZoom
                    case 'legacy'
                        sQuery  = sActual + uActual(uvIdx)*(q.fAlpha - 1);
                        tQuery  = tActual + vActual(uvIdx)*(q.fAlpha - 1);

                    case 'telecentric'
                        si      = ( 1 - q.fMag )*q.fLength;
                        so      = -si/q.fMag;
                        soPrime = so + q.fPlane;
                        siPrime = (1/q.fLength - 1/soPrime)^(-1);
                        MPrime  = siPrime/soPrime;
                        
                        alpha   = siPrime/si;

                        sQuery  = q.fGridX*MPrime/alpha + uActual(uvIdx)*(1 - 1/alpha);
                        tQuery  = q.fGridY*MPrime/alpha + vActual(uvIdx)*(1 - 1/alpha);
                        [sQuery,tQuery] = meshgrid( sQuery, tQuery );

                end                  

                extractedImageTemp = interp2( sRange,tRange, squeeze(radArray(uvIdx,:,:)), sQuery,tQuery, '*linear',0 );

                switch q.fMethod
                    case 'add'
                        extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                        imageIntegral       = imageIntegral + extractedImageTemp;

                    case 'mult'
                        extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                        extractedImageTemp  = double(extractedImageTemp) + .0001;
                        extractedImageTemp  = extractedImageTemp.^(1/numelUV*mask(uvIdx));
                        imageProduct        = imageProduct .* extractedImageTemp;

                    case 'filt'
                        extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                        extractedImageTemp  = double(extractedImageTemp);
                        extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                        filterMatrix        = filterMatrix + ( extractedImageTemp>q.fFilter(1) );
                        imageIntegral       = imageIntegral + extractedImageTemp;

                end%switch

            end%if

        end%for

        switch q.fMethod    % PARFOR requires two reduction variables, here we choose which to keep
            case 'mult',    syntheticImage  = imageProduct;
            otherwise,      syntheticImage  = imageIntegral;
        end
        syntheticImage(syntheticImage<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
        
    case 'st'
        
        % Crop and reshape 4D-array to optimize parfor performance
        radArray = radArray( 1+interpPadding:end-interpPadding, 1+interpPadding:end-interpPadding, :, : );
        radArray = permute( radArray, [2 1 4 3] );
        radArray = reshape( radArray, size(radArray,1)*size(radArray,2), size(radArray,3), size(radArray,4) );
        
        [sPrime,tPrime]     = meshgrid( sSSRange, tSSRange );
        [uActual,vActual]   = meshgrid( uRange*sizePixelAperture, vRange*sizePixelAperture );

        numelUV = numel(uActual);
        
        parfor ( uvIdx = 1:numelUV, Inf )

            if mask(uvIdx) > 0 % if mask pixel is not zero, calculate.

                % Shift-Invariant (Paul)
                sQuery = uActual(uvIdx)*(q.fAlpha - 1) + sPrime;
                tQuery = vActual(uvIdx)*(q.fAlpha - 1) + tPrime;

                extractedImageTemp = interp2( sRange,tRange, squeeze(radArray(uvIdx,:,:)), sQuery,tQuery, '*linear',0 );
                
                switch q.fMethod
                    case 'add'
                        extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                        imageIntegral       = imageIntegral + extractedImageTemp;

                    case 'mult'
                        extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                        extractedImageTemp  = double(extractedImageTemp) + .0001;
                        extractedImageTemp  = extractedImageTemp.^(1/numelUV*mask(uvIdx));
                        imageProduct        = imageProduct .* extractedImageTemp;

                    case 'filt'
                        extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                        extractedImageTemp  = double(extractedImageTemp);
                        extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                        filterMatrix        = filterMatrix + ( extractedImageTemp>q.fFilter(1) );
                        imageIntegral       = imageIntegral + extractedImageTemp;

                end%switch

            end%if

        end%for

        switch q.fMethod    % PARFOR requires two reduction variables, here we choose which to keep
            case 'mult',    syntheticImage  = imageProduct;
            otherwise,      syntheticImage  = imageIntegral;
        end
        syntheticImage(syntheticImage<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
        
    case {'uv','both'}
        
        [tActual,sActual,vActual,uActual] = ndgrid( tRange, sRange, vRange*sizePixelAperture, uRange*sizePixelAperture );
        
        if verLessThan('matlab', '7.13') % lower MATLAB versions don't support gridded interpolant, but do support *linear
            oldMethod = true;
            I = permute(radArray,[4,3,2,1]);
            I = I(:,:,1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding);
        else
            oldMethod = false;
            V = permute(radArray,[4,3,2,1]);
            V = V(:,:,1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding);
            
            % From MATLAB's built-in 'makemonotonic' (see inside interpn)
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
            
            % From MATLAB's built-in 'makemonotonic' (see inside interpn)
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

            if verLessThan('matlab', '8.0') % if MATLAB version is 7.13? (2011b) and definitely 7.14 (2012a), griddedInterpolant doesn't support 'none' flag
                Fimg = griddedInterpolant( tActual,sActual, vActualM,uActualM, VM, 'linear' );
            else
                Fimg = griddedInterpolant( tActual,sActual, vActualM,uActualM, VM, 'linear','none' );
            end
        end%if
        
        sizeUV = [length(vSSRange) length(uSSRange)];
        numelUV = prod(sizeUV);
        
        for uvIdx = 1:numelUV
            
            [uIdx,vIdx] = ind2sub( sizeUV, uvIdx );
            
            if mask(uvIdx) > 0 % if mask pixel is not zero, calculate.

                uPrime = uSSRange(uIdx)*sizePixelAperture; % u and v converted to millimeters here
                vPrime = vSSRange(vIdx)*sizePixelAperture; % u and v converted to millimeters here

                % Shift-Invariant (Paul)
                sQuery = uPrime*(q.fAlpha - 1) + sSSRange;
                tQuery = vPrime*(q.fAlpha - 1) + tSSRange;

                [tQuery,sQuery,vQuery,uQuery] = ndgrid( tQuery,sQuery, vPrime,uPrime );

                if oldMethod
                    extractedImageTemp = interpn( tActual,sActual, vActual,uActual, I, tQuery,sQuery, vQuery,uQuery, '*linear',0 );
                else
                    extractedImageTemp = Fimg( tQuery,sQuery, vQuery,uQuery );
                end

                extractedImageTemp(extractedImageTemp<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
                extractedImageTemp(isnan(extractedImageTemp)) = 0;

                switch q.fMethod
                    case 'add'
                        extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                        imageIntegral       = imageIntegral + extractedImageTemp;

                    case 'mult'
                        extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                        extractedImageTemp  = double(extractedImageTemp) + .0001;
                        extractedImageTemp  = extractedImageTemp.^(1/numelUV*mask(uvIdx));
                        imageProduct        = imageProduct .* extractedImageTemp;

                    case 'filt'
                        extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                        extractedImageTemp  = double(extractedImageTemp);
                        extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                        filterMatrix        = filterMatrix + ( extractedImageTemp>q.fFilter(1) );
                        imageIntegral       = imageIntegral + extractedImageTemp;

                end%switch

            end%if
            
        end%for

        switch q.fMethod    % PARFOR requires two reduction variables, here we choose which to keep
            case 'mult',    syntheticImage  = imageProduct;
            otherwise,      syntheticImage  = imageIntegral;
        end

end%switch


%% Output conditioning

switch q.fMethod
    case 'add'
        % Nothing to do
        syntheticImage = syntheticImage/sum(sum(mask));
    case 'mult'
        syntheticImage( syntheticImage==2 ) = 0;  % Modified by chris

    case 'filt'
        filterMatrix = filterMatrix/sum( mask(:)>0 );
        syntheticImage( filterMatrix<q.fFilter(2) ) = 0;

end%switch

end%function
