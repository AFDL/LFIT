function [cal,tfAcceptCal] = calgeneral(calImagePath,calType,sens,numMicroX,numMicroY,microPitch,pixelPitch)
%CALGENERAL General method for generating calibration matrix.
%
% This function generates the calibration data matrix for a given
% calibration image. The basic algorithm outline is as follows:
%   1. Identifies all distinct objects (spots) in the scene
%   2. Calculates weighted centroids for all objects.
%   3. User selects first three points.
%   4. Program moves L->R along each row, guessing the location of the
%      next microlens, then searching the known list of centroid locations
%      for the closest result. If the returned location is too great a
%      distance away from the guess, the program assumes the guess is true
%      and repeats the process throughout the whole image.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


% Assign variables
sWidth      = numMicroX; %used for preallocation of megaMatrix; if actual values are higher, it'll just be a bit slower at the end.
tHeight     = numMicroY; % like above, used for preallocation to speed the program up.
subRadX     = floor((microPitch/pixelPitch)/2); % only used in tolerances/boundary limit calculations. Typically 8.
calFail     = false; % if something goes awry during calibration, auto fail and retry

% HARD CODED VALUES
xEdgeBuffer             = 8; % in pixels; prevents picking microlenses too far to the edge of the image
extraMicrolensMargin    = 5; % if the number of rows exceeds the number of microlenses in the y-direction PLUS this value, the calibration will fail.

% If the algorithm selects a microlens center located farther than maxAllowRadius
% from the predicted center, a dim microlens is assumed; the predicted center/guess
% is taken to be true, the searched selection is ignored, and the algorithm
% continues to the next microlens.
maxAllowRadius = subRadX/1.6;

% Load calibration image and pre-process to filter out noise
fprintf('Loading calibration image and pre-processing...');
calImage = im2double(imadjust(imread(calImagePath)));
calImageBW = bwmorph(im2bw(calImage,sens),'clean'); % create binary (black/white) image and filter out single pixel noise
fprintf('complete.\n');

