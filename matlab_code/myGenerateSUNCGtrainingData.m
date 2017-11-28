
function myGenerateSUNCGtrainingData(sceneListFilename)
	data_dirs;
	addpath('./utils'); 

	% % So that we're allowed to use 8 parallel for loop threads
	% myCluster = parcluster('local');
	% myCluster.NumWorkers = 8;
	% saveProfile(myCluster);

	parpool(4);

	sceneDirs = getFileLines(sceneListFilename);
	numSceneDirs = numel(sceneDirs);

	numScenesDone = 0;
	for i=1:numSceneDirs
		sceneName = sceneDirs{i};
		numScenesDone = numScenesDone + 1;
		disp(sprintf('Processing scene %s (%d/%d)...', sceneName, numScenesDone, numSceneDirs))

		% Strip the trailing __0__ off the scene name to get the SUNCG scene ID
		sceneToks = strsplit(sceneName, '__');
		sceneId = sceneToks(1);
		sceneId = sceneId{1};

		% Filter out only the 'good' frames (i.e. ones that have floor and ceiling)
		goodFrames = getGoodFrames(sceneName, sceneId);

		% Pick out N random frames from this scene to use as training data
		nViewsPerScene = 13;	% This gets us close to the number of training views used by sscnet
		perm = randperm(numel(goodFrames));
		frames = cell(nViewsPerScene);
		for j=1:nViewsPerScene
			index = perm(j);
			frames{j} = goodFrames{index};
		end

		% Process frames
		% for j=1:nViewsPerScene
		parfor j=1:nViewsPerScene
			frameID = frames{j};
			disp(sprintf('   Processing frame %s...', frameID))

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
		    % yUpToZUp = [1, 0, 0, 0; 0, 0, -1, 0; 0, 1, 0, 0; 0, 0, 0, 1];
		    yUpToZUp = [1, 0, 0, 0; 0, 0, 1, 0; 0, 1, 0, 0; 0, 0, 0, 1];
		    camPoseMat = yUpToZUp * camPoseMat;     % Convert to z-up coordinates as last part of transform
		    extCam2World = camPoseMat(1:3, 1:4);    % Remove the last row (which is just [0, 0, 0, 1]) b/c subsequent code expects this

		    % Load the floor ID and room ID
		    [floorId, roomId] = loadFloorAndRoomIDFile(idsFilename);

		    %% generating scene voxels in camera view 
	        [sceneVox, voxOriginWorld] = getSceneVoxSUNCG(suncg_data_dir,sceneId,floorId+1,roomId+1,extCam2World);
	        camPoseArr = [extCam2World',[0;0;0;1]];
	        camPoseArr = camPoseArr(:);

	        % Compress with RLE and save to binary file 
	        writeRLEfile(binFilename,sceneVox,camPoseArr,voxOriginWorld)
		end
	end 
end


function [floorId, roomId] = loadFloorAndRoomIDFile(filename)
	fid = fopen(filename);
	floorId_line = fgetl(fid);
	floorId = str2num(floorId_line);
	roomId_line = fgetl(fid);
	roomId_toks = strsplit(roomId_line, '_');
	roomId_cell = roomId_toks(2);
	roomId = str2num(roomId_cell{1});
	fclose(fid); 
end


function isGood = isGoodFrame(sceneName, sceneId, houseJsonObj, frameId)
	data_dirs;

	% Load the floor and room id file for this frame
	idsFilename = sprintf('%s/%s/%s_ids.txt', input_dir, sceneName, frameId);
	[floorId, roomId] = loadFloorAndRoomIDFile(idsFilename);

	roomStruct = houseJsonObj.levels{floorId+1}.nodes{roomId+1};

	% Verify that this room has both a floor and a ceiling
	floorFilename = [fullfile(suncg_data_dir,'room',sceneId,roomStruct.modelId) 'f.obj'];
	ceilFilename = [fullfile(suncg_data_dir,'room',sceneId,roomStruct.modelId) 'c.obj'];

	isGood = false;
	if exist(floorFilename, 'file') == 2 && exist(ceilFilename, 'file') == 2
		isGood = true;
	end

end


% Returns a cell array with IDs of the frames which pass the 'isGoodFrame' test
function frameIds = getGoodFrames(sceneName, sceneId)
	data_dirs;

	frameIds = {};

	scenedirfullpath = sprintf('%s/%s', input_dir, sceneName);
	scenedircontents = dir(scenedirfullpath);

	houseJsonObj = loadjson(fullfile(suncg_data_dir,'house',sceneId,'house.json'));

	numAllFrames = 0;
	numFrames = 0;
	for j=1:size(scenedircontents,1)
		fileentry = scenedircontents(j);
		[filepath, name, ext] = fileparts(fileentry.name);
		% .png files identify the frames
		if strcmp(ext, '.png') == 1
			numAllFrames = numAllFrames + 1;
			frameId = name;
			if isGoodFrame(sceneName, sceneId, houseJsonObj, frameId)
				numFrames = numFrames + 1;
				frameIds{numFrames} = frameId;
			end
		end
	end

	% disp(sprintf('   all: %d', numAllFrames));
	% disp(sprintf('   good: %d', numFrames));

end