conveyor_belt = ConveyorBelt('ConveyorBeltFixed.PLY');

a = Rubbish('HalfSizedRedGreenBrick.ply');
b = Rubbish('HalfSizedRedGreenBrick.ply');
c = Rubbish('HalfSizedRedGreenBrick.ply');

a.attach_parent(conveyor_belt);
a.set_transform_4by4(transl(0,0,0));
b.attach_parent(conveyor_belt);
b.set_transform_4by4(transl(0.3,-0.1,0));
c.attach_parent(conveyor_belt);
c.set_transform_4by4(transl(-0.2,0.2,0));

axis equal
view(3)

for i = 1:1000
    conveyor_belt.tick();
    conveyor_belt.render();
    pause(10/1000);
    axis equal
end


