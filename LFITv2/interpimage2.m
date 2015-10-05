function [radArray,sRange,tRange] = interpimage2(calData,imagePath,calType,microPitch,pixelPitch,numMicroX,numMicroY)
% interpimage2 | Generates the plaid radArray of intensities for a given image
%
% Uses input calibration data to extract microimages from the raw image,
% interpolating them onto a plaid grid in a 4D matrix (radArray)

% From the calibration data set
centers = calData{1};
xPoints = calData{2}; %used in visualization/debugging
yPoints = calData{3}; %used in visualization/debugging
kMax = calData{4};
lMax = calData{5}; % note that the notation is lowercase letter "L" max, not the number "1" max

% Read in image data
imageData=im2double(imread(imagePath));
imWidth = size(imageData,2);
imHeight = size(imageData,1);

% Calculate microlens radius in pixels
microRadius = floor((microPitch/pixelPitch)/2); % removed -1; should be 8 for rectangular and 7 for hexagonal now. Note that this is the 'x' microPitch.

% Calculate actual pitch between microlenses in x and y directions for (s,t) range calculations (especially hexagonal case)
microPitchX = (size(imageData,2)/numMicroX).*pixelPitch;
microPitchY = (size(imageData,1)/numMicroY).*pixelPitch;

% Define max extent of i and j

% Define u and v coordinate vectors in pixels
uVect = (microRadius:-1:-microRadius);
vVect = (microRadius:-1:-microRadius);
% uVect = (-microRadius:1:microRadius);
% vVect = (-microRadius:1:microRadius);

% Define padding
interpPadding = 1;

% Define u and v coordinate system vectors, padded by 1 pixel on each side.
uVectPad = (microRadius+interpPadding:-1:-microRadius-interpPadding);
vVectPad = (microRadius+interpPadding:-1:-microRadius-interpPadding);
% uVectPad = (-microRadius-interpPadding:1:microRadius+interpPadding);
% vVectPad = (-microRadius-interpPadding:1:microRadius+interpPadding);

[v,u]=ndgrid(vVect,uVect);

% Preallocate matrix
radArrayRaw=zeros(numel(vVect),numel(uVect),kMax,lMax);

% Initialize timer and update command line
num=0;
fprintf('\nInterpolating image data onto a uniform (u,v) grid...');
fprintf('\n   Time remaining:           ');

% Loop through each microlens
for k=1:kMax % column
    time=tic;
    for l=1:lMax % row % careful! It's for L = ONE : L MAX
        
        % Read in center in pixel coordinates at the current microlens from the calibration data
        xExact = centers(l,k,1);
        yExact = centers(l,k,2);
        
        % Round the centers in order to prepare vectors for extracting a small grid of image data.
        % These use the padded vectors to extract a slightly larger window to account for any NaN cropping
        % in the interpn step below, depending on the interpolation method used.
        xPixel = round(xExact) - uVectPad; %uVect is negative here so that Ihat below pulls from imageData from left to right (without flipping anything)
        yPixel = round(yExact) - vVectPad; %vVect is negative here so that Ihat below pulls from imageData from top to bottom (without flipping anything)
        
        % uhat and vhat are our known u,v coordinates which correspond to the u,v values of the small window of pixels we are extracting
        uKnown = xExact - xPixel;
        vKnown = yExact - yPixel;
        
        % Grid the coordinate vectors (via ndgrid as required for interpn)
        [vKnownGrid,uKnownGrid]=ndgrid(vKnown,uKnown);
        
        % Extract microimage (grid of pixels/intensities behind the given microlens)
        extractedI=imageData(yPixel,xPixel); % MATLAB indexing works via array(row,col) so be careful!
        
        % Window out data in square about circular aperture
        switch calType
            case 'rect'
                apertureFlag = 0; %allow the full square in
            case 'hexa'
                apertureFlag = 1; %allow only in the circular portion of the microimage to window out the overlap
        end
        
        switch apertureFlag
            case 0
                % Square/Full aperture
                circMask = ones(1+(2*((microRadius+interpPadding))));
            case 1
                % Circular mask close
                circMask = zeros(1+(2*((microRadius+interpPadding))));
                circMask(1+interpPadding:end-interpPadding,1+interpPadding:end-interpPadding) = fspecial('disk', double(microRadius)); %interpPadding here makes circMask same size as u,v dimensions of radArray
                cirlims=[min(min(circMask)) max(max(circMask))];
                circMask=(circMask-cirlims(1))./(cirlims(2) - cirlims(1));
            case 2
                % Circular mask wider
                circMask = fspecial('disk', double(microRadius+interpPadding)); %interpPadding here makes circMask same size as u,v dimensions of radArray
                cirlims=[min(min(circMask)) max(max(circMask))];
                circMask=(circMask-cirlims(1))./(cirlims(2) - cirlims(1));
            otherwise
                error('Aperture flag defined incorrectly. Check request vector.');
        end
        
        extractedI = extractedI.*circMask;
        
        % Interpolate. 
        % We know the pixel intensities at (decimal) u,v locations. 
        % Thus, we interpolate to get intensities at uniform/integer u,v locations.
        I=interpn(vKnownGrid,uKnownGrid,extractedI,v,u,'linear');
        I(I<0) = 0; % positivity constraint. Set negative values to 0 since they are non-physical.

        % Note generally how I is indexed I(v,u) or I(row,col).
        % Thus, if we're going to store this in a matrix indexed by (i,j,k,l), we must account for this.
        Ip = permute(I,[2 1]);
        
        % Store data in temporary raw radArray
        radArrayRaw(:,:,k,l) = single(Ip); %store as single
    end
    
    % Timer logic
    time=toc(time);
    timerVar=time/60*((kMax-k));
    
    if timerVar>=1
        timerVar=round(timerVar);
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g m',timerVar)
    else
        timerVar=round(time*((kMax-k)));
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));
        fprintf('%g s',timerVar)
    end
