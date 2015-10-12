function [syntheticImage] = refocus(radArray,alphaVal,SS_UV,SS_ST,sRange,tRange,apertureFlag,refocusType,filterInfo,telecentricInfo)
%REFOCUS Refocuses a plenoptic image to a given value of alpha.
%
%	Requires global variable sizePixelAperture, which is the conversion
%   factor for u and v to millimeters (mm).

% profile on
% tic

global sizePixelAperture; % (si*pixelPitch)/focLenMicro;

magTypeFlag = telecentricInfo(1); % 0 = legacy, 1 = constant magnification

if magTypeFlag == 1
    SS_UV = 1;
    SS_ST = 1;
end

radArray = single(radArray);
sRange = single(sRange);
tRange = single(tRange); %double for consistency/program won't run otherwise
interpPadding = 1; %HARDCODED; if the padding in interpimage2.m changes, change this accordingly.
microRadius = single(floor(size(radArray,1)/2)) - interpPadding; %since we've padded the extracted data by a pixel in interpimage2, subtract 1

% Define aperture mask
switch apertureFlag
    case 0 % Square/Full aperture
        circMask = ones(1+(2*((microRadius+interpPadding)*SS_UV)));

    case 1 % Circular mask
        circMask = zeros(1+(2*((microRadius+interpPadding)*SS_UV)));
        circMask(1+interpPadding*SS_UV:end-interpPadding*SS_UV,1+interpPadding*SS_UV:end-interpPadding*SS_UV) = fspecial('disk', double(microRadius)*SS_UV); %interpPadding here makes circMask same size as u,v dimensions of radArray
        circMask = ( circMask - min(circMask(:)) )/range(circMask(:));

    otherwise
        error('Aperture flag defined incorrectly. Check request vector.');

end

uRange = linspace(microRadius,-microRadius,1+(microRadius*2));
vRange(:,1) = linspace(microRadius,-microRadius,1+(microRadius*2));

tempSizeS = numel(sRange)*SS_ST;
tempSizeT = numel(tRange)*SS_ST;

switch refocusType
    case {1,3},     syntheticImage = zeros(tempSizeT,tempSizeS,'single');
    case 2,         syntheticImage = ones(tempSizeT,tempSizeS,'single');
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

if refocusType == 3
    filterMatrix    = zeros(tempSizeT,tempSizeS);
    noiseThreshold  = filterInfo(1);
    filterThreshold = filterInfo(2);
end

if magTypeFlag == 1
    xmin = telecentricInfo(2);
    xmax = telecentricInfo(3);

    ymin = telecentricInfo(4);
    ymax = telecentricInfo(5);

    nVoxX = telecentricInfo(8);
    nVoxY = telecentricInfo(9);

    filterMatrix = zeros(nVoxY,nVoxX);

    if refocusType == 2
        syntheticImage = ones(nVoxY,nVoxX,'single');        
    else
        syntheticImage = zeros(nVoxY,nVoxX,'single');
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
                uIndex = -(u) + microRadius+1 + interpPadding; %u is negative here since the uVector decreases from top to bottom (ie +7 to -7) while MATLAB image indexing increases from top to bottom
                vIndex = -(v) + microRadius+1 + interpPadding; %v is negative here since the vVector decreases from top to bottom (ie +7 to -7) while MATLAB image indexing increases from top to bottom
                
%               if apertureFlag == 0 || circMask(vIndex,uIndex) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    activePixelCount = activePixelCount + 1;
                    uAct = u.*sizePixelAperture; %u and v converted to millimeters here
                    vAct = v.*sizePixelAperture; %u and v converted to millimeters here
