function [travelVector] = gentravelvector(edgeBuffer,sizeRad,SS_UV,travelVectorIndex)
%GENTRAVELVECTOR Creates vector of points in (u,v) space through which the perspective function can sweep.
%
% Set edgeBuffer to keep the path off the very edges of the image.
% Set SS_UV to gain finer, non-integer steps along the path.
% travelVectorIndex: 1 = square, 2 = circle, 3 = cross, 4 = load from file

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.

subXRad = floor( sizeRad(2)/2 );
subYRad = floor( sizeRad(1)/2 );

subXRadT    = subXRad - edgeBuffer;
subYRadT    = subYRad - edgeBuffer;
subWidthT   = (subXRad*2 +1) - (edgeBuffer*2);
subHeightT  = (subYRad*2 +1) - (edgeBuffer*2);

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
        theta   = 0;        % angle that will be increased each loop
        h       = 0;        % x coordinate of circle center
        k       = 0;        % y coordinate of circle center
        step    = 1/SS_UV;  % amount to add to theta each time (degrees)
        r       = subXRadT; % radius of circle
        travInd = 0;        % index
        
        while theta < 360;
            travInd = travInd + 1;
            travelVector(travInd,1) = (h + r*cosd(theta));
            travelVector(travInd,2) = (k + r*sind(theta));
            theta = theta + 7*step;
        end
        
    case 3 % cross
        
        travInd = 0;

        for p = (1:(subWidthT-1)*SS_UV)/SS_UV  % left -> right
            travInd = travInd + 1;
            travelVector(travInd,:) = [-(subXRadT)+p 0];
        end

        for p = (1:(subXRadT)*SS_UV)/SS_UV  % right -> center
            travInd = travInd + 1;
            travelVector(travInd,:) = [(subXRadT)-p 0];
        end

        for q =(1:(subYRadT)*SS_UV)/SS_UV  % center -> bottom
            travInd = travInd + 1;
            travelVector(travInd,:) = [0 0-q];
        end

        for q =(1:(subHeightT-1)*SS_UV)/SS_UV  % bottom -> top
            travInd = travInd + 1;
            travelVector(travInd,:) = [0 (-subYRadT)+q];
        end

        for q =(1:(subYRadT)*SS_UV)/SS_UV  % top -> center
            travInd = travInd + 1;
            travelVector(travInd,:) = [0 subYRadT-q];
        end

        for p = (1:(subXRadT)*SS_UV)/SS_UV  % center -> left
            travInd = travInd + 1;
            travelVector(travInd,:) = [(0)-p 0];
        end
        
    case 4 % load from file...
        
        [fileNameString,newPath] = uigetfile({'*.txt','Text files (*.txt)';'*.*','All Files';},'Select a text file containing the u and v coordinates for a perspective sweep...',cd);
        
        if fileNameString == 0
            % No file selected.
            warning('Invalid travel vector index. Automatically generating square travel vector.');
            
            travInd = 0;
                
                for p = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT)];
                end
                for q = (1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd=  travInd + 1;
                    travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q];
                end
                for r = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [(subXRadT)-r (subYRadT)];
                end
                for svar = (1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar];
                end
                
        else
            try
                fileID = fopen([newPath fileNameString],'r');
                formatSpec = '%f %f';
                sizeA = [2 Inf];
                travelVector = fscanf(fileID,formatSpec,sizeA);
                fclose(fileID);
                travelVector = travelVector.';
            catch
                warning('Error reading travel vector file. Check file and documentation. Using square vector.');
                travInd = 0;
                
                for p = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT)];
                end
                for q = (1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q];
                end
                for r = (1:(subWidthT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [(subXRadT)-r (subYRadT)];
                end
                for svar = (1:(subHeightT-1)*SS_UV)/SS_UV
                    travInd = travInd + 1;
                    travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar];
                end
            end
        end
        
    otherwise
        warning('Invalid travel vector index. Automatically generating square travel vector.');
        travInd = 0;
        
        for p = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd = travInd + 1;
            travelVector(travInd,:) = [-(subXRadT)+p -(subYRadT)];
        end
        for q =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd = travInd + 1;
            travelVector(travInd,:) = [(subXRadT) -(subYRadT)+q];
        end
        for r = (1:(subWidthT-1)*SS_UV)/SS_UV
            travInd = travInd + 1;
            travelVector(travInd,:) = [(subXRadT)-r (subYRadT)];
        end
        for svar =(1:(subHeightT-1)*SS_UV)/SS_UV
            travInd = travInd + 1;
            travelVector(travInd,:) = [-(subXRadT) (subYRadT)-svar];
        end
        
end%switch

end%function
