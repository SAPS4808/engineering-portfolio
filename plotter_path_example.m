function [trajectory, timeSeconds] = plotter_path_example(animate)
% PLOTTER_PATH_EXAMPLE Reconstructed, simulation-only portfolio example.
% Created after the class exercise; NOT the original classroom source.
% Not tested on the original hardware. No serial port or motor commands.
% Units, rectangle size and feed rate below are illustrative, not measured.
% Usage: plotter_path_example; or [xy,t] = plotter_path_example(false);
% MATLAB R2016b or later. No additional toolboxes required.

if nargin < 1
    animate = true;
end
validateattributes(animate, {'logical'}, {'scalar'});

% A closed rectangle demonstrates coordinated X/Y positioning.
waypoints = [0 0; 80 0; 80 50; 0 50; 0 0];
feedRate = 8;       % Illustrative coordinate units per second.
sampleSpacing = 1; % Maximum distance between adjacent simulated samples.
validateattributes(waypoints, {'numeric'}, ...
    {'2d','ncols',2,'finite','real','nonempty'});
validateattributes(feedRate, {'numeric'}, {'scalar','finite','positive'});
validateattributes(sampleSpacing, {'numeric'}, {'scalar','finite','positive'});
assert(size(waypoints,1) >= 2, 'At least two waypoints are required.');

trajectory = waypoints(1,:);
for segment = 1:size(waypoints,1)-1
    startPoint = waypoints(segment,:);
    endPoint = waypoints(segment+1,:);
    delta = endPoint - startPoint;
    segmentLength = norm(delta);
    if segmentLength == 0
        continue
    end
    sampleCount = max(1, ceil(segmentLength/sampleSpacing));
    fraction = (1:sampleCount)' / sampleCount;
    points = startPoint + fraction .* delta;
    trajectory = [trajectory; points]; %#ok<AGROW>
end

% Idealized timing assumes constant feed along each segment. Real stages
% require acceleration limits, calibration, homing and controller-specific
% handling. This example does not model those effects or a pen-lift axis.
stepDistance = sqrt(sum(diff(trajectory,1,1).^2,2));
timeSeconds = [0; cumsum(stepDistance)/feedRate];
assert(all(isfinite(trajectory(:))), 'Trajectory must be finite.');
assert(max(stepDistance,[],'omitnan') <= sampleSpacing + 1e-9);
assert(norm(trajectory(end,:) - waypoints(end,:)) < 1e-9);

figure('Name','Reconstructed plotter example - simulation only');
plot(waypoints(:,1),waypoints(:,2),'--','Color',[0.65 0.65 0.65]);
hold on; axis equal; grid on;
xlabel('X - illustrative units'); ylabel('Y - illustrative units');
title({'Rectangle path - reconstructed example', ...
    'Simulation only; not original class code or hardware validation'});
trace = animatedline('Color',[0.19 0.36 0.72],'LineWidth',2);
pen = plot(trajectory(1,1),trajectory(1,2),'o', ...
    'MarkerFaceColor',[0.19 0.36 0.72],'MarkerEdgeColor','none');
if animate
    for sample = 1:size(trajectory,1)
        if ~isgraphics(pen)
            break
        end
        addpoints(trace,trajectory(sample,1),trajectory(sample,2));
        set(pen,'XData',trajectory(sample,1),'YData',trajectory(sample,2));
        drawnow;
        pause(0.01); % Presentation speed, NOT the calculated physical timing.
    end
else
    addpoints(trace,trajectory(:,1),trajectory(:,2));
    set(pen,'XData',trajectory(end,1),'YData',trajectory(end,2));
end
fprintf('Example path: %.1f units; idealized time: %.2f s.\n', ...
    sum(stepDistance),timeSeconds(end));
end
