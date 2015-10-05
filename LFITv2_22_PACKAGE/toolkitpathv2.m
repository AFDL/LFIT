function [pathString, LFIversion] = toolkitpathv2(useAltPath,altPathString)
% toolkitpath | Returns path to the folder containing the LFI toolkit and the current version.
%
%  Usage Notes: The default path for the toolkit is typically "C:\Users\<current user>\MATLAB\LFITv2\".
%  It is assumed that the toolkit will be in the MATLAB user directory as above regardless. However, if a different
%  path is desired for the toolkit folder, the usage of altPath is supported. For example, to use this function to
%  return "C:\Users\<current user>\MATLAB\LFI_toolkit_V001\", call this function as LFI_toolkit_path(true,'C:\Users\<current user>\MATLAB\LFI_toolkit_V001\');
%
%  Author: Jeffrey Bolan | 9/10/2014
%  -Last change: Limited scope of LFITv2 subfolder check by removing exist and rewriting (1/27/2015)

% Check flag to see if non standard path is in use
if useAltPath == false
    if ~isempty(dir('LFITv2')) %better than using 'exist', which looks on the entire search path.
        tempUserString = cd;
        pathString = [tempUserString '\LFITv2\'];
    else
        tempUserString = userpath;
        userString = tempUserString(1:end-1);
        pathString = [userString '\LFITv2\'];
    end
else
    % Use literally the path the user gave
    pathString = altPathString;
end

% Add LFI_toolkit path to search path
addpath(pathString); % adds the toolkit folder to the top of MATLAB's search path listing

% Check to make sure the defined function directory actually has the functions in it!

if exist([pathString 'currentVersion.txt'],'file') == 2
    LFIversion = importdata([pathString 'currentVersion.txt']);
    fprintf('LFI Toolkit V%2.2f function folder located.\n',LFIversion);
    
    % Check online for updates, notifying user if newer LFI Toolkit available.
    [onlineVersion,checkSuccess] = updatecheck(LFIversion); % output variables aren't currently used, but are passed for future proofing.
else
    LFIversion = dir([pathString '*.ver']); % old version (1.02 only) check
    if exist([pathString LFIversion.name],'file') == 2
        warning('This version (1.02) of the LFI Toolkit is out of date. Please update to the latest version.');
    else
        % If this error triggers, make sure you've copied the subfolder *that actually has the functions* into the MATLAB user directory.
        % Do NOT just copy the contents of the LFI_Toolkit V... ZIP file into the MATLAB user directory, but instead the function subfolder.
        % "LFI_toolkit"
        error('LFI Toolkit folder not found. Please copy "LFI_toolkit" subfolder with functions into the MATLAB user directory. Do NOT just copy the contents of the LFI_Toolkit V... ZIP file into the MATLAB user directory, but instead copy the function subfolder "LFI_toolkit" that has all the functions. The directory path will look like: "C:\Users\<username>\Documents\MATLAB\LFI_toolkit\", where "LFI_toolkit" contains the acutal m files for the toolkit.');
    end
end

end
