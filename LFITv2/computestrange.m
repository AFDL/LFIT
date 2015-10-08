function [ sRange,tRange ] = computestrange(calData,imagePath,microPitchX,microPitchY,pixelPitch)
%COMPUTESTRANGE Calculates the s and t ranges for the calibration set

% From calibration data
centers = calData{1};
xPoints = calData{2};
yPoints = calData{3};
kMax    = calData{4};
lMax    = calData{5};

xCenter = size(im2double(imread(imagePath)),2)/2;
yCenter = size(im2double(imread(imagePath)),1)/2;
imageCenter = [xCenter yCenter];


% Create s and t ranges based on median row and column
midX = median(xPoints);
midY = median(yPoints);

calibratedAreaCenter = [midX midY];
closestPoint(:,1) = xPoints;
closestPoint(:,2) = yPoints;
[centerMicrolensInd, offsetDist] = dsearchn(closestPoint(:,:),calibratedAreaCenter);
locationCenterMicrolens = closestPoint(centerMicrolensInd,:);

% Logic to account for if one side is cropped more than the other
xCenters = centers(:,:,1);
yCenters = centers(:,:,2);

% Find k and l indices for the microlens closest to the center
indexK = dsearchn(xCenters(:),locationCenterMicrolens(1));
indexL = dsearchn(yCenters(:),locationCenterMicrolens(2));

[unused,kCenter] = ind2sub(size(xCenters),indexK);
[lCenter,unused] = ind2sub(size(yCenters),indexL);

leftLimit   = min(min(xCenters(lCenter,:))); % find the minimum x pixel value from the center row
topLimit    = min(min(yCenters(:,kCenter))); % find the minimum y pixel value from the center column
rightLimit  = max(max(xCenters(lCenter,:))); % find the maximum x pixel value from the center row
bottomLimit = max(max(yCenters(:,kCenter))); % find the maximum y pixel value from the center column

sRange = linspace(leftLimit-imageCenter(1),rightLimit-imageCenter(1),kMax).*pixelPitch;
tRange = linspace(topLimit-imageCenter(2),bottomLimit-imageCenter(2),lMax).*pixelPitch;

end

