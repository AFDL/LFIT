function [cal] = lfiCalibrate( )
%lfiCalibrate uses a lens-center image and sensor information to create a plenoptic calibration.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


switch
end

switch lower(calMethod)
	case {'rect','rectFast'},	lfiCalibrate_rectFast
	case {'hexa','hexaFast'},	lfiCalibrate_hexaFast
	case 'rectRobust', 			lfiCalibrate_rectRobust
	case 'hexaRobust', 			lfiCalibrate_hexaRobust
	otherwise
end
