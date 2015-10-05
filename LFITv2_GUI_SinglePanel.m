function varargout = LFITv2_GUI_SinglePanel(varargin)
% LFITV2_GUI_SINGLEPANEL MATLAB code for LFITv2_GUI_SinglePanel.fig
%      LFITV2_GUI_SINGLEPANEL, by itself, creates a new LFITV2_GUI_SINGLEPANEL or raises the existing
%      singleton*.
%
%      H = LFITV2_GUI_SINGLEPANEL returns the handle to a new LFITV2_GUI_SINGLEPANEL or the handle to
%      the existing singleton*.
%
%      LFITV2_GUI_SINGLEPANEL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LFITV2_GUI_SINGLEPANEL.M with the given input arguments.
%
%      LFITV2_GUI_SINGLEPANEL('Property','Value',...) creates a new LFITV2_GUI_SINGLEPANEL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LFITv2_GUI_SinglePanel_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LFITv2_GUI_SinglePanel_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LFITv2_GUI_SinglePanel

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LFITv2_GUI_SinglePanel_OpeningFcn, ...
                   'gui_OutputFcn',  @LFITv2_GUI_SinglePanel_OutputFcn, ...
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


% --- Executes just before LFITv2_GUI_SinglePanel is made visible.
function LFITv2_GUI_SinglePanel_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LFITv2_GUI_SinglePanel (see VARARGIN)

% Set default values internally and in GUI boxes
handles.colormapList = {'gray';'jet';'hsv';'hot';'cool';'spring';'summer';'autumn';'winter';'bone';'copper';'pink';'lines'};
handles.travelVectorTypes = {'Square','Circle','Cross','Path from File...'};
handles = setDefaults(hObject,handles);

% Load last run if present
if ~isempty(dir('lastGUI.gcfg'))
    handles = loadState(cd,'\lastGUI.gcfg',hObject,handles);
end

% Read in workspace variables
workspaceVariables = evalin('base','who');
for k = 1:size(workspaceVariables,1)
    varName = workspaceVariables{k};
    temp = evalin('base',varName);
    eval([varName '=' 'temp;']); %into workspace
    eval([['handles.' varName] '=' 'temp;']); %put into handles structure
end

% See if the data loaded or if something went wrong.
try
handles.microRadius = floor(size(handles.radArray,1)/2);
set(handles.tagCurIm,'String', handles.firstImage); % image name
set(handles.tagProgramVersion, 'String', ['v' num2str(handles.progVersion,'%2.2f')]);
catch noLoadErr
    error('Processed image data (radArray) not found. GUI opened prematurely. Please run the scripts in order as in the demonstration program.');
end

% Choose default command line output for LFITv2_GUI_SinglePanel
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Initialize axes
axes(handles.tagHeaderIm);
imshow('header.png');

axes(handles.tagUVDiag);
colormap('gray');
imshow(fspecial('disk', handles.microRadius),[]);

axes(handles.tagRefocusGraph);
imshow('refocusRef.png');

% Update perspective plot
updatePerspPlot(hObject);

