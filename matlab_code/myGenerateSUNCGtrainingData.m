function myGenerateSUNCGtrainingData()

	addpath('./utils'); 

	suncg_data_dir = '/mnt/nfs_datasets/SUNCG/suncg_data';
	input_dir = '/mnt/nfs_datasets/SUNCG/suncg_sdf-ceil_images_640x480';
	output_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data';

	dircontents = dir(input_dir);

	% Count the number of scene dirs we'll need to go through (for progress updates)
	numSceneDirs = 0;
	for i=1:size(dircontents,1)
		scenedir = dircontents(i);
		% Skip the . and .. entries
		if scenedir.isdir && strcmp(scenedir.name, '.') == 0 && strcmp(scenedir.name, '..') == 0
			numSceneDirs = numSceneDirs + 1;
		end
	end

	% Search through top-level directory, looking for subdirectories
	numScenesDone = 0;
	for i=1:size(dircontents,1)
		scenedir = dircontents(i);
		% Skip the . and .. entries
		if scenedir.isdir && strcmp(scenedir.name, '.') == 0 && strcmp(scenedir.name, '..') == 0
			sceneName = scenedir.name;
			numScenesDone = numScenesDone + 1;
			disp(sprintf('Processing scene %s (%d/%d)...', sceneName, numScenesDone, numSceneDirs))
			%%% Strip the trailing __0__ off the scene name to get the SUNCG scene ID
			sceneToks = strsplit(sceneName, '__');
			sceneId = sceneToks(1);
			%%%
			scenedirfullpath = sprintf('%s/%s', input_dir, sceneName);
			scenedircontents = dir(scenedirfullpath);

			% Count the numer of frames in this scene (for progress updates)
			numFrames = 0;
			for j=1:size(scenedircontents,1)
				fileentry = scenedircontents(j);
				[filepath, name, ext] = fileparts(fileentry.name);
				if strcmp(ext, '.png') == 1
					numFrames = numFrames + 1;
				end
			end

			% Process frames
			numFramesDone = 0;
			for j=1:size(scenedircontents,1)
				fileentry = scenedircontents(j);
				[filepath, name, ext] = fileparts(fileentry.name);
				if strcmp(ext, '.png') == 1
					frameID = name;
					numFramesDone = numFramesDone + 1;
					disp(sprintf('   Processing frame %s (%d/%d)...', frameID, numFramesDone, numFrames))
					origDepthFilename = sprintf('%s/%s/%s.png', input_dir, sceneName, frameID);
					camPoseFilename = sprintf('%s/%s/%s.txt', input_dir, sceneName, frameID);
					idsFilename = sprintf('%s/%s/%s_ids.txt', input_dir, sceneName, frameID);
					shiftedDepthFilename = sprintf('%s/%s_%s_0000.png', output_dir, sceneName, frameID);
					binFilename = sprintf('%s/%s_%s_0000.bin', output_dir, sceneName, frameID);

					% Save the shifted version of the depth image to the output directory
					saveShiftedDepth(origDepthFilename, shiftedDepthFilename);

				    % Load the camera pose matrix
				    fid = fopen(camPoseFilename);
				    camPoseMat = cell2mat(textscan(fid, '%f %f %f %f'));
				    fclose(fid);
				    yUpToZUp = [1, 0, 0, 0; 0, 0, -1, 0; 0, 1, 0, 0; 0, 0, 0, 1];
				    camPoseMat = yUpToZUp * camPoseMat;     % Convert to z-up coordinates as last part of transform
				    extCam2World = camPoseMat(1:3, 1:4);    % Remove the last row (which is just [0, 0, 0, 1]) b/c subsequent code expects this

				    % Load the floor ID and room ID
				    fid = fopen(idsFilename);
				    floorId_line = fgetl(fid);
				    floorId = str2num(floorId_line);
				    roomId_line = fgetl(fid);
				    roomId_toks = strsplit(roomId_line, '_');
				    roomId_cell = roomId_toks(2);
				    roomId = str2num(roomId_cell{1});
				    fclose(fid);

				    %% generating scene voxels in camera view 
			        [sceneVox, voxOriginWorld] = getSceneVoxSUNCG(suncg_data_dir,sceneId,floorId+1,roomId+1,extCam2World);
			        camPoseArr = [extCam2World',[0;0;0;1]];
			        camPoseArr = camPoseArr(:);
			        
			        % Compress with RLE and save to binary file 
			        writeRLEfile(binFilename,sceneVox,camPoseArr,voxOriginWorld)
				end
			end
		end
	end 