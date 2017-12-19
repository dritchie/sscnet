'''
Take a directory of SSCNet training data, filter it so it only contains frames from n_scenes scenes
'''

import os
import re
from shutil import copyfile

n_scenes = 20

input_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data_filtered'
output_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data_filtered_small'

if not os.path.exists(output_dir):
	os.makedirs(output_dir)

dir_contents = [f for f in os.listdir(input_dir) if os.path.isfile(os.path.join(input_dir, f))]

# Build map from scene name to frames
scene_to_frames = {}
for fname in dir_contents:
	root, ext = os.path.splitext(fname)
	if ext == '.png':
		# Split into scene name + the rest (minus extension)
		match = re.search(r"([a-f0-9]+)__\d___\d+_0000", root)
		sceneId = match.group(1)
		if not (sceneId in scene_to_frames):
			scene_to_frames[sceneId] = []
		scene_to_frames[sceneId].append(root)

# print(len(scene_to_frames.keys()))

# Keep only n_scenes of frames
subset_keys = scene_to_frames.keys()[0:n_scenes]
for sceneId in subset_keys:
	frameNames = scene_to_frames[sceneId]
	for frameName in frameNames:
		in_bin_path = os.path.join(input_dir, frameName + '.bin')
		in_png_path = os.path.join(input_dir, frameName + '.png')
		out_bin_path = os.path.join(output_dir, frameName + '.bin')
		out_png_path = os.path.join(output_dir, frameName + '.png')
		copyfile(in_bin_path, out_bin_path)
		copyfile(in_png_path, out_png_path)
