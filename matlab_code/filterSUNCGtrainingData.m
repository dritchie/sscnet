% Filter out any frames that contain only empty/wall/ceiling/floor/outside labels in the
%    ground-truth volume
function filterSUNCGtrainingData()
	input_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data';
	output_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data_filtered';

	% Ensure output_dir exists
	if exist(output_dir, 'dir') ~= 7
		mkdir(output_dir);
	end

	addpath('./utils'); 

	input_dir_contents = dir(input_dir);

	% Count how many files we need to process
	num_frames = 0;
	for file = input_dir_contents'
		[filepath, name, ext] = fileparts(file.name);
		if strcmp(ext, '.bin') == 1
			num_frames = num_frames + 1;
		end
	end

	% 0 = empty
	% 1,2,3 = ceiling, floor, wall
	% 255 = outside room
	master_set = [0, 1, 2, 3, 255];

	num_frames_done = 0;
	num_frames_copied = 0;

	fprintf('Processing...\n');
	for file = input_dir_contents'
		[filepath, name, ext] = fileparts(file.name);
		if strcmp(ext, '.bin') == 1
			num_frames_done = num_frames_done + 1;
			fullpath = fullfile(input_dir, [name '.bin']);
			unique_vox_vals = readUniqueValsFromRLEfile(fullpath);
			% Here's the check for whether the volume contains anything other than
			%   empty/wall/floor/ceiling/outside
			if all(ismember(unique_vox_vals, master_set))
				num_frames_copied = num_frames_copied + 1;
				in_fullpath_bin = fullpath;
				in_fullpath_png = fullfile(input_dir, [name '.png']);
				out_fullpath_bin = fullfile(output_dir, [name '.bin']);
				out_fullpath_png = fullfile(output_dir, [name '.png']);
				copyfile(in_fullpath_bin, out_fullpath_bin);
				copyfile(in_fullpath_png, out_fullpath_png);
			end
			fprintf('Processed %d/%d frames (kept %d)\n', num_frames_done, num_frames, num_frames_copied);
		end
	end

end