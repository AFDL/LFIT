function [syntheticImage] = refocusfft(q,radArray,sRange,tRange)
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

radArray = single(radArray);
sRange = single(sRange);
tRange = single(tRange); %double for consistency/program won't run otherwise
interpPadding = 1; %HARDCODED; if the padding in interpimage2.m changes, change this accordingly.
microRadius = single(floor(size(radArray,1)/2)) - interpPadding; %since we've padded the extracted data by a pixel in interpimage2, subtract 1

SS_UV = q.uvFactor;
SS_ST = q.stFactor;

% Define aperture mask
if strcmpi( q.mask, 'circ' )
    % Circular mask
    circMask = zeros(1+(2*((microRadius+interpPadding)*SS_UV)));
    circMask(1+interpPadding*SS_UV:end-interpPadding*SS_UV,1+interpPadding*SS_UV:end-interpPadding*SS_UV) = fspecial('disk', double(microRadius)*SS_UV); %interpPadding here makes circMask same size as u,v dimensions of radArray
    cirlims=[min(min(circMask)) max(max(circMask))];
    circMask=(circMask-cirlims(1))./(cirlims(2) - cirlims(1));
else
    % No mask
    circMask = ones(1+(2*((microRadius+interpPadding)*SS_UV)));
end

uRange = linspace(microRadius,-microRadius,1+(microRadius*2));
vRange(:,1) = linspace(microRadius,-microRadius,1+(microRadius*2));

tempSizeS = numel(sRange)*SS_ST;
tempSizeT = numel(tRange)*SS_ST;
syntheticImage = zeros(tempSizeT,tempSizeS,'single');
extractedImageTemp = zeros(tempSizeT,tempSizeS,'single');

uSSRange = linspace(microRadius,-microRadius,(1+(microRadius*2)*SS_UV));
vSSRange = linspace(microRadius,-microRadius,(1+(microRadius*2)*SS_UV));
sSSRange = linspace(sRange(1),sRange(end),(numel(sRange))*SS_ST);
tSSRange = linspace(tRange(1),tRange(end),(numel(tRange))*SS_ST);

if SS_ST == 1
    if SS_UV == 1,  superSampling = 'none';
    else            superSampling = 'uv';
    end
else
    if SS_UV == 1,  superSampling = 'st';
    else            superSampling = 'both';
    end
end

% tic

% -----------------
% Begin Paul's code
% -----------------

w = 2; % Window size. This is fixed to 2 as of R4. Linear window (triangle) is always length 2
[nx, ny, null, null] = size(permute(radArray,[3 4 1 2]));

% padVec - this specifies the number of zeroes to pad the RAD array by
% before the FFT. Good values are 5% in the spatial direction and 20 in the
% angular dimensions.
padVec = [10, 10, 10, 10]; 

RAD = padarray(permute(radArray,[3 4 1 2]), padVec); % zero pad the radiance array

dx = double(sRange(2)-sRange(1));
dy = double(tRange(2)-tRange(1));
du = double((uRange(1)-uRange(2)).*sizePixelAperture);
dv = double((vRange(1)-vRange(2)).*sizePixelAperture);

RAD = ifftshift(RAD);
RAD = fftn(RAD);
RAD = fftshift(RAD);

[nxPad, nyPad, nuPad, nvPad] = size(RAD);

% We need our kx and ky vectors. The following code accounts for even or odd length vectors
if mod(size(RAD,1),2)  %Is this odd?  
    kx = -floor(size(RAD,1)/2) : floor(size(RAD,1)/2);
else %then it's even
    kx = -floor(size(RAD,1)/2) : floor(size(RAD,1)/2) - 1;
end

if mod(size(RAD,2),2)  %Is this odd?  
    ky = -floor(size(RAD,2)/2) : floor(size(RAD,2)/2);
else %then it's even
    ky = -floor(size(RAD,2)/2) : floor(size(RAD,2)/2) - 1;
end

if mod(size(RAD,3),2)  %Is this odd?  
    ku = -floor(size(RAD,3)/2) : floor(size(RAD,3)/2);
    kuMid = ceil(length(ku)/2);
