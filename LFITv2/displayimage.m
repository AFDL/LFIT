function displayimage(imageName,captionFlag,captionString,colormapType,backgroundColor)
%DISPLAYIMAGE Displays a scaled-intensity image via imagesc with colormap

set(gcf, 'color', backgroundColor);
imagesc(imageName);
colormap(colormapType);

if captionFlag ~= 0
    title(captionString);
end

axis image;
axis off;

end