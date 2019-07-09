function [onlineVersion,checkSuccess] = updatecheck(currentVersion)
%UPDATECHECK Checks online for updates to LFI Toolkit and notifies user if a newer version is available.
%
% A text file, found on the LFIT github repository, with the most current
% version number is compared against the current version of the LFI Toolkit
% (generally obtained by querying the text file in the LFI_toolkit function
% folder) as passed to this function.

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


% Update checker functionality
checkSuccess = 0;
onlineVersion = 0;

try
    
    if verLessThan('matlab', '8.0') == false % when MATLAB added 'Timeout' flag
        [strOnline,checkSuccess] = urlread('https://raw.githubusercontent.com/AFDL/LFIT/master/LFITv2/currentVersion.txt','Timeout',2); % read current version number of LFI Toolkit from text file
    else
        [strOnline,checkSuccess] = urlread('https://raw.githubusercontent.com/AFDL/LFIT/master/LFITv2/currentVersion.txt'); % basic method without timeout limit (for older versions of MATLAB)
    end
    
    if checkSuccess == 1 % if it worked (if not, don't trouble the user)
        onlineVersion = str2double(strOnline);
        if onlineVersion > currentVersion
            warning('Newer version of the Light Field Imaging Toolkit is available. Obtain updated version from AFDL Code Repository.');
            fprintf('Installed version of LFIT:  v%2.2f\n',currentVersion);
            fprintf('Newest version of LFIT:     v%2.2f\n',onlineVersion);
        end
    end
    
catch
    
    % update check failed. Don't bother the user.
    
end
