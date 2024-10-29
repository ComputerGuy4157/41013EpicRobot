classdef SceneObject < GenericRenderable
    properties
        pc_type = "SceneObject";
        colour = "blue"
    end

    methods
        function tick()
        end
        function SetTransformParameters(self, x, y, z, scale_factor, rotation_matrix, colour)
            % Scale the Object
            self.pts = self.pts*scale_factor;

            % Create a 4x4 identity matrix
            transformation_matrix = eye(4);

            % Set the rotation part of the transformation matrix
            transformation_matrix(1:3, 1:3) = rotation_matrix;

            % Set the translation part of the transformation matrix
            transformation_matrix(1:3, 4) = [x; y; z];

            self.current_transform = transformation_matrix;
            self.needsRedraw = true;

            self.colour = colour;
        end
        function render_optional(self)
            self.draw_handle.FaceColor = self.colour;
        end
    end
end