function seams = computeSeam(scoreMatrix)
	height = size(scoreMatrix, 1);
	seams = zeros(height, 1); % Image height X 1

	scoreMatrix = padarray(scoreMatrix, [0 1], realmax);

	[~, c] = min(scoreMatrix(end, :));	% column index of lowest score in last row of M
	seams(end) = c - 1; % accounts for 1 px left padding

	for r = height - 1 : -1 : 1
		row = scoreMatrix(r, :);
		[~, offset] = min(row(c-1 : c+1));
		c = c + offset - 2;
		seams(r) = c - 1; % accounts for 1 px left padding
	end
end
