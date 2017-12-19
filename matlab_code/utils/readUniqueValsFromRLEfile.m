function unique_vals = readUniqueValsFromRLEfile(sceneVoxFilename)
fileID = fopen(sceneVoxFilename,'r');  
voxOriginWorld = fread(fileID,3,'single');
camPoseArr = fread(fileID,16,'single');
checkVoxRLE = fread(fileID,'uint32');
fclose(fileID);
% Every other entry is a value (the other entries are run lengths)
vox_vals = checkVoxRLE(1:2:end);
unique_vals = unique(vox_vals);
end