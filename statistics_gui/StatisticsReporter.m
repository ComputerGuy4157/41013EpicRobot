classdef StatisticsReporter < handle
    properties
        ui_handle
        robot_handles

        total_control_enabled(1,:) logical

        robot_slider_handles cell;
        robot_button_group_handles cell;
        robot_tc_handles cell;

        estop_button_array_handle

        slider_button_control_toggles cell;

        game_controller; %vrjoystick;
        system_running_local;

    end

    methods
        function self = StatisticsReporter(ui_handle, robot_array, stick)

            self.game_controller = stick;

            global eStop_triggered system_armed system_running
            eStop_triggered = false;
            system_armed = false;
            system_running = true;
            self.system_running_local = true;

            Estoptext = ["Emergency" + newline + "Stop"];

            self.estop_button_array_handle{1} = uibutton(ui_handle, 'Text', Estoptext, ...
                'Position', [10, 20, 150, 120], ...
                'ButtonPushedFcn', @(~, ~) self.triggerEStop());

            self.estop_button_array_handle{1}.FontSize = 25;

            self.estop_button_array_handle{2} = uibutton(ui_handle, 'Text', 'Rearm System', ...
                'Position', [180, 20, 230, 55], ...
                'ButtonPushedFcn', @(~, ~) self.rearmSystem());

            self.estop_button_array_handle{2}.FontSize = 25;

            self.estop_button_array_handle{3} = uibutton(ui_handle, 'Text', 'Resume System', ...
                'Position', [180, 85, 230, 55], ...
                'ButtonPushedFcn', @(~, ~) self.resumeSystem());

            self.estop_button_array_handle{3}.FontSize = 25;

            

            self.slider_button_control_toggles = cell(length(robot_array));
            self.total_control_enabled = createArray(1,length(robot_array),"logical");
            self.robot_button_group_handles = cell(length(robot_array));
            self.robot_slider_handles = cell(6,length(robot_array));
            self.robot_tc_handles = cell(length(robot_array));
            self.robot_handles = robot_array
            self.ui_handle = ui_handle;
            ui_handle.Position = [0 0 968 656];

            max_height = createArray(length(robot_array));


            %create UI sliders for each joint on each robot, vertical
            %arrangement?

            tc_box_words = ['ACTIVATE' newline 'CONTROLLER']
            

            for i = 1:length(robot_array)
                box = uibuttongroup(ui_handle,"Position",[10 + 160 * (i - 1) 150 150 500])
                self.robot_button_group_handles{i} = box
                for j = 1:height(robot_array{i}.robot.model.qlim)
                    min = robot_array{i}.robot.model.qlim(j,1);
                    max = robot_array{i}.robot.model.qlim(j,2);
                    current = robot_array{i}.current_q(j);
                    
                    
                    self.robot_slider_handles{j,i} = uislider(box,"Limits",[min max], "Value",current,...
                        'Position', [25 j * 40 100 20],'ValueChangedFcn',@(src,event) self.submit_manual(src, event),"UserData",i);
                    self.robot_slider_handles{j,i}.MajorTicks = [min max];
                    self.robot_slider_handles{j,i}.MinorTicks = [];
                    max_height = ((j + 1) * 40);
                end
                self.robot_tc_handles{i} = uibutton(box,"state","Text",tc_box_words,"Position",[15 max_height 120 120],...
                    "ValueChangedFcn", @(src,event) self.activate_total_control(src, event),"UserData",i);

                the_switch = uiswitch(box,'ValueChangedFcn', @(src, event) self.activate_manual_control(src, event),"UserData",i);
                the_switch.Items = ["Auto", "Manual"];
                the_switch.Position = [40 max_height + 120 + 30 40 20]
                self.slider_button_control_toggles{i} = the_switch;
                
                
            end
        end

        function update(self)
            % get Q data and update
            for i = 1:length(self.robot_handles)
                for j = 1:height(self.robot_handles{i}.robot.model.qlim)
                    current = self.robot_handles{i}.current_q(j);
                    self.robot_slider_handles{j,i}.Value = current;
                end
            end
            %check for ESTOP button (SQUARE)
            [axis, button, pov] = read(self.game_controller);
            if button(4) && self.system_running_local;
                self.triggerEStop();
            end
        end

        function submit_manual(self, src, event)
            
            robot_index = event.Source.UserData;
            q_array = createArray(1,length(self.robot_handles{robot_index}.current_q),"double");
            %get relevant slider handles
            handles = self.robot_slider_handles(:,robot_index)
            for i = 1:height(handles)
                q_array(i) = handles{i,1}.Value;
            end
            self.robot_handles{robot_index}.force_submit_external(q_array);
        end

        function activate_manual_control(self,src,event)
            robot_index = event.Source.UserData;
            wants_activation = event.Value;
            if strcmp(wants_activation,"Manual")
                wants_activation = 1;
            else
                wants_activation = 0;
            end

            self.robot_handles{robot_index}.activate_manual_control(wants_activation);
        end

        function activate_total_control(self, src, event)
            robot_index = event.Source.UserData;
            %check for any robot total control being enabled and disable it
            for i = 1:length(self.robot_handles)
                if self.total_control_enabled(i) == 1
                    self.robot_tc_handles{i}.Value = 0;
                    self.robot_handles{i}.total_control_deactivate();
                    self.total_control_enabled(i) = 0;
                end
            end

            if (event.Value) %requesting activation
                self.total_control_enabled(robot_index) = 1;
                try
                stick1 = vrjoystick(1); %try to acquire controller data
                stick2 = vrjoystick(2);
                self.robot_handles{robot_index}.total_control_activate(stick1, stick2);
                catch
                    warn("Could not activate TC!");
                end
            else %deactivate and set camera back to normal position
                self.robot_tc_handles{robot_index}.Value = 0;
                self.robot_handles{robot_index}.total_control_deactivate();
                self.total_control_enabled(robot_index) = 0;
                view(3);
                camva(10);
            end

            
            
        end

        % Emergency stop callback
        function triggerEStop(self)
            global eStop_triggered system_running
            eStop_triggered = true;
            system_running = false; % Stop the system immediately
            self.system_running_local = false;
            self.estop_button_array_handle{1}.Enable = 'off';
            self.estop_button_array_handle{2}.Enable = 'on';
            self.estop_button_array_handle{3}.Enable = 'off';
        end

        % Rearm callback: Allows the system to be started again but doesn’t start it
        function rearmSystem(self)
            global eStop_triggered system_armed
            if eStop_triggered
                eStop_triggered = false;  % Disengage the eStop
                system_armed = true;      % System is ready to start
            end
            self.estop_button_array_handle{1}.Enable = 'off';
            self.estop_button_array_handle{2}.Enable = 'off';
            self.estop_button_array_handle{3}.Enable = 'on';
        end

        % Resume callback: Resumes operations only if the system is armed
        function resumeSystem(self)
            global system_running system_armed
            if system_armed
                system_running = true;
                self.system_running_local = true;
                system_armed = false;  % Un-arm the system after resuming
            end
            self.estop_button_array_handle{1}.Enable = 'on';
            self.estop_button_array_handle{2}.Enable = 'off';
            self.estop_button_array_handle{3}.Enable = 'off';
        end
    end
end
