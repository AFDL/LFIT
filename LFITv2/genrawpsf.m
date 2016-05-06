function [outputPSF] = genrawpsf(microDiameterExact,psfFlag)
%GENRAWPSF Generates a raw, unpadded PSF to be used in refocusing.
%
% microDiameterExact: exact diameter of a microlens in pixels
%
% psfFlag: 0 = reserved
%          1 = disk (ceiling, ie all ones)
%          2 = disk (sums to 1)
%          3 = disk (normalized to max of 1)

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


microRadius = (microDiameterExact/2) - 1;

if psfFlag > 0
    
    flatPSF = fspecial('disk', microRadius);
    
    switch psfFlag
        case 1 % disk, forced to all ones
            flatPSF(flatPSF>0) = 1;
            
        case 2 % intensities sum to 1
            % Nothing to do

        case 3 % normalized to a max of 1
            flatPSF = flatPSF./max(max(flatPSF));

        otherwise
            error('Invalid psfFlag passed to genpsf.m');

    end%switch
    
end%if

outputPSF = flatPSF; % note that this will need to be padded to match the experimental focal stack dimensions.

end%function