switch lower(calType)
    case 'rect'
        
        % Calculate centroid locations
        fprintf('Calculating centroid locations...');
        centroidArray = regionprops(calImageBW, calImage, {'Centroid','WeightedCentroid'});
        numCent = numel(centroidArray); % number of centroids detected
        for k = 1 : numCent
            centroidArrayUnsorted(k,:) = (centroidArray(k).WeightedCentroid(:)); %single % x,y centroid locations (unsorted)
        end
        clear centroidArray; % free memory
        fprintf('complete.\n');
        
        
        % User input to select the first three points
        fprintf('Initializing center locations algorithm...');
        cF = figure;
        imagesc(calImage(1:256,1:256)); axis image; axis off; colormap(jet); hold on; % display top left window for selection purposes
        plot(centroidArrayUnsorted); hold off;
        
        title('Select the first calibration point (preferably on 2nd row or below):');
        clickPoint(1,:) = ginput(1);
        
        title('Select the next calibration point directly to the right of the first point:');
        clickPoint(2,:) = ginput(1);
        
        title('Now select the first point on the row beneath the first 2 points:');
        clickPoint(3,:) = ginput(1);
            
        clickPointInd = dsearchn(centroidArrayUnsorted(:,:),clickPoint);
        initialPoints = centroidArrayUnsorted(clickPointInd,:);
        
        try     close(cF);
        catch   % figure already closed
        end
        
        % Set up predictor/microlens ordering algorithm
        
        lastPoints      = initialPoints(1,:); % last points used
        lastDistX       = initialPoints(2,1) - initialPoints(1,1); % x2-x1
        lastDistY       = initialPoints(2,2) - initialPoints(1,2); % y2-y1
        rowSpc          = initialPoints(3,2) - initialPoints(1,2); % y3-y1 (row spacing)
        alphaPre        = atan((initialPoints(3,1) - initialPoints(1,1)) / (initialPoints(3,2) - initialPoints(1,2))); % vertical angle offset of lens centers (how much the columns are rotated in a sense, relative to the vertical axis)
        rowStarterPoints= initialPoints(1,:); % first point of a row (x,y)
        imageSize       = size(calImage); % define image dimensions
        rowInd          = 1; % row index
        colInd          = 2; % column index % start from 2 so that the first point is registered
        bottomMargin    = imageSize(1,1) - rowSpc; % bottom limit (to prevent selection of row pixels from a row that appears or disappears at the bottom; this crops it out essentially.)
        ind             = 1; % current index
        updateRowSpc    = false; % update row spacing and row starting point flag
        
        % Preallocate matrices
        rowWidth(tHeight)       = 0;
        closestPointRC          = zeros([sWidth tHeight 2],'double');
        closestPointRC(1,1,:)   = initialPoints(1,:);
        
        fprintf('complete.\n');
        fprintf('Beginning algorithm: ');
        fprintf('\nProgress: [');
        
        while true % Loop through each microlens in the image
            
            if lastPoints(1,1)+lastDistX > (imageSize(2) - (subRadX +xEdgeBuffer)) % make sure the predictor stays within the bounds of the image
                % Move to new row since the predictor has gone off the right side of the image
                rowWidth(rowInd) = colInd - 1;
                colInd = 1;
                % Guess next point, the first point of the next row
                nextGuess = [rowStarterPoints(1) + tan(alphaPre)*rowSpc   rowStarterPoints(2) + rowSpc];
                % Trigger flag to update row spacing number and row starter point locations
                updateRowSpc = true;
                if rowStarterPoints(2) + rowSpc > bottomMargin % prediction traveled beyond the bottom of the image so exit the loop
                    break
                end
                rowStarterPointsOld = rowStarterPoints;
                rowStarterPoints = nextGuess;
                rowInd = rowInd + 1; %t
            else
                % Same row
                nextGuess = [lastPoints(1,1)+lastDistX   lastPoints(1,2)+lastDistY];
            end
            
            % Use above x,y prediction to find the closest located microlens centroid to that guess
            [closestPointInd,closestPointDist] = dsearchn(centroidArrayUnsorted(:,:),nextGuess);
            
            % Logic to include dim points
            if closestPointDist > maxAllowRadius % can tweak this number to reduce the allowable variance between the guessed value and the searched value
                closestPointRC(rowInd,colInd,:) = nextGuess; % distance to closest centroid exceeds above bound; assume prediction is correct and microlens was too faint
            else
                closestPointRC(rowInd,colInd,:) = centroidArrayUnsorted(closestPointInd,:); % centroid location is within above bound; use it.
            end
            
            if updateRowSpc % new row
                rowSpc = closestPointRC(rowInd,colInd,2) - rowStarterPointsOld(1,2); % update row spacing if it varies
                rowStarterPoints = closestPointRC(rowInd,colInd,:); % also properly update row starting point
                updateRowSpc = false;
                if rem(rowInd,2) == 1 % every second row (odd row), update progess bar.
                    fprintf('.');
                end
            end
            
            lastPoints = closestPointRC(rowInd,colInd,:);
            colInd = colInd + 1; %s
            
            % If other logic to stop the predictor fails, this will end the loop based on the number of points
            if ind < numCent
                ind = ind + 1;
            else
                colInd = colInd - 1; %for clarity when examining variables since the next column wasn't evaluated
                break
            end
            
        end
        
        % Crop the image
        rowWidth(rowWidth==0)   = Inf; % keep zeros out of minimum calculation
        maxRowWidth             = min(rowWidth);
        maxColHeight            = rowInd - 1;
        calibrationPoints       = closestPointRC(1:maxColHeight,1:maxRowWidth,:);
        
        % User interface update
        fprintf(']\n Complete.\n');
        fprintf('\n');
        
        % Create calibration structure for export
        cal.exactX  = calibrationPoints(:,:,1)';     % x(s,t)
        cal.exactY  = calibrationPoints(:,:,2)';     % y(s,t)
        cal.roundX  = round( cal.exactX );
        cal.roundY  = round( cal.exactY );
        cal.numS    = maxRowWidth;
        cal.numT    = maxColHeight;
        
        
    case 'hexa'
        
        % User input to select the first three points
        fprintf('Initializing center locations algorithm...');
        cF = figure; imagesc(calImage(1:256,1:256)); axis image; axis off; colormap(gray); hold on; % display top left window for selection purposes
        
        centroidArraySel = regionprops(calImageBW(1:256,1:256), calImage(1:256,1:256), {'Centroid','WeightedCentroid'});
        for k = 1 : numel(centroidArraySel) % display weighted centroids overlaying the microlenses
            scatter(centroidArraySel(k).WeightedCentroid(1), centroidArraySel(k).WeightedCentroid(2), 'ro');
        end
        
        title('Select the first calibration point on the 1st overhanging row');
        clickPoint(1,:) = ginput(1);
        
        title('Select the next calibration point to the right of the first point');
        clickPoint(2,:) = ginput(1);
        
        title('Now select the first point on the inset row beneath the first 2 points');
        clickPoint(3,:) = ginput(1);
        
        for k=1:size(centroidArraySel,1)
            localXYList(k,:) = [centroidArraySel(k).WeightedCentroid(1) centroidArraySel(k).WeightedCentroid(2)];
        end
        clickPointInd = dsearchn(localXYList,clickPoint);
        initialPoints = localXYList(clickPointInd,:);
        
        try     close(cF);
        catch   % figure already closed
        end
        
        
        % Set up predictor/microlens ordering algorithm
        
        num             = 0; % initialize time remaining for display
        lastDistX       = initialPoints(2,1) - initialPoints(1,1); %x2-x1
        lastDistY       = initialPoints(2,2) - initialPoints(1,2); %y2-y1
        rowSpc          = initialPoints(3,2) - initialPoints(1,2); %y3-y1 (row spacing)
        imageSize       = size(calImage); % define image dimensions
        rowInd          = 1; % row index
        colInd          = 2; % column index % start from 2 so that the first point is registered
        bottomMargin    = imageSize(1,1) - 4*rowSpc; % bottom limit (to prevent selection of row pixels from a row that appears or disappears at the bottom; this crops it out essentially.)
        ind             = 1; % current index
        updateRowSpc    = false; % update row spacing and row starting point flag
        inset           = false; % flags if on an inset or outset row. Always start with outset row. This is the "odd-r" horizontal layout on http://www.redblobgames.com/grids/hexagons/
        rowStarterPoints= initialPoints(1,:); % first point of a row (x,y)
        lastPoints      = initialPoints(1,:); % last points used
        
        % Check that initial points aren't too close to either the left or top of the image
        if rowStarterPoints(1,1) < 2*(subRadX +xEdgeBuffer)
            % Move starting point over to the right by taking the 2nd point as the first
            rowStarterPoints = initialPoints(2,:);
            if rowStarterPoints(1,2) < (2*rowSpc + subRadX)
                % If too close to the top of the image, take the third initial point on the below row to keep the bottom loop from failing.
                rowStarterPoints = initialPoints(3,:);
                inset = true;
            end
            k=0;
            while rowStarterPoints(1,1) < 2*(subRadX +xEdgeBuffer) && k<6
                k = k+1; %loop stopper
                nextGuess = [rowStarterPoints(1,1)+lastDistX   rowStarterPoints(1,2)+lastDistY];
                guessPointInd = dsearchn(localXYList,nextGuess);
                rowStarterPoints = localXYList(guessPointInd,:);
            end
        end
        if rowStarterPoints(1,2) < (3*rowSpc + subRadX) && inset == false
            % If too close to the top of the image AND we haven't already tried the 3rd point (inset flag), take the third initial point on the below row to keep the bottom loop from failing.
            rowStarterPoints = initialPoints(3,:);
        else
            inset = false; % we'll call the starting row outset/overhanging regardless
            nextGuess = [(rowStarterPoints(1))  rowStarterPoints(2) + 2*rowSpc]; %jump down two rows
            guessPointInd = dsearchn(localXYList,nextGuess);
            rowStarterPoints = localXYList(guessPointInd,:);
        end
        lastPoints = rowStarterPoints(1,:); % start with whatever we moved the row starting point to.
        
        % Preallocate matrices
        rowWidth(tHeight)       = 0;
        closestPointRC          = zeros([sWidth tHeight 2],'double');
        closestPointRC(1,1,:)   = rowStarterPoints(1,:);
        
        fprintf('complete.\n');
        
        fprintf('Beginning algorithm: ');
        progress(0);
        
        while ~calFail % Loop through each microlens in the image
            if lastPoints(1,1)+lastDistX > (imageSize(2) - 2*(subRadX +xEdgeBuffer))  % make sure the predictor stays within the bounds of the image
                % Move to new row since the predictor has gone off the right side of the image
                rowWidth(rowInd) = colInd - 1;
                colInd = 1;
                % Guess next point, the first point of the next row
                if inset == false
                    inset = true; %inset/underhang row
                    nextGuess = [((rowStarterPoints(1)) + lastDistX/2)   (rowStarterPoints(2) + rowSpc)];
                else
                    inset = false; %outset/overhanging
                    nextGuess = [((rowStarterPoints(1)) - lastDistX/2)  (rowStarterPoints(2) + rowSpc)];
                end
                % Trigger flag to update row spacing number and row starter point locations
                updateRowSpc = true;
                if rowStarterPoints(2) + rowSpc > bottomMargin % prediction traveled beyond the bottom of the image so exit the loop
                    break
                end
                rowStarterPointsOld = rowStarterPoints;
                rowStarterPoints = nextGuess;
                rowInd = rowInd + 1; %t
                if rowInd > tHeight+extraMicrolensMargin
                    calFailString = 'Calibration failed. Number of rows identified exceeds number of microlenses present in the vertical direction.';
                    calFail = true; %if we've exceeded the total number of microlenses in the y direcction, something is wrong with the calibration
                end
                
            else
                % Same row
                nextGuess = [lastPoints(1,1)+lastDistX   lastPoints(1,2)+lastDistY];
            end
            
            % Use above x,y prediction to find the closest located microlens centroid to that guess
            nextXFlat = round(nextGuess(1));
            nextYFlat = round(nextGuess(2));
            centroidArrayLocal = regionprops(calImageBW((-subRadX+nextYFlat):(subRadX+nextYFlat),(-subRadX+nextXFlat):(subRadX+nextXFlat)), calImage((-subRadX+nextYFlat):(subRadX+nextYFlat),(-subRadX+nextXFlat):(subRadX+nextXFlat)), {'Centroid','WeightedCentroid'});
            if size(centroidArrayLocal,1) ~= 0
                localXYList = zeros(size(centroidArrayLocal,1),2);
                absXYList = zeros(size(centroidArrayLocal,1),2);
                for k=1:size(centroidArrayLocal,1)
                    localXYList(k,:) = [centroidArrayLocal(k).WeightedCentroid(1) centroidArrayLocal(k).WeightedCentroid(2)];
                end
                absXYList(:,1) = localXYList(:,1) + (nextXFlat-subRadX)-1;
                absXYList(:,2) = localXYList(:,2) + (nextYFlat-subRadX)-1;
                [closestPointInd,closestPointDist] = dsearchn(absXYList,nextGuess);
            else
                closestPointDist = maxAllowRadius + 1; %this triggers the auto point placement below when a centroid can't be found
            end
            
            % Logic to include dim points, varying according to whether it's a new row or not
            if ~updateRowSpc
                % Regular dim logic
                if closestPointDist > maxAllowRadius % can tweak this number to reduce the allowable variance between the guessed value and the searched value
                    closestPointRC(rowInd,colInd,:) = nextGuess; % distance to closest centroid exceeds above bound; assume prediction is correct and microlens was too faint
                else
                    closestPointRC(rowInd,colInd,:) = absXYList(closestPointInd,:); % centroid location is within above bound; use it.
                end
            else
                % We will enforce a more stringent constraint on the formation of a new row by reducing the variation permitted from the guess
                if closestPointDist > maxAllowRadius/2 % can tweak this number to reduce the allowable variance between the guessed value and the searched value
                    closestPointRC(rowInd,colInd,:) = nextGuess; % distance to closest centroid exceeds above bound; assume prediction is correct and microlens was too faint
                else
                    closestPointRC(rowInd,colInd,:) = absXYList(closestPointInd,:); % centroid location is within above bound; use it.
                end
                
            end
            
            clear localXYList absXYList;
            
            if updateRowSpc % new row
                rowSpc = closestPointRC(rowInd,colInd,2) - rowStarterPointsOld(1,2); % update row spacing if it varies
                rowStarterPoints = closestPointRC(rowInd,colInd,:); % also properly update row starting point
                updateRowSpc = false;
                %                 if rem(rowInd,2) == 1 % every second row (odd row), update progess bar.
                %                     fprintf('.');
                %                 end
                
                
                % Time remaining logic for display
                progress(rowInd,tHeight);
                
            end
            
            lastPoints = closestPointRC(rowInd,colInd,:);
            colInd = colInd + 1; %s
            
            ind = ind + 1;
            
        end%while
        
        if ~calFail
            % Crop the image from bottom and right
            rowWidth(rowWidth==0) = Inf; % keep zeros out of minimum calculation
            maxRowWidth = min(rowWidth);
            maxColHeight = rowInd - 1;
            calibrationPoints = closestPointRC(1:maxColHeight,1:maxRowWidth,:);
            
            % Create calibration structure for export
            cal.exactX  = calibrationPoints(:,:,1)';     % x(s,t)
            cal.exactY  = calibrationPoints(:,:,2)';     % y(s,t)
            cal.roundX  = round( cal.exactX );
            cal.roundY  = round( cal.exactY );
            cal.numS    = maxRowWidth;
            cal.numT    = maxColHeight;
        else
            % Calibration failed. Don't bother computing the above calData.
            cal = 0;
        end
        
        
        % FAST HEXAGONAL CAL
    case 'hexafast'
        
        k           = 6;    % hard coded; tolerance around microlens centers
        dC          = 0;    % basic counter
        startOffset = 1;    % 1 if overhanging, 0 if offset. We're enforcing the first row as overhanging.
        hexOrRect   = 1;    % 1 if hex, 0 if rect.
        
        calImage=im2double(imread(calImagePath));
        disp('Follow the instructions in the window to select the three initial microlens centers.');
        
        try     cF = figure('Name','Calibration','units','normalized','outerposition',[0 0 1 1]); %try to maximize
        catch,  cF = figure('Name','Calibration');
        end
        
        imagesc(calImage(1:256,1:256)); axis image; axis off; colormap(jet); hold on;
        
        title('1: Select the first microlens center calibration point...');
        points(1,:) = ginput(1);
        scatter(points(1,1),points(1,2),'r+');
            
        title('2: Select the next calibration point to the right of the first point');
        points(2,:) = ginput(1);
        scatter(points(2,1),points(2,2),'r+');
            
        title('3: Select the point on the next row that is directly between the first two points');
        points(3,:) = ginput(1);
        scatter(points(3,1),points(3,2),'r+');
            
        drawnow;
        
        try     close(cF);
        catch   % figure already closed
        end
        
        fprintf('\nIdentifying microlens centers');
        
        [imPixelHeight,imPixelWidth] = size(calImage);
        yspace  = points(3,2) - points(1,2);
        xspace  = points(2,1) - points(1,1);
        pixVert = round(points(1,2));
        pixHorz = round(points(1,1));
        
        z=8;done=false;first=false;
        
        b=1;
        while pixHorz<imPixelWidth
            
            a=1;
            while pixVert<imPixelHeight
                if pixVert-8<0
                    X(1,:)      = [];
                    Y(1,:)      = [];
                    pixVert     = round(pixVert+yspace);
                end
                if pixHorz-8<0
                    X(:,1)      = [];
                    Y(:,1)      = [];
                    pixVert     = round(points(1,2));
                    pixHorz     = round(points(2,1));
                    first       = true;
                    break
                    
                end
                if pixHorz+10>imPixelWidth %used to be +8; modified to +10 (Jeffrey; 2/3/15)
                    X(:,end)    = [];
                    Y(:,end)    = [];
                    pixHorz     = imPixelWidth;
                    pixVert     = imPixelHeight;
                    done        = true;
                    break
                end
                if pixVert+z > imPixelHeight
                    X(end,:)    = [];
                    Y(end,:)    = [];
                    imPixelHeight = Y(a-2,b) + yspace-2;
                    z = 0;
                else
                    Rvert=0;Rhorz=0;m=0;
                    for y=pixVert+(-4:4)
                        for x=pixHorz+(-4:4)
                            m       = calImage(y,x)+m;
                            Rhorz   = x*calImage(y,x) + Rhorz;
                            Rvert   = y*calImage(y,x) + Rvert;
                        end
                    end
                    X(a,b) = Rhorz/m;
                    Y(a,b) = Rvert/m;
                                      
                    % Modified from Tim
                    if mod((a+1 + startOffset),2) == 0
                        tempOff = -1;
                    else
                        tempOff = 1;
                    end
                    offset = hexOrRect.*tempOff; % do we offset this row? (1 = yes, 0 = no)                   
                    
                    % New row points
                    pixVert = round(Rvert/m+yspace);
                    pixHorz = round(Rhorz/m) + round(hexOrRect.*offset.*(xspace./2));
                    
                    a=a+1;
                end
            end%while
            
            if dC >=6
                fprintf('.');
                dC = 0;
            else
                dC = dC + 1;
            end
            
            if done
                fprintf('.complete!\n');
                break
            end
            
            if ~first %if first = false, calculate 
                pixVert = round(Y(1,b));
                pixHorz = round(X(1,b)+xspace);
                b       = b + 1;
            else
                first=false;
            end
            
        end%while
        
        fprintf('Internally arranging center location data into appropriate variables.');
        
        % Remove partial rows
        while any( X(end,10:end-10) == 0 )
            X(end,:) = [];
            Y(end,:) = [];
        end
        
        % Remove partial columns
        while any( X(10:end-10,end) == 0 )
            X(:,end) = [];
            Y(:,end) = [];
        end
        fprintf('.');
        
        % Create calibration structure for export
        cal.exactX  = permute(X,[2 1]);     % x(s,t)
        cal.exactY  = permute(Y,[2 1]);     % y(s,t)
        cal.roundX  = round( cal.exactX );
        cal.roundY  = round( cal.exactY );
        cal.numS    = size(cal.exactX,1);
        cal.numT    = size(cal.exactX,2);
        
        
        fprintf('complete!\n\n');
