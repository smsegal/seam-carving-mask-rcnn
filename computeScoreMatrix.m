function scoreMatrix = computeScoreMatrix(energyImage)
		%% (b)
		% energyImage = [
		% 	1 4 3 5 2;
		% 	3 2 5 2 3;
		% 	5 2 4 2 1;
		% 	];
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
