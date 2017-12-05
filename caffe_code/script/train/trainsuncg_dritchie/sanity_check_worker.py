import caffe
import numpy as np
import os
import os.path
import sys


which_gpu = 1
training_data_dir = '/mnt/nfs_datasets/SUNCG/sscnet_training_data'


def vol2points(vol,tsdf,seg_label):
    classlabel = np.argmax(vol, axis=1) 
    colorMap = np.array([[ 22,191,206],[214, 38, 40],[ 43,160, 43],[158,216,229],[114,158,206],[204,204, 91],[255,186,119],[147,102,188],[ 30,119,181],[188,188, 33],[255,127, 12],[196,175,214],[153,153,153]])
    points = []
    rgb    = []
    for x in range(classlabel.shape[1]):
        for y in range(classlabel.shape[2]):
            for z in range(classlabel.shape[3]):
                tsdfvalue = tsdf[0][0][4*x][4*y][4*z]
                if (classlabel[0][x][y][z] > 0 and seg_label[0][0][x][y][z] <= 254 and ( tsdfvalue < 0 or tsdfvalue > 0.8)):
                    points.append(np.array([x,y,z]))
                    rgb.append(np.array(colorMap[classlabel[0][x][y][z],:]))
    points = np.vstack(points)
    rgb = np.vstack(rgb)
    return {'points':points, 'rgb':rgb}

def writeply(filename, points,rgb):
	target = open(filename, 'w')
	# write the  header 
	target.write('ply\n');
	target.write('format ascii 1.0 \n')
	target.write('element vertex ' + str(points.shape[0]) + '\n')
	target.write('property float x\n')
	target.write('property float y\n')
	target.write('property float z\n')
	target.write('property uchar red\n')
	target.write('property uchar green\n')
	target.write('property uchar blue\n')
	target.write('end_header\n')
	# write the  points 
	for i in range(points.shape[0]):
		target.write('%f %f %f %d %d %d\n'%(points[i,0],points[i,1],points[i,2], rgb[i,0],rgb[i,1],rgb[i,2]))
	target.close()


def run(checkpoint_num, frame_name):
	checkpoint_file = 'suncg_iter_{}.caffemodel'.format(checkpoint_num)
	frame_image_local = frame_name + '.png'
	frame_bin_local = frame_name + '.bin'
	frame_image = os.path.join(training_data_dir, frame_image_local)
	frame_bin = os.path.join(training_data_dir, frame_bin_local)

	# Copy the inputs to the working dir
	os.system('cp {} {}'.format(frame_image, frame_image_local))
	os.system('cp {} {}'.format(frame_bin, frame_bin_local))

	# Run the net
	# Load up the net and run it on these input files
	caffe.set_mode_gpu()
	caffe.set_device(which_gpu)
	model_path =  'sanity_check_net.txt'
	pretrained_path = checkpoint_file
	net = caffe.Net(model_path, pretrained_path, caffe.TEST)
	out = net.forward()

	# Remove the inputs in the working dir
	os.system('rm -f {}'.format(frame_image_local))
	os.system('rm -f {}'.format(frame_bin_local))

	# Write output .ply
	plyfile = 'sanity_check/{}_iter_{}.ply'.format(frame_name, checkpoint_num)
	predictions = np.array(net.blobs['prob'].data)
	tsdf = np.array(net.blobs['data'].data)
	seg_label = np.array(net.blobs['seg_label'].data)
	pd = vol2points(predictions,tsdf,seg_label)
	writeply(plyfile, pd['points'],pd['rgb'])

if __name__ == '__main__':
	checkpoint_num = sys.argv[1]
	frame_name = sys.argv[2]
	run(checkpoint_num, frame_name)