function [calData,tfAcceptCal] = calrect(calImagePath)
%CALRECT Fast rectangular calibration routine for plenoptic images.


k	= 7;        % hard coded; tolerance around microlens centers

%% Gather three calibration points from the user

% Prompt user for initial three points in the following fashion:
% . . .
% 1 2 .
% 3 . .

% Note that the above starting point (1) can be varied, as long as the
% positions of 2 and 3 remain the same RELATIVE to 1. Start the sequence on
% whatever microlens you want, but the pattern must be the same as above.

calImage = im2double(imread(calImagePath));

disp('Follow the instructions in the window to select the three initial microlens centers.');

cF = figure;
imagesc(calImage(1:256,1:256)); axis image; axis off; colormap(jet);

title('Select the first calibration point on the 2nd row');
points(1,:) = ginput(1);

title('Select the next calibration point to the right of the first point');
points(2,:) = ginput(1);

title('Now select the first point on the row beneath the first 2 points');
points(3,:) = ginput(1);
    
try     close(cF);
catch	% figure already closed
end

%% Search for other calibration points

[imPixelHeight,imPixelWidth] = size(calImage);
yspace      = points(3,2) - points(1,2);
xspace      = points(2,1) - points(1,1);
pixVert     = round(points(1,2));
pixHorz     = round(points(1,1));

done = false; first = false;

z = 10; b = 1;
while pixHorz < imPixelWidth
    
    a = 1;
    while pixVert < imPixelHeight
        
        if pixVert-10 < 0
            X(1,:)      = [];
            Y(1,:)      = [];
            pixVert     = round(pixVert+yspace);
        end
        
        if pixHorz-10 < 0
            X(:,1)      = [];
            Y(:,1)      = [];
            pixVert     = round(points(1,2));
            pixHorz     = round(points(2,1));
            first       = true;
            break
        end
        
        if pixHorz+10 > imPixelWidth
            X(:,end)	= [];
            Y(:,end)	= [];
            pixHorz     = imPixelWidth;
            pixVert     = imPixelHeight;
            done        = true;
            break
        end
        
        if pixVert+z > imPixelHeight
            X(end,:)        = [];
            Y(end,:)        = [];
            imPixelHeight   = Y(a-2,b) + yspace - 2;
            z               = 0;
        else
            Rvert = 0; Rhorz = 0;
            m = 0;
            for y = pixVert+(-4:4)
                for x = pixHorz+(-4:4)
                    m       = m + calImage(y,x);
                    Rhorz   = Rhorz + x*calImage(y,x);
                    Rvert   = Rvert + y*calImage(y,x);
                end
            end
            X(a,b)  = Rhorz/m;
            Y(a,b)  = Rvert/m;
            pixVert = round(Rvert/m+yspace);
            pixHorz = round(Rhorz/m);
            a       = a + 1;
        end
        
    end%while
    
    if done, break
    end
    
    if ~first
        pixVert = round(Y(1,b));
        pixHorz = round(X(1,b)+xspace);
        b       = b + 1;
    else
        first   = false;
    end
    
end%while

% Remove partial rows
while any(X(end,10:end-10)==0)
    X(end,:) = [];
    Y(end,:) = [];
end

% Remove partial columns
while any(X(10:end-10,end)==0)
    X(:,end) = [];
    Y(:,end) = [];
end


%% Assign (s,t,u,v) coordinates to pixel values

X   = permute(X,[2 1]);
Y   = permute(Y,[2 1]);

xc  = round(X(:,:)); % microlens centers to nearest pixel
yc  = round(Y(:,:));

% for r = -k:k
%     u(:,:,r+k+1) = -X + (xc-r);
%     v(:,:,r+k+1) = -Y + (yc+r);
% end

% for sInd = 1:size(X,1) 
%     for tInd = 1:size(X,2)
%         uhat(sInd,tInd,:)   = u(sInd,tInd,:);
%         vhat(sInd,tInd,:)   = v(sInd,tInd,:); 
%         i(sInd,tInd,:)      = X(sInd,tInd) + uhat(sInd,tInd,:);
%         j(sInd,tInd,:)      = Y(sInd,tInd) + vhat(sInd,tInd,:);
%     end
% end

% calData={i,j,uhat,vhat};
calibrationPoints(:,:,1) = permute(X,[2 1]);
calibrationPoints(:,:,2) = permute(Y,[2 1]);

% Convert calibrationPoints to X and Y lists
ind = 1;
for rw = 1:size(calibrationPoints(:,:,1),1)
    for cl = 1:size(calibrationPoints(:,:,2),2)
        closestPoint(ind,:) = (calibrationPoints(rw,cl,:));
        ind = ind + 1;
    end
end

sIndMax = size(calibrationPoints,2);
tIndMax = size(calibrationPoints,1);

calData = {calibrationPoints,closestPoint(:,1),closestPoint(:,2),sIndMax,tIndMax};

%% Verify calibration

% Rescale calibration for maximum contrast 
calImage = ( calImage - min(calImage(:)) )/range(calImage(:));

% Display calibration for inspection
cF = figure;
warning('off','images:initSize:adjustingMag'); % no warning output
imshow(calImage); hold on;
scatter(X(:),Y(:),'r+'); hold off;
title('Calibration Image: Microlens Centers. Inspect the image for apparent errors, then press any key to be prompted to validate/reject the calibration.');
pause;

% 
loop = true;
while loop
    
    userInput = input('Is the calibration correct/free from observable errors? Type Y or N: ','s');
    switch lower(userInput)
        case {'y','yes'}
            tfAcceptCal = true;
            fprintf('Calibration accepted.\n');
            loop = false;
            
        case {'n','no'}
            tfAcceptCal = false;
            fprintf('Calibration rejected.\n');
            loop = false;
            
        otherwise
            disp('Please enter Y or N then press the <Enter> key.');
            
    end
    
end%while

try     close(cF);
catch   % figure already closed
end

end%function