%                   uAct = u.*1.254; %u and v converted to millimeters here
%                   vAct = v.*1.254; %u and v converted to millimeters here

                    switch magTypeFlag
                        case 0 % Shift-Invariant Method (Paul)
                            sQuery  = uAct*(alphaVal - 1) + sActual;
                            tQuery  = vAct*(alphaVal - 1) + tActual;

                        case 1
                            f       = telecentricInfo(11);
                            M       = telecentricInfo(12);
                            si      = (1-M)*f;
                            so      = -si/M;
                            siPrime = alphaVal*si;
                            z       = telecentricInfo(13);
                            soPrime = so + z;
                            MPrime  = siPrime/soPrime;
                            extractedImageTemp = zeros(nVoxY,nVoxX,'single');

                            sQuery = linspace(xmin,xmax,nVoxX)*MPrime/alphaVal + uAct*(1 - 1/alphaVal);
                            tQuery = linspace(ymin,ymax,nVoxY)*MPrime/alphaVal + vAct*(1 - 1/alphaVal);
                            [sQuery,tQuery] = meshgrid(sQuery,tQuery);

                    end                  
                  
                    Z = permute(radArray(uIndex,vIndex,:,:),[4 3 1 2]);                    
                    extractedImageTemp = interp2(sRange,tRange.',Z,sQuery,tQuery,'*linear',0); %row,col,Z,row,col                   
%                   syntheticImage = interpn(uRange,vRange',sRange,tRange,radArray,uAct,vAct,sQuery,tQuery,'*linear',0); %row,col,Z,row,col                   
%                   syntheticImage = nansum(nansum(syntheticImage,1),2);
%                   syntheticImage = reshape(syntheticImage,length(tRange),length(sRange));
                    
                    switch refocusType
                        case 1
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vIndex,uIndex);
                       
                        case 2
                            extractedImageTemp = gray2ind(extractedImageTemp,65536);
                            extractedImageTemp = double(extractedImageTemp) + .0001;
                            extractedImageTemp = extractedImageTemp.^(1/(length(uRange)*length(vRange))*circMask(uIndex-1,vIndex-1));
                            syntheticImage = syntheticImage.*extractedImageTemp;

                        case 3
                            extractedImageTemp = gray2ind(extractedImageTemp,65536); %%%new
                            extractedImageTemp = double(extractedImageTemp);%%%new
                            filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vIndex,uIndex);

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
                
                if apertureFlag == 0 || circMask(vInd,uInd) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    activePixelCount = activePixelCount + 1;
                    uPrime = uSSRange(uInd).*sizePixelAperture; %u and v converted to millimeters here
                    vPrime = vSSRange(vInd).*sizePixelAperture; %u and v converted to millimeters here
                    
                    % Shift-Invariant (Paul)
                    sEff = uPrime.*(alphaVal - 1) + sSSRange;
                    tEff = vPrime.*(alphaVal - 1) + tSSRange;
                    
                    [tQuery, sQuery, vQuery, uQuery] = ndgrid(tEff,sEff,vPrime,uPrime);
                    
                    if oldMethod
                        extractedImageTemp = interpn(tActual,sActual,vActual,uActual,I,tQuery,sQuery,vQuery,uQuery,'*linear',0);
                    else
                        extractedImageTemp = Fimg(tQuery,sQuery,vQuery,uQuery);
                    end

                    extractedImageTemp(extractedImageTemp<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
                    extractedImageTemp(isnan(extractedImageTemp)) = 0;

                    switch refocusType
                        case 1
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);
                       
                        case 2
                            max_int = max(max(syntheticImage)); % normalize
                            syntheticImage = syntheticImage/max_int; 
                            max_int = max(max(extractedImageTemp)); % normalize
                            extractedImageTemp = extractedImageTemp/max_int;
                            extractedImageTemp(isnan(extractedImageTemp)) = 0; 
                
                            new_uv = extractedImageTemp*circMask(vInd,uInd);
                            new_uv( new_uv==0 ) = 1;  % Modified by chris
%                           [m,n] = size(new_uv);                   
%                           for a = 1:m
%                               for b = 1:n
%                                   if new_uv(a,b) == 0
%                                       new_uv(a,b) = 1;
%                                   else
%                                   end
%                               end
%                           end
                
                            new_uv = new_uv + 1;

                            syntheticImage = syntheticImage.*new_uv;

                        case 3
                            filterMatrix(extractedImageTemp>noiseThreshold) = filterMatrix(extractedImageTemp>noiseThreshold) + 1;
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);

                    end%switch

                end%if

            end%for
        end%for
        
    case 'st' % Separate case here because it's about 2x faster than just using the uv/both case above
        for uInd=1:numel(uSSRange)
            for vInd=1:numel(vSSRange)
                
                if apertureFlag == 0 || circMask(vInd,uInd) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    activePixelCount = activePixelCount + 1;
                    uPrime = uSSRange(uInd).*sizePixelAperture; %u and v converted to millimeters here
                    vPrime = vSSRange(vInd).*sizePixelAperture; %u and v converted to millimeters here
                    
                    % Shift-Invariant (Paul)
                    sEff = uPrime.*(alphaVal - 1) + sSSRange;
                    tEff = vPrime.*(alphaVal - 1) + tSSRange;
                    
                    Z = permute(radArray(uInd+interpPadding,vInd+interpPadding,:,:),[4 3 1 2]);
                    
                    extractedImageTemp(:,:) = interp2(sRange,tRange.',Z,sEff,tEff.','*linear',0); %row,col,Z,row,col
                    switch refocusType
                        case 1
                            syntheticImage = syntheticImage + extractedImageTemp*circMask(vInd,uInd);
                       
                        case 2
                            max_int = max(max(syntheticImage)); % normalize
                            syntheticImage = syntheticImage/max_int; 
                            max_int = max(max(extractedImageTemp)); % normalize
                            extractedImageTemp = extractedImageTemp/max_int;
                            extractedImageTemp(isnan(extractedImageTemp)) = 0; 
                
                            new_uv = extractedImageTemp*circMask(vInd,uInd);
                            [m,n] = size(new_uv);                    
                            for a = 1:m     
                                for b = 1:n
                                    if new_uv(a,b) == 0
                                        new_uv(a,b) = 1;
                                    else
                                    end
                                end
                            end
                
                            new_uv = new_uv + 1;

                            syntheticImage = syntheticImage.*new_uv;

                        case 3
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

switch refocusType
    case 2
        syntheticImage( syntheticImage==2 ) = 0;  % Modified by chris
%       [p,q] = size(syntheticImage);                    
%       for a = 1:p     
%           for b = 1:q
%               if syntheticImage(a,b) == 2
%                   syntheticImage(a,b) = 0;
%               else
%               end
%           end
%       end

    case 3
        filterMatrix = filterMatrix./activePixelCount;
        syntheticImage(filterMatrix<filterThreshold) = 0;

end%switch

        %%%Check constant magnification
%         syntheticImage = imwarp(syntheticImage, affine2d([-M/MPrime 0 0; 0 -M/MPrime 0; 0 0 1]));
        %%%

% profile viewer
% toc

end%function
