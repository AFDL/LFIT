function gifwrite(frame,cMap,dither,filename,delayTime,loopCount,ind)
% gifwrite | Use inside a loop to create a GIF file frame-by-frame
%
% frame = image to write to GIF file
% cMap = colormap used to display the image
% dither = 0 for none, 1 for dithering (recommended)
% filename = full file path (unless saving in the current directory)
% delayTime = delay between frames (0 default)
% loopCount = number of times the GIF loops (inf default)
% ind = which frame of the GIF that is currently being written (1 = first frame)

if dither == 0
    dOpt = 'nodither';
else
    dOpt = 'dither';
end

im = frame2im(frame);

% Colormap logic
try
[imind,cm] = rgb2ind(im,256,dOpt);
catch err
    try
        imind = im;
        cm = colormap([cMap '(256)']);
    catch err2
        rethrow(err);
    end
end

% On the first loop, create the file. In subsequent loops, append.
if ind==1
    imwrite(imind,cm,filename,'gif','DelayTime',delayTime,'loopcount',loopCount);
else
    imwrite(imind,cm,filename,'gif','DelayTime',delayTime,'writemode','append');
end

end