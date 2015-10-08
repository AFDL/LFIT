function [rawImageArray] = genrefocusraw(radArray,requestVector,sRange,tRange)
%GENREFOCUSRAW Generates a series of refocused images, unscaled in intensity, as defined by the request vector

num=0; % timer logic
fprintf('\nGenerating refocused views...');
fprintf('\n   Time remaining:       ');
for aInd = 1:size(requestVector,1) % for each refocused 
    time=tic;
    
    magTypeFlag = requestVector{aInd,15}(1);% 0 = legacy, 1 = constant magnification
    
    switch magTypeFlag
        case 0
            rawImageArray(:,:,aInd) = refocus(radArray,requestVector{aInd,1},requestVector{aInd,2},requestVector{aInd,3},sRange,tRange,requestVector{aInd,11},requestVector{aInd,13},requestVector{aInd,14},requestVector{aInd,15});

        case 1
            f       = requestVector{aInd,15}(11);
            M       = requestVector{aInd,15}(12);
            si      = (1-M)*f;
            so      = -si/M;
            z       = requestVector{aInd,15}(13);
            soPrime = so + z;
            siPrime = (1/f - 1./soPrime).^(-1);
            MPrime  = siPrime./soPrime;
            alphaVal= siPrime/si; 
            
            rawImageArray(:,:,aInd) = refocus(radArray,alphaVal,requestVector{aInd,2},requestVector{aInd,3},sRange,tRange,requestVector{aInd,11},requestVector{aInd,13},requestVector{aInd,14},requestVector{aInd,15});

    end
        
    % Timer logic
    time=toc(time);
    timerVar=time/60*((size(requestVector,1)-aInd ));
    if timerVar>=1
        timerVar=round(timerVar);
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));    
        fprintf('%g m',timerVar)
    else
        timerVar=round(time*((size(requestVector,1)-aInd )));
        for count=1:num+2
            fprintf('\b')
        end
        num=numel(num2str(timerVar));    
        fprintf('%g s',timerVar)
    end
    
end%for
fprintf('\n   Complete.\n');
