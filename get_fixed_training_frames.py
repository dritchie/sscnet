'''
Look through SSCNet training frames, find all frames that also appear in the "fixids" lists (lists of frames
   whose floor / room ID has changed)
'''

import os
import re

raw_data_dir = '/mnt/nfs_datasets/SUNCG/suncg_sdf-ceil_images_640x480'
training_data_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data'


'''
Convert a comma-separated scene,frame filename into a scene_frame_0000 filename
'''
def from_comma_separated(filename):
	toks = filename.split(',')
	scene = toks[0]
	frame = toks[1]
	return '{}_{}_0000'.format(scene, frame)

'''
Convert a scene_frame_0000 filename into a comma separated scene,frame filename
'''
def to_comma_separated(filename):
	match = re.search(r"([a-f0-9]+__\d__)_(\d+)_0000", filename)
	scene = match.group(1)
	frame = match.group(2)
	return '{},{}'.format(scene, frame)

'''
Get all frames from one fixids_*.txt file
'''
def load_fixids_file(filename):
	fixids_file = open(filename, 'r')
	lines = fixids_file.readlines()
	lines = [l.strip() for l in lines]
	return [from_comma_separated(l) for l in lines]

'''
Get the complete list of fixed frames
'''
def get_fixed_frames():
	frames = []
	# Get everything in fixids_*.txt
	for i in range(0, 4):
		filename = '{}/fixids_{}.txt'.format(raw_data_dir, i)
		frames.extend(load_fixids_file(filename))
	# Get everything in fixids_*_new.txt
	for i in range(0, 4):
		filename = '{}/fixids_{}_new.txt'.format(raw_data_dir, i)
		frames.extend(load_fixids_file(filename))
	# Get everything in fixids_*_new2.txt
	for i in range(0, 4):
		filename = '{}/fixids_{}_new2.txt'.format(raw_data_dir, i)
		frames.extend(load_fixids_file(filename))
	# Get everything in fixids_*_new3.txt
	for i in range(0, 4):
		filename = '{}/fixids_{}_new3.txt'.format(raw_data_dir, i)
		frames.extend(load_fixids_file(filename))
	return frames

'''
Get the complete list of training frames
'''
def get_training_frames():
	dirlst = os.listdir(training_data_dir)
	dir_contents = [f for f in dirlst if os.path.isfile(os.path.join(training_data_dir, f))]
	frames = []
	for fname in dir_contents:
		root, ext = os.path.splitext(fname)
		if ext == '.png':
			frames.append(root)
	return frames

'''
Save a list of strings to a file, line-by-line
'''
def save_strings_to_file(strings, filename):
	f = open(filename, 'w')
	for s in strings:
		f.write(s + '\n')
	f.close()




fixed_frames = get_fixed_frames()
training_frames = get_training_frames()

# Find all training_frames that are also fixed_frames
fixed_frames = set(fixed_frames)
fixed_training_frames = [frame for frame in training_frames if frame in fixed_frames]

print('# fixed frames: {}'.format(len(fixed_training_frames)))

# Write out a master file of all fixed frames, plus split it into four sub-files for
#    parallel data gen on four different machines
fixed_training_frames_cs = list(map(to_comma_separated, fixed_training_frames))
save_strings_to_file(fixed_training_frames_cs, './matlab_code/fixed_training_frames.txt')
num_splits = 4
splits = [fixed_training_frames_cs[i::num_splits] for i in range(num_splits)]
for i in range(0, num_splits):
	save_strings_to_file(splits[i], './matlab_code/fixed_training_frames_{}.txt'.format(i))






# Check if there are any empty (i.e. 84 byte) .bin files in the list of frames which
#    are not marked as fixed
not_fixed_training_frames = [frame for frame in training_frames if not (frame in fixed_frames)]
empty_bins = []
for frame in not_fixed_training_frames:
	binfile = '{}/{}.bin'.format(training_data_dir, frame)
	info = os.stat(binfile)
	if info.st_size == 84:
		empty_bins.append(frame)

print('# unfixed frames w/ empty volumes: {}'.format(len(empty_bins)))

# Copy some of these files to the test/ dir so we can look at them
if os.path.exists('./test/empty_bin_frames'):
	os.system('rm -rf ./test/empty_bin_frames')
os.makedirs('./test/empty_bin_frames')
for frame in empty_bins[0:100]:
	os.system('cp {}/{}.png ./test/empty_bin_frames/'.format(training_data_dir, frame))

# Save this list of frames for Angie to look at
save_strings_to_file(list(map(to_comma_separated, empty_bins)), './still_empty.txt')


# Create a 'good' training set: all frames that were not marked as fixed and that also
#    don't have empty ground truth volumes
# (Might not be strictly speaking 'good,' since the ground truth volumes could be wrong
#    but not empty)
good_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data_good'
# size_of_good_set = 100	# small subset of overall good frames
empty_set = set(empty_bins)
good_frames = [frame for frame in not_fixed_training_frames if not (frame in empty_set)]
print('# unfixed frames with non-empty volumes: {}'.format(len(good_frames)))
if os.path.exists(good_dir):
	os.system('rm -rf {}'.format(good_dir))
os.makedirs(good_dir)
# for frame in good_frames[0:size_of_good_set]:
for frame in good_frames:
	os.system('cp {}/{}.bin {}/'.format(training_data_dir, frame, good_dir))
	os.system('cp {}/{}.png {}/'.format(training_data_dir, frame, good_dir))


