function saveShiftedDepth(infilename, outfilename)
	depthVis = imread(infilename);
    depthVis = bitor(bitshift(depthVis,3), bitshift(depthVis,3-16));
    imwrite(depthVis,outfilename);
end