end
fprintf('\n   Complete.\n');

% Calculate sRange and tRange (in mm)
[sRange,tRange] = computestrange(calData,imagePath,microPitchX,microPitchY,pixelPitch);

% If it's a hexagonal array, resample onto a rectilinear grid
switch calType
    case 'rect'
        % no resampling required
        radArray = single(radArrayRaw);
   
    case 'hexa'
        
        num=0;
        fprintf('\nResampling onto rectilinear grid from hexagonal array...');
        fprintf('\n   Time remaining:           ');
        
        % Hypothetical s and t ranges for a rectangular array with the same number of microlenses as in the hexagonal
        sRange = single(sRange);
        tRange = single(tRange);
        
        % Create a rectilinear sampling grid
        spacingFactor = 2; % essentially supersampling factor in s. By setting this to 2, the resampled grid in the s direction will be twice as dense as the original s range.
        sSSRange = linspace(sRange(1),sRange(end),(numel(sRange))*spacingFactor); % this SS in the s direction allows some values to line up
        spacing = sSSRange(2) - sSSRange(1); % mm in horizontal direction
        tSSRange = linspace(tRange(1),tRange(end),round((tRange(end) - tRange(1))/spacing)  ); %t spacing should be the same as s spacing
        [tSSGrid, sSSGrid] = ndgrid(double(tSSRange),double(sSSRange));
        

        % Relate known x and y coordinate microlens locations to physical s and t locations in millimeters
        xKnown = reshape(centers(:,:,1),[],1).*pixelPitch - (imWidth.*pixelPitch)/2;
        yKnown = reshape(centers(:,:,2),[],1).*pixelPitch - (imHeight.*pixelPitch)/2;

        % Create interpolation vectors
        radArray = zeros(numel(uVect),numel(vVect),numel(sSSRange),numel(tSSRange),'single');
        
        % Interpolate the known hexagonal data to the rectilinear grid defined above
        
        % Initialize scatteredInterpolant, assuming a new enough version of MATLAB
        if verLessThan('matlab', '8.1')
            error('MATLAB 2013a or newer required for hexagonal resampling.');
        else
            initIntensity = double(reshape(permute(radArrayRaw(1,1,:,:),[4 3 2 1]),[],1));
            Ifun = scatteredInterpolant(yKnown,xKnown,initIntensity,'linear');
        end
        
       
        % Cycle through each u and v value, interpolating for s and t
        for uInd = 1:numel(uVect)
            time=tic;
            for vInd = 1:numel(vVect)
                knownIntensity = double(reshape(permute(radArrayRaw(uInd,vInd,:,:),[4 3 2 1]),[],1)); %rearrange intensity data into a single vector, holding an s value while varying t, incrementing to next s and sweeping through t again, etc...
                if verLessThan('matlab', '8.1')
                    error('MATLAB 2013a or newer required for hexagonal resampling.');
                else
                    Ifun.Values = knownIntensity; % intensities change, but we evaluate the same points
                    % Speed of below statement appears to be limited by the scattered interpolation; not the permute or reshape.
                    radArray(uInd,vInd,:,:) = permute(reshape(Ifun(tSSGrid(:),sSSGrid(:)),numel(tSSRange),numel(sSSRange)),[2 1]);
                end
            end
            
            % Timer logic
            time=toc(time);
            timerVar=time/60*((numel(uVect)-uInd));
            
            if timerVar>=1
                timerVar=round(timerVar);
                for count=1:num+2
                    fprintf('\b')
                end
                num=numel(num2str(timerVar));
                fprintf('%g m',timerVar)
            else
                timerVar=round(time*((numel(uVect)-uInd)));
                for count=1:num+2
                    fprintf('\b')
                end
                num=numel(num2str(timerVar));
                fprintf('%g s',timerVar)
            end
        end
        
        % Remove any NaN's if present.
        radArray = single(radArray);
        radArray(isnan(radArray)) = single(0);

        % Overwrite s and t ranges with the appropriate supersampled s and t ranges (since we've supersampled up front in this function, we need to make the
        % other functions think that the supersampled ranges are normal. Of course, this means any supersampling applied in later functions will be in addition
        % to the supersampling already applied here.
        sRange = sSSRange;
        tRange = tSSRange;
        fprintf('\n   Complete.\n');
end

end


