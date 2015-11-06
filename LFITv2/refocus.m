function [syntheticImage] = refocus(q,radArray,sRange,tRange)
%REFOCUS Refocuses a plenoptic image to a given value of alpha.
%
%   Requires global variable sizePixelAperture, which is the conversion
%   factor for u and v to millimeters (mm).

% profile on
% tic

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

extractedImageTemp = zeros( sizeT, sizeS, 'single' );

switch q.fZoom
    case 'legacy'
        switch q.fMethod
            case 'add'
                syntheticImage  = zeros( sizeT, sizeS, 'single' );
            case 'mult'
                syntheticImage  = ones( sizeT, sizeS, 'single' );
            case 'filter'
                syntheticImage  = zeros( sizeT, sizeS, 'single' );
                filterMatrix    = zeros( sizeT, sizeS, 'single' );
                noiseThreshold  = q.fFilter(1);
                filterThreshold = q.fFilter(2);
        end

    case 'telecentric'
        switch q.fMethod
            case 'add'
                syntheticImage  = zeros( length(q.fGridY), length(q.fGridX), 'single' );
            case 'mult'
                syntheticImage  = ones( length(q.fGridY), length(q.fGridX), 'single' );
            case 'filter'
                syntheticImage  = zeros( length(q.fGridY), length(q.fGridX), 'single' );
                filterMatrix    = zeros( length(q.fGridY), length(q.fGridX), 'single' );
                noiseThreshold  = q.fFilter(1);
                filterThreshold = q.fFilter(2);
        end

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


%%
 
switch superSampling
    case 'none'

        [sActual,tActual] = meshgrid( sRange, tRange );
        [uActual,vActual] = meshgrid( uRange*sizePixelAperture, vRange*sizePixelAperture );

        numelUV = numel(uActual);
        
        % Crop and reshape to optimize parfor performance
        radArray = radArray( 1+interpPadding:end-interpPadding, 1+interpPadding:end-interpPadding, :, : );
        radArray = permute( radArray, [2 1 4 3] );
        radArray = reshape( radArray, numelUV, sizeT, sizeS );

        for uvIdx = 1:numelUV
           
%               if mask(vIdx,uIdx) ~= 0 % if mask pixel is not zero, calculate.

                    switch q.fZoom
                        case 'legacy'
                            sQuery  = uActual(uvIdx)*(q.fAlpha - 1) + sActual;
                            tQuery  = vActual(uvIdx)*(q.fAlpha - 1) + tActual;

                        case 'telecentric'
                            si      = ( 1 - q.fMag )*q.fLength;
                            so      = -si/q.fMag;
                            siPrime = q.fAlpha*si;
                            soPrime = so + q.fPlane;
                            MPrime  = siPrime/soPrime;

                            sQuery  = q.fGridX*MPrime/q.fAlpha + uActual(uvIdx)*(1 - 1/q.fAlpha);
                            tQuery  = q.fGridY*MPrime/q.fAlpha + vActual(uvIdx)*(1 - 1/q.fAlpha);
                            [sQuery,tQuery] = meshgrid( sQuery, tQuery );

                    end                  
                    
                    extractedImageTemp = interp2( sRange, tRange, squeeze(radArray(uvIdx,:,:)), sQuery, tQuery, '*linear', 0 ); %row,col,Z,row,col
                    
                    switch q.fMethod
                        case 'add'
                            extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                            syntheticImage      = syntheticImage + extractedImageTemp;
                       
                        case 'mult'
                            extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                            extractedImageTemp  = double(extractedImageTemp) + .0001;
                            extractedImageTemp  = extractedImageTemp.^(1/numelUV*mask(uvIdx));
                            syntheticImage      = syntheticImage.*extractedImageTemp; %! parfor: non-conforming reduction variable

                        case 'filt'
                            extractedImageTemp  = gray2ind(extractedImageTemp,65536);
                            extractedImageTemp  = double(extractedImageTemp);
                            extractedImageTemp  = extractedImageTemp*mask(uvIdx);
                            filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1; %! parfor: invalid indexing
                            syntheticImage      = syntheticImage + extractedImageTemp;

                    end%switch
                 
