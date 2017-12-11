import os
import subprocess

training_data_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data'

# checkpoints_to_run = range(200, 2000, 200)
checkpoints_to_run = [29800]

frames_to_run = [
	# '0ac297c80cba3266c3999204e27d67ae__0___5_0000',
	'02a934040972db8edd03f0c8f3cbf712__0___19_0000',
	'2c146fe47252b29c4d6e2f2a18495b07__1___56_0000',
	'338f951bfaecd2052ce32afd4b7309db__1___28_0000'
]

for checkpoint_num in checkpoints_to_run:

	# Copy all the .pngs for all test frames to sanity_check, so we can easily look at them
	for frame_name in frames_to_run:
		os.system('cp {}.png sanity_check/'.format(os.path.join(training_data_dir, frame_name)))

	print('Running checkpoint {}...'.format(checkpoint_num))
	for frame_name in frames_to_run:
		print('   Running frame {}'.format(frame_name))
		# Run the net (in process isolation, so it gets torn down after every run)
		subprocess.call(['python', 'sanity_check_worker.py', str(checkpoint_num), frame_name])
