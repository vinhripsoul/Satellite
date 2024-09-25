% Wipe workspace
close all; clear all; clc;
rotate3d on
% Load in the state data. This is the history of x where x = [r; v]. Units
% for the position vector are meters and velocity is meters/second
load('orbit_example.mat')

% Read in a map of the Earth. Note this does not have to be a perfect map.
% What is going to happen is that we wrap the map around a sphere. Its not
% perfect, but a good visualization tool.
imData = imread('2_no_clouds_4k.jpg');

% Create a sphere  to represent the Earth. The Sphere command produces
% points that create a unit sphere (radius = 1.0)
[xS,yS,zS] = sphere(50);

% Scale the sphere so that it has a radius equal to Earth's equatorial
% radius
earth_radius = 6378137.0;  % meters
xSE = earth_radius*xS;
ySE = earth_radius*yS;
zSE = earth_radius*zS;

% Plot the Earth Shere
surface(xSE,ySE,zSE);
% Make sure to set the axis to equal otherwise the plots will show very
% distorted!
axis equal

% Add the axis labels
grid on
xlabel('Inertial x (m)')
ylabel('Inertial y (m)')
zlabel('Inertial z (m)')

% Wrap the map around the sphere
ch = get(gca,'children');
set(ch,'facecolor','texturemap','cdata',flipud(imData),'edgecolor','none');

% Now we will plot the orbit around the Earth. We want to plot within hte
% same figure so use the "hold on" command
hold on 
plot3(x(1,:), x(2,:), x(3,:), 'k', 'Linewidth', 2)

%  After plotting we can turn the hold off
hold off

%{
NOTE - You must plot the Earth first and then the orbit. If you try and do
it in the reverse order an error is thrown about the facecolor of the orbit
line. Ive never figured out a way to overcome this.
%}