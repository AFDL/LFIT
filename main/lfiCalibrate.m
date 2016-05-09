function [cal] = lfiCalibrate( calImagePath, calMethod )
%LFICALIBRATE uses a lens-center image and sensor information to create a plenoptic calibration.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


if nargin<2
	% No calibration method specified, determine automatically
	imWidth = size( imread(calImagePath), 2 );
	switch imWidth
		case 6600, calMethod = 'hexa';
		case 4904, calMethod = 'rect';
		otherwise, error('Unable to automatically determine calibration type.')
end

switch lower(calMethod)
	case {'rect','rectFast'}
		cal = lfiCalibrate_rectFast( calImagePath );

		if ~isstruct(cal)
			warning('Fast rectangular calibration failed. Trying robust method.');
			cal = lfiCalibrate( calImagePath, 'rectRobust' );
		end%if

	case {'hexa','hexaFast'}
		cal = lfiCalibrate_hexaFast( calImagePath );

		if ~isstruct(cal)
			warning('Fast hexagonal calibration failed. Trying robust method.');
			cal = lfiCalibrate( calImagePath, 'hexaRobust' );
		end%if

	case 'rectRobust'
		cal = lfiCalibrate_rectRobust( calImagePath );
		
		if ~isstruct(cal), error('Robust rectangular calibration failed.'); end

	case 'hexaRobust'
		cal = lfiCalibrate_hexaRobust( calImagePath );

		if ~isstruct(cal), error('Robust hexagonal calibration failed.'); end

	otherwise
		error('Invalid calibration method specified.');

end%switch

end%function
