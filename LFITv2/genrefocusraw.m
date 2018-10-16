function [rawImageArray] = genrefocusraw(q,radArray,sRange,tRange)
%GENREFOCUSRAW Generates a series of refocused images, unscaled in intensity, as defined by the request vector.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


fprintf('\nGenerating refocused views...');
progress(0);

switch q.fZoom
    case 'legacy'
        nPlanes = length(q.fAlpha);
        rawImageArray = zeros( length(tRange)*q.stFactor, length(sRange)*q.stFactor, nPlanes, 'single' );

    case 'telecentric'
        nPlanes = length(q.fPlane);
        rawImageArray = zeros( length(q.fGridY), length(q.fGridX), nPlanes, 'single' );

end

for fIdx = 1:nPlanes % for each refocused

    switch q.fZoom
        case 'legacy'
            qi          = q;
            qi.fAlpha   = q.fAlpha(fIdx);

            rawImageArray(:,:,fIdx) = refocus(qi,radArray,sRange,tRange);

        case 'telecentric'
            qi          = q;
            qi.fPlane   = q.fPlane(fIdx);

            rawImageArray(:,:,fIdx) = refocus(qi,radArray,sRange,tRange);

    end

    % Timer logic
    progress(fIdx,nPlanes);

end%for
