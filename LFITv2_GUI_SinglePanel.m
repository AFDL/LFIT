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
handles.contrastList = {'none','slice','stack'};
handles = setDefaults(hObject,handles);

% Load last run if present
if ~isempty(dir('lastGUI.gcfg'))
    handles = loadState(cd,'lastGUI.gcfg',hObject,handles);
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
% saveState(cd,'lastGUI.gcfg',handles)
closereq


% --- Executes during object creation, after setting all properties.
function tagHeaderIm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagHeaderIm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate tagHeaderIm


%%%%----------%%%%
%%%%---FILE---%%%%
%%%%----------%%%%
% functions related to the 'file' section of the GUI

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
            handles.outputPath = fullfile(handles.plenopticImagesPath,'Output'); % if user didn't select a folder, make one in the same directory as the plenoptic images
            fprintf('\nNo output directory selected. Output will be in: %s \n',handles.outputPath);
        end
       
    end
    imagePath = fullfile(handles.plenopticImagesPath,imageName(1).name);
    
    % Interpolate image data
    [radArray,sRange,tRange] = interpimage2(handles.cal,imagePath,handles.sensorType,handles.microPitch,handles.pixelPitch,handles.numMicroX,handles.numMicroY);
       
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
    try     close(loadHandle);
    catch   % user must have closed it already; good!
    end
    stringLoaded = [handles.firstImage ' successfully loaded and processed.'];
    uiwait(msgbox(stringLoaded,'Load Complete','modal'));
end


% --- Executes on button press in tagViewDocumentation.
function tagViewDocumentation_Callback(hObject, eventdata, handles)
% hObject    handle to tagViewDocumentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
open('LFITv2_Documentation.pdf');


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


%%%%----------------------%%%%
%%%%---GENERAL SETTINGS---%%%%
%%%%----------------------%%%%
% functions related to the 'general settings' section of the GUI

% --- Executes on selection change in tagColormapMenu.
function tagColormapMenu_Callback(hObject, eventdata, handles)
% hObject    handle to tagColormapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagColormapMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagColormapMenu
handles.colormap   = handles.colormapList{get(hObject,'Value')};

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagColormapMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagColormapMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String',{'Grayscale';'Jet';'HSV';'Hot';'Cool';'Spring';'Summer';'Autumn';'Winter';'Bone';'Copper';'Pink';'Lines'});


% --- Executes on selection change in tagImageType.
function tagImageType_Callback(hObject, eventdata, handles)
% hObject    handle to tagImageType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagImageType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagImageType
types = {'bmp','png','jpg','png16','tif16'};
handles.imFileType = types{ get(hObject,'Value') };

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


% --- Executes on selection change in tagContrast.
function tagContrast_Callback(hObject, eventdata, handles)
% hObject    handle to tagContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagContrast contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagContrast
types = {'none','slice','stack'};
handles.contrast = types{ get(hObject,'Value') };

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagContrast_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String',{'none','slice','stack'});


function tagMinIntensity_Callback(hObject, eventdata, handles)
% hObject    handle to tagMinIntensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagMinIntensity as text
%        str2double(get(hObject,'String')) returns contents of tagMinIntensity as a double
handles.minIntensity = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagMinIntensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagMinIntensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tagMaxIntensity_Callback(hObject, eventdata, handles)
% hObject    handle to tagMaxIntensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagMaxIntensity as text
%        str2double(get(hObject,'String')) returns contents of tagMaxIntensity as a double
handles.maxIntensity = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagMaxIntensity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagMaxIntensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%---ANIMATION SETTINGS---%%
% functions related to the 'animation settings' subsection of the GUI

% --- Executes on selection change in tagCodec.
function tagCodec_Callback(hObject, eventdata, handles)
% hObject    handle to tagCodec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagCodec contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagCodec
types = {'uncompressed','jpeg','jpeg2000-lossless','jpeg2000','h264','gif'};
handles.vidCodec = types{ get(hObject,'Value') };

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagCodec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagCodec (see GCBO)
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
    set(hObject,'String',{'Uncompressed AVI';'Motion JPEG AVI';'Motion JPEG 2000 (lossless)';'Motion JPEG 2000 (lossy)';'MPEG-4 (H.264)';'GIF'});
end


