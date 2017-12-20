'''
Combine all non-empty training examples from training_data2 with all from training_data_good
'''

import os
import re

training_data_2_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data2'
training_data_good_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data_good'
output_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data_goodAND2'


'''
Get the complete list of frames from a directory
'''
def get_frames(directory):
	dirlst = os.listdir(directory)
	dir_contents = [f for f in dirlst if os.path.isfile(os.path.join(directory, f))]
	frames = []
	for fname in dir_contents:
		root, ext = os.path.splitext(fname)
		if ext == '.png':
			frames.append(root)
	return frames

'''
Returns true iff a frame has an empty training volume
'''
def is_empty(frame, directory):
	binfile = '{}/{}.bin'.format(directory, frame)
	info = os.stat(binfile)
	return info.st_size == 84


# Copy everything from _good into _goodAND2
os.system('cp -r {} {}'.format(training_data_good_dir, output_dir))

# Find all non-empty frames from _2, copy those into _goodAND2
frames2 = get_frames(training_data_2_dir)
frames2 = [f for f in frames2 if not is_empty(f, training_data_2_dir)]
for frame in frames2:
	os.system('cp {}/{}.png {}/'.format(training_data_2_dir, frame, output_dir))
	os.system('cp {}/{}.bin {}/'.format(training_data_2_dir, frame, output_dir))