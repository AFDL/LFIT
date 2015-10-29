function [syntheticImage] = refocus(q,radArray,sRange,tRange)
%REFOCUS Refocuses a plenoptic image to a given value of alpha.
%
%	Requires global variable sizePixelAperture, which is the conversion
%   factor for u and v to millimeters (mm).

% profile on
% tic

global sizePixelAperture; % (si*pixelPitch)/focLenMicro;

if strcmpi( q.fZoom, 'telecentric' );
    SS_UV = 1;
    SS_ST = 1;
else
    SS_UV = q.uvFactor;
    SS_ST = q.stFactor;
end

radArray = single(radArray);
sRange = single(sRange);
tRange = single(tRange); %double for consistency/program won't run otherwise
interpPadding = 1; %HARDCODED; if the padding in interpimage2.m changes, change this accordingly.
microRadius = single(floor(size(radArray,1)/2)) - interpPadding; %since we've padded the extracted data by a pixel in interpimage2, subtract 1

% Define aperture mask
if strcmpi( q.mask, 'circ' )
    % Circular mask
    circMask = zeros(1+(2*((microRadius+interpPadding)*SS_UV)));
    circMask(1+interpPadding*SS_UV:end-interpPadding*SS_UV,1+interpPadding*SS_UV:end-interpPadding*SS_UV) = fspecial('disk', double(microRadius)*SS_UV); %interpPadding here makes circMask same size as u,v dimensions of radArray
    circMask = ( circMask - min(circMask(:)) )/( max(circMask(:)) - min(circMask(:)) );
else
    % No mask
    circMask = ones(1+(2*((microRadius+interpPadding)*SS_UV)));
end

uRange = linspace(microRadius,-microRadius,1+(microRadius*2));
vRange(:,1) = linspace(microRadius,-microRadius,1+(microRadius*2));

tempSizeS = numel(sRange)*SS_ST;
tempSizeT = numel(tRange)*SS_ST;

if strmpci( q.fMethod, 'mult' )
    syntheticImage = ones(tempSizeT,tempSizeS,'single');
else
    syntheticImage = zeros(tempSizeT,tempSizeS,'single');    
end

extractedImageTemp = zeros(tempSizeT,tempSizeS,'single');

uSSRange = linspace(microRadius,-microRadius,(1+(microRadius*2)*SS_UV));
vSSRange = linspace(microRadius,-microRadius,(1+(microRadius*2)*SS_UV));
sSSRange = linspace(sRange(1),sRange(end),tempSizeS);
tSSRange = linspace(tRange(1),tRange(end),tempSizeT);

if SS_ST == 1
    if SS_UV == 1,  superSampling = 'none';
    else            superSampling = 'uv';
    end
else
    if SS_UV == 1,  superSampling = 'st';
    else            superSampling = 'both';
    end
end

if strcmpi( q.fMethod, 'filt' )
    filterMatrix    = zeros(tempSizeT,tempSizeS);
    noiseThreshold  = q.fFilter(1);
    filterThreshold = q.fFilter(2);
end

if strcmpi( q.fZoom, 'telecentric' )
    filterMatrix = zeros( length(q.fGridY), length(q.fGridX) );

    if strmpci( q.fMethod, 'mult' )
        syntheticImage = ones( length(q.fGridY), length(q.fGridX), 'single' );        
    else
        syntheticImage = zeros( length(q.fGridY), length(q.fGridX), 'single' );
    end
end

activePixelCount = 0;
 
switch superSampling
    case 'none'

        [tActual,sActual] = ndgrid(tRange,sRange);

%       [u,v,tActual,sActual]=ndgrid(uRange,vRange,tRange,sRange);
        for u=uRange
            for v=vRange.'
                
                % The plus 1 is to make the index start at 0 not 1. The interpPadding accounts for any pixel padding in interpimage2.m
                uIdx = -(u) + microRadius+1 + interpPadding; % u is negative here since the uVector decreases from top to bottom (ie +7 to -7) while MATLAB image indexing increases from top to bottom
                vIdx = -(v) + microRadius+1 + interpPadding; % v is negative here since the vVector decreases from top to bottom (ie +7 to -7) while MATLAB image indexing increases from top to bottom
                
