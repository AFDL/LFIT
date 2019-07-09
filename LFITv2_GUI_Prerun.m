function varargout = LFITv2_GUI_Prerun(varargin)
%LFITV2_GUI_PRERUN M-file for LFITv2_GUI_Prerun.fig
% LFITV2_GUI_PRERUN, by itself, creates a new LFITV2_GUI_PRERUN or raises
% the existing singleton*.
%
% H = LFITV2_GUI_PRERUN returns the handle to a new LFITV2_GUI_PRERUN or
% the handle to the existing singleton*.
%
% LFITV2_GUI_PRERUN('CALLBACK',hObject,eventData,handles,...) calls the
% local function named CALLBACK in LFITV2_GUI_PRERUN.M with the given input
% arguments.
%
% LFITV2_GUI_PRERUN('Property','Value',...) creates a new LFITV2_GUI_PRERUN
% or raises the existing singleton*. Starting from the left, property
% value pairs are applied to the GUI before LFITv2_GUI_Prerun_OpeningFcn
% gets called. An unrecognized property name or invalid value makes
% property application stop. All inputs are passed to
% LFITv2_GUI_Prerun_OpeningFcn via varargin.
%
% *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
% instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright (c) 2014-2016 Dr. Brian Thurow <thurow@auburn.edu>
%
% This file is part of the Light-Field Imaging Toolkit (LFIT), licensed
% under version 3 of the GNU General Public License. Refer to the included
% LICENSE or <http://www.gnu.org/licenses/> for the full text.


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LFITv2_GUI_Prerun_OpeningFcn, ...
    'gui_OutputFcn',  @LFITv2_GUI_Prerun_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before LFITv2_GUI_Prerun is made visible.
function LFITv2_GUI_Prerun_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LFITv2_GUI_Prerun (see VARARGIN)

handles = setDefaults(hObject,handles);

% Load last run if present
if ~isempty(dir('lastrun.cfg')) %better than using 'exist', which looks on the entire search path.
    handles = loadState(cd,'lastrun.cfg',hObject,handles);
end

% Choose default command line output for LFITv2_GUI_Prerun
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Update main title axes
axes(handles.tagHeaderIm);
imshow('header.png');

initialize_gui(hObject, handles, false);