function tagFrameRate_Callback(hObject, eventdata, handles)
% hObject    handle to tagFrameRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagFrameRate as text
%        str2double(get(hObject,'String')) returns contents of tagFrameRate as a double
handles.frameRate = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagFrameRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagFrameRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tagQuality_Callback(hObject, eventdata, handles)
% hObject    handle to tagQuality (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagQuality as text
%        str2double(get(hObject,'String')) returns contents of tagQuality as a double
handles.quality = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagQuality_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagQuality (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%%%-----------------------%%%%
%%%%---PERSPECTIVE VIEWS---%%%%
%%%%-----------------------%%%%
% functions related to the 'perspective views' section of the GUI

% --- Executes during object creation, after setting all properties.
function tagUVDiag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagUVDiag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate tagUVDiag

% handles.perspPlot = gcbo;
% 
% Update handles structure
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
handles.SSSTP = str2double(get(hObject,'String'));

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
disp('Calculating perspective view...');
q           = lfiQuery('perspective');
q.pUV       = [handles.uVal handles.vVal];
q.stFactor  = handles.SSSTP;
q.saveas    = false;
q.display   = 'fast';
q.colormap  = handles.colormap;
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];

genperspective(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);


% --- Executes on button press in tagGenerateSaveP.
function tagGenerateSaveP_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenerateSaveP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Calculating perspective view...');
q           = lfiQuery('perspective');
q.pUV       = [handles.uVal handles.vVal];
q.stFactor  = handles.SSSTP;
q.saveas    = handles.imFileType;
q.display   = 'fast';
q.colormap  = handles.colormap;
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];

genperspective(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);


% --- Executes on button press in tagExportPerspectiveVid.
function tagExportPerspectiveVid_Callback(hObject, eventdata, handles)
% hObject    handle to tagExportPerspectiveVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmpi( handles.vidCodec, 'h264' )
    fileType = 'mp4';
elseif strcmpi( handles.vidCodec, 'gif' )
    fileType = 'gif';
else
    fileType = 'avi';
end

q               = lfiQuery('perspective');
q.pUV           = gentravelvector( handles.edgeBuffer, size(handles.radArray), handles.SSUVPM, handles.travelVector );
q.uvFactor      = handles.SSUVPM;
q.stFactor      = handles.SSSTP;
q.mask          = handles.aperMask;
q.saveas        = fileType;
q.quality       = handles.quality;
q.codec         = handles.vidCodec;
q.framerate     = handles.frameRate;
q.display       = 'fast';
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];
q.colormap      = handles.colormap;
q.background    = [0 0 0];

genperspective(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);


%%---PERSPECTIVE ANIMATION SETTINGS---%%
% functions related to the 'perspective animation settings' subsection of the GUI

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


% --- Executes on selection change in tagTravelVector.
function tagTravelVector_Callback(hObject, eventdata, handles)
% hObject    handle to tagTravelVector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagTravelVector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagTravelVector
handles.travelVector = get(hObject,'Value');

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


%%%%----------------%%%%
%%%%---REFOCUSING---%%%%
%%%%----------------%%%%
% functions related to the 'refocusing' section of the GUI

% --- Executes on button press in tagGenDispR.
function tagGenDispR_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenDispR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

q               = lfiQuery('focus');
q.fMethod       = handles.refocusType;
q.fFilter       = [handles.noiseThreshold handles.filterThreshold];
if handles.telecentric
    q.fZoom     = 'telecentric';
    q.fGridX    = linspace( handles.Xmin, handles.Xmax, handles.VoxX );
    q.fGridY    = linspace( handles.Ymin, handles.Ymax, handles.VoxY );
    q.fPlane    = handles.Zlocation;
    q.fLength   = handles.focLenMain;
    q.fMag      = handles.magnification;
else
    q.fZoom     = 'legacy';
    q.fAlpha    = handles.alpha;
end
q.uvFactor      = handles.SSUVR;
q.stFactor      = handles.SSSTR;
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];
q.mask          = handles.aperMask;
q.saveas        = false;
q.display       = 'fast';
q.colormap      = handles.colormap;
q.background    = [1 1 1];

genrefocus(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);


% --- Executes on button press in tagGenSaveR.
function tagGenSaveR_Callback(hObject, eventdata, handles)
% hObject    handle to tagGenSaveR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

