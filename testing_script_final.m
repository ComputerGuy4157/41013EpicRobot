clear all;

view(3);
xlim([-3 0]);
ylim([-1.3 0.5]);
zlim([-0.5 1.3]);

figure(1);
drawnow();

BuildScene

% Initialize the conveyor belt
% conveyor_belt = ConveyorBelt('ConveyorBeltFixed.PLY');
% conveyor_belt.set_transform_4by4(eye(4));

% Create a detection controller but without attaching objects
dc = DetectionController;
%conveyor_belt.render();
light('Style', 'local', 'Position', [-1.5 0 2], 'Parent', gca);
drawnow;

% Initialize the Ultimate Collision Checker
ucc = UltimateCollisionChecker;

% Create and position the robots
robot_array = cell(1,1);
robot_array{1} = UR3EC(transl(-1.0,-0.4,0), dc, ucc);
robot_array{end+1} = UR3EC(transl(-1.5,-0.4,0), dc, ucc);
robot_array{end+1} = UR3EC(transl(-2.0,-0.4,0), dc, ucc);
robot_array{end+1} = UR3EC(transl(-2.5,-0.4,0), dc, ucc);
robot_array{end+1} = ABBC(transl(-0.5,1.2,-0.5) * trotz(pi), dc, ucc);
robot_array{end+1} = ABBC(transl(-3.0,1.2,-0.5) * trotz(pi),dc, ucc);

RandomBrickArray = createArray(0, 0, 'cell');

xlim([-5 -1]);
ylim([-4 4]);
zlim([-0.5 2]);
axis equal;
zlim([-0.5 2]);


% Declare global flags

global eStop_triggered system_armed system_running
eStop_triggered = false;
system_armed = false;
system_running = true;


% Create UI buttons for emergency stop, rearm, and resume
f = uifigure;
f.AutoResizeChildren = 'off';
ss = StatisticsReporter(f, robot_array, vrjoystick(1));

% Main simulation loop
times = createArray(1, 3000, "double");
for i = 1:3000
    % Check emergency stop
    if ~system_running
        ss.update();
        pause(0.01);  % Pause briefly to allow for button interactions
        continue;     % Skip to next iteration if system is not running
    end

    % Only run loop content when system is active
    timeStart = tic;

    % Random chance to spawn new Rubbish every 50 ticks
    if mod(i, 50) == 0
        if rand > 0.2  % Regular rubbish
            r = Rubbish('HalfSizedRedGreenBrick2.ply');
            r.attach_parent(conveyor_belt);
            RandomBrickArray{end+1} = r;
            dc.register(r);
            r.set_transform_4by4(transl(-0.1, ((rand - 0.5) * 0.2), 0));
        else  % Big rubbish
            r = Rubbish('Can.ply');
            r.pc_type = "BigRubbish";
            r.attach_parent(conveyor_belt);
            RandomBrickArray{end+1} = r;
            dc.register(r);
            r.set_transform_4by4(transl(-0.1, ((rand - 0.5) * 0.2), 0));
        end
    end

    % Process ticks
    conveyor_belt.tick();
    for j = 1:length(robot_array)
        robot_array{j}.tick();
    end
    ucc.tick();

    hold on;
    conveyor_belt.render();
    for j = 1:length(robot_array)
        robot_array{j}.render();
    end
    hold off;

    ss.update();

    drawnow;
    time = toc(timeStart);
    times(i) = time;
end

figure(5);
plot(times);