% UIWAIT makes LFITv2_GUI_SinglePanel wait for user response (see UIRESUME)
uiwait(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = LFITv2_GUI_SinglePanel_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% Save last run
saveState(cd,'\lastGUI.gcfg',handles)

closereq


% --- Executes during object creation, after setting all properties.
function tagHeaderIm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagHeaderIm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate tagHeaderIm



% --- Executes on button press in tagLoadIm.
function tagLoadIm_Callback(hObject, eventdata, handles)
% hObject    handle to tagLoadIm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[newImage,newPath] = uigetfile({'*.tiff; *.tif','TIFF files (*.tiff, *.tif)'},'Select a single raw plenoptic image to begin processing...',handles.plenopticImagesPath);

if newImage == 0
    % Keep last file since user did NOT select a file to import.
%     warning('File not selected for import.');
else
    % Tell user
    stringLoading = [newImage ' now being processed. See command line output for info and estimated wait time. This window will automatically close when processing is complete.'];
    loadHandle = msgbox(stringLoading,'Please wait...');
    
    % Strip out old image data from local handles
    oldVars = {'radArray'; 'sRange'; 'tRange'; 'imageName'; 'imageSpecificName'; 'imagePath';};
    handles = rmfield(handles,oldVars);
    
    % Place image name in expected format.
    imageName = struct('name',newImage);
    
    % Update variables
    imageSpecificName = [handles.imageSetName '_' imageName(1).name(1:end-4)]; %end-4 removes .tif
    if strcmp(handles.plenopticImagesPath,newPath) == false
        handles.plenopticImagesPath = newPath; % if the user selects an image outside of the main plenoptic images directory.
        % Since the user chose an image in a different directory than was defined originally, prompt for a new output folder.
        directory_name = uigetdir(handles.plenopticImagesPath,'Select an output folder to hold all exported/processed images...');
        if directory_name ~= 0
            handles.outputPath = directory_name;
        else
            handles.outputPath = [handles.plenopticImagesPath '\' 'Output']; % if user didn't select a folder, make one in the same directory as the plenoptic images
            fprintf('\nNo output directory selected. Output will be in: %s \n',handles.outputPath);
        end
       
    end
    imagePath = [handles.plenopticImagesPath '\' imageName(1).name];
    
    % Interpolate image data
    [radArray,sRange,tRange] = interpimage2(handles.calData,imagePath,handles.sensorType,handles.microPitch,handles.pixelPitch,handles.numMicroX,handles.numMicroY);
       
    % Update local handles
    handles.radArray = radArray;
    handles.sRange = sRange;
    handles.tRange = tRange;
    handles.imageName = imageName;
    handles.imageSpecificName = imageSpecificName;
    handles.imagePath = imagePath;
    handles.firstImage = imageName(1).name;
    
    % Update real handles structure
    guidata(hObject, handles);
    
    % Refresh the GUI
    refreshFields(hObject,handles);
    
    % Tell the user
    try
        close(loadHandle);
    catch generr4
        % user must have closed it already; good!
    end
    stringLoaded = [handles.firstImage ' successfully loaded and processed.'];
    uiwait(msgbox(stringLoaded,'Load Complete','modal'));
end


% --- Executes on button press in tagOpenUVDialog.
function tagOpenUVDialog_Callback(hObject, eventdata, handles)
% hObject    handle to tagOpenUVDialog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function tagU_Callback(hObject, eventdata, handles)
% hObject    handle to tagU (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagU as text
%        str2double(get(hObject,'String')) returns contents of tagU as a double
input = str2double(get(hObject,'String'));
handles.uVal = input;

% Update handles structure
guidata(hObject, handles);

% Update perspective plot (u,v)
updatePerspPlot(hObject);


% --- Executes during object creation, after setting all properties.
function tagU_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagU (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagV_Callback(hObject, eventdata, handles)
% hObject    handle to tagV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagV as text
%        str2double(get(hObject,'String')) returns contents of tagV as a double
input = str2double(get(hObject,'String'));
handles.vVal = input;

% Update handles structure
guidata(hObject, handles);

% Update perspective plot (u,v)
updatePerspPlot(hObject);


% --- Executes during object creation, after setting all properties.
function tagV_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagSSSTP_Callback(hObject, eventdata, handles)
% hObject    handle to tagSSSTP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagSSSTP as text
%        str2double(get(hObject,'String')) returns contents of tagSSSTP as a double
input = str2double(get(hObject,'String'));
handles.SSSTP = input;
handles.SSSTPM = input;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagSSSTP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagSSSTP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagGenerateDispP.
function tagGenerateDispP_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenerateDispP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%[u,v,SS_ST,saveFlag,displayFlag,imadjustFlag,colormap,backgroundColor,captionFlag,'A caption string'];
disp('Calculating perspective view...');
requestVectorP = {handles.uVal,handles.vVal,handles.SSSTP,0,2,handles.enhanceContrastP,handles.colormapP,'white',0,'No caption';};
perspectivegen(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorP,handles.sRange,handles.tRange);
updatePerspPlot(hObject)

% --- Executes on button press in tagGenerateSaveP.
function tagGenerateSaveP_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenerateSaveP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Calculating perspective view...');
requestVectorP = {handles.uVal,handles.vVal,handles.SSSTP,handles.imFileType,2,handles.enhanceContrastP,handles.colormapP,'white',0,'No caption';};
perspectivegen(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorP,handles.sRange,handles.tRange);
updatePerspPlot(hObject)

% --- Executes on selection change in tagColormapMenuP.
function tagColormapMenuP_Callback(hObject, eventdata, handles)
% hObject    handle to tagColormapMenuP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagColormapMenuP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagColormapMenuP
% items = get(hObject,'String');
index_selected = get(hObject,'Value');
% item_selected = items{index_selected};
handles.colormapP = handles.colormapList{index_selected};
handles.colormapGIF = handles.colormapList{index_selected};
handles.colormapRM = handles.colormapList{index_selected};
handles.colormapPM = handles.colormapList{index_selected};
handles.colormapFS = handles.colormapList{index_selected};
handles.colormapR = handles.colormapList{index_selected};

% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function tagColormapMenuP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagColormapMenuP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String',{'Grayscale';'Jet';'HSV';'Hot';'Cool';'Spring';'Summer';'Autumn';'Winter';'Bone';'Copper';'Pink';'Lines'});


% --- Executes on button press in tagContrastP.
function tagContrastP_Callback(hObject, eventdata, handles)
% hObject    handle to tagContrastP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagContrastP
handles.enhanceContrastP = get(hObject,'Value');
handles.enhanceContrastM = get(hObject,'Value');
handles.enhanceContrastR = get(hObject,'Value');
handles.enhanceContrastGIF = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in tagDispCoordP.
function tagDispCoordP_Callback(hObject, eventdata, handles)
% hObject    handle to tagDispCoordP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagDispCoordP
handles.dispCoordTitleP = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


function tagAlphaR_Callback(hObject, eventdata, handles)
% hObject    handle to tagAlphaR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagAlphaR as text
%        str2double(get(hObject,'String')) returns contents of tagAlphaR as a double
input = str2double(get(hObject,'String'));
handles.alphaR = input;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagAlphaR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagAlphaR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagSSSTR_Callback(hObject, eventdata, handles)
% hObject    handle to tagSSSTR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagSSSTR as text
%        str2double(get(hObject,'String')) returns contents of tagSSSTR as a double
input = str2double(get(hObject,'String'));
handles.SSSTR = input;
handles.SSSTRM = input;
handles.SSSTFS = input;
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagSSSTR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagSSSTR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagSSUVR_Callback(hObject, eventdata, handles)
% hObject    handle to tagSSUVR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagSSUVR as text
%        str2double(get(hObject,'String')) returns contents of tagSSUVR as a double
input = str2double(get(hObject,'String'));
handles.SSUVR = input;
handles.SSUVRM = input;
handles.SSUVFS = input;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagSSUVR_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagSSUVR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagGenDispR.
function tagGenDispR_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenDispR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
refocusedImageStack = 0;
%[telecentricFlag,Xmin,Xmax,Ymin,Ymax,Zmin,Zmax,VoxX,VoxY,VoxZ,focLenMain,magnification,zLocation]
telecentricInfo = [handles.telecentric,handles.Xmin,handles.Xmax,handles.Ymin,handles.Ymax,handles.Zmin,handles.Zmax,handles.VoxX,handles.VoxY,handles.VoxZ,handles.focLenMain,handles.magnification,handles.Zlocation];
%[alpha,SS_UV,SS_ST,saveFlag,displayFlag,contrastFlag,colormap,bgcolor,captionFlag,'A caption string',apertureFlag,directoryFlag,Refocus Type,Filter Info, Telecentric Info];
requestVectorR = {handles.alphaR,handles.SSUVR,handles.SSSTR,0,2,handles.enhanceContrastR,handles.colormapR,'white',0,'No caption',handles.aperMask,0,handles.refocusType,[handles.noiseThreshold handles.filterThreshold],telecentricInfo;};
%(x,y,alphaIndex,imageIndex)
tic
refocusedImageStack = genrefocus(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorR,handles.sRange,handles.tRange,handles.imageIndex,handles.numImages,refocusedImageStack);
toc
updatePerspPlot(hObject)           

% --- Executes on button press in tagGenSaveR.
function tagGenSaveR_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenSaveR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
refocusedImageStack = 0;
%[telecentricFlag,Xmin,Xmax,Ymin,Ymax,Zmin,Zmax,VoxX,VoxY,VoxZ,focLenMain,magnification,zLocation]
telecentricInfo = [handles.telecentric,handles.Xmin,handles.Xmax,handles.Ymin,handles.Ymax,handles.Zmin,handles.Zmax,handles.VoxX,handles.VoxY,handles.VoxZ,handles.focLenMain,handles.magnification,handles.Zlocation];
%[alpha,SS_UV,SS_ST,saveFlag,displayFlag,contrastFlag,colormap,bgcolor,captionFlag,'A caption string',apertureFlag,directoryFlag,Refocus Type,Filter Info, Telecentric Info];
requestVectorR = {handles.alphaR,handles.SSUVR,handles.SSSTR,handles.imFileType,2,handles.enhanceContrastR,handles.colormapR,'white',0,'No caption',handles.aperMask,0,handles.refocusType,[handles.noiseThreshold handles.filterThreshold],telecentricInfo;};
%(x,y,alphaIndex,imageIndex)
refocusedImageStack = genrefocus(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorR,handles.sRange,handles.tRange,handles.imageIndex,handles.numImages,refocusedImageStack);
updatePerspPlot(hObject)  

% --- Executes on button press in tagApertureNone.
function tagApertureNone_Callback(hObject, eventdata, handles)
% hObject    handle to tagApertureNone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagApertureNone


% --- Executes on button press in tagCircAper.
function tagCircAper_Callback(hObject, eventdata, handles)
% hObject    handle to tagCircAper (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagCircAper

% --- Executes on button press in tagCaptionAlphaR.
function tagCaptionAlphaR_Callback(hObject, eventdata, handles)
% hObject    handle to tagCaptionAlphaR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagCaptionAlphaR
handles.dispAlphaTitleR = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


function tagEdgeBuffer_Callback(hObject, eventdata, handles)
% hObject    handle to tagEdgeBuffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagEdgeBuffer as text
%        str2double(get(hObject,'String')) returns contents of tagEdgeBuffer as a double
handles.edgeBuffer = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagEdgeBuffer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagEdgeBuffer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagLoadGUI.
function tagLoadGUI_Callback(hObject, eventdata, handles)
% hObject    handle to tagLoadGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile({'*.gcfg','GUI Configuration Files (*.gcfg)';}, 'Select a GUI settings file to load...');
if filename ~= 0
    handles = loadState(pathname,filename,hObject,handles);
end

% --- Executes on button press in tagSaveGUI.
function tagSaveGUI_Callback(hObject, eventdata, handles)
% hObject    handle to tagSaveGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uiputfile( {'*.gcfg','GUI Configuration Files (*.gcfg)';}, 'Save');
if filename ~= 0
    saveState(pathname,filename,handles)
end


function tagSSUVPM_Callback(hObject, eventdata, handles)
% hObject    handle to tagSSUVPM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagSSUVPM as text
%        str2double(get(hObject,'String')) returns contents of tagSSUVPM as a double
handles.SSUVPM = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagSSUVPM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagSSUVPM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in tagMirrorLoopRM.
function tagMirrorLoopRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagMirrorLoopRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagMirrorLoopRM
handles.mirrorLoopRM = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


function tagAlphaStartRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagAlphaStartRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagAlphaStartRM as text
%        str2double(get(hObject,'String')) returns contents of tagAlphaStartRM as a double
handles.alphaStartRM = str2double(get(hObject,'String'));
handles.alphaStartFS = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagAlphaStartRM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagAlphaStartRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagStepsRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagStepsRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagStepsRM as text
%        str2double(get(hObject,'String')) returns contents of tagStepsRM as a double
handles.stepsRM = str2double(get(hObject,'String'));
handles.numStepsFS = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagStepsRM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagStepsRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagAlphaEndRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagAlphaEndRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagAlphaEndRM as text
%        str2double(get(hObject,'String')) returns contents of tagAlphaEndRM as a double
handles.alphaEndRM = str2double(get(hObject,'String'));
handles.alphaEndFS = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagAlphaEndRM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagAlphaEndRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in tagCodecRM.
function tagCodecRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagCodecRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagCodecRM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagCodecRM
index_selected = get(hObject,'Value');
handles.vidCodecRM = index_selected;
handles.vidCodecPM = index_selected;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagCodecRM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagCodecRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% Different versions of MATLAB support different codecs; note that not all codecs will be supported on every PC.
if verLessThan('matlab', '7.11')
    set(hObject,'String',{'None (uncompressed)';'MSVC';'RLE';'Cinepak'});
else
    set(hObject,'String',{'Uncompressed AVI';'Motion JPEG AVI';'Motion JPEG 2000 (lossless)';'Motion JPEG 2000 (lossy)';'MPEG-4 (H.264)'});
end


function tagFrameRateRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagFrameRateRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagFrameRateRM as text
%        str2double(get(hObject,'String')) returns contents of tagFrameRateRM as a double
handles.frameRateRM = str2double(get(hObject,'String'));
handles.frameRatePM = handles.frameRateRM;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagFrameRateRM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagFrameRateRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagQualityRM_Callback(hObject, eventdata, handles)
% hObject    handle to tagQualityRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagQualityRM as text
%        str2double(get(hObject,'String')) returns contents of tagQualityRM as a double
handles.qualityRM = str2double(get(hObject,'String'));
handles.qualityPM = handles.qualityRM;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagQualityRM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagQualityRM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagExportPerspectiveVid.
function tagExportPerspectiveVid_Callback(hObject, eventdata, handles)
% hObject    handle to tagExportPerspectiveVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
indexSelected = handles.vidCodecPM - 1;
if indexSelected == 4
    fileType = 3; %MP4
else
    fileType = 2; %AVI
end
%[edgeBuffer,SS_UV, SS_ST, saveFlag, displayFlag, imadjustFlag, captionFlag, caption string]
requestVectorPM = {handles.edgeBuffer,handles.SSUVPM,handles.SSSTPM,[fileType 0 0; handles.qualityPM handles.frameRatePM indexSelected;],2,handles.enhanceContrastM,handles.colormapPM,[0 0 0],0,'No caption',handles.travelVector;};
animateperspective(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorPM,handles.sRange,handles.tRange);

% --- Executes on button press in tagExportRefocusVid.
function tagExportRefocusVid_Callback(hObject, eventdata, handles)
% hObject    handle to tagExportRefocusVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
indexSelected = handles.vidCodecPM - 1;
if indexSelected == 4
    fileType = 3; %MP4
else
    fileType = 2; %AVI
end
if handles.dynamicContrastM == 0
    contrastFlag = 2;
else
    contrastFlag = handles.enhanceContrastM;
end
%[telecentricFlag,Xmin,Xmax,Ymin,Ymax,Zmin,Zmax,VoxX,VoxY,VoxZ,focLenMain,magnification,zLocation]
telecentricInfo = [handles.telecentric,handles.Xmin,handles.Xmax,handles.Ymin,handles.Ymax,handles.Zmin,handles.Zmax,handles.VoxX,handles.VoxY,handles.VoxZ,handles.focLenMain,handles.magnification,handles.Zlocation];
%[alphaArray,SS_UV,SS_ST,saveFlag,displayFlag,imadjustFlag,colormap,background color,caption flag,caption string,apertureFlag,Refocus Type,Filter Info, Telecentric Info]
requestVectorRM = {[handles.stepSpaceRM handles.stepsRM; handles.alphaStartRM handles.alphaEndRM; handles.mirrorLoopRM 0;],handles.SSUVRM,handles.SSSTRM,[fileType 0 0; handles.qualityRM handles.frameRateRM indexSelected;],2,contrastFlag,handles.colormapRM,[0 0 0],0,'No caption',1,handles.refocusType,[handles.noiseThreshold handles.filterThreshold],telecentricInfo;}; %hardcoded circular mask
animaterefocus(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorRM,handles.sRange,handles.tRange);


function tagFrameDelayGIF_Callback(hObject, eventdata, handles)
% hObject    handle to tagFrameDelayGIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagFrameDelayGIF as text
%        str2double(get(hObject,'String')) returns contents of tagFrameDelayGIF as a double
handles.frameDelayGIF = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagFrameDelayGIF_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagFrameDelayGIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagDitheringGIF.
function tagDitheringGIF_Callback(hObject, eventdata, handles)
% hObject    handle to tagDitheringGIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagDitheringGIF
handles.ditheringGIF = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in tagLimitLoops.
function tagLimitLoops_Callback(hObject, eventdata, handles)
% hObject    handle to tagLimitLoops (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagLimitLoops
handles.limitLoopsGIF = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


function tagLoopLimit_Callback(hObject, eventdata, handles)
% hObject    handle to tagLoopLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagLoopLimit as text
%        str2double(get(hObject,'String')) returns contents of tagLoopLimit as a double
handles.loopLimitGIF = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagLoopLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagLoopLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagPerspectiveGIF.
function tagPerspectiveGIF_Callback(hObject, eventdata, handles)
% hObject    handle to tagPerspectiveGIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fileType = 1; %GIF
if handles.limitLoopsGIF == false
    loops = inf; %literally inf, NOT a string 'inf'
else
    loops = handles.loopLimitGIF;
end
%[edgeBuffer,SS_UV, SS_ST, saveFlag, displayFlag, imadjustFlag, captionFlag, caption string]
requestVectorPM = {handles.edgeBuffer,handles.SSUVPM,handles.SSSTPM,[fileType 0 0; handles.frameDelayGIF loops handles.ditheringGIF;],2,handles.enhanceContrastGIF,handles.colormapGIF,[0 0 0],0,'No caption',handles.travelVector;};
animateperspective(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorPM,handles.sRange,handles.tRange);


% --- Executes on button press in tagRefocusGIF.
function tagRefocusGIF_Callback(hObject, eventdata, handles)
% hObject    handle to tagRefocusGIF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fileType = 1; %GIF
if handles.limitLoopsGIF == false
    loops = inf; %literally inf, NOT a string 'inf'
else
    loops = handles.loopLimitGIF;
end
if handles.dynamicContrastGIF == 0
    contrastFlag = 2;
else
    contrastFlag = handles.enhanceContrastGIF;
end
%[telecentricFlag,Xmin,Xmax,Ymin,Ymax,Zmin,Zmax,VoxX,VoxY,VoxZ,focLenMain,magnification,zLocation]
telecentricInfo = [handles.telecentric,handles.Xmin,handles.Xmax,handles.Ymin,handles.Ymax,handles.Zmin,handles.Zmax,handles.VoxX,handles.VoxY,handles.VoxZ,handles.focLenMain,handles.magnification,handles.Zlocation];
%[alphaArray,SS_UV,SS_ST,saveFlag,displayFlag,imadjustFlag,colormap,background color,caption flag,caption string,apertureFlag,Refocus Type,Filter Info, Telecentric Info]
requestVectorRM = {[handles.stepSpaceRM handles.stepsRM; handles.alphaStartRM handles.alphaEndRM; handles.mirrorLoopRM 0;],handles.SSUVRM,handles.SSSTRM,[fileType 0 0; handles.frameDelayGIF loops handles.ditheringGIF;],2,contrastFlag,handles.colormapGIF,[0 0 0],0,'No caption',1,handles.refocusType,[handles.noiseThreshold handles.filterThreshold],telecentricInfo;}; %hardcoded circular mask
animaterefocus(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorRM,handles.sRange,handles.tRange);

% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%[telecentricFlag,Xmin,Xmax,Ymin,Ymax,Zmin,Zmax,VoxX,VoxY,VoxZ,focLenMain,magnification,zLocation]
telecentricInfo = [handles.telecentric,handles.Xmin,handles.Xmax,handles.Ymin,handles.Ymax,handles.Zmin,handles.Zmax,handles.VoxX,handles.VoxY,handles.VoxZ,handles.focLenMain,handles.magnification,handles.Zlocation];
%[alphaArray,SS_UV,SS_ST,saveFlag,displayFlag,contrastFlag,colormap,bgcolor,captionFlag,'A caption string',apertureFlag,Refocus Type,Filter Info, Telecentric Info];
requestVectorFS = {[handles.stepSpaceFS handles.numStepsFS; handles.alphaStartFS handles.alphaEndFS;],handles.SSUVFS,handles.SSSTFS,handles.imFileType,2,0,handles.colormapFS,'white',0,'No caption',1,handles.refocusType,[handles.noiseThreshold handles.filterThreshold],telecentricInfo;};
tempstack = genfocalstack(handles.radArray,handles.outputPath,handles.imageSpecificName,requestVectorFS,handles.sRange,handles.tRange);

% --- Executes on button press in tagViewDocumentation.
function tagViewDocumentation_Callback(hObject, eventdata, handles)
% hObject    handle to tagViewDocumentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
open('LFITv2_Documentation.pdf');

% --- Executes on selection change in tagImageType.
function tagImageType_Callback(hObject, eventdata, handles)
% hObject    handle to tagImageType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagImageType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagImageType
index_selected = get(hObject,'Value');
handles.imFileType = index_selected;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagImageType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagImageType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String',{'Bitmap (*.bmp)';'PNG (*.png)';'JPEG (*.jpg)';'PNG 16-bit (*.png)';'TIFF 16-bit (*.tif)'});


% --- Executes when selected object is changed in tagEnforceMask.
function tagEnforceMask_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in tagEnforceMask 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'tagApertureNone'
        handles.aperMask = 0;
    case 'tagCircAper'
        handles.aperMask = 1;
end

% Update handles structure
guidata(hObject, handles);


% --- Executes when selected object is changed in tagSpaceRM.
function tagSpaceRM_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in tagSpaceRM 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'tagLinearSpaceRM'
        handles.stepSpaceRM = 0;
        handles.stepSpaceFS = 0;
    case 'tagLogSpaceRM'
        handles.stepSpaceRM = 1;
        handles.stepSpaceFS = 1;
end

% Update handles structure
guidata(hObject, handles);

function [handles] = setDefaults(hObject,handles)
% Put default values into handles structure
handles.uVal = 0;
handles.vVal = 0;
handles.SSSTP = 1;
handles.colormapP = 'gray';
handles.enhanceContrastP = 1;
handles.dispCoordTitleP = 0;

set(handles.tagU, 'String', handles.uVal);
set(handles.tagV, 'String', handles.vVal);
set(handles.tagSSSTP, 'String', handles.SSSTP);
set(handles.tagColormapMenuP,'Value',find(strcmp(handles.colormapP, handles.colormapList)));
set(handles.tagContrastP, 'Value', handles.enhanceContrastP);

set(handles.tagDispCoordP, 'Value', handles.dispCoordTitleP);

handles.alphaR = 1.00;
handles.SSSTR = 1;
handles.SSUVR = 1;
handles.colormapR = 'gray';
handles.enhanceContrastR = 0;
handles.dispAlphaTitleR = 0;
handles.aperMask = 1;

set(handles.tagAlphaR, 'String', handles.alphaR);
set(handles.tagSSSTR, 'String', handles.SSSTR);
set(handles.tagSSUVR, 'String', handles.SSUVR);
set(handles.tagColormapMenuP,'Value',find(strcmp(handles.colormapR, handles.colormapList)));
set(handles.tagContrastP, 'Value', handles.enhanceContrastR);


set(handles.tagCaptionAlphaR, 'Value', handles.dispAlphaTitleR);
if handles.aperMask == 0
    set(handles.tagApertureNone, 'Value', 1);
else
    set(handles.tagCircAper, 'Value', 1);
end

handles.edgeBuffer = 2;
handles.SSUVPM = 1;
handles.SSSTPM = 1;

set(handles.tagEdgeBuffer, 'String', handles.edgeBuffer);
set(handles.tagSSUVPM, 'String', handles.SSUVPM);
set(handles.tagSSSTP, 'String', handles.SSSTPM);

handles.imFileType = 4;

set(handles.tagImageType, 'Value', handles.imFileType);

handles.alphaStartRM = 0.90;
handles.stepsRM = 20;
handles.alphaEndRM = 1.10;
handles.SSSTRM = 1;
handles.SSUVRM = 1;
handles.stepSpaceRM = 0;
handles.mirrorLoopRM = 0;

set(handles.tagAlphaStartRM, 'String', handles.alphaStartRM);
set(handles.tagStepsRM, 'String', handles.stepsRM);
set(handles.tagAlphaEndRM, 'String', handles.alphaEndRM);
set(handles.tagSSSTR, 'String', handles.SSSTRM);
set(handles.tagSSUVR, 'String', handles.SSUVRM);
set(handles.tagCaptionAlphaR, 'Value', handles.dispAlphaTitleR);
if handles.stepSpaceRM == 0
    set(handles.tagLinearSpaceRM, 'Value', 1);
else
    set(handles.tagLogSpaceRM, 'Value', 1);
end
set(handles.tagMirrorLoopRM, 'Value', handles.mirrorLoopRM);

handles.vidCodecRM = 2;
handles.frameRateRM = 15;
handles.qualityRM = 90;
handles.colormapRM = 'gray';

% In reality, these are duplicates of the above RM settings block (but is split out in case we ever differentiated between the two)
handles.colormapPM = 'gray';
handles.vidCodecPM = 2;
handles.frameRatePM = 15;
handles.qualityPM = 90;

set(handles.tagFrameRateRM, 'String', handles.frameRateRM);
set(handles.tagQualityRM, 'String', handles.qualityRM);
set(handles.tagCodecRM, 'Value', handles.vidCodecRM);
set(handles.tagColormapMenuP,'Value',find(strcmp(handles.colormapRM, handles.colormapList)));

handles.frameDelayGIF = 0;
handles.ditheringGIF = 1;
handles.limitLoopsGIF = 0;
handles.loopLimitGIF = 1;
handles.colormapGIF = 'gray';

set(handles.tagFrameDelayGIF, 'String', handles.frameDelayGIF);
set(handles.tagDitheringGIF, 'Value', handles.ditheringGIF);
set(handles.tagLimitLoops, 'Value', handles.limitLoopsGIF);
set(handles.tagLoopLimit, 'String', handles.loopLimitGIF);
set(handles.tagColormapMenuP,'Value',find(strcmp(handles.colormapGIF, handles.colormapList)));

handles.alphaStartFS = 0.90;
handles.numStepsFS = 20;
handles.alphaEndFS = 1.10;
handles.SSSTFS = 1;
handles.SSUVFS = 1;
handles.stepSpaceFS = 0;
handles.colormapFS = 'gray';

set(handles.tagAlphaStartRM, 'String', handles.alphaStartFS);
set(handles.tagStepsRM, 'String', handles.numStepsFS);
set(handles.tagAlphaEndRM, 'String', handles.alphaEndFS);
set(handles.tagSSSTR, 'String', handles.SSSTFS);
set(handles.tagSSUVR, 'String', handles.SSUVFS);

if handles.stepSpaceFS == 0
    set(handles.tagLinearSpaceRM, 'Value', 1);
else
    set(handles.tagLogSpaceRM, 'Value', 1);
end
set(handles.tagColormapMenuP,'Value',find(strcmp(handles.colormapFS, handles.colormapList)));

handles.firstImage = '<no image loaded>';
set(handles.tagCurIm,'String', handles.firstImage); % image name

handles.enhanceContrastM = 1;
set(handles.tagContrastP, 'Value', handles.enhanceContrastM);

handles.dynamicContrastM = 0;
set(handles.tagDynamicContrastM, 'Value', handles.dynamicContrastM);

handles.dynamicContrastGIF = 0;
set(handles.tagDynamicContrastM, 'Value', handles.dynamicContrastGIF);

handles.enhanceContrastGIF = 1;
set(handles.tagContrastP, 'Value', handles.enhanceContrastGIF);

handles.progVersion = 2.00; % it'll get converted to a string when set below.
set(handles.tagProgramVersion, 'String', ['v' num2str(handles.progVersion,'%2.2f')]);

handles.travelVector = 1;
set(handles.tagTravelVector,'Value',handles.travelVector);

handles.refocusType = 1; %additive = 1
set(handles.tagRefocusType,'Value',handles.refocusType);

handles.noiseThreshold = 0;
set(handles.tagNoiseThreshold,'String',handles.noiseThreshold);

handles.filterThreshold = 0.9;
set(handles.tagFilterThreshold,'String',handles.filterThreshold);

handles.telecentric = 0;
set(handles.tagTelecentric, 'Value', handles.telecentric);

handles.Zlocation = 0;
set(handles.tagZlocation, 'String', handles.Zlocation);

handles.Xmin = -18;
set(handles.tagXmin, 'String', handles.Xmin);
handles.Xmax = 18;
set(handles.tagXmax, 'String', handles.Xmax);

handles.Ymin = -12;
set(handles.tagYmin, 'String', handles.Ymin);
handles.Ymax = 12;
set(handles.tagYmax, 'String', handles.Ymax);

handles.Zmin = -12;
set(handles.tagZmin, 'String', handles.Zmin);
handles.Zmax = 12;
set(handles.tagZmax, 'String', handles.Zmax);

handles.VoxX = 300;
set(handles.tagVoxX, 'String', handles.VoxX);
handles.VoxY = 200;
set(handles.tagVoxY, 'String', handles.VoxY);
handles.VoxZ = 200;
set(handles.tagVoxZ, 'String', handles.VoxZ);

set(handles.tagAlphaR,'Enable','on');
set(handles.tagSSSTR,'Enable','on');
set(handles.tagSSUVR,'Enable','on');
set(handles.tagAlphaStartRM,'Enable','on');
set(handles.tagStepsRM,'Enable','on');
set(handles.tagAlphaEndRM,'Enable','on');
set(handles.tagLinearSpaceRM,'Enable','on');
set(handles.tagLogSpaceRM,'Enable','on');
    
set(handles.tagZlocation,'Enable','off');
set(handles.tagXmin,'Enable','off');
set(handles.tagXmax,'Enable','off');
set(handles.tagYmin,'Enable','off');
set(handles.tagYmax,'Enable','off');
set(handles.tagZmin,'Enable','off');
set(handles.tagZmax,'Enable','off');
set(handles.tagVoxX,'Enable','off');
set(handles.tagVoxY,'Enable','off');
set(handles.tagVoxZ,'Enable','off'); 

% Update handles structure
guidata(hObject, handles);

function saveState(pathname,filename,handles)
% Delete big variables from handles structure
workspaceVariables = evalin('base','who');
handlesSave = rmfield(handles,workspaceVariables);
save([pathname filename], 'handlesSave','-mat');

function handles = loadState(pathname,filename,hObject,handles)
% Load last configuration
try
    loadedStruct = load([pathname filename], '-mat');
    names = fieldnames(loadedStruct.handlesSave);
    % The handles structure appears to list field names in a particular order; we are only interested in the fields after colormapList, the first custom handle.
    startInd = find(strcmp('colormapList',names));
    for k = startInd:numel(names)
        handles.(names{k}) = loadedStruct.handlesSave.(names{k});
    end
    refreshFields(hObject,handles); %handles loaded behind the scenes; now update the GUI to match the actual values
catch generror2
    warning('Loading of previous configuration settings failed. Resetting to default values...');
    % Could delete old run config here, but for now let's leave that up to the user and just load defaults.
    setDefaults(hObject,handles);
end

function refreshFields(hObject,handles)
% Sets all the field boxes in the GUI to whatever the literal handle values are. This is necessary b/c of how loading works.

set(handles.tagU, 'String', handles.uVal);
set(handles.tagV, 'String', handles.vVal);
set(handles.tagSSSTP, 'String', handles.SSSTP);
set(handles.tagColormapMenuP,'Value',find(strcmp(handles.colormapP, handles.colormapList)));
set(handles.tagContrastP, 'Value', handles.enhanceContrastP);
set(handles.tagDispCoordP, 'Value', handles.dispCoordTitleP);

set(handles.tagAlphaR, 'String', handles.alphaR);
set(handles.tagSSSTR, 'String', handles.SSSTR);
set(handles.tagSSUVR, 'String', handles.SSUVR);
set(handles.tagCaptionAlphaR, 'Value', handles.dispAlphaTitleR);
if handles.aperMask == 0
    set(handles.tagApertureNone, 'Value', 1);
else
    set(handles.tagCircAper, 'Value', 1);
end


set(handles.tagEdgeBuffer, 'String', handles.edgeBuffer);
set(handles.tagSSUVPM, 'String', handles.SSUVPM);

set(handles.tagImageType, 'Value', handles.imFileType);

set(handles.tagAlphaStartRM, 'String', handles.alphaStartRM);
set(handles.tagStepsRM, 'String', handles.stepsRM);
set(handles.tagAlphaEndRM, 'String', handles.alphaEndRM);

set(handles.tagCaptionAlphaR, 'Value', handles.dispAlphaTitleR);
if handles.stepSpaceRM == 0
    set(handles.tagLinearSpaceRM, 'Value', 1);
else
    set(handles.tagLogSpaceRM, 'Value', 1);
end
set(handles.tagMirrorLoopRM, 'Value', handles.mirrorLoopRM);

set(handles.tagFrameRateRM, 'String', handles.frameRateRM);
set(handles.tagQualityRM, 'String', handles.qualityRM);
set(handles.tagCodecRM, 'Value', handles.vidCodecRM);

set(handles.tagFrameDelayGIF, 'String', handles.frameDelayGIF);
set(handles.tagDitheringGIF, 'Value', handles.ditheringGIF);
set(handles.tagLimitLoops, 'Value', handles.limitLoopsGIF);
set(handles.tagLoopLimit, 'String', handles.loopLimitGIF);

set(handles.tagCurIm,'String', handles.firstImage); % image name

set(handles.tagDynamicContrastM, 'Value', handles.dynamicContrastM);

set(handles.tagProgramVersion, 'String', ['v' num2str(handles.progVersion,'%2.2f')]);

set(handles.tagTravelVector,'Value',handles.travelVector);

set(handles.tagRefocusType,'Value',handles.refocusType);

set(handles.tagNoiseThreshold,'String',handles.noiseThreshold);
set(handles.tagFilterThreshold,'String',handles.filterThreshold);

set(handles.tagTelecentric, 'Value', handles.telecentric);
set(handles.tagZlocation, 'String', handles.Zlocation);
set(handles.tagXmin, 'String', handles.Xmin);
set(handles.tagXmax, 'String', handles.Xmax);
set(handles.tagYmin, 'String', handles.Ymin);
set(handles.tagYmax, 'String', handles.Ymax);
set(handles.tagZmin, 'String', handles.Zmin);
set(handles.tagZmax, 'String', handles.Zmax);
set(handles.tagVoxX, 'String', handles.VoxX);
set(handles.tagVoxY, 'String', handles.VoxY);
set(handles.tagVoxZ, 'String', handles.VoxZ);

refreshTelecentric(hObject,handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, use UIRESUME and return
    uiresume(hObject);
else
    % The GUI is no longer waiting, so destroy it now.
    delete(hObject);
end


% --- Executes during object creation, after setting all properties.
function tagUVDiag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagUVDiag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate tagUVDiag

% handles.perspPlot = gcbo;
% 
% % Update handles structure
% guidata(hObject, handles);

function updatePerspPlot(hObject)
% Updates perspective plot
handles = guidata(hObject);
oldAxes = gca;
axes(handles.tagUVDiag);
colormap('gray');
imshow(fspecial('disk', handles.microRadius),[]);
hold on;
scatter(-(handles.uVal) + handles.microRadius + 1, -(handles.vVal) + handles.microRadius + 1,'b+');
axes(oldAxes);


% --- Executes on selection change in tagTravelVector.
function tagTravelVector_Callback(hObject, eventdata, handles)
% hObject    handle to tagTravelVector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagTravelVector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagTravelVector
index_selected = get(hObject,'Value');
handles.travelVector = index_selected;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagTravelVector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagTravelVector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String',{'Square';'Circle';'Cross';'Path from File...'});


% --- Executes on button press in tagDynamicContrastM.
function tagDynamicContrastM_Callback(hObject, eventdata, handles)
% hObject    handle to tagDynamicContrastM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagDynamicContrastM
handles.dynamicContrastM = get(hObject,'Value');
handles.dynamicContrastGIF = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in tagRefocusType.
function tagRefocusType_Callback(hObject, eventdata, handles)
% hObject    handle to tagRefocusType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagRefocusType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagRefocusType
index_selected = get(hObject,'Value');
handles.refocusType = index_selected;

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagRefocusType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagRefocusType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagNoiseThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to tagNoiseThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagNoiseThreshold as text
%        str2double(get(hObject,'String')) returns contents of tagNoiseThreshold as a double
handles.noiseThreshold = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagNoiseThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagNoiseThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function tagFilterThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to tagFilterThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagFilterThreshold as text
%        str2double(get(hObject,'String')) returns contents of tagFilterThreshold as a double
handles.filterThreshold = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagFilterThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagFilterThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tagTelecentric.
function tagTelecentric_Callback(hObject, eventdata, handles)
% hObject    handle to tagTelecentric (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagTelecentric
handles.telecentric = get(hObject,'Value');
refreshTelecentric(hObject,handles);

% Update handles structure
guidata(hObject, handles);


function tagXmin_Callback(hObject, eventdata, handles)
% hObject    handle to tagXmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagXmin as text
%        str2double(get(hObject,'String')) returns contents of tagXmin as a double
% handles.Xmin = get(hObject,'Value');
% fprintf('%f',handles.Xmin)
handles.Xmin = str2double(get(hObject,'String'));
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagXmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagXmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagXmax_Callback(hObject, eventdata, handles)
% hObject    handle to tagXmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagXmax as text
%        str2double(get(hObject,'String')) returns contents of tagXmax as a double
% handles.Xmax = get(hObject,'Value');
handles.Xmax = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagXmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagXmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagZlocation_Callback(hObject, eventdata, handles)
% hObject    handle to tagZlocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagZlocation as text
%        str2double(get(hObject,'String')) returns contents of tagZlocation as a double
handles.Zlocation = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagZlocation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagZlocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagVoxX_Callback(hObject, eventdata, handles)
% hObject    handle to tagVoxX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagVoxX as text
%        str2double(get(hObject,'String')) returns contents of tagVoxX as a double
handles.VoxX = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagVoxX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagVoxX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit32_Callback(hObject, eventdata, handles)
% hObject    handle to edit32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit32 as text
%        str2double(get(hObject,'String')) returns contents of edit32 as a double


% --- Executes during object creation, after setting all properties.
function edit32_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit33_Callback(hObject, eventdata, handles)
% hObject    handle to edit33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit33 as text
%        str2double(get(hObject,'String')) returns contents of edit33 as a double


% --- Executes during object creation, after setting all properties.
function edit33_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit34_Callback(hObject, eventdata, handles)
% hObject    handle to edit34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit34 as text
%        str2double(get(hObject,'String')) returns contents of edit34 as a double


% --- Executes during object creation, after setting all properties.
function edit34_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit35_Callback(hObject, eventdata, handles)
% hObject    handle to edit35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit35 as text
%        str2double(get(hObject,'String')) returns contents of edit35 as a double


% --- Executes during object creation, after setting all properties.
function edit35_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit36_Callback(hObject, eventdata, handles)
% hObject    handle to edit36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit36 as text
%        str2double(get(hObject,'String')) returns contents of edit36 as a double


% --- Executes during object creation, after setting all properties.
function edit36_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit37_Callback(hObject, eventdata, handles)
% hObject    handle to edit37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit37 as text
%        str2double(get(hObject,'String')) returns contents of edit37 as a double


% --- Executes during object creation, after setting all properties.
function edit37_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagYmin_Callback(hObject, eventdata, handles)
% hObject    handle to tagYmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagYmin as text
%        str2double(get(hObject,'String')) returns contents of tagYmin as a double
handles.Ymin = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagYmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagYmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagYmax_Callback(hObject, eventdata, handles)
% hObject    handle to tagYmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagYmax as text
%        str2double(get(hObject,'String')) returns contents of tagYmax as a double
handles.Ymax = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagYmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagYmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagVoxY_Callback(hObject, eventdata, handles)
% hObject    handle to tagVoxY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagVoxY as text
%        str2double(get(hObject,'String')) returns contents of tagVoxY as a double
handles.VoxY = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagVoxY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagVoxY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagZmin_Callback(hObject, eventdata, handles)
% hObject    handle to tagZmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagZmin as text
%        str2double(get(hObject,'String')) returns contents of tagZmin as a double
handles.Zmin = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagZmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagZmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagZmax_Callback(hObject, eventdata, handles)
% hObject    handle to tagZmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagZmax as text
%        str2double(get(hObject,'String')) returns contents of tagZmax as a double
handles.Zmax = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagZmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagZmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tagVoxZ_Callback(hObject, eventdata, handles)
% hObject    handle to tagVoxZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagVoxZ as text
%        str2double(get(hObject,'String')) returns contents of tagVoxZ as a double
handles.VoxZ = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function tagVoxZ_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagVoxZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function refreshTelecentric(hObject,handles)

if handles.telecentric == 1 
    set(handles.tagAlphaR,'Enable','off');
    

    set(handles.tagSSSTR,'Enable','off');
    
    set(handles.tagSSUVR,'Enable','off');
    set(handles.tagAlphaStartRM,'Enable','off');
    set(handles.tagStepsRM,'Enable','off');
    set(handles.tagAlphaEndRM,'Enable','off');
    set(handles.tagLinearSpaceRM,'Enable','off');
    set(handles.tagLogSpaceRM,'Enable','off');
    
    set(handles.tagZlocation,'Enable','on');
    set(handles.tagXmin,'Enable','on');
    set(handles.tagXmax,'Enable','on');
    set(handles.tagYmin,'Enable','on');
    set(handles.tagYmax,'Enable','on');
    set(handles.tagZmin,'Enable','on');
    set(handles.tagZmax,'Enable','on');
    set(handles.tagVoxX,'Enable','on');
    set(handles.tagVoxY,'Enable','on');
    set(handles.tagVoxZ,'Enable','on');
else
   set(handles.tagAlphaR,'Enable','on');
    set(handles.tagSSSTR,'Enable','on');
    set(handles.tagSSUVR,'Enable','on');    
    set(handles.tagAlphaStartRM,'Enable','on');
    set(handles.tagStepsRM,'Enable','on');
    set(handles.tagAlphaEndRM,'Enable','on');
    set(handles.tagLinearSpaceRM,'Enable','on');
    set(handles.tagLogSpaceRM,'Enable','on');
    set(handles.tagZlocation,'Enable','off');
    set(handles.tagXmin,'Enable','off');
    set(handles.tagXmax,'Enable','off');
    set(handles.tagYmin,'Enable','off');
    set(handles.tagYmax,'Enable','off');
    set(handles.tagZmin,'Enable','off');
    set(handles.tagZmax,'Enable','off');
    set(handles.tagVoxX,'Enable','off');
    set(handles.tagVoxY,'Enable','off');
    set(handles.tagVoxZ,'Enable','off'); 
end