q               = lfiQuery('focus');
q.fMethod       = handles.refocusType;
q.fFilter       = [handles.noiseThreshold handles.filterThreshold];
if handles.telecentric
    q.fZoom     = 'telecentric';
    q.fGridX    = linspace( handles.Xmin, handles.Xmax, handles.VoxX );
    q.fGridY    = linspace( handles.Ymin, handles.Ymax, handles.VoxY );
    q.fPlane    = handles.Zlocation;
    q.fLength   = handles.focLenMain;
    q.fMag      = handles.magnification;
else
    q.fZoom     = 'legacy';
    q.fAlpha    = handles.alpha;
end
q.uvFactor      = handles.SSUVR;
q.stFactor      = handles.SSSTR;
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];
q.mask          = handles.aperMask;
q.saveas        = handles.imFileType;
q.display       = 'fast';
q.colormap      = handles.colormap;
q.background    = [1 1 1];

genrefocus(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);
  

% --- Executes on button press in tagExportRefocusVid.
function tagExportRefocusVid_Callback(hObject, eventdata, handles)
% hObject    handle to tagExportRefocusVid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmpi( handles.vidCodec, 'h264' )
    fileType = 'mp4';
elseif strcmpi( handles.vidCodec, 'gif' )
    fileType = 'gif';
else
    fileType = 'avi';
end

q               = lfiQuery('focus');
q.fMethod       = handles.refocusType;
q.fFilter       = [handles.noiseThreshold handles.filterThreshold];
if handles.telecentric
    q.fZoom     = 'telecentric';
    q.fGridX    = linspace( handles.Xmin, handles.Xmax, handles.VoxX );
    q.fGridY    = linspace( handles.Ymin, handles.Ymax, handles.VoxY );
    q.fPlane    = linspace( handles.Zmin, handles.Zmax, handles.VoxZ );
    q.fLength   = handles.focLenMain;
    q.fMag      = handles.magnification;
else
    q.fZoom     = 'legacy';
    if handles.stepSpace,       alpha = logspace( log10(handles.alphaStart), log10(handles.alphaEnd), handles.steps );
    else                        alpha = linspace( handles.alphaStart, handles.alphaEnd, handles.steps );
    end
    if handles.mirrorLoop,    alpha = [ alpha(2:end) fliplr(alpha) ];
    end
    q.fAlpha    = alpha;
end
q.uvFactor      = handles.SSUVR;
q.stFactor      = handles.SSSTR;
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];
q.mask          = handles.aperMask;
q.saveas        = fileType;
q.quality       = handles.quality;
q.codec         = handles.vidCodec;
q.framerate     = handles.frameRate;
q.display       = 'fast';
q.colormap      = handles.colormap;
q.background    = [0 0 0];

genrefocus(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);

% --- Executes on button press in tagExportFocalStack.
function tagExportFocalStack_Callback(hObject, eventdata, handles)
% hObject    handle to tagExportFocalStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

q               = lfiQuery('focus');
q.fMethod       = handles.refocusType;
q.fFilter       = [handles.noiseThreshold handles.filterThreshold];
if handles.telecentric
    q.fZoom     = 'telecentric';
    q.fGridX    = linspace( handles.Xmin, handles.Xmax, handles.VoxX );
    q.fGridY    = linspace( handles.Ymin, handles.Ymax, handles.VoxY );
    q.fPlane    = linspace( handles.Zmin, handles.Zmax, handles.VoxZ );
    q.fLength   = handles.focLenMain;
    q.fMag      = handles.magnification;
else
    q.fZoom     = 'legacy';
    if handles.stepSpace,     alpha = logspace( log10(handles.alphaStart), log10(handles.alphaEnd), handles.steps );
    else                        alpha = linspace( handles.alphaStart, handles.alphaEnd, handles.steps );
    end
    q.fAlpha    = alpha;
end
q.uvFactor      = handles.SSUVR;
q.stFactor      = handles.SSSTR;
q.contrast      = handles.contrast;
q.intensity     = [handles.minIntensity, handles.maxIntensity];
q.mask          = handles.aperMask;
q.saveas        = handles.imFileType;
q.display       = 'fast';
q.colormap      = handles.colormap;
q.background    = [1 1 1];