else %then it's even
    ku = -floor(size(RAD,3)/2) : floor(size(RAD,3)/2) - 1;
    kuMid = length(ku)/2+1;
end

if mod(size(RAD,4),2)  %Is this odd?  
    kv = -floor(size(RAD,4)/2) : floor(size(RAD,4)/2);
    kvMid = ceil(length(kv)/2);
else %then it's even
    kv = -floor(size(RAD,4)/2) : floor(size(RAD,4)/2) - 1;
    kvMid = length(kv)/2+1;
end


ky = -ky; %This line is necessary because the direction of our y array is reversed

%Convert the kx, ky, ku, kv vectors into the frequency vectors based on the
%spatial domain sampling rate.


kx = kx./(dx.*nxPad);
ky = ky./(dy.*nyPad);
ku = ku./(du.*nuPad);
kv = kv./(dv.*nvPad);




[KX, KY] = ndgrid(kx, ky);


KXIndx = 1:length(kx);
KYIndx = 1:length(ky);

[KXIndx KYIndx] = ndgrid(KXIndx, KYIndx);


% We need a set of variables to allow us to oversample and interpolate the
% spectral slice before we generate our new focal plane. This pushes the
% aliased samples further from the center of the image so that they can be
% cropped off.

kxOS_2x = linspace(kx(1),kx(end),2*length(kx));
kyOS_2x = linspace(ky(1),ky(end),2*length(ky));
[KXOS KYOS] = ndgrid(kxOS_2x, kyOS_2x);





%This is a variable to hold the spectrum of our spectral slice.

G = (zeros(size(KX,1), size(KY,2)));

%These variables store our spectral slices for creating plots.

spec = zeros(size(G,1), size(G,2), length(focalPlanes));
specOS = single(zeros(size(KXOS,1), size(KYOS,2), length(focalPlanes)));

newimageFFT_lin = single(zeros([nx, ny, length(focalPlanes)]));



%% Clear extra variables - free up memory
clear kx ky

%Calculate the center of our array for indexing
npxOS = size(KXOS,1);
npyOS = size(KYOS,2);

xOSCenter = ceil(npxOS/2);
yOSCenter = ceil(npyOS/2);

xCenter = ceil(nx/2);
yCenter = ceil(ny/2);

interpVal = zeros(size(KX,1), size(KX,2));
          
dKu = abs(ku(2) - ku(1)); %ku spacing
dKv = abs(kv(2) - kv(1)); %kv spacing

win = -ceil(w/2):ceil(w/2);




%Initialize the weighting vectors
wnU = 0; 
wnV = 0;


%loop over each focal plane

for kk = 1:length(focalPlanes)

    
    %Calculate the sample values for our spectral slice
    
    ku_alpha = (1 - focalPlanes(kk) ) .* KX;
    kv_alpha = (1 - focalPlanes(kk) ) .* KY;
    
    
    ku_alphaPix = (ku_alpha./dKu) + kuMid; %We need to calculate distances based on pixel spacing for our interpolation
    
    ku_alphaIdx = round(ku_alphaPix); %calculate the nearest ku point
    
    ku_alphaIdx( ( ku_alphaIdx + win(1) ) < 1 )= NaN; %Check for index values outside the valid range
    ku_alphaIdx( ( ku_alphaIdx ) > (length(ku) - win(end) )) = NaN; %Check for index values outside the valid range
    
    
    kv_alphaPix = (kv_alpha./dKv) + kvMid; %We need to calculate distances based on pixel spacing for our interpolation

    kv_alphaIdx = round(kv_alphaPix); %calculate the nearest kv point
    
    kv_alphaIdx( ( kv_alphaIdx + win(1) ) < 1 )= NaN; %Check for index values outside the valid range
    kv_alphaIdx( ( kv_alphaIdx ) > (length(kv) - win(end) )) = NaN; %Check for index values outside the valid range
    
    
    for uIdx = 1:length(win) % Start with first pixel in the window in the U-direction, then find v pixels "above" and "below"
        
        wnU = 0*wnU;
        
        dU = ku_alphaPix - (ku_alphaIdx + win(uIdx)); %Distance to the closest u pixel. Needed for weighting function
        uInterp = ku_alphaIdx + win(uIdx);

        wnU = max(1-abs(dU),0);

        
        dIdxU = find(abs(dU)<w/2); %Check for pixels outside the window - These will be weighted by 0
        
        if ~isempty(dIdxU) %Only computer values we need
            
            
            for vIdx = 1:length(win)
                
                
                wnV = 0*wnV; 
        
                dV = kv_alphaPix - (kv_alphaIdx + win(vIdx));
                vInterp = kv_alphaIdx + win(vIdx);
                dIdxV = find(abs(dV)<w/2);
                dIdxV = intersect(dIdxU, dIdxV);
                
                wnV = max(1-abs(dV),0);
        

               if ~isempty(dIdxV)
                   
                    linIndexV = sub2ind(size(RAD), KXIndx(dIdxV), KYIndx(dIdxV), uInterp(dIdxV), vInterp(dIdxV));
                    
                    interpVal(dIdxV) = interpVal(dIdxV) + RAD(linIndexV).*wnV(dIdxV);

