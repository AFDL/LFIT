function [ sRange,tRange ] = computestrange(cal,imagePath,pixelPitch)
%COMPUTESTRANGE Calculates the s and t ranges for the calibration set


imCenterX   = size(im2double(imread(imagePath)),2)/2;
imCenterY   = size(im2double(imread(imagePath)),1)/2;

% Create s and t ranges based on median row and column
midX        = median(cal.roundX(:));
midY        = median(cal.roundY(:));

calibratedAreaCenter    = [midX midY];
closestPoint(:,1)       = cal.roundX(:);
closestPoint(:,2)       = cal.roundY(:);
[centerMicrolensInd,~]  = dsearchn(closestPoint,calibratedAreaCenter);
locationCenterMicrolens = closestPoint(centerMicrolensInd,:);

% Find k and l indices for the microlens closest to the center
indexK      = dsearchn(cal.exactX(:),locationCenterMicrolens(1));
indexL      = dsearchn(cal.exactY(:),locationCenterMicrolens(2));

[~,kCenter] = ind2sub(size(cal.exactX),indexK);
[lCenter,~] = ind2sub(size(cal.exactY),indexL);

leftLimit   = min(min(cal.exactX(lCenter,:))); % find the minimum x pixel value from the center row
topLimit    = min(min(cal.exactY(:,kCenter))); % find the minimum y pixel value from the center column
rightLimit  = max(max(cal.exactX(lCenter,:))); % find the maximum x pixel value from the center row
bottomLimit = max(max(cal.exactY(:,kCenter))); % find the maximum y pixel value from the center column

sRange      = linspace( leftLimit-imCenterX, rightLimit-imCenterX, cal.numS )*pixelPitch;
tRange      = linspace( topLimit-imCenterY, bottomLimit-imCenterY, cal.numT )*pixelPitch;

end%function