genrefocus(q,handles.radArray,handles.sRange,handles.tRange,handles.outputPath,handles.imageSpecificName);

% --- Executes on button press in tagMirrorLoop.
function tagMirrorLoop_Callback(hObject, eventdata, handles)
% hObject    handle to tagMirrorLoop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagMirrorLoop
handles.mirrorLoop = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


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
        handles.aperMask = false;
    case 'tagCircAper'
        handles.aperMask = 'circ';
end

% Update handles structure
guidata(hObject, handles);


% --- Executes when selected object is changed in tagSpace.
function tagSpace_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in tagSpace 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'tagLinearSpace'
        handles.stepSpace = 0;
%         handles.stepSpaceFS = 0;
    case 'tagLogSpace'
        handles.stepSpace = 1;
%         handles.stepSpaceFS = 1;
end

% Update handles structure
guidata(hObject, handles);


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


%%---REFOCUSING TYPE---%%
% functions related to the 'refocusing type' subsection of the GUI

% --- Executes on selection change in tagRefocusType.
function tagRefocusType_Callback(hObject, eventdata, handles)
% hObject    handle to tagRefocusType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns tagRefocusType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from tagRefocusType
types = {'add','mult','filt'};
handles.refocusType = types{ get(hObject,'Value') };

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


%%---LEGACY MAGNIFICATION---%%
% functions related to the 'legacy magnification' subsection of the GUI

function tagAlpha_Callback(hObject, eventdata, handles)
% hObject    handle to tagAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagAlpha as text
%        str2double(get(hObject,'String')) returns contents of tagAlpha as a double
input = str2double(get(hObject,'String'));
handles.alpha = input;

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagAlpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagAlpha (see GCBO)
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
handles.SSSTR = str2double(get(hObject,'String'));

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
handles.SSUVR = str2double(get(hObject,'String'));

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


function tagAlphaStart_Callback(hObject, eventdata, handles)
% hObject    handle to tagAlphaStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagAlphaStart as text
%        str2double(get(hObject,'String')) returns contents of tagAlphaStart as a double
handles.alphaStart = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagAlphaStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagAlphaStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tagSteps_Callback(hObject, eventdata, handles)
% hObject    handle to tagSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagSteps as text
%        str2double(get(hObject,'String')) returns contents of tagSteps as a double
handles.steps = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagSteps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagSteps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function tagAlphaEnd_Callback(hObject, eventdata, handles)
% hObject    handle to tagAlphaEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagAlphaEnd as text
%        str2double(get(hObject,'String')) returns contents of tagAlphaEnd as a double
handles.alphaEnd = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function tagAlphaEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagAlphaEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%%---LEGACY MAGNIFICATION---%%
% functions related to the 'legacy magnification' subsection of the GUI

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


function tagXmin_Callback(hObject, eventdata, handles)
% hObject    handle to tagXmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagXmin as text
%        str2double(get(hObject,'String')) returns contents of tagXmin as a double

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
    set(handles.tagAlpha,'Enable','off');
    
    set(handles.tagSSSTR,'Enable','off');
    
    set(handles.tagSSUVR,'Enable','off');
    set(handles.tagAlphaStart,'Enable','off');
    set(handles.tagSteps,'Enable','off');
    set(handles.tagAlphaEnd,'Enable','off');
    set(handles.tagLinearSpace,'Enable','off');
    set(handles.tagLogSpace,'Enable','off');
    
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
   set(handles.tagAlpha,'Enable','on');
    set(handles.tagSSSTR,'Enable','on');
    set(handles.tagSSUVR,'Enable','on');    
    set(handles.tagAlphaStart,'Enable','on');
    set(handles.tagSteps,'Enable','on');
    set(handles.tagAlphaEnd,'Enable','on');
    set(handles.tagLinearSpace,'Enable','on');
    set(handles.tagLogSpace,'Enable','on');
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


%%%%-----------%%%%
%%%%---OTHER---%%%%
%%%%-----------%%%%
% functions related to mutiple sections or currently unused

function [handles] = setDefaults(hObject,handles)
% Put default values into handles structure
%%---FILE---%%
handles.firstImage = '<no image loaded>';

set(handles.tagCurIm,'String', handles.firstImage); % image name

