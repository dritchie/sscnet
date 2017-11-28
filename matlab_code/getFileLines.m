% Returns a cell array
function lines = getFileLines(filename)
	text = fileread(filename);
	lines = strsplit(text, '\n');
end