% UIWAIT makes LFITv2_GUI_Prerun wait for user response (see UIRESUME)
uiwait(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = LFITv2_GUI_Prerun_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = 'test';
assignin('base','calFolderPath',handles.cal_path);
assignin('base','plenopticImagesPath',handles.plen_path);
assignin('base','outputPath',handles.out_path);
assignin('base','imageSetName',handles.imageSetName);
assignin('base','runMode',handles.runMode);
assignin('base','focLenMain',handles.focLenMain);
assignin('base','pixelPitch',handles.pixelPitch);
assignin('base','rulerHeight',handles.rulerHeight);
assignin('base','focLenMicro',handles.focLenMicro);
assignin('base','loadFlag',handles.loadFlag);
assignin('base','saveFlag',handles.saveFlag);
% assignin('base','sizePixelAperture',handles.sizePixelAperture);
assignin('base','startProgram',handles.startProgram);
assignin('base','numMicroX',handles.numMicroX);
assignin('base','numMicroY',handles.numMicroY);
assignin('base','sensorType',handles.sensorType);
assignin('base','microDiameterExact',handles.microDiameterExact);

% Not explicitly used currently in main program, but passed anyway
assignin('base','magnification',handles.magnification);
assignin('base','sensorHeight',handles.sensorHeight);
assignin('base','microPitch',handles.microPitch);


si = handles.focLenMain*(1-(handles.magnification));
sizePixelAperture = (si*handles.pixelPitch)/handles.focLenMicro;
handles.sizePixelAperture = sizePixelAperture;
assignin('base','sizePixelAperture',handles.sizePixelAperture);

% Save last run
saveState(cd,'lastrun.cfg',handles)

% pause;
% error;
closereq

% --------------------------------------------------------------------
function initialize_gui(hObject, handles, isreset)
% If the calFolderPath field is present and the reset flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to reset the data.
if isfield(handles, 'calFolderPath') && ~isreset
    return;
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Close button not pressed; run button pressed, so let program continue
handles.startProgram = true;

% Update handles structure
guidata(hObject, handles);

uiresume(handles.mainFigGUI);

% Get parallel pool status
p = gcp('nocreate');
if isempty(p)
    parpool( handles.numThreads );      % Create new pool
elseif p.NumWorkers ~= handles.numThreads
    delete(p);                          % Destroy existing pool
    parpool( handles.numThreads );      % Create new pool
else
    % Pool of appropriate size already exists
end



% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
open('LFITv2_Documentation.pdf');


% --- Executes on button press in pushbutton11.
function pushbutton11_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.out_path ~=  0
    directory_name = uigetdir(handles.plen_path,'Select an output folder to hold all exported/processed images...');
    if directory_name ~= 0
        handles.out_path = directory_name;
        set(handles.tagTextOut,'String',directory_name);
    else
        set(handles.tagTextOut,'String',handles.out_path);
    end
else
    directory_name = uigetdir(path,'Select an output folder to hold all exported/processed images...');
    if directory_name ~= 0
        handles.out_path = directory_name;
        set(handles.tagTextOut,'String',directory_name);
    else
        set(handles.tagTextOut,'String',handles.out_path);
    end
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.cal_path ~=  0
    directory_name = uigetdir(handles.cal_path,'Select the folder containing the raw TIFF calibration images...');
    if directory_name ~=  0 % if the user didn't pick a folder
        handles.cal_path = directory_name;
        set(handles.tagTextCal,'String',directory_name); % update GUI/set to new value
    else
        set(handles.tagTextCal,'String',handles.cal_path); %set to old value
    end
else
    directory_name = uigetdir(path,'Select the folder containing the raw TIFF calibration images...');
    if directory_name ~=  0 % if the user didn't pick a folder
        handles.cal_path = directory_name;
        set(handles.tagTextCal,'String',directory_name); % update GUI/set to new value
    else
        set(handles.tagTextCal,'String',handles.cal_path); %set to old value
    end
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.plen_path ~=  0
    directory_name = uigetdir(handles.plen_path,'Open folder of raw TIFF plenoptic images for processing...');
    if directory_name ~= 0
        handles.plen_path = directory_name;
        set(handles.tagTextPlen,'String',directory_name);
    else
        set(handles.tagTextPlen,'String',handles.plen_path);
    end
else
    directory_name = uigetdir(path,'Open folder of raw TIFF plenoptic images for processing...');
    if directory_name ~= 0
        handles.plen_path = directory_name;
        set(handles.tagTextPlen,'String',directory_name);
    else
        set(handles.tagTextPlen,'String',handles.plen_path);
    end
end

% Update handles structure
guidata(hObject, handles);






function tagTextImageSet_Callback(hObject, eventdata, handles)
% hObject    handle to tagTextImageSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagTextImageSet as text
%        str2double(get(hObject,'String')) returns contents of tagTextImageSet as a double

input = get(hObject,'String');
handles.imageSetName = input;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagTextImageSet_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagTextImageSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end







function tagRefHeight_Callback(hObject, eventdata, handles)
% hObject    handle to tagRefHeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagRefHeight as text
%        str2double(get(hObject,'String')) returns contents of tagRefHeight as a double
input = str2double(get(hObject,'String'));
handles.rulerHeight = input;
handles.magnification = -handles.sensorHeight/handles.rulerHeight;
set(handles.tagMagnification, 'String', handles.magnification);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagRefHeight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagRefHeight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagMainFocalLen_Callback(hObject, eventdata, handles)
% hObject    handle to tagMainFocalLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagMainFocalLen as text
%        str2double(get(hObject,'String')) returns contents of tagMainFocalLen as a double
input = str2double(get(hObject,'String'));
handles.focLenMain = input;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagMainFocalLen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagMainFocalLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton9.
function pushbutton9_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in uipanel17.
function uipanel17_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel17
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'tagRadioSingleIm'
        handles.runMode = 0;
    case 'tagRadioBatch'
        handles.runMode = 1;
end

% Update handles structure
guidata(hObject, handles);


% --- Executes when user attempts to close mainFigGUI.
function mainFigGUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to mainFigGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, use UIRESUME and return
    uiresume(hObject);
else
    % The GUI is no longer waiting, so destroy it now.
    delete(hObject);
end



% --- Executes when selected object is changed in tagCameraSelection.
function tagCameraSelection_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in tagCameraSelection
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% CAMERA DATA DEFINED HERE
% To change camera data, replace the data in this section.

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    
    % 16 MP (Rectangular Microlens Array) Camera
    case 'tagRect'
        handles.sensorType          = 'rect';
        handles.pixelPitch          = 0.0074;   % mm
        handles.focLenMicro         = 0.5;      % mm
        handles.sensorHeight        = 24.272;   % mm
        
        % Not visualized in GUI
        handles.microPitch          = 0.125;    % mm
        handles.numMicroX           = 289;
        handles.numMicroY           = 193; 
        handles.microDiameterExact  = 16.9689;  % pixels
        
    % 29 MP (Hexagonal Microlens Array) Camera
    case 'tagHexa'
        handles.sensorType          = 'hexa';
        handles.pixelPitch          = 0.0055;	% mm
        handles.focLenMicro         = 0.308;	% mm
        handles.sensorHeight        = 24.272;   % mm
        
        % Not visualized in GUI
        handles.microPitch          = 0.077;	% mm
        handles.numMicroX           = 471; 
        handles.numMicroY           = 362; 
        handles.microDiameterExact  = 14.0127;  % pixels
    
     % Other User Defined Camera
    case 'tagOtherCamera'
        handles.sensorType          = input('Please type the arrangement of the microlens array:''hexa'' or ''rect''\n');
        handles.pixelPitch          = input('Please type the pixel pitch in mm\n');
        handles.focLenMicro         = input('Please type the microlens focal length in mm\n');
        handles.sensorHeight        = input('Please type the image sensor height in mm\n');
        handles.microPitch          = input('Please type the microlens pitch in mm\n');
        handles.numMicroX           = input('Please type the number of microlens in the horizontal direction\n'); 
        handles.numMicroY           = input('Please type the number of microlens in the vertical direction\n');
        handles.microDiameterExact  = input('Please type the diameter of a microlens in pixels\n');
        
end

handles.magnification = -handles.sensorHeight/handles.rulerHeight;
set(handles.tagMagnification, 'String', handles.magnification);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in tagSaveConfig.
function tagSaveConfig_Callback(hObject, eventdata, handles)
% hObject    handle to tagSaveConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uiputfile( {'*.cfg','Configuration Files (*.cfg)';}, 'Save');
if filename ~= 0
    saveState(pathname,filename,handles)
end


% --- Executes on button press in tagLoadConfig.
function tagLoadConfig_Callback(hObject, eventdata, handles)
% hObject    handle to tagLoadConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile({'*.cfg','Configuration Files (*.cfg)';}, 'Select a configuration file to load...');
if filename ~= 0
    handles = loadState(pathname,filename,hObject,handles);
end

% --- Executes on button press in pushbutton17.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
web mailto:mzm0210@auburn.edu

% --- Save State Function
function saveState(pathname,filename,handles)

state.v01 = handles.cal_path;
state.v02 = handles.plen_path;
state.v03 = handles.out_path;
state.v04 = handles.imageSetName;
state.v05 = handles.runMode;
state.v07 = handles.focLenMain;
state.v08 = handles.pixelPitch;
state.v09 = handles.rulerHeight;
state.v10 = handles.focLenMicro;
state.v11 = handles.sensorHeight;
state.v12 = handles.magnification;
state.v13 = handles.microPitch;
state.v14 = handles.numMicroX;
state.v15 = handles.numMicroY;
state.v16 = handles.microDiameterExact;
state.v17 = handles.loadFlag;
state.v18 = handles.saveFlag;
state.v19 = handles.sizePixelAperture;
state.v20 = handles.sensorType;
state.v21 = handles.numThreads;

save(fullfile(pathname,filename), 'state','-mat');

% --- Load State Function
function handles = loadState(pathname,filename,hObject,handles)
try
    temp = load(fullfile(pathname,filename), '-mat');
    
    handles.cal_path            = temp.state.v01;
    handles.plen_path           = temp.state.v02;
    handles.out_path            = temp.state.v03;
    handles.imageSetName        = temp.state.v04;
    handles.runMode             = temp.state.v05;
    handles.focLenMain          = temp.state.v07;
    handles.pixelPitch          = temp.state.v08;
    handles.rulerHeight         = temp.state.v09;
    handles.focLenMicro         = temp.state.v10;
    handles.sensorHeight        = temp.state.v11;
    handles.magnification       = temp.state.v12;
    handles.microPitch          = temp.state.v13;
    handles.numMicroX           = temp.state.v14;
    handles.numMicroY           = temp.state.v15;
    handles.microDiameterExact  = temp.state.v16;
    handles.loadFlag            = temp.state.v17;
    handles.saveFlag            = temp.state.v18;
    handles.sizePixelAperture   = temp.state.v19;
    handles.sensorType          = temp.state.v20;
    handles.numThreads          = temp.state.v21;
        
    set(handles.tagTextCal, 'String', handles.cal_path);
    set(handles.tagTextPlen, 'String', handles.plen_path);
    set(handles.tagTextOut, 'String', handles.out_path);
    set(handles.tagTextImageSet, 'String', handles.imageSetName);
    if handles.runMode == 0
        set(handles.tagRadioSingleIm, 'Value', 1);
    else
        set(handles.tagRadioBatch, 'Value', 1);
    end

    set(handles.tagMainFocalLen, 'String', handles.focLenMain);

    set(handles.tagRefHeight, 'String', handles.rulerHeight);

    set(handles.tagMagnification, 'String', handles.magnification);
    if handles.loadFlag == 0 && handles.saveFlag == 0
        set(handles.tagNoLoadSave, 'Value', 1);
    else
        set(handles.tagAutoLoadSave, 'Value', 1);
    end
    % Note that no provision is made to remember if clear calibration was selected. This is by design to prevent accidental deletion of calibration data.
    
    if handles.loadFlag == 3 %load external cal
        set(handles.tagLoadExternalCal, 'Value',1);
    end
    
    if handles.sensorType == 'rect'
        set(handles.tagRect, 'Value', 1);
    else
        set(handles.tagHexa, 'Value', 1);
    end
    
catch generror2
    %load failed
    warning('Loading of previous configuration settings failed. Resetting to default values...');
    handles = setDefaults(handles);
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in tagNoLoadSave.
function tagNoLoadSave_Callback(hObject, eventdata, handles)
% hObject    handle to tagNoLoadSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagNoLoadSave


% --- Executes on button press in tagAutoLoadSave.
function tagAutoLoadSave_Callback(hObject, eventdata, handles)
% hObject    handle to tagAutoLoadSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagAutoLoadSave


% --- Executes when selected object is changed in tagCalLoadSave.
function tagCalLoadSave_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in tagCalLoadSave
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'tagNoLoadSave'
        handles.loadFlag = 0;
        handles.saveFlag = 0;
    case 'tagAutoLoadSave'
        handles.loadFlag = 1;
        handles.saveFlag = 1;
    case 'tagClearCalSaveNew'
        handles.loadFlag = 2;
        handles.saveFlag = 1;
    case 'tagLoadExternalCal'
        handles.loadFlag = 3;
        handles.saveFlag = 0;
end

% Update handles structure
guidata(hObject, handles);

function [handles] = setDefaults(hObject,handles)
% Put default values into handles structure
handles.cal_path        = 'C:\TestFolder\Calibration';
handles.plen_path       = 'C:\TestFolder\Images';
handles.out_path        =  fullfile(handles.plen_path,'Output');
handles.imageSetName    = 'Test';
handles.runMode         = 0; %0 = single, 1 = batch
handles.focLenMain      = 50;
% handles.focLenMain      = 80;
handles.pixelPitch      = 0.0055;
% handles.pixelPitch      = 0.0074;
handles.rulerHeight     = 24.2;
% handles.rulerHeight     = 406;
handles.focLenMicro     = 0.308;
% handles.focLenMicro     = 0.5;
handles.sensorHeight    = 24.272;   % mm
handles.magnification   = -handles.sensorHeight/handles.rulerHeight;
handles.microPitch      = 0.077;	% mm
% handles.microPitch      = 0.125;	% mm

handles.numMicroX           = 471;      % mm
handles.numMicroY           = 362;      % mm
handles.microDiameterExact  = 14.0127;  % pixels
handles.loadFlag            = 1;
handles.saveFlag            = 1;
handles.startProgram        = false;
handles.sensorType          = 'hexa';   % 'rect' or 'hexa' (string)

handles.numThreads          = 4;

set(handles.tagTextCal, 'String', handles.cal_path);
set(handles.tagTextPlen, 'String', handles.plen_path);
set(handles.tagTextOut, 'String', handles.out_path);
set(handles.tagTextImageSet, 'String', handles.imageSetName);
if handles.runMode == 0
    set(handles.tagRadioSingleIm, 'Value', 1);
else
    set(handles.tagRadioBatch, 'Value', 1);
end

set(handles.tagMainFocalLen, 'String', handles.focLenMain);

set(handles.tagRefHeight, 'String', handles.rulerHeight);

set(handles.tagMagnification, 'String', handles.magnification);

if handles.loadFlag == 0 && handles.saveFlag == 0
    set(handles.tagNoLoadSave, 'Value', 1);
else
    set(handles.tagAutoLoadSave, 'Value', 1);
end

si = handles.focLenMain*(1-(handles.magnification));
sizePixelAperture = (si*handles.pixelPitch)/handles.focLenMicro;
handles.sizePixelAperture = sizePixelAperture;

if strcmp(handles.sensorType,'rect') == true
    set(handles.tagRect, 'Value', 1); %rect
else
    set(handles.tagHexa, 'Value', 1); %hexa
end

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagHeaderIm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagHeaderIm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate tagHeaderIm



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton13.
function [handles] = pushbutton13_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.startProgram = true;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object deletion, before destroying properties.
function tagHeaderIm_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to tagHeaderIm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function tagCameraSelection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagCameraSelection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function tagNumThreads_Callback(hObject, eventdata, handles)
% hObject    handle to tagNumThreads (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagNumThreads as text
%        str2double(get(hObject,'String')) returns contents of tagNumThreads as a double
input = str2double(get(hObject,'String'));
handles.numThreads = input;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagNumThreads_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagNumThreads (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
