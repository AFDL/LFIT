function [ sRange,tRange ] = computestrange(cal,imagePath,pixelPitch)
%COMPUTESTRANGE Calculates the s and t ranges for the calibration set.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


imCenterX   = size(imread(imagePath),2)/2;
imCenterY   = size(imread(imagePath),1)/2;

% Create s and t ranges based on median row and column
calCenterX  = median( cal.exactX(:) );
calCenterY  = median( cal.exactY(:) );

calCenterXY         = [calCenterX calCenterY];
microlensesXY(:,1)	= cal.exactX(:);
microlensesXY(:,2) 	= cal.exactY(:);
calCenterInd        = dsearchn( microlensesXY, calCenterXY );

% Find s and t indices for the microlens closest to the center
[calCenterS,calCenterT] = ind2sub( size(cal.exactX), calCenterInd );

calLimLeft   = min( cal.exactX(:,calCenterT) );     % find the minimum x pixel value from the center row
calLimTop    = min( cal.exactY(calCenterS,:) );     % find the minimum y pixel value from the center column
calLimRight  = max( cal.exactX(:,calCenterT) );     % find the maximum x pixel value from the center row
calLimBottom = max( cal.exactY(calCenterS,:) );     % find the maximum y pixel value from the center column

sRange      = linspace( calLimLeft-imCenterX, calLimRight-imCenterX, cal.numS )*pixelPitch;
tRange      = linspace( calLimTop-imCenterY, calLimBottom-imCenterY, cal.numT )*pixelPitch;

end%function