%               end%if

        end%for

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
            V = V(:,:,1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding); % doesn't use padded data set
            
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
                Fimg = griddedInterpolant(tActual,sActual,vActualM,uActualM,VM,'linear');
            else
                Fimg = griddedInterpolant(tActual,sActual,vActualM,uActualM,VM,'linear','none');
            end
        end%if
        
        sizeUV = [length(vSSRange) length(uSSRange)];
        numelUV = prod(sizeUV);
        
        for uvIdx = 1:numelUV
            
            [uIdx,vIdx] = ind2sub( sizeUV, uvIdx );
            
            if mask(vIdx,uIdx) ~= 0 % if mask pixel is not zero, calculate.

                uPrime = uSSRange(uIdx)*sizePixelAperture; %u and v converted to millimeters here
                vPrime = vSSRange(vIdx)*sizePixelAperture; %u and v converted to millimeters here

                % Shift-Invariant (Paul)
                sEff = uPrime.*(q.fAlpha - 1) + sSSRange;
                tEff = vPrime.*(q.fAlpha - 1) + tSSRange;

                [tQuery, sQuery, vQuery, uQuery] = ndgrid(tEff,sEff,vPrime,uPrime);

                if oldMethod
                    extractedImageTemp = interpn(tActual,sActual,vActual,uActual,I,tQuery,sQuery,vQuery,uQuery,'*linear',0);
                else
                    extractedImageTemp = Fimg(tQuery,sQuery,vQuery,uQuery);
                end

                extractedImageTemp(extractedImageTemp<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
                extractedImageTemp(isnan(extractedImageTemp)) = 0;

                switch q.fMethod
                    case 'add'
                        syntheticImage = syntheticImage + extractedImageTemp*mask(vIdx,uIdx);

                    case 'mult'
                        max_int = max(max(syntheticImage)); % normalize
                        syntheticImage = syntheticImage/max_int; 
                        max_int = max(max(extractedImageTemp)); % normalize
                        extractedImageTemp = extractedImageTemp/max_int;
                        extractedImageTemp(isnan(extractedImageTemp)) = 0; 

                        new_uv = extractedImageTemp*mask(vIdx,uIdx);
                        new_uv( new_uv==0 ) = 1;  % Modified by chris

                        new_uv = new_uv + 1;

                        syntheticImage = syntheticImage.*new_uv;

                    case 'filt'
                        filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                        syntheticImage = syntheticImage + extractedImageTemp*mask(vIdx,uIdx);

                end%switch

            end%if
            
        end%for
        
    case 'st' % Separate case here because it's about 2x faster than just using the uv/both case above

        sizeUV = [length(vSSRange) length(uSSRange)];
        numelUV = prod(sizeUV);
        
        for uvIdx = 1:numelUV

            [uIdx vIdx] = ind2sub( sizeUV, uvIdx );

            if mask(vIdx,uIdx) ~= 0 % if mask pixel is not zero, calculate.

                uPrime = uSSRange(uIdx)*sizePixelAperture; %u and v converted to millimeters here
                vPrime = vSSRange(vIdx)*sizePixelAperture; %u and v converted to millimeters here

                % Shift-Invariant (Paul)
                sEff = uPrime.*(q.fAlpha - 1) + sSSRange;
                tEff = vPrime.*(q.fAlpha - 1) + tSSRange;

                Z = permute(radArray(uIdx+interpPadding,vIdx+interpPadding,:,:),[4 3 1 2]);
                extractedImageTemp(:,:) = interp2(sRange,tRange.',Z,sEff,tEff.','*linear',0); %row,col,Z,row,col
                
                switch q.fMethod
                    case 'add'
                        syntheticImage = syntheticImage + extractedImageTemp*mask(vIdx,uIdx);

                    case 'mult'
                        max_int = max(max(syntheticImage)); % normalize
                        syntheticImage = syntheticImage/max_int; 
                        max_int = max(max(extractedImageTemp)); % normalize
                        extractedImageTemp = extractedImageTemp/max_int;
                        extractedImageTemp(isnan(extractedImageTemp)) = 0; 

                        new_uv = extractedImageTemp*mask(vIdx,uIdx);
                        new_uv( new_uv==0 ) = 1;  % Modified by chris

                        new_uv = new_uv + 1;

                        syntheticImage = syntheticImage.*new_uv;

                    case 'filt'
                        filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                        syntheticImage = syntheticImage + extractedImageTemp*mask(vIdx,uIdx);

                end%switch

            end%if

        end%for

        syntheticImage(syntheticImage<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.

end%switch


%% Output conditioning

switch q.fMethod
    case 'add'
        % Nothing to do
        
    case 'mult'
        syntheticImage( syntheticImage==2 ) = 0;  % Modified by chris

    case 'filt'
        filterMatrix = filterMatrix/sum( mask~=0 );
        syntheticImage(filterMatrix<filterThreshold) = 0;

end%switch

        %%%Check constant magnification
%         syntheticImage = imwarp(syntheticImage, affine2d([-M/MPrime 0 0; 0 -M/MPrime 0; 0 0 1]));
        %%%

% profile viewer
% toc

end%function
