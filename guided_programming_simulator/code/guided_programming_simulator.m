classdef guided_programming_simulator < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        FileMenu                      matlab.ui.container.Menu
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        DBSProgrammingAssistantLabel  matlab.ui.control.Label
        ContinueSearchingButton       matlab.ui.control.Button
        AmplitudeLabel                matlab.ui.control.Label
        FrequencyLabel                matlab.ui.control.Label
        PulseWidthLabel               matlab.ui.control.Label
        CathodeButtonGroup            matlab.ui.container.ButtonGroup
        Button                        matlab.ui.control.RadioButton
        Button_2                      matlab.ui.control.RadioButton
        Button_3                      matlab.ui.control.RadioButton
        Button_4                      matlab.ui.control.RadioButton
        mA05Label                     matlab.ui.control.Label
        mA05EditField                 matlab.ui.control.NumericEditField
        Hz1200EditFieldLabel          matlab.ui.control.Label
        Hz1200EditField               matlab.ui.control.NumericEditField
        s10200EditFieldLabel          matlab.ui.control.Label
        s10200EditField               matlab.ui.control.NumericEditField
        UpdateSettingsButton          matlab.ui.control.Button
        SetEstimatedBestButton        matlab.ui.control.Button
        AnodeButtonGroup              matlab.ui.container.ButtonGroup
        Button_5                      matlab.ui.control.RadioButton
        Button_6                      matlab.ui.control.RadioButton
        Button_7                      matlab.ui.control.RadioButton
        Button_8                      matlab.ui.control.RadioButton
        SetRandomButton               matlab.ui.control.Button
        ShowOptimumCheckBox           matlab.ui.control.CheckBox
        optimum_label                 matlab.ui.control.Label
        CenterPanel                   matlab.ui.container.Panel
        history_uitable               matlab.ui.control.Table
        UIAxes                        matlab.ui.control.UIAxes
        TremorGauge_2Label            matlab.ui.control.Label
        TremorGauge_2                 matlab.ui.control.LinearGauge
        EstimatedOptimalLabel         matlab.ui.control.Label
        Image                         matlab.ui.control.Image
        contact_0                     matlab.ui.control.Button
        contact_1                     matlab.ui.control.Button
        contact_2                     matlab.ui.control.Button
        contact_3                     matlab.ui.control.Button
        AmplitudemALabel              matlab.ui.control.Label
        FrequencyHzLabel              matlab.ui.control.Label
        RightPanel                    matlab.ui.container.Panel
        SubmitButton                  matlab.ui.control.Button
        TremorMeasurementLabel        matlab.ui.control.Label
        tremor_field                  matlab.ui.control.NumericEditField
        SideEffectMeasurementLabel    matlab.ui.control.Label
        side_effect_field             matlab.ui.control.NumericEditField
        TremorGaugeLabel              matlab.ui.control.Label
        TremorGauge                   matlab.ui.control.SemicircularGauge
        SideEffectGaugeLabel          matlab.ui.control.Label
        SideEffectGauge               matlab.ui.control.SemicircularGauge
        tremor_enable                 matlab.ui.control.CheckBox
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
    end

    
    properties (Access = private)
        cathode_history         = []; 
        amplitude_history       = []; 
        frequency_history       = []; 
        pulse_width_history     = []; 
        history_table           = [];
        
        input_cathode           = 0:3;
        input_anode             = 0:3;
        input_amplitude         = 0:.1:5;
        input_frequency         = 1:200;
        
        input_space             = [];
        n_samples               = 0;
        n_burn_in               = 2;
        
        next_setting            = [];
        estimated_optimal       = [];
        estimated_optimal_out   = [];
        
        mu                      = [];
        sigma                   = [2 0 0 0; 0 2 0 0; 0 0 2 0; 0 0 0 2000];
        objective_model         = [];
        normalize_constant      = [];
        optimum_string          = [];
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.input_space     = combvec(app.input_cathode, app.input_anode, app.input_amplitude, app.input_frequency)';
            
