ryerson_720_480 = imread('ryerson.jpg');

ryerson_640_480 = seam_carve_resize(ryerson_720_480, 640, 480);
imshow(ryerson_640_480);
imwrite(ryerson_640_480,'question3_ryerson_640_480.jpg','jpg');
pause;

ryerson_720_320 = seam_carve_resize(ryerson_720_480, 720, 320);
imshow(ryerson_720_320);
imwrite(ryerson_720_320,'question3_ryerson_720_320.jpg','jpg');
pause;

% ryerson_576_384 = seam_carve_resize(ryerson_720_480, 576, 384);
% imshow(ryerson_576_384);

%%% BONUS
fprintf('Calculating expanded image for bonus.\n');
ryerson_792_528  = seam_carve_resize(ryerson_720_480, 792, 528);
imshow(ryerson_792_528);
imwrite(ryerson_792_528,'question3_ryerson_BONUS_792_528.jpg','jpg');