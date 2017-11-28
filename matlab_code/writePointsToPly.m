% points is 3 x N matrix
function writePointsToPly(points, outfilename, subsample)

	% Filter out points that are NaN
	points = points(:,sum(isnan(points),1)==0);
	% points = points(:,sum(points,1)>0);
	if subsample
		S = 1000;
		points = points(:,1:S:end);
	end

	f = fopen(outfilename, 'w');

	nPoints = size(points, 2);

	% Write .ply header
	fprintf(f, 'ply\n');
    fprintf(f, 'format ascii 1.0 \n');
    fprintf(f, 'element vertex %d\n', nPoints);
    fprintf(f, 'property float x\n');
    fprintf(f, 'property float y\n');
    fprintf(f, 'property float z\n');
    fprintf(f, 'property uchar red\n');
    fprintf(f, 'property uchar green\n');
    fprintf(f, 'property uchar blue\n');
    fprintf(f, 'end_header\n');

    % Write points
	for i=1:nPoints 
		point = points(:,i);
		fprintf(f, '%f %f %f 125 125 125\n', point(1), point(2), point(3));
	end

	fclose(f);

end