%%---GENERAL SETTINGS---%%
handles.colormap = 'gray';
handles.imFileType = 'png16';
handles.contrast = 'none';
handles.minIntensity = 0;
handles.maxIntensity = 1;
handles.vidCodec = 'jpeg';
handles.frameRate = 15;
handles.quality = 90;

set(handles.tagColormapMenu,'Value',find(strcmp(handles.colormap, handles.colormapList)));
set(handles.tagImageType, 'Value', 4);
set(handles.tagContrast, 'Value', 1);
set(handles.tagMinIntensity, 'String', handles.minIntensity);
set(handles.tagMaxIntensity, 'String', handles.maxIntensity);
set(handles.tagCodec, 'Value', 2);
set(handles.tagFrameRate, 'String', handles.frameRate);
set(handles.tagQuality, 'String', handles.quality);

%%---PERSPECTIVE VIEWS---%%
handles.uVal = 0;
handles.vVal = 0;
handles.edgeBuffer = 2;
handles.SSUVPM = 1;
handles.SSSTP = 1;
handles.travelVector = 1;

set(handles.tagU, 'String', handles.uVal);
set(handles.tagV, 'String', handles.vVal);
set(handles.tagEdgeBuffer, 'String', handles.edgeBuffer);
set(handles.tagSSUVPM, 'String', handles.SSUVPM);
set(handles.tagSSSTP, 'String', handles.SSSTP);
set(handles.tagTravelVector,'Value',handles.travelVector);

%%---REFOCUSING---%%
handles.aperMask = 'circ';
handles.refocusType = 'add'; %additive = 1
handles.noiseThreshold = 0;
handles.filterThreshold = 0.9;
handles.mirrorLoop = 0;

if strcmpi( handles.aperMask, 'circ' )
    set(handles.tagCircAper, 'Value', 1);
else
    set(handles.tagApertureNone, 'Value', 1);
end
set(handles.tagRefocusType,'Value',1);
set(handles.tagNoiseThreshold,'String',handles.noiseThreshold);
set(handles.tagFilterThreshold,'String',handles.filterThreshold);
set(handles.tagMirrorLoop, 'Value', handles.mirrorLoop);

%---LEGACY REFOCUSING---%%
handles.alpha = 1.00;
handles.SSSTR = 1;
handles.SSUVR = 1;
handles.alphaStart = 0.90;
handles.steps = 20;
handles.alphaEnd = 1.10;
handles.stepSpace = 0;

set(handles.tagAlpha, 'String', handles.alpha);
set(handles.tagSSSTR, 'String', handles.SSSTR);
set(handles.tagSSUVR, 'String', handles.SSUVR);
set(handles.tagAlphaStart, 'String', handles.alphaStart);
set(handles.tagSteps, 'String', handles.steps);
set(handles.tagAlphaEnd, 'String', handles.alphaEnd);
if handles.stepSpace == 0
    set(handles.tagLinearSpace, 'Value', 1);
else
    set(handles.tagLogSpace, 'Value', 1);
end

set(handles.tagAlpha,'Enable','on');
set(handles.tagSSSTR,'Enable','on');
set(handles.tagSSUVR,'Enable','on');
set(handles.tagAlphaStart,'Enable','on');
set(handles.tagSteps,'Enable','on');
set(handles.tagAlphaEnd,'Enable','on');
set(handles.tagLinearSpace,'Enable','on');
set(handles.tagLogSpace,'Enable','on');

%---CONSTANT MAGNIFICATION---%%
handles.telecentric = 0;
handles.Zlocation = 0;
handles.Xmin = -18;
handles.Xmax = 18;
handles.Ymin = -12;
handles.Ymax = 12;
handles.Zmin = -12;
handles.Zmax = 12;
handles.VoxX = 300;
handles.VoxY = 200;
handles.VoxZ = 200;

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

%%---OTHER---%%
handles.progVersion = 2.00; % converted to a string when set below.

set(handles.tagProgramVersion, 'String', ['v' num2str(handles.progVersion,'%2.2f')]);

%%---UNUSED---%%
handles.dispCoordTitleP = 0;
handles.dispAlphaTitleR = 0;

set(handles.tagDispCoordP, 'Value', handles.dispCoordTitleP);
set(handles.tagCaptionAlphaR, 'Value', handles.dispAlphaTitleR);

% Update handles structure
guidata(hObject, handles);



