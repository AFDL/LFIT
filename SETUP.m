%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                      INSTALLER SCRIPT FOR LFIT                      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Run this script once to install the LFI 
% Toolkit in the appropriate MATLAB folder.
%
% Caution: This program deletes the LFITv2
% directory in the MATLAB user directory if 
% approved by the user. As always, AVOID 
% saving user files in this LFI_toolkit
% folder to avoid loss of data.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


clear variables; close all; clc;

tempUserString = userpath;
userString = tempUserString(1:end-1);
pathString = fullfile(userString,'LFITv2',filesep);

try % try to get current version of the toolkit
    currentVersion = importdata(fullfile('LFITv2','currentVersion.txt')); % literally local (ie in cd subfolder) version per file
catch err0
    error('SETUP.m cannot find the LFITv2 function subfolder with currentVersion.txt. Make sure you did not move SETUP.m from the extracted LFITv2 Package zip file.');
end

fprintf('LFIT INSTALLATION - Version %2.2f\n',currentVersion);
fprintf('---------------------------------------------\n\n');

addpath('LFITv2/'); % adds the local toolkit folder to the top of MATLAB's search path listing
[onlineVersion,checkSuccess] = updatecheck(currentVersion); % Check online for updates, notifying user if newer Light Field Imaging Toolkit available.
rmpath('LFITv2/'); % removes the local toolkit folder from the top of MATLAB's search path listing

if checkSuccess && onlineVersion > currentVersion % if successful update check and newer version availabe, ask user whether or not to install this OLD version (since a newer one is apparently available)
    loop = true;
    fprintf('\n');
    fprintf('A newer version of the Light Field Imaging Toolkit (%2.2f) is available.',onlineVersion);
    inputString = sprintf('Continue installing this older version (%2.2f)? Y or N: ',currentVersion);
    while loop
        userInput = input(inputString, 's');
        switch lower(userInput)
            case {'y','yes'}
                tfInstall = true;
                fprintf('Proceeding with older version installation.\n');
                loop = false;
            case {'n','no'}
                tfInstall = false;
                fprintf('Stopping installer.\n');
                loop = false;
            otherwise
                disp('Please enter Y or N then press the <Enter> key.');
        end
    end
    
else
    tfInstall = true;
end

if ~tfInstall
    fprintf('\nSETUP DID NOT COMPLETE. \nPROGRAM END. \n');
else
    % Check for existing toolkit folders
    if exist(pathString,'dir') == 7 %found existing directory
        if exist([pathString 'currentVersion.txt'],'file') == 2 % look for version file
            LFIversion = importdata([pathString 'currentVersion.txt']);
            if LFIversion > currentVersion % newer version already installed
                loop = true;
                fprintf('\n');
                disp(['A newer version of the Light Field Imaging Toolkit (' num2str(LFIversion,'%2.2f') ') is ALREADY INSTALLED.']);
                inputString = ['Do you wish to DELETE the existing installation and INSTALL this older version (' num2str(currentVersion,'%2.2f') ')? Y or N: '];
                while loop
                    userInput = input(inputString, 's');
                    switch lower(userInput)
                        case {'y','yes'}
                            tfInstall = true;
                            fprintf('Proceeding with older version installation.\n');
                            loop = false;
                        case {'n','no'}
                            tfInstall = false;
                            fprintf('Stopping installer.\n');
                            loop = false;
                        otherwise
                            disp('Please enter Y or N then press the <Enter> key.');
                    end
                end
            else % older version installed
                loop = true;
                disp(['An older version of the Light Field Imaging Toolkit (' num2str(LFIversion,'%2.2f') ') has been found.']);
                inputString = ['Do you wish to DELETE the existing installation and INSTALL this newer version (' num2str(currentVersion,'%2.2f') ')? Y or N: '];
                while loop
                    userInput = input(inputString, 's');
                    switch lower(userInput)
                        case {'y','yes'}
                            tfInstall = true;
                            fprintf('Proceeding with newer version installation.\n');
                            loop = false;
                        case {'n','no'}
                            tfInstall = false;
                            fprintf('Stopping installer.\n');
                            loop = false;
                        otherwise
                            disp('Please enter Y or N then press the <Enter> key.');
                    end
                end
            end
            
        else % no version file found, but folder already exists.
            loop = true;
            disp('An existing Light Field Imaging Toolkit folder has been found.');
            inputString = sprintf('Do you wish to DELETE the existing installation and INSTALL this version (%2.2f)? Y or N: ', currentVersion);
            while loop
                userInput = input(inputString, 's');
                switch lower(userInput)
                    case {'y','yes'}
                        tfInstall = true;
                        fprintf('Proceeding with installation.\n');
                        loop = false;
                    case {'n','no'}
                        tfInstall = false;
                        fprintf('Stopping installer.\n');
                        loop = false;
                    otherwise
                        disp('Please enter Y or N then press the <Enter> key.');
                end
            end
        end % version file if statement
    else % no existing installation found
        % continue
    end
    if tfInstall %if still true
        %install
        if exist(pathString,'dir') == 7 % if found existing directory, DELETE it
            rState = recycle; % record recycling state
            recycle('on'); % send deleted files to recycle bin or equivalent
            try
                rmdir(pathString,'s'); % delete existing LFI_toolkit folder
            catch err1
                % Can't remove directory. Throw error. User might manually install the program instead.
                error('Could not remove existing LFI_toolkit directory. Close all open files, applications, and windows related to this folder and retry setup or manually install.');
            end
            recycle(rState); % restore state
        end
        copyfile('LFITv2/',pathString,'f');
        fprintf('\nINSTALLATION COMPLETE. \nPROGRAM END. \n');
    else
        %end program
        fprintf('\nSETUP DID NOT COMPLETE. \nPROGRAM END. \n');
    end
    
end
