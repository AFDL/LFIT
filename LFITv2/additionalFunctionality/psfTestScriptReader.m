% function [reconVol] = (psfFlag,radArray,outputPath,imageSpecificName,microDiameterExact,sRange,tRange);
%PSFTESTSCRIPTREADER

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.

%% Get 3D PSF by reading in a folder containing a PSF focal stack

% arg0 = path, arg1 = prompt user for path (1 = true), arg2 = file type index (png = 4), arg3 = normalize (true or false)
[PSF3D] = readimseq('C:\imFolderPath',1,4,false);

%% Get focal stack of experimental volume by reading in from a folder

% arg0 = path, arg1 = prompt user for path (1 = true), arg2 = file type index (png = 4), arg3 = normalize (true or false)
[focalStack] = readimseq('C:\imFolderPath',1,4,false); 

%% 3D Deconvolution
regVal = 1e-4;
[reconVol] = deconv3dwiener(PSF3D, focalStack, regVal);

%% Save focal stack to folder

% arg1 = path, arg2 = prompt user for path (1 = true), arg3 = file type index (png = 4), arg4 = normalize (true or false)
saveimseq(reconVol,'C:\Locker\Plenoptic Data\My Experiments\3_Fall_2014\Flame Occlusion MINI\Process\Deconv',1,4,false);

implay(reconVol)