function refreshFields(hObject,handles)
% Sets all the field boxes in the GUI to whatever the literal handle values are. This is necessary b/c of how loading works.

%%---FILE---%%
set(handles.tagCurIm,'String', handles.firstImage); 

%%---GENERAL SETTINGS---%%
set(handles.tagColormapMenu,'Value',find(strcmp(handles.colormap, handles.colormapList)));
set(handles.tagImageType, 'Value', 4);
set(handles.tagContrast, 'Value', 1);
set(handles.tagMinIntensity, 'String', handles.minIntensity);
set(handles.tagMaxIntensity, 'String', handles.maxIntensity);
set(handles.tagCodec, 'Value', 2);
set(handles.tagFrameRate, 'String', handles.frameRate);
set(handles.tagQuality, 'String', handles.quality);

%%---PERSPECTIVE VIEWS---%%
set(handles.tagU, 'String', handles.uVal);
set(handles.tagV, 'String', handles.vVal);
set(handles.tagEdgeBuffer, 'String', handles.edgeBuffer);
set(handles.tagSSUVPM, 'String', handles.SSUVPM);
set(handles.tagSSSTP, 'String', handles.SSSTP);
set(handles.tagTravelVector,'Value',handles.travelVector);

%%---REFOCUSING---%%
if strcmpi( handles.aperMask, 'circ' )
    set(handles.tagCircAper, 'Value', 1);
else
    set(handles.tagApertureNone, 'Value', 1);
end
set(handles.tagRefocusType,'Value',1);
set(handles.tagNoiseThreshold,'String',handles.noiseThreshold);
set(handles.tagFilterThreshold,'String',handles.filterThreshold);
set(handles.tagMirrorLoop, 'Value', handles.mirrorLoop);

%---LEGACY REFOCUSING---%
set(handles.tagAlpha, 'String', handles.alpha);
set(handles.tagSSSTR, 'String', handles.SSSTR);
set(handles.tagSSUVR, 'String', handles.SSUVR);
set(handles.tagAlphaStart, 'String', handles.alphaStart);
set(handles.tagSteps, 'String', handles.steps);
set(handles.tagAlphaEnd, 'String', handles.alphaEnd);
if handles.stepSpace == 0
    set(handles.tagLinearSpace, 'Value', 1);
else
    set(handles.tagLogSpace, 'Value', 1);
end

%---CONSTANT MAGNIFICATION---%
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

%%---OTHER---%%
set(handles.tagProgramVersion, 'String', ['v' num2str(handles.progVersion,'%2.2f')]);

%%---UNUSED---%%
set(handles.tagDispCoordP, 'Value', handles.dispCoordTitleP);
set(handles.tagCaptionAlphaR, 'Value', handles.dispAlphaTitleR);


function saveState(pathname,filename,handles)
% Delete big variables from handles structure
workspaceVariables = evalin('base','who');
handlesSave = rmfield(handles,workspaceVariables);
save(fullfile(pathname,filename), 'handlesSave','-mat');

function handles = loadState(pathname,filename,hObject,handles)
% Load last configuration
try
    loadedStruct = load(fullfile(pathname,filename), '-mat');
    names = fieldnames(loadedStruct.handlesSave);
    % The handles structure appears to list field names in a particular order; we are only interested in the fields after colormapList, the first custom handle.
    startInd = find(strcmp('colormapList',names));
    for k = startInd:numel(names)
        handles.(names{k}) = loadedStruct.handlesSave.(names{k});
    end
    refreshFields(hObject,handles); %handles loaded behind the scenes; now update the GUI to match the actual values
catch
    warning('Loading of previous configuration settings failed. Resetting to default values...');
    % Could delete old run config here, but for now let's leave that up to the user and just load defaults.
    setDefaults(hObject,handles);
end

% --- Executes when figure1 is resized.
function figure1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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


% --- Executes on button press in tagDispCoordP.
function tagDispCoordP_Callback(hObject, eventdata, handles)
% hObject    handle to tagDispCoordP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagDispCoordP
handles.dispCoordTitleP = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in tagCaptionAlphaR.
function tagCaptionAlphaR_Callback(hObject, eventdata, handles)
% hObject    handle to tagCaptionAlphaR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tagCaptionAlphaR
handles.dispAlphaTitleR = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);
