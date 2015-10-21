function displayimage(imageName,captionString,colormapType,backgroundColor)
%DISPLAYIMAGE Displays a scaled-intensity image via imagesc with colormap

set(gcf, 'color', backgroundColor);
imagesc(imageName);
colormap(colormapType);

if ~isempty(captionString)
    title(captionString);
end

axis image;
axis off;

end