%               if ~q.mask || circMask(vIdx,uIdx) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    activePixelCount = activePixelCount + 1;
                    uAct = u.*sizePixelAperture; % u and v converted to millimeters here
                    vAct = v.*sizePixelAperture; % u and v converted to millimeters here

                    switch q.fZoom
                        case 'legacy'
                            sQuery  = uAct*(q.fAlpha - 1) + sActual;
                            tQuery  = vAct*(q.fAlpha - 1) + tActual;

                        case 'telecentric'
                            si      = ( 1 - q.fMag )*q.fLength;
                            so      = -si/q.fMag;
                            siPrime = q.fAlpha*si;
                            soPrime = so + q.fPlane;
                            MPrime  = siPrime/soPrime;

                            sQuery = q.fGridX*MPrime/q.fAlpha + uAct*(1 - 1/q.fAlpha);
                            tQuery = q.fGridY*MPrime/q.fAlpha + vAct*(1 - 1/q.fAlpha);
                            [sQuery,tQuery] = meshgrid(sQuery,tQuery);

                    end                  
                  
                    Z = permute(radArray(uIdx,vIdx,:,:),[4 3 1 2]);
                    extractedImageTemp = interp2(sRange,tRange.',Z,sQuery,tQuery,'*linear',0); %row,col,Z,row,col                   
%                   syntheticImage = interpn(uRange,vRange',sRange,tRange,radArray,uAct,vAct,sQuery,tQuery,'*linear',0); %row,col,Z,row,col                   
%                   syntheticImage = nansum(nansum(syntheticImage,1),2);
%                   syntheticImage = reshape(syntheticImage,length(tRange),length(sRange));
                    
                    switch q.fMethod
                        case 'add'
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vIdx,uIdx);
                       
                        case 'mult'
                            extractedImageTemp = gray2ind(extractedImageTemp,65536);
                            extractedImageTemp = double(extractedImageTemp) + .0001;
                            extractedImageTemp = extractedImageTemp.^(1/(length(uRange)*length(vRange))*circMask(uIdx-1,vIdx-1));
                            syntheticImage = syntheticImage.*extractedImageTemp;

                        case 'filt'
                            extractedImageTemp = gray2ind(extractedImageTemp,65536); %%%new
                            extractedImageTemp = double(extractedImageTemp);%%%new
                            filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vIdx,uIdx);

                    end%switch
                 
%               end

            end%for
        end%for

        syntheticImage(syntheticImage<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
                
    case {'uv', 'both'}
        
        [tActual,sActual,vActual,uActual] = ndgrid(tRange,sRange,vRange.*sizePixelAperture,uRange.*sizePixelAperture);
        
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
        
        for uInd=1:numel(uSSRange)
            for vInd=1:numel(vSSRange)
                
                if ~q.mask || circMask(vInd,uInd) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    activePixelCount = activePixelCount + 1;
                    uPrime = uSSRange(uInd).*sizePixelAperture; %u and v converted to millimeters here
                    vPrime = vSSRange(vInd).*sizePixelAperture; %u and v converted to millimeters here
                    
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
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);
                       
                        case 'mult'
                            max_int = max(max(syntheticImage)); % normalize
                            syntheticImage = syntheticImage/max_int; 
                            max_int = max(max(extractedImageTemp)); % normalize
                            extractedImageTemp = extractedImageTemp/max_int;
                            extractedImageTemp(isnan(extractedImageTemp)) = 0; 
                
                            new_uv = extractedImageTemp*circMask(vInd,uInd);
                            new_uv( new_uv==0 ) = 1;  % Modified by chris
                
                            new_uv = new_uv + 1;

                            syntheticImage = syntheticImage.*new_uv;

                        case 'filt'
                            filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);

                    end%switch

                end%if

            end%for
        end%for
        
    case 'st' % Separate case here because it's about 2x faster than just using the uv/both case above
        for uInd=1:numel(uSSRange)
            for vInd=1:numel(vSSRange)
                
                if ~q.mask || circMask(vInd,uInd) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    activePixelCount = activePixelCount + 1;
                    uPrime = uSSRange(uInd).*sizePixelAperture; %u and v converted to millimeters here
                    vPrime = vSSRange(vInd).*sizePixelAperture; %u and v converted to millimeters here
                    
                    % Shift-Invariant (Paul)
                    sEff = uPrime.*(q.fAlpha - 1) + sSSRange;
                    tEff = vPrime.*(q.fAlpha - 1) + tSSRange;
                    
                    Z = permute(radArray(uInd+interpPadding,vInd+interpPadding,:,:),[4 3 1 2]);
                    
                    extractedImageTemp(:,:) = interp2(sRange,tRange.',Z,sEff,tEff.','*linear',0); %row,col,Z,row,col
                    switch q.fMethod
                        case 'add'
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);
                       
                        case 'mult'
                            max_int = max(max(syntheticImage)); % normalize
                            syntheticImage = syntheticImage/max_int; 
                            max_int = max(max(extractedImageTemp)); % normalize
                            extractedImageTemp = extractedImageTemp/max_int;
                            extractedImageTemp(isnan(extractedImageTemp)) = 0; 
                
                            new_uv = extractedImageTemp*circMask(vInd,uInd);
                            new_uv( new_uv==0 ) = 1;  % Modified by chris
                
                            new_uv = new_uv + 1;

                            syntheticImage = syntheticImage.*new_uv;

                        case 'filt'
                            filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);

                    end%switch

                end%if

            end%for
        end%for

        syntheticImage(syntheticImage<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.

    otherwise
        error('Incorrect supersampling logic determination. Debug refocus.m and/or check requestVector input.');

end%switch

switch q.fMethod
    case 'add'
        % Nothing to do
        
    case 'mult'
        syntheticImage( syntheticImage==2 ) = 0;  % Modified by chris

    case 'filt'
        filterMatrix = filterMatrix./activePixelCount;
        syntheticImage(filterMatrix<filterThreshold) = 0;

end%switch

        %%%Check constant magnification
%         syntheticImage = imwarp(syntheticImage, affine2d([-M/MPrime 0 0; 0 -M/MPrime 0; 0 0 1]));
        %%%

% profile viewer
% toc

end%function
