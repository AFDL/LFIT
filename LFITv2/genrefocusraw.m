function [rawImageArray] = genrefocusraw(q,radArray,sRange,tRange)
%GENREFOCUSRAW Generates a series of refocused images, unscaled in intensity, as defined by the request vector

num=0; % timer logic
fprintf('\nGenerating refocused views...');
fprintf('\n   Time remaining:       ');

switch q.fZoom
    case 'legacy'
        nPlanes = length(q.fAlpha);
        rawImageArray = zeros( length(tRange)*q.stFactor, length(sRange)*q.stFactor, nPlanes, 'single' );
        
    case 'telecentric'
        nPlanes = length(q.fPlane);
        rawImageArray = zeros( length(q.fGridY), length(q.fGridX), nPlanes, 'single' );
        
end

for fIdx = 1:nPlanes % for each refocused
    
    time=tic;
    
    switch q.fZoom
        case 'legacy'
            qi          = q;
            qi.fAlpha   = q.fAlpha(fIdx);
            
            rawImageArray(:,:,fIdx) = refocus(qi,radArray,sRange,tRange);

        case 'telecentric'            
            si          = ( 1 - q.fMag )*q.fLength;
            so          = -si/q.fMag;
            soPrime     = so + q.fPlane(fIdx);
            siPrime     = (1/q.fLength - 1/soPrime)^(-1);
            
            qi          = q;
            qi.fAlpha   = siPrime/si;
            qi.fPlane   = q.fPlane(fIdx);
            
            rawImageArray(:,:,fIdx) = refocus(qi,radArray,sRange,tRange);

    end
        
    % Timer logic
    time=toc(time);
    timerVar=(time/60)*(nPlanes-fIdx);
    if timerVar>=1
        timerVar=round(timerVar);
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));    
        fprintf('%g m',timerVar)
    else
        timerVar=round( time*(nPlanes-fIdx) );
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));    
        fprintf('%g s',timerVar)
    end
    
end%for

fprintf('\n   Complete.\n');