end

if ~calFail
    % Nothing above has flagged this as a bad calibration
      
    % SUBPLOTS
    try     cF = figure('Name','Inspect the corners then press any key to continue to the next step...','units','normalized','outerposition',[0 0 1 1]);
    catch,  cF = figure('Name','Inspect the corners then press any key to continue to the next step...');
    end
    
    calLimX     = (0.05*size(calImage,2));
    calLimY     = (0.05*size(calImage,1));
    calLimXU    = size(calImage,2);
    calLimYU    = size(calImage,1);
    
    subplot(2,2,1); %TL
    imshow(calImage(1:calLimY,1:calLimX),[]); hold on;
    
    % Find all the points within the displayed window
    tempI = find(cal.exactX>=1 & cal.exactX<=calLimX & cal.exactY>=1 & cal.exactY<=calLimY);
    scatter(cal.exactX(tempI),cal.exactY(tempI),'r+');
    title('Top Left');
    
    subplot(2,2,2); %TR
    imshow(calImage(1:calLimY,calLimXU-calLimX:calLimXU),[]); hold on; % resets coordinate system from 1:... instead of #:end; must account for this when plotting below
    tempI = find(cal.exactX>=calLimXU-calLimX & cal.exactX<=calLimXU & cal.exactY>1 & cal.exactY<=calLimY);
    scatter(cal.exactX(tempI)-(calLimXU-calLimX) + 1,cal.exactY(tempI),'r+'); % Account for offset. The plus 1 is because MATLAB images are indexed starting with 1, not 0.
    title('Top Right');
    
    subplot(2,2,3); %BL
    imshow(calImage(calLimYU-calLimY:calLimYU,1:calLimX),[]); hold on;
    tempI = find(cal.exactX>=1 & cal.exactX<=calLimX & cal.exactY>=(calLimYU-calLimY) & cal.exactY<=calLimYU);
    scatter(cal.exactX(tempI),cal.exactY(tempI) - (calLimYU-calLimY) + 1,'r+');
    title('Bottom Left');
    
    subplot(2,2,4); %BR
    imshow(calImage(end-calLimY:end,end-calLimX:end),[]); hold on;
    tempI = find(cal.exactX>=calLimXU-calLimX & cal.exactX<=calLimXU & cal.exactY>=(calLimYU-calLimY) & cal.exactY<=calLimYU);
    scatter(cal.exactX(tempI)-(calLimXU-calLimX) + 1,cal.exactY(tempI) - (calLimYU-calLimY) + 1,'r+');
    title('Bottom Right');
    
    pause;
    try     close(cFR);
    catch   % figure already closed
    end
    
    fprintf('\n|   POST-CALIBRATION MENU   |\n');
    fprintf('-----------------------------------------------------------------\n');
    fprintf('[1] = Accept the calibration. \n');
    fprintf('[2] = Reject the calibration. \n');
    fprintf('[3] = View the full calibration window.\n');
    fprintf('[4] = View the "corners" calibration window.\n');
    fprintf('\n');
    
    while true
        
        userInput = input('Enter a number from the menu above to proceed: ','s');
        switch lower(strtrim(userInput))
            case {'1','one','y','yes'}
                tfAcceptCal = true;
                fprintf('Calibration accepted. Continuing...\n');
                break
                
            case {'2','two','n','no'}
                tfAcceptCal = false;
                calFailString ='Calibration rejected.';
                break
                
            case {'3','three'}
                % FULL WINDOW
                cF = figure;
                warning('off','images:initSize:adjustingMag'); %no warning output
                imshow(calImage,[])
                hold on
                title('Calibration Image: Microlens Centers. Press any key to be prompted to validate/reject the calibration...');
                scatter(cal.exactX(:),cal.exactY(:),'r+');
                pause;
                try     close(cFR);
                catch   % figure already closed
                end
                
            case {'4','four'}
                % SUBPLOTS
                try     cF = figure('Name','Inspect the corners then press any key to continue to the next step...','units','normalized','outerposition',[0 0 1 1]);
                catch,  cF = figure('Name','Inspect the corners then press any key to continue to the next step...');
                end
                
                calLimX = (0.05*size(calImage,2));
                calLimY = (0.05*size(calImage,1));
                calLimXU = size(calImage,2);
                calLimYU = size(calImage,1);
                
                subplot(2,2,1); %TL
                imshow(calImage(1:calLimY,1:calLimX),[]); hold on;
                % Find all the points within the displayed window
                tempI = find(cal.exactX>=1 & cal.exactX<=calLimX & cal.exactY>=1 & cal.exactY<=calLimY);
                scatter(cal.exactX(tempI),cal.exactY(tempI),'r+');
                title('Top Left');
                
                subplot(2,2,2); %TR
                imshow(calImage(1:calLimY,calLimXU-calLimX:calLimXU),[]); hold on; % resets coordinate system from 1:... instead of #:end; must account for this when plotting below
                tempI = find(cal.exactX>=calLimXU-calLimX & cal.exactX<=calLimXU & cal.exactY>1 & cal.exactY<=calLimY);
                scatter(cal.exactX(tempI)-(calLimXU-calLimX) + 1,cal.exactY(tempI),'r+'); % Account for offset. The plus 1 is because MATLAB images are indexed starting with 1, not 0.
                title('Top Right');
                
                subplot(2,2,3); %BL
                imshow(calImage(calLimYU-calLimY:calLimYU,1:calLimX),[]);
                hold on;
                tempI = find(cal.exactX>=1 & cal.exactX<=calLimX & cal.exactY>=(calLimYU-calLimY) & cal.exactY<=calLimYU);
                scatter(cal.exactX(tempI),cal.exactY(tempI) - (calLimYU-calLimY) + 1,'r+');
                title('Bottom Left');
                
                subplot(2,2,4); %BR
                imshow(calImage(end-calLimY:end,end-calLimX:end),[]);
                hold on;
                tempI = find(cal.exactX>=calLimXU-calLimX & cal.exactX<=calLimXU & cal.exactY>=(calLimYU-calLimY) & cal.exactY<=calLimYU);
                scatter(cal.exactX(tempI)-(calLimXU-calLimX) + 1,cal.exactY(tempI) - (calLimYU-calLimY) + 1,'r+');
                title('Bottom Right');
                
                pause;
                try     close(cFR);
                catch   %figure already closed
                end
                
            otherwise
                disp('Please enter a number from the above menu then press the <Enter> key.');
                
        end%switch
        
    end%while
    
else
    tfAcceptCal = false;
    warning(calFailString); 
end
