function splitLineBasedFile(filename, numSplits)

	lines = getFileLines(filename);
	numlines = numel(lines);

	% Open a bunch of files to write to
	files = {};
	for i=1:numSplits
		files{i} = fopen(sprintf('%s.%d', filename, i), 'w');
	end

	% Split the lines into multiple files
	linesPerSplit = floor(numlines / numSplits);
	for i=1:numlines
		split = min(floor((i-1) / linesPerSplit) + 1, numSplits);
		file = files{split};
		fprintf(file, '%s\n', lines{i});
	end

	% Close files
	for i=1:numSplits
		fclose(files{i});
	end
end