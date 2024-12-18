classdef UltimateCollisionChecker < handle & ParentChild & Tickable
    properties
        pc_type = "UCC";
        detection_cube_cache;
        collision_handle_array cell;
        time_since_called = 0;
        
    end
%Attached Children are all meant to be Robot Q position FIFO queues
    methods

        function self = UltimateCollisionChecker(self)
            self@ParentChild();
            self.detection_cube_cache = CubeCache(0);
            self.custom_pc_logic = 1;
        end

        function tick(self)
            self.number_of_ticks = self.number_of_ticks + 1;
            self.time_since_called = self.time_since_called + 1;
            %must tick our cache
            self.detection_cube_cache.pull();

            if mod(self.number_of_ticks,15) == 0
                for i = 1:length(self.collision_handle_array);
                    self.collision_handle_array{1,i}.draw_handle.FaceAlpha = 0;
                end
                if ~isempty(self.collision_handle_array)
                    self.collision_handle_array(1,:) = [];
                end
            end

        end

        function collision = check_collision(self, calling_q_matrix, calling_fifo)
            self.time_since_called = 0;
            %tic;

            % theProfiler = false;
            % if height(calling_q_matrix) > 40
            %     profile on -timestamp -historysize 10000000 -timer performance
            %     theProfiler = true;
            % end
            % 
            %figure out which child called the function
            num_children = length(self.attached_child);
            calling_fifo_index = 0;
            for i = 1:num_children
                if self.attached_child{i} == calling_fifo
                    calling_fifo_index = i;
                    break
                end
            end
            if calling_fifo_index == 0
                error("UltimateCollisionChecker: Could not find calling FIFO!");
            end
            %construct terrifyingly ginormous Q array, padding if required
            %first figure out which FIFO is longest

            fifo_lengths = createArray(1,num_children,"double");
            
            for i = 1:num_children
                fifo_lengths(i) = self.attached_child{1,i}.get_active_and_queue_length();
                if i == calling_fifo_index
                    fifo_lengths(i) = fifo_lengths(i) + height(calling_q_matrix);
                end
            end
            longestFIFO = max(fifo_lengths);
            

            

            ultimate_q_array = cell(longestFIFO, num_children);
            
            %ultimate_dcube_array = cell(longestFIFO, num_children);
             %row 1 corresponds to the "active" region, also why q
                %array is one higher than longestFIFO

            if longestFIFO > 40

            end
            



            %STAGE 1: IMPORT DATA
            for i = 1:num_children
                if ~(calling_fifo_index == i)
                    fifo_data = self.attached_child{i}.get_active_and_queue(longestFIFO);
                    fifo_data = num2cell(fifo_data,2); %turn into vertical cell array, each entry contains the entire Q state for one tick
                else %if we are the caller... build fifo data that would correspond to what we want
                    data_length = self.attached_child{i}.get_active_and_queue_length();
                    fifo_data = cell(height(calling_q_matrix),1);
                    data = self.attached_child{i}.get_active_and_queue(data_length);
                    fifo_data(1:data_length,1) = num2cell(data,2);
                    fifo_data(data_length + 1:data_length + height(calling_q_matrix),1) = num2cell(calling_q_matrix,2);
                    %Pad if data too short
                    overrun = longestFIFO - height(fifo_data);
                    if overrun > 0
                        fifo_data = padarray(fifo_data,[overrun 0],'replicate','post');
                    end
                end
                ultimate_q_array(:,i) = fifo_data;
            end
            
            %children = self.attached_child;
            % 
            %STAGE 2.-1: BUILD PARALLELISATION DATA
            % children = self.attached_child;
            % linkdata = cell(1,num_children);
            % robot_base_transform = cell(1,num_children);
            % robot = cell(1,num_children);
            % robot_p_dc_t = cell(1,num_children);
            % for i = 1:num_children
            %     linkdata{i} = children{i}.assigned_robot.linkdata;
            %     robot_base_transform{i} = children{i}.assigned_robot.base_transform;
            %     robot{i} = children{i}.assigned_robot;
            %     robot_p_dc_t{i} = children{i}.assigned_robot.p_dc_t;
            % end

            % addAttachedFiles(gcp,["Link.m" "transl.m" "trscale.m"]);

            %ticBytes;

            %first import cached dcube array data and row-resize if needed

            

            

            ultimate_dcube_array = self.detection_cube_cache.get_active_and_queue(longestFIFO); %entries marked as "0" need a Detection Cube Array generated
            %Invalidate the calling FIFO's detection cube array... as thats
            %what we're intending on replacing!

            
            ultimate_dcube_array(:,calling_fifo_index) = cell(height(longestFIFO),1);

            %STAGE 2: GENERATE BOXES
            for i = 1:num_children
            %for i = 1:num_children %tried to use parfor here, unfortunately has massive overhead so we just use normal for
                %generate boxes for Q array on one robot
                for j = 1:longestFIFO
                    if isempty(ultimate_dcube_array{j,i})
                        ultimate_dcube_array{j,i} = self.attached_child{i}.assigned_robot.build_detection_cubes(ultimate_q_array{j,i});
                    end
                    %ultimate_dcube_array{j,i} = build_detection_cubes_static(ultimate_q_array{j,i}, linkdata{i}, robot_base_transform{i}, robot_p_dc_t{i}) %Use if you want to try parallelisation
                    %ultimate_dcube_array{j,i} = cubes;
                end
            end

            %tocBytes;

            
            %STAGE 3: THE LARGE CUBE COLLIDER

            theheight2 = height(ultimate_dcube_array);

            %collisiontest = createArray(theheight2,1,"logical");
            collision_this_row = false;
            
            collision = false;

            

            %fifo_data = self.detection_cube_cache.get_active_and_queue(longestFIFO);
            

            
            for rowSelector = 1:theheight2
                if collision_this_row %stop checking further rows if a collision in a previous row occured
                    break
                end
                collision_this_row = false;
                sliced_ultimate_dcube_array = ultimate_dcube_array(rowSelector,:);
                for j = 1:num_children
                    if calling_fifo_index ~= j %dont check self
                        checked_length = length(sliced_ultimate_dcube_array{calling_fifo_index});
                        for CubeSelector = 1:checked_length
                            checked_length_2 = length(sliced_ultimate_dcube_array{j});
                            for CubeSelectorTarget = 1:checked_length_2
                                collision_test = sliced_ultimate_dcube_array{calling_fifo_index}{CubeSelector}.check_dc(sliced_ultimate_dcube_array{j}{CubeSelectorTarget});
                                if collision_test & ~collision_this_row
                                    collision_this_row = true;
                                    collision = true;
                                    self.drawCollisionData(rowSelector, calling_fifo_index, CubeSelector, j, CubeSelectorTarget, ultimate_dcube_array);
                                    %draw first collision cubes that do collide then check no further, because obviously something bad will happen
                                    %toc;
                                    warning("Robots will collide.");
                                    return;
                                end
                            end
                        end
                    end
                end
            end
        
            
            

            % if theProfiler
            %      profile viewer
            % end

            %toc;

            if ~collision
                self.detection_cube_cache.replace_queue(ultimate_dcube_array);
            end
                
            
            return
        end

        function drawCollisionData(self, row, robot1, offendingcube, robot2, offendingcube2, dcube_array)
            %self.collision_handle_array = DetectionCube.empty(1,0);
            robot_1_cubes = dcube_array{row, robot1};
            robot_2_cubes = dcube_array{row, robot2};

            for i = 1:length(robot_1_cubes)
                robot_1_cubes{i}.needsRedraw = 1;
                robot_1_cubes{i}.needsRepatch = 1;
                handle = robot_1_cubes{i}.render();
                if i == offendingcube
                handle.FaceColor = "red";
                handle.FaceAlpha = 0.7;
                else
                handle.FaceColor = [0.4660 0.6740 0.1880];
                handle.FaceAlpha = 0.4;
                end
                
            end
            self.collision_handle_array(end+1,1:length(robot_1_cubes)) = robot_1_cubes;
            for j = 1:length(robot_2_cubes)
                robot_2_cubes{j}.needsRedraw = 1;
                robot_2_cubes{j}.needsRepatch = 1;
                handle = robot_2_cubes{j}.render();
                if j == offendingcube2
                handle.FaceColor = "red";
                handle.FaceAlpha = 0.7;
                else
                handle.FaceColor = [0.4660 0.6740 0.1880];
                handle.FaceAlpha = 0.4;
                end
                %self.collision_handle_array(end + 1) = robot_2_cubes{j};
            end
            self.collision_handle_array(end,length(robot_1_cubes)+1:length(robot_2_cubes)+length(robot_1_cubes)) = robot_2_cubes;
        end

        
            

    end


    methods(Access = public)
        function f_custom_pc_logic(self) %called when Attach Parent from another object, must recreate cube cache
            self.detection_cube_cache = CubeCache(length(self.attached_child));
        end
    end
end