function [reconVol] = deconv3dwiener(in3DPSF, inFocalStack, regVal)
%DECONV3DWIENER Computes 3D Wiener filter deconvolution of a focal stack and 3D PSF
%
%  Takes a (centered) 3D PSF and focal stack as inputs. With the inputted regularization parameter,
%  a 3D Wiener filter deconvolution is taken. Outputs a 3D reconstructed volume.
%
%  Original Author: Paul Anglin
%  Adapted by: Jeffrey Bolan | 9/19/14

% Move centered focal stack and centered PSF to top left corner and take FFTs
fdPSF       = fftn(fftshift(in3DPSF)); %fdPSF = frequency domain PSF
fdFocalStack= fftn(fftshift(inFocalStack)); %fdFocalStack = frequency domain focal stack

% Normalize
fdPSF       = fdPSF/max(max(fdPSF(:));
fdFocalStack= fdFocalStack/max(fdFocalStack(:));

% 3D Deconvolution (Wiener)
Y = ( conj(fdPSF).*fdFocalStack )./( conj(fdPSF).*fdPSF + regVal );

% Move back to spatial domain and center
y = fftshift(ifftn(Y));

% Normalize
y = y/max(y(:));

% Output
reconVol = y;
reconVol(reconVol<0) = 0; % positivity constraint; a priori, we know that negative intensities are nonsensical


end

