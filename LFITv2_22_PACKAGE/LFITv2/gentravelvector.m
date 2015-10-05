function [travelVector] = gentravelvector(edgeBuffer,subXRad,subYRad,SS_UV,travelVectorIndex)
% gentravelvector | Creates vector of points in (u,v) space through which the perspective function can sweep
%
% Set edgeBuffer to keep the path off the very edges of the image.
% Set SS_UV to gain finer, non-integer steps along the path.
% travelVectorIndex: 1 = square, 2 = circle, 3 = cross, 4 = load from file...


subXRadT = subXRad-edgeBuffer;
subYRadT = subYRad-edgeBuffer;
subWidthT = (subXRad*2 +1)-(edgeBuffer*2);
subHeightT = (subYRad*2 +1)-(edgeBuffer*2);

switch travelVectorIndex
    case 1 %square
        
        travInd = 0;
        
        for p = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT);];
        end
        for q =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q;];
        end
        for r = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [(subXRadT)-r (subYRadT);];
        end
        for svar =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar;];
        end
        
    case 2 % circular
        % NOTE: Algorithm from http://www.mathopenref.com/coordcirclealgorithm.html with slight modifications.
        theta = 0;       % angle that will be increased each loop
        h = 0;           % x coordinate of circle center
        k = 0;           % y coordinate of circle center
        step = 1/SS_UV;  % amount to add to theta each time (degrees)
        r = subXRadT;    % radius of circle
        travInd = 0;     % index
        
        while theta < 360;
            travInd = travInd + 1;
            travelVector(travInd,1) = (h + r*cosd(theta));
            travelVector(travInd,2) = (k + r*sind(theta));
            theta = theta + 7*step;
        end
        
    case 3 % cross
        
        travInd = 0;
        
        %L-R
        for p = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [-(subXRadT)+p 0;];
        end
        %R-C
        for p = (1:(subXRadT)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [(subXRadT)-p 0;];
        end
        %C-B
        for q =(1:(subYRadT)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [0 0-q;];
        end
        %B-T
        for q =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [0 (-subYRadT)+q;];
        end
        %T-C
        for q =(1:(subYRadT)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [0 subYRadT-q;];
        end
        %C-L
        for p = (1:(subXRadT)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [(0)-p 0;];
        end
        
    case 4 % load from file...
        
        [fileNameString,newPath] = uigetfile({'*.txt','Text files (*.txt)';'*.*','All Files';},'Select a text file containing the u and v coordinates for a perspective sweep...',cd);
        
        if fileNameString == 0
            % No file selected.
            warning('Invalid travel vector index. Automatically generating square travel vector.');
            
            travInd = 0;
                
                for p = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT);];
                end
                for q =(1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q;];
                end
                for r = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [(subXRadT)-r (subYRadT);];
                end
                for svar =(1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar;];
                end
                
        else
            try
                fileID = fopen([newPath fileNameString],'r');
                formatSpec = '%f %f';
                sizeA = [2 Inf];
                travelVector = fscanf(fileID,formatSpec,sizeA);
                fclose(fileID);
                travelVector = travelVector.';
            catch errRead
                warning('Error reading travel vector file. Check file and documentation. Using square vector.');
                travInd = 0;
                
                for p = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT);];
                end
                for q =(1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q;];
                end
                for r = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [(subXRadT)-r (subYRadT);];
                end
                for svar =(1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd= travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar;];
                end
            end
        end
        
    otherwise
        warning('Invalid travel vector index. Automatically generating square travel vector.');
        travInd = 0;
        
        for p = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT);];
        end
        for q =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q;];
        end
        for r = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [(subXRadT)-r (subYRadT);];
        end
        for svar =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd= travInd + 1;
            travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar;];
        end
end

end