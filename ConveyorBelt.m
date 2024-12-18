classdef ConveyorBelt < GenericRenderable
    properties
        speed = 0.002
        pc_type = "ConveyorBelt";
    end

    methods
        function self = ConveyorBelt(ply_file)
            self@GenericRenderable(ply_file);
            self.pts(:,2) = self.pts(:,2) * 0.5;
        end
        function tick(self) %All objects attached to the Conveyor Belt will be translated by speed.
            self.number_of_ticks = self.number_of_ticks + 1;
            num_children = length(self.attached_child);
            c = self.current_transform;
            %translate each object by HOW MUCH
            %move objects in different direction according to rotation of
            %conveyor belt, but not translation or scale
            scale_x = sqrt(c(1,1)^2+c(1,2)^2+c(1,3)^2);
            scale_y = sqrt(c(2,1)^2+c(2,2)^2+c(2,3)^2);
            scale_z = sqrt(c(3,1)^2+c(3,2)^2+c(3,3)^2);

            c(1:3,1) = c(1:3,1) / scale_x;
            c(1:3,2) = c(1:3,2) / scale_y;
            c(1:3,3) = c(1:3,3) / scale_z;

            %move along wherever the X axis points
            movement = -c(1:3,1)';
            movement = movement * self.speed;
            applied_transform = transl(movement(1),movement(2),movement(3));
            
            for i = 1:num_children
                child_pos = self.attached_child{i}.current_transform;
                child_pos = child_pos * applied_transform;
                self.attached_child{i}.set_transform_4by4(child_pos);
                self.attached_child{i}.tick(); %also tick children
            end
        end

        function set_speed(self, speed)
            self.speed = speed;
        end
    end
end