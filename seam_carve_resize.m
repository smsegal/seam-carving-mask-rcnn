function resizedImage = seam_carve_resize(image, newWidth, newHeight)
	horizontally_resized = seam_carve_horizontal(image, newWidth, [0 0 255]);
	resizedImage = seam_carve_vertical(horizontally_resized, newHeight);
end

function resizedImage = seam_carve_vertical(image, newHeight)
	resizedImage = seam_carve_horizontal(rot90(image), newHeight, [255 0 0]);
	resizedImage = rot90(resizedImage, 3);	% undo rotation
end

function resizedImage = seam_carve_horizontal(image, newWidth, color)

% 	imshow(image)
	image = im2double(image);
	[image_height, image_width, ~] = size(image);
	sizeDiff = image_width - newWidth;

	expanding = sizeDiff < 0;	% false/0 when shrinking, true/1 when expanding

	num_seams = abs(sizeDiff);

	seams = cell(num_seams, 1);

	resizedImage = image;
	for i = 1 : num_seams
		fprintf('Iteration %i/%i\n', i, num_seams);

		E = computeEnergy(resizedImage);
		M = computeScoreMatrix(E);
		seam = computeSeam(M);
		resizedImage = removeSeam(resizedImage, seam);

		seams{i} = seam; % save for later, in case we need to expand

		imshow(resizedImage);
	end

	if expanding
		resizedImage = image;	% reset, start from the original
		for i = 1 : num_seams
			resizedImage = addSeam(resizedImage, seams{i});
			imshow(resizedImage);
		end
	end
end

function energyImage = computeEnergy(image)

	%% (a)
	[grad_mag_R, ~] = imgradient(image(:, :, 1));
	% imshow(color_image(:, :, 1), [1 255]);
	% pause;
	[grad_mag_G, ~] = imgradient(image(:, :, 2));
	% imshow(color_image(:, :, 2), [1 255]);
	% pause;
	[grad_mag_B, ~] = imgradient(image(:, :, 3));
	% imshow(color_image(:, :, 3), [1 255]);
	% pause;
	E = grad_mag_R + grad_mag_G + grad_mag_B;
% 	imshow(E, [1 255]);
	energyImage = E;
end

function scoreMatrix = computeScoreMatrix(energyImage)
		%% (b)
% 		energyImage = [
% 			1 4 3 5 2;
% 			3 2 5 2 3;
% 			5 2 4 2 1;
% 			];
%
		[E_height, E_width] = size(energyImage);
		M = zeros(E_height, E_width);


		%% (c)
		M(1, :) = energyImage(1, :); %first row of M = first row of E
		%% (d)
		for y = 2 : E_height
				rowAbove = M(y-1, :);
			for x = 2:(E_width - 1)
		% 		fprintf('X: %i, Y: %i\t\t%i\t%i\t%i\n', x, y, rowAbove(x-1), rowAbove(x), rowAbove(x+1));
				M(y, x) = energyImage(y, x) + min(rowAbove(x-1 : x+1));
			end
			M(y, 1) = energyImage(y, 1) + min(rowAbove(1 : 2));	%left column
			M(y, E_width) = energyImage(y, E_width) + min(rowAbove(E_width - 1 : E_width));	%right column
		end

		scoreMatrix = M;
end

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

function newImage = removeSeam(sourceImage, seam)
	[height, width, numColourPlanes] = size(sourceImage);

	newImage = zeros(height, width - 1, numColourPlanes);

	for r = 1:height
		seamIndex = seam(r);

		left = sourceImage(r, 1 : seamIndex-1, :);
		right = sourceImage(r, seamIndex+1 : end, :);
% 		together = [left right];
% 		test = newImage(r, :, :);
% 		whos left right together test
		newImage(r, :, :) = [left right];
	end
end

function newImage = addSeam(sourceImage, seam)
	[height, width, numColourPlanes] = size(sourceImage);

	paddedSource = padarray(sourceImage, [0 1], 'post');	% resize to add column on the right
	paddedSource(:, end) = mean(sourceImage(:, end-1:end), 2); %	set last column to avg of right 2 columns


	newImage = zeros(height, width + 1, numColourPlanes);
	for r = 1:height
		seamIndex = seam(r);

		left = sourceImage(r, 1 : seamIndex, :);
		right = sourceImage(r, seamIndex+1 : end, :);

		newPixel = mean(paddedSource(r, seamIndex : seamIndex + 1, :));
% 		newPixel = cat(3, 255, 0, 0);
		newImage(r, :, :) = [left newPixel right];
	end
end