%                     interpVal(dIdxV) = interpVal(dIdxV) + real(RAD(linIndexV).*wnV(dIdxV));
%                     interpVal(dIdxV) = interpVal(dIdxV) + 1i.*imag(RAD(linIndexV).*wnV(dIdxV));
                    
               end
               
               
               
            end
        

        
        end
        
        G(dIdxU) = G(dIdxU) + (interpVal(dIdxU).*wnU(dIdxU));
        
        interpVal = 0*interpVal;
        
        

   
    end

     %% Oversample the spectrum by 2, perform ifft, then crop out central section
    
    GOS = interpn(KX, KY, G, KXOS, KYOS);
    
    Temp = fftshift(ifftn( ifftshift( GOS(:,:) )) );
    
    % Take the center of the spatial domain image
    
    Temp(1:(xOSCenter-xCenter+1),:) = [];
    Temp(nx+1:end,:) = [];

    Temp(:,1:(yOSCenter-yCenter+1)) = [];
    Temp(:,ny+1:end) = [];

    newimageFFT_lin(:,:,kk) = Temp;
    
    % Save our spectrum for plotting later

    spec(:,:,kk) = G;
    specOS(:,:,kk) = GOS;

    %Reset our variables
    
    G = zeros(size(G));
    GOS = zeros(size(GOS));
    

end


%Normalize the spectral stack to 1. This is not necessary just makes
%plotting easier.

newimageFFT_lin = newimageFFT_lin./max(max(max(newimageFFT_lin)));


fStackFFT = newimageFFT_lin;



