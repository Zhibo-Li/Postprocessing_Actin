% This function is used to remove the background of a series of images
% based on the average among all of them.
%
% only support 8-bit and 16-bit images @ 2022-01-14
% inputs should be multitif file @ 2022-01-14

clear; clc; close all;
pathname = 'G:\PhD, PMMH, ESPCI\Experimental Data (EXTRACTED)\20220624-SU8_Fibers-Individual_triangularPillar_uppoint\'; % the path that contains the *.tif files to be processed
filelist = dir(fullfile(pathname,'*.tif'));

for ii = 1:size(filelist, 1)
    
    filename = filelist(ii).name;
    IP = [pathname,filename];
    
    % find out extension and filename
    inext = regexp(filename,'.tif');
    tifroot = filename(1:inext-1);
    
    % get image info
    InfoImage=imfinfo(IP);
    % bit depth
    bitimg = InfoImage.BitDepth;
    % number of images in the multi-tiff file
    imtot=length(InfoImage);
    % size of images
    imgW = InfoImage.Width;
    imgH = InfoImage.Height;
    
    IMG = zeros(imgH, imgW);
    newimg = zeros(imgH, imgW, imtot);
    newimg = uint16(newimg);
    
    % Read the pics and add them
    for i = 1:imtot
        img = im2double(imread(IP,i));
        IMG = IMG + img;
    end
    
    % Calculate the mean value
    if bitimg == 16
        bg = im2uint16(IMG/imtot);
    elseif bitimg == 8
        bg = im2uint8(IMG/imtot);
    end
    
    for j = 1:imtot
        newimg(:, :, j) = imread(IP,j) - bg;
    end
    
    if ~exist([pathname,'AfterAveBGR'],'dir')
        mkdir([pathname,'AfterAveBGR'])
    end
    
    % save as *.mat file
    %         save([pathname,'AfterAveBGR',filesep,tifroot,'_AABGR_A.mat'],'newimgA','timeGapA');
    %         save([pathname,'AfterAveBGR',filesep,tifroot,'_AABGR_B.mat'],'newimgB','timeGapB');
    
    % save as *.tif file (multiple tiff)
    options.append = true;
    saveastiff(newimg, [pathname,'AfterAveBGR',filesep,tifroot,'_AABGR.tif'], options);
    
end