%             app.mu(1)           = 1;
%             app.mu(2)           = 1;
%             app.mu(3)           = 3.5;
%             app.mu(4)           = 130;
            
            app.mu(1)           = randi(4)-1;
            app.mu(2)           = randi(4)-1;
            app.mu(3)           = app.input_amplitude(randi(size(app.input_amplitude,2)));
            app.mu(4)           = app.input_frequency(randi(size(app.input_frequency,2)));
            
            
            if app.mu(1) == app.mu(2)
                app.optimum_string = sprintf('%d-/C+, %.1f mA, %d Hz', app.mu(1), app.mu(3), app.mu(4));
            else
                app.optimum_string = sprintf('%d-/%d+, %.1f mA, %d Hz', app.mu(1), app.mu(2), app.mu(3), app.mu(4));
            end
            app.optimum_label.Text = app.optimum_string;
            
            app.normalize_constant  = mvnpdf(app.mu, app.mu, app.sigma);
                        
            cla(app.UIAxes)
            hold(app.UIAxes)
            
            yyaxis(app.UIAxes,"left")
            ylim(app.UIAxes, [0 5])
            
            yyaxis(app.UIAxes,"right")
            ylim(app.UIAxes, [0 200])
            
        end

        % Button pushed function: UpdateSettingsButton
        function UpdateSettingsButtonPushed(app, event)
            
            % Collect the data from the fields
            cathode             = str2double(app.CathodeButtonGroup.SelectedObject.Text(1));
            anode               = str2double(app.AnodeButtonGroup.SelectedObject.Text(1));
            amplitude           = app.mA05EditField.Value;
            frequency           = app.Hz1200EditField.Value;
            pulse_width         = app.s10200EditField.Value;
            
            % Store in history
            app.n_samples       = app.n_samples + 1;
            tremor              = -99999;
            sample_num          = app.n_samples;
            history_row         = table(sample_num, cathode, anode, amplitude, frequency, pulse_width, tremor);
            app.history_table   = [app.history_table; history_row];
            
            % Update table 
            app.history_uitable.Data = flip(app.history_table,1);
            
            % Apply to simulation function
            x_sample(1)         = cathode;
            x_sample(2)         = anode;
            x_sample(3)         = amplitude;
            x_sample(4)         = frequency;
            
            tremor              = mvnpdf(x_sample, app.mu, app.sigma) / app.normalize_constant * -10 + 10 + randn(1)*1;
                   
            tremor              = max(tremor,0);
            tremor              = min(tremor,10);
            
            % Display output on gauge
            if app.tremor_enable.Value
                app.TremorGauge.Value = tremor;
            end
            
            % Disable update buttons
            app.UpdateSettingsButton.Enable         = false;
            app.ContinueSearchingButton.Enable      = false;
            app.SetRandomButton.Enable              = false;
            app.SetEstimatedBestButton.Enable       = false;                

            app.AmplitudeLabel.Enable               = false;
            app.mA05EditField.Enable                = false;
            app.mA05Label.Enable                    = false;
            
            app.FrequencyLabel.Enable               = false;
            app.Hz1200EditField.Enable              = false;
            app.Hz1200EditFieldLabel.Enable         = false;
                  
            app.SubmitButton.Enable                 = true;
            app.tremor_field.Enable                 = true;
            app.TremorMeasurementLabel.Enable       = true;
            app.TremorGauge.Enable                  = true;
            app.TremorGaugeLabel.Enable             = true;

        end

        % Button pushed function: SubmitButton
        function SubmitButtonPushed(app, event)
            
            % Read data from fields
            tremor = app.tremor_field.Value;
            
            % Update table
            app.history_table.tremor(app.n_samples) = tremor;
            app.history_uitable.Data = flip(app.history_table,1);

            % Apply data history to update function
            if app.n_samples > app.n_burn_in && std(app.history_table.tremor) ~= 0
                x1  = app.history_table.cathode;
                x2  = app.history_table.anode;
                x3  = app.history_table.amplitude;
                x4  = app.history_table.frequency;
                
                y   = -1*app.history_table.tremor;
                
                objective_est   = gp_object();
                objective_est.initialize_data([x1 x2 x3 x4], y)
                objective_est.minimize(1)       
                
                % Store next sample and optimal
                app.next_setting = bayes_opt_update(objective_est, app.input_space, 'UCB', 2, app.n_samples);
                [x_opt, y_opt] = objective_est.discrete_extrema(app.input_space);
                
                app.estimated_optimal(app.n_samples,:)      = x_opt;
                app.estimated_optimal_out(app.n_samples,:)  = y_opt*-1;
                
                cla(app.UIAxes)
                hold(app.UIAxes)
                yyaxis(app.UIAxes,"left")
                plot(app.UIAxes, app.estimated_optimal(:,3));
                ylim(app.UIAxes, [0 5])
                
                yyaxis(app.UIAxes,"right")
                plot(app.UIAxes, app.estimated_optimal(:,4));
                ylim(app.UIAxes, [0 200])

                app.TremorGauge_2.Value                 = app.estimated_optimal_out(app.n_samples);
                
                contacts(1) = app.contact_0;
                contacts(2) = app.contact_1;
                contacts(3) = app.contact_2;
                contacts(4) = app.contact_3;

                for c1 = 1:4
                    contacts(c1).BackgroundColor = [.5 .5 .5];
                end
                
                if app.estimated_optimal(app.n_samples,1) ~= app.estimated_optimal(app.n_samples,2)
                    contacts(app.estimated_optimal(app.n_samples,2)+1).BackgroundColor = [0 0 164]/255;
                end
                    
                contacts(app.estimated_optimal(app.n_samples,1)+1).BackgroundColor = [164 0 0]/255;
         
                % Enable new settings button
                app.ContinueSearchingButton.Enable            = true;
                app.SetEstimatedBestButton.Enable             = true;
            end
            
            % Enable/disable button
            app.UpdateSettingsButton.Enable     = true;
            app.SetRandomButton.Enable          = true;
            app.AmplitudeLabel.Enable           = true;
            app.mA05EditField.Enable            = true;
            app.mA05Label.Enable                = true;
            
            app.FrequencyLabel.Enable           = true;
            app.Hz1200EditField.Enable          = true;
            app.Hz1200EditFieldLabel.Enable     = true;
            
            app.SubmitButton.Enable             = false;
            app.tremor_field.Enable             = false;
            app.TremorGauge.Enable              = false;
            app.TremorMeasurementLabel.Enable   = false;
            app.TremorGaugeLabel.Enable         = true;

            pause(.25)
        end

        % Button pushed function: ContinueSearchingButton
        function ContinueSearchingButtonPushed(app, event)
            app.CathodeButtonGroup.SelectedObject           = app.CathodeButtonGroup.Buttons(app.next_setting(1)+1);
            app.AnodeButtonGroup.SelectedObject             = app.AnodeButtonGroup.Buttons(app.next_setting(2)+1);
            
            app.mA05EditField.Value                         = app.next_setting(3);
            app.Hz1200EditField.Value                       = app.next_setting(4);
            app.ContinueSearchingButton.Enable              = false;
            app.SetEstimatedBestButton.Enable               = true;
            
        end

        % Button pushed function: SetEstimatedBestButton
        function SetEstimatedBestButtonPushed(app, event)
            app.CathodeButtonGroup.SelectedObject           = app.CathodeButtonGroup.Buttons(app.estimated_optimal(app.n_samples,1)+1);
            app.AnodeButtonGroup.SelectedObject             = app.AnodeButtonGroup.Buttons(app.estimated_optimal(app.n_samples,2)+1);
            
            app.mA05EditField.Value                         = app.estimated_optimal(app.n_samples,3);
            app.Hz1200EditField.Value                       = app.estimated_optimal(app.n_samples,4);
            app.ContinueSearchingButton.Enable              = true;
            app.SetEstimatedBestButton.Enable               = false;
            
        end

        % Value changed function: tremor_enable
        function tremor_enableValueChanged(app, event)
            value = app.tremor_enable.Value;
            if value
                app.TremorGauge.Enable = true;
                app.TremorGaugeLabel.Enable = true;
            else
                app.TremorGauge.Enable = false;
                app.TremorGaugeLabel.Enable = false;
            end
        end

        % Button pushed function: SetRandomButton
        function SetRandomButtonPushed(app, event)
            app.CathodeButtonGroup.SelectedObject           = app.CathodeButtonGroup.Buttons(randi(4));
            app.AnodeButtonGroup.SelectedObject             = app.AnodeButtonGroup.Buttons(randi(4));
            
            app.mA05EditField.Value                         = app.input_amplitude(randi(size(app.input_amplitude,2)));
            app.Hz1200EditField.Value                       = app.input_frequency(randi(size(app.input_frequency,2)));
            
            if app.n_samples > app.n_burn_in && std(app.history_table.tremor) ~= 0
                app.ContinueSearchingButton.Enable          = true;
                app.SetEstimatedBestButton.Enable           = true;
            end
        end

        % Value changed function: ShowOptimumCheckBox
        function ShowOptimumCheckBoxValueChanged(app, event)
            value = app.ShowOptimumCheckBox.Value;
           
            if value
                app.optimum_label.Visible = true;
            else
                app.optimum_label.Visible = false;
            end
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 3x1 grid
                app.GridLayout.RowHeight = {515, 515, 515};
                app.GridLayout.ColumnWidth = {'1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 1;
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 3;
                app.RightPanel.Layout.Column = 1;
            elseif (currentFigureWidth > app.onePanelWidth && currentFigureWidth <= app.twoPanelWidth)
                % Change to a 2x2 grid
                app.GridLayout.RowHeight = {515, 515};
                app.GridLayout.ColumnWidth = {'1x', '1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = [1,2];
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 2;
            else
                % Change to a 1x3 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {261, '1x', 186};
                app.LeftPanel.Layout.Row = 1;
                app.LeftPanel.Layout.Column = 1;
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 2;
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 3;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 982 515];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {261, '1x', 186};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create DBSProgrammingAssistantLabel
            app.DBSProgrammingAssistantLabel = uilabel(app.LeftPanel);
            app.DBSProgrammingAssistantLabel.Position = [24 472 158 22];
            app.DBSProgrammingAssistantLabel.Text = 'DBS Programming Assistant';

            % Create ContinueSearchingButton
            app.ContinueSearchingButton = uibutton(app.LeftPanel, 'push');
            app.ContinueSearchingButton.ButtonPushedFcn = createCallbackFcn(app, @ContinueSearchingButtonPushed, true);
            app.ContinueSearchingButton.Enable = 'off';
            app.ContinueSearchingButton.Position = [26 395 210 22];
            app.ContinueSearchingButton.Text = 'Continue Searching';

            % Create AmplitudeLabel
            app.AmplitudeLabel = uilabel(app.LeftPanel);
            app.AmplitudeLabel.Position = [26 185 60 22];
            app.AmplitudeLabel.Text = 'Amplitude';

            % Create FrequencyLabel
            app.FrequencyLabel = uilabel(app.LeftPanel);
            app.FrequencyLabel.Position = [26 147 62 22];
            app.FrequencyLabel.Text = 'Frequency';

            % Create PulseWidthLabel
            app.PulseWidthLabel = uilabel(app.LeftPanel);
            app.PulseWidthLabel.Enable = 'off';
            app.PulseWidthLabel.Position = [26 108 70 22];
            app.PulseWidthLabel.Text = 'Pulse Width';

            % Create CathodeButtonGroup
            app.CathodeButtonGroup = uibuttongroup(app.LeftPanel);
            app.CathodeButtonGroup.BorderType = 'none';
            app.CathodeButtonGroup.Title = 'Cathode';
            app.CathodeButtonGroup.Position = [24 284 212 49];

            % Create Button
            app.Button = uiradiobutton(app.CathodeButtonGroup);
            app.Button.Text = '0-';
            app.Button.Position = [5 7 33 22];
            app.Button.Value = true;

            % Create Button_2
            app.Button_2 = uiradiobutton(app.CathodeButtonGroup);
            app.Button_2.Text = '1-';
            app.Button_2.Position = [59 7 33 22];

            % Create Button_3
            app.Button_3 = uiradiobutton(app.CathodeButtonGroup);
            app.Button_3.Text = '2-';
            app.Button_3.Position = [112 7 33 22];

            % Create Button_4
            app.Button_4 = uiradiobutton(app.CathodeButtonGroup);
            app.Button_4.Text = '3-';
            app.Button_4.Position = [165 7 33 22];

            % Create mA05Label
            app.mA05Label = uilabel(app.LeftPanel);
            app.mA05Label.Position = [173 185 63 22];
            app.mA05Label.Text = 'mA [0 5]';

            % Create mA05EditField
            app.mA05EditField = uieditfield(app.LeftPanel, 'numeric');
            app.mA05EditField.Position = [111 185 54 22];

            % Create Hz1200EditFieldLabel
            app.Hz1200EditFieldLabel = uilabel(app.LeftPanel);
            app.Hz1200EditFieldLabel.Position = [173 147 63 22];
            app.Hz1200EditFieldLabel.Text = 'Hz [1-200]';

            % Create Hz1200EditField
            app.Hz1200EditField = uieditfield(app.LeftPanel, 'numeric');
            app.Hz1200EditField.Position = [111 147 54 22];

            % Create s10200EditFieldLabel
            app.s10200EditFieldLabel = uilabel(app.LeftPanel);
            app.s10200EditFieldLabel.Enable = 'off';
            app.s10200EditFieldLabel.Position = [173 108 63 22];
            app.s10200EditFieldLabel.Text = 'µs [10-200]';

            % Create s10200EditField
            app.s10200EditField = uieditfield(app.LeftPanel, 'numeric');
            app.s10200EditField.Enable = 'off';
            app.s10200EditField.Position = [111 108 54 22];

            % Create UpdateSettingsButton
            app.UpdateSettingsButton = uibutton(app.LeftPanel, 'push');
            app.UpdateSettingsButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateSettingsButtonPushed, true);
            app.UpdateSettingsButton.Position = [25 62 211 22];
            app.UpdateSettingsButton.Text = 'Update Settings';

            % Create SetEstimatedBestButton
            app.SetEstimatedBestButton = uibutton(app.LeftPanel, 'push');
            app.SetEstimatedBestButton.ButtonPushedFcn = createCallbackFcn(app, @SetEstimatedBestButtonPushed, true);
            app.SetEstimatedBestButton.Enable = 'off';
            app.SetEstimatedBestButton.Position = [26 431 210 22];
            app.SetEstimatedBestButton.Text = 'Set Estimated Best';

            % Create AnodeButtonGroup
            app.AnodeButtonGroup = uibuttongroup(app.LeftPanel);
            app.AnodeButtonGroup.BorderType = 'none';
            app.AnodeButtonGroup.Title = 'Anode';
            app.AnodeButtonGroup.Position = [24 224 212 49];

            % Create Button_5
            app.Button_5 = uiradiobutton(app.AnodeButtonGroup);
            app.Button_5.Text = '0+';
            app.Button_5.Position = [5 8 36 22];
            app.Button_5.Value = true;

            % Create Button_6
            app.Button_6 = uiradiobutton(app.AnodeButtonGroup);
            app.Button_6.Text = '1+';
            app.Button_6.Position = [59 8 36 22];

            % Create Button_7
            app.Button_7 = uiradiobutton(app.AnodeButtonGroup);
            app.Button_7.Text = '2+';
            app.Button_7.Position = [112 8 36 22];

            % Create Button_8
            app.Button_8 = uiradiobutton(app.AnodeButtonGroup);
            app.Button_8.Text = '3+';
            app.Button_8.Position = [165 8 36 22];

            % Create SetRandomButton
            app.SetRandomButton = uibutton(app.LeftPanel, 'push');
            app.SetRandomButton.ButtonPushedFcn = createCallbackFcn(app, @SetRandomButtonPushed, true);
            app.SetRandomButton.Position = [26 359 210 22];
            app.SetRandomButton.Text = 'Set Random';

            % Create ShowOptimumCheckBox
            app.ShowOptimumCheckBox = uicheckbox(app.LeftPanel);
            app.ShowOptimumCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowOptimumCheckBoxValueChanged, true);
            app.ShowOptimumCheckBox.Text = 'Show Optimum';
            app.ShowOptimumCheckBox.Position = [25 32 106 22];

            % Create optimum_label
            app.optimum_label = uilabel(app.LeftPanel);
            app.optimum_label.Visible = 'off';
            app.optimum_label.Position = [106 11 126 22];
            app.optimum_label.Text = '1-/C+, 3.5 mA, 130 Hz';

            % Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create history_uitable
            app.history_uitable = uitable(app.CenterPanel);
            app.history_uitable.ColumnName = {'#'; 'Cathode'; 'Anode'; 'Amplitude'; 'Frequency'; 'Pulse Width'; 'Tremor'};
            app.history_uitable.RowName = {};
            app.history_uitable.Position = [22 206 495 287];

            % Create UIAxes
            app.UIAxes = uiaxes(app.CenterPanel);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, 'Samples')
            ylabel(app.UIAxes, '')
            app.UIAxes.PlotBoxAspectRatio = [3.42384105960265 1 1];
            app.UIAxes.Position = [52 15 413 173];

            % Create TremorGauge_2Label
            app.TremorGauge_2Label = uilabel(app.CenterPanel);
            app.TremorGauge_2Label.HorizontalAlignment = 'center';
            app.TremorGauge_2Label.Position = [483 11 43 22];
            app.TremorGauge_2Label.Text = 'Tremor';

            % Create TremorGauge_2
            app.TremorGauge_2 = uigauge(app.CenterPanel, 'linear');
            app.TremorGauge_2.Limits = [0 10];
            app.TremorGauge_2.Orientation = 'vertical';
            app.TremorGauge_2.MinorTicks = [];
            app.TremorGauge_2.Position = [485 49 32 112];

            % Create EstimatedOptimalLabel
            app.EstimatedOptimalLabel = uilabel(app.CenterPanel);
            app.EstimatedOptimalLabel.FontSize = 16;
            app.EstimatedOptimalLabel.FontWeight = 'bold';
            app.EstimatedOptimalLabel.Position = [214 177 147 22];
            app.EstimatedOptimalLabel.Text = 'Estimated Optimal';

            % Create Image
            app.Image = uiimage(app.CenterPanel);
            app.Image.Position = [13 17 40 162];
            app.Image.ImageSource = 'electrode_null.png';

            % Create contact_0
            app.contact_0 = uibutton(app.CenterPanel, 'push');
            app.contact_0.BackgroundColor = [0.651 0.651 0.651];
            app.contact_0.Position = [23 25 21 22];
            app.contact_0.Text = '0';

            % Create contact_1
            app.contact_1 = uibutton(app.CenterPanel, 'push');
            app.contact_1.BackgroundColor = [0.651 0.651 0.651];
            app.contact_1.Position = [23 53 21 22];
            app.contact_1.Text = '1';

            % Create contact_2
            app.contact_2 = uibutton(app.CenterPanel, 'push');
            app.contact_2.BackgroundColor = [0.651 0.651 0.651];
            app.contact_2.Position = [23 81 21 22];
            app.contact_2.Text = '2';

            % Create contact_3
            app.contact_3 = uibutton(app.CenterPanel, 'push');
            app.contact_3.BackgroundColor = [0.651 0.651 0.651];
            app.contact_3.Position = [23 110 21 22];
            app.contact_3.Text = '3';

            % Create AmplitudemALabel
            app.AmplitudemALabel = uilabel(app.CenterPanel);
            app.AmplitudemALabel.FontColor = [0 0.4471 0.7412];
            app.AmplitudemALabel.Position = [64 174 88 22];
            app.AmplitudemALabel.Text = 'Amplitude (mA)';

            % Create FrequencyHzLabel
            app.FrequencyHzLabel = uilabel(app.CenterPanel);
            app.FrequencyHzLabel.FontColor = [0.851 0.3255 0.098];
            app.FrequencyHzLabel.Position = [400 174 86 22];
            app.FrequencyHzLabel.Text = 'Frequency (Hz)';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create SubmitButton
            app.SubmitButton = uibutton(app.RightPanel, 'push');
            app.SubmitButton.ButtonPushedFcn = createCallbackFcn(app, @SubmitButtonPushed, true);
            app.SubmitButton.Enable = 'off';
            app.SubmitButton.Position = [32 76 119 22];
            app.SubmitButton.Text = 'Submit ';

            % Create TremorMeasurementLabel
            app.TremorMeasurementLabel = uilabel(app.RightPanel);
            app.TremorMeasurementLabel.Enable = 'off';
            app.TremorMeasurementLabel.Position = [39 231 119 22];
            app.TremorMeasurementLabel.Text = 'Tremor Measurement';

            % Create tremor_field
            app.tremor_field = uieditfield(app.RightPanel, 'numeric');
            app.tremor_field.Enable = 'off';
            app.tremor_field.Position = [77 202 81 22];

            % Create SideEffectMeasurementLabel
            app.SideEffectMeasurementLabel = uilabel(app.RightPanel);
            app.SideEffectMeasurementLabel.Enable = 'off';
            app.SideEffectMeasurementLabel.Position = [18 153 140 22];
            app.SideEffectMeasurementLabel.Text = 'Side Effect Measurement';

            % Create side_effect_field
            app.side_effect_field = uieditfield(app.RightPanel, 'numeric');
            app.side_effect_field.Enable = 'off';
            app.side_effect_field.Position = [77 124 81 22];

            % Create TremorGaugeLabel
            app.TremorGaugeLabel = uilabel(app.RightPanel);
            app.TremorGaugeLabel.HorizontalAlignment = 'center';
            app.TremorGaugeLabel.Enable = 'off';
            app.TremorGaugeLabel.Position = [70 469 43 22];
            app.TremorGaugeLabel.Text = 'Tremor';

            % Create TremorGauge
            app.TremorGauge = uigauge(app.RightPanel, 'semicircular');
            app.TremorGauge.Limits = [0 10];
            app.TremorGauge.MajorTicks = [0 10];
            app.TremorGauge.Enable = 'off';
            app.TremorGauge.Position = [32 399 120 65];

            % Create SideEffectGaugeLabel
            app.SideEffectGaugeLabel = uilabel(app.RightPanel);
            app.SideEffectGaugeLabel.HorizontalAlignment = 'center';
            app.SideEffectGaugeLabel.Enable = 'off';
            app.SideEffectGaugeLabel.Position = [60 359 64 22];
            app.SideEffectGaugeLabel.Text = 'Side Effect';

            % Create SideEffectGauge
            app.SideEffectGauge = uigauge(app.RightPanel, 'semicircular');
            app.SideEffectGauge.Limits = [0 10];
            app.SideEffectGauge.MajorTicks = [0 10];
            app.SideEffectGauge.Enable = 'off';
            app.SideEffectGauge.Position = [32 289 120 65];

            % Create tremor_enable
            app.tremor_enable = uicheckbox(app.UIFigure);
            app.tremor_enable.ValueChangedFcn = createCallbackFcn(app, @tremor_enableValueChanged, true);
            app.tremor_enable.Text = '';
            app.tremor_enable.Position = [819 470 18 22];
            app.tremor_enable.Value = true;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = guided_programming_simulator

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end