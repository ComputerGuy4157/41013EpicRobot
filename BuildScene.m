conveyor_belt = ConveyorBelt('ConveyorBeltFixed.PLY');
conveyor_belt.set_transform_4by4(eye(4));
conveyor_belt.render();

barrier_1 = SceneObject('barrier.ply');
barrier_1.SetTransformParameters(0.5,2.2,-0.5, 0.2, rotz(deg2rad(90)), "black");
barrier_1.render();
barrier_2 = SceneObject('barrier.ply');
barrier_2.SetTransformParameters(0.5,-0.07,-0.5, 0.2, rotz(deg2rad(90)), "black");
barrier_2.render();


barrier_3 = SceneObject('barrier.ply');
barrier_3.SetTransformParameters(-6.1,2.2,-0.5, 0.2, rotz(deg2rad(90)), "black");
barrier_3.render();
barrier_4 = SceneObject('barrier.ply');
barrier_4.SetTransformParameters(-6.1,-0.07,-0.5, 0.2, rotz(deg2rad(90)), "black");
barrier_4.render();

barrier_5 = SceneObject('barrier.ply');
barrier_5.SetTransformParameters(-0.5,3.5,-0.5, 0.2, rotz(deg2rad(180)), "black");
barrier_5.render();
barrier_6 = SceneObject('barrier.ply');
barrier_6.SetTransformParameters(-2.77,3.5,-0.5, 0.2, rotz(deg2rad(180)), "black");
barrier_6.render();
barrier_7 = SceneObject('barrier.ply');
barrier_7.SetTransformParameters(-5.04,3.5,-0.5, 0.2, rotz(deg2rad(180)), "black");
barrier_7.render();

barrier_8 = SceneObject('barrier.ply');
barrier_8.SetTransformParameters(-0.5,-1.3,-0.5, 0.2, rotz(deg2rad(180)), "black");
barrier_8.render();
barrier_9 = SceneObject('barrier.ply');
barrier_9.SetTransformParameters(-2.77,-1.3,-0.5, 0.2, rotz(deg2rad(180)), "black");
barrier_9.render();
barrier_10 = SceneObject('barrier.ply');
barrier_10.SetTransformParameters(-5.04,-1.3,-0.5, 0.2, rotz(deg2rad(180)), "black");
barrier_10.render();

human = SceneObject('human.ply');
human.SetTransformParameters(1,2.2, 0.5, 1, rotz(deg2rad(270)), "magenta");
human.render();

human = SceneObject('human.ply');
human.SetTransformParameters(1,2.2, 0.5, 1, rotz(deg2rad(270)), "magenta");
human.render();

barrier = SceneObject('extinguisher.ply');
barrier.SetTransformParameters(1,2.7, 0, 0.2, rotz(deg2rad(270)), "red");
barrier.render();