%{
switch superSampling
    
    case 'none'
        
        [tActual,sActual]=ndgrid(tRange,sRange);
        
        for u=uRange
            for v=vRange.'
                
                % The plus 1 is to make the index start at 0 not 1. The interpPadding accounts for any pixel padding in interpimage2.m
                uIndex = -(u) + microRadius+1 + interpPadding; %u is negative here since the uVector decreases from top to bottom (ie +7 to -7) while MATLAB image indexing increases from top to bottom
                vIndex = -(v) + microRadius+1 + interpPadding; %v is negative here since the vVector decreases from top to bottom (ie +7 to -7) while MATLAB image indexing increases from top to bottom
                
                if apertureFlag == 0 || circMask(vIndex,uIndex) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    uAct = u.*sizePixelAperture; %u and v converted to millimeters here
                    vAct = v.*sizePixelAperture; %u and v converted to millimeters here
                    
                    % Shift-Invariant Method (Paul)
                    sQuery = uAct.*(alphaVal - 1) + sActual;
                    tQuery = vAct.*(alphaVal - 1) + tActual;
                    
                    extractedImageTemp=interpn(tActual,sActual,permute((radArray(uIndex,vIndex,:,:)),[4,3,2,1]),tQuery,sQuery,'*linear',0);
                    
                    syntheticImage= syntheticImage + extractedImageTemp*circMask(vIndex,uIndex);
                end
            end
        end
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
            if isvector(uActual)
                if length(uActual) > 1 && uActual(1) > uActual(2)
                    uActualM = uActual(end:-1:1);
                    VM = flipdim(V,idim);
                end
            else
                if size(uActual,idim) > 1
                    sizeX = size(uActual);
                    if uActual(1) > uActual(prod(sizeX(1:(idim-1)))+1)
                        uActualM = flipdim(uActual,idim);
                        VM = flipdim(V,idim);
                    end
                end
            end
            
            % From MATLAB's built-in 'makemonotonic' (see inside interpn)
            idim = 3;
            if isvector(vActual)
                if length(vActual) > 1 && vActual(1) > vActual(2)
                    vActualM = vActual(end:-1:1);
                    VM = flipdim(VM,idim);
                end
            else
                if size(vActual,idim) > 1
                    sizeX = size(vActual);
                    if vActual(1) > vActual(prod(sizeX(1:(idim-1)))+1)
                        vActualM = flipdim(vActual,idim);
                        VM = flipdim(VM,idim);
                    end
                end
            end
            
            Fimg = griddedInterpolant(tActual,sActual,vActualM,uActualM,VM,'linear','none');
        end
        
        for uInd=1:numel(uSSRange)
            for vInd=1:numel(vSSRange)
                
                if apertureFlag == 0 || circMask(vInd,uInd) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    
                    uPrime = uSSRange(uInd).*sizePixelAperture; %u and v converted to millimeters here
                    vPrime = vSSRange(vInd).*sizePixelAperture; %u and v converted to millimeters here
                    
                    % Shift-Invariant (Paul)
                    sEff = uPrime.*(alphaVal - 1) + sSSRange;
                    tEff = vPrime.*(alphaVal - 1) + tSSRange;
                    
                    [tQuery, sQuery, vQuery, uQuery] = ndgrid(tEff,sEff,vPrime,uPrime);
                    
                    switch oldMethod
                        case false
                            extractedImageTemp = Fimg(tQuery,sQuery,vQuery,uQuery);
                        otherwise
                            extractedImageTemp = interpn(tActual,sActual,vActual,uActual,I,tQuery,sQuery,vQuery,uQuery,'*linear',0);
                    end
                    extractedImageTemp(extractedImageTemp<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
                    extractedImageTemp(isnan(extractedImageTemp)) = 0;
                    syntheticImage = syntheticImage + extractedImageTemp.*circMask(vInd,uInd); %mulitple the radArray portion at a given u,v by 0-->1 according to the aperture location
                end
            end
        end
        
    case 'st'
        % Separate case here because it's about 2x faster than just using the uv/both case above
        for uInd=1:numel(uSSRange)
            for vInd=1:numel(vSSRange)
                
                if apertureFlag == 0 || circMask(vInd,uInd) ~= 0 %optimization; if full aperture used or if circular mask pixel is not zero, calculate.
                    
                    uPrime = uSSRange(uInd).*sizePixelAperture; %u and v converted to millimeters here
                    vPrime = vSSRange(vInd).*sizePixelAperture; %u and v converted to millimeters here
                    
                    % Shift-Invariant (Paul)
                    sEff = uPrime.*(alphaVal - 1) + sSSRange;
                    tEff = vPrime.*(alphaVal - 1) + tSSRange;
                    
                    Z = permute(radArray(uInd+interpPadding,vInd+interpPadding,:,:),[4 3 1 2]);
                    
                    extractedImageTemp(:,:) = interp2(sRange,tRange.',Z,sEff,tEff.','*linear',0); %row,col,Z,row,col
                    syntheticImage = syntheticImage + extractedImageTemp.*circMask(vInd,uInd); %mulitple the radArray portion at a given u,v by 0-->1 according to the aperture location
                end
            end
        end
        syntheticImage(syntheticImage<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.
    otherwise
        error('Incorrect supersampling logic determination. Debug refocus.m and/or check requestVector input.');
end
%}
% toc
end
