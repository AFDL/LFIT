function [fStackFFT, spec, specOS] = fStackGen_FFT_LinWinR2(focalPlanes, RAD, x_array, y_array, u_array, v_array, padVec)
%FSTACKGEN_FFT_LINWINR2 Generate a focal stack using FFT based refocusing.
%
% IMPORTANT! Double precision is required for all data! Single precision
% will result in unusable results as padding size increases.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


w = 2; % Window size. This is fixed to 2 as of R4. Linear window (triangle) is always length 2

%focalPlanes - vector of the desired alpha values. e.g. [0.9, 0.95, 1, 1.05, 1.1]

%RAD - The 4D, plaid, radiance array - NOTE, this must be plaid!!!

%x_array, y_array, u_array, v_array - 4D location arrays - From R2 on this assumes the arrays are plaid.

% padVec - this specifies the number of zeroes to pad the RAD array by
% before the FFT. Good values are 5% in the spatial direction and 20 in the
% angular dimensions. e.g. padVec = [10, 10, 10, 10];

[nx, ny, ~, ~] = size(RAD);


%% Zero pad the radiance array
RAD = padarray(RAD, padVec);


dx = double(abs(x_array(2,1,1,1) - x_array(1)));
dy = double(abs(y_array(1,2,1,1) - y_array(1)));
du = double(abs(u_array(1,1,2,1) - u_array(1)));
dv = double(abs(v_array(1,1,1,2) - v_array(1)));

clear x_array y_array u_array v_array %Clear variables to free up memory


RAD = ifftshift(RAD);
RAD = fftn(RAD);
RAD = fftshift(RAD);


[nxPad nyPad nuPad nvPad] = size(RAD);



%% We need our kx and ky vectors. The following code accounts for even or odd length vectors

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

kxOS_2x     = linspace(kx(1),kx(end),2*length(kx));
kyOS_2x     = linspace(ky(1),ky(end),2*length(ky));
[KXOS KYOS] = ndgrid(kxOS_2x, kyOS_2x);





%This is a variable to hold the spectrum of our spectral slice.

G = (zeros(size(KX,1), size(KY,2)));

%These variables store our spectral slices for creating plots.

spec    = zeros(size(G,1), size(G,2), length(focalPlanes));
specOS  = zeros(size(KXOS,1), size(KYOS,2), length(focalPlanes), 'single');

newimageFFT_lin = zeros(nx, ny, length(focalPlanes), 'single');



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

        
        dIdxU = find( abs(dU) < w/2 ); %Check for pixels outside the window - These will be weighted by 0
        
        if ~isempty(dIdxU) %Only computer values we need
            
            
            for vIdx = 1:length(win)
                
                
                wnV = 0*wnV; 
        
                dV      = kv_alphaPix - (kv_alphaIdx + win(vIdx));
                vInterp = kv_alphaIdx + win(vIdx);
                dIdxV   = find( abs(dV) < w/2 );
                dIdxV   = intersect(dIdxU, dIdxV);
                
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

