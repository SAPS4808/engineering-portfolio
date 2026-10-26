function ME1360_sequential_demo
% Open this file in desktop MATLAB and click Run. No firmware upload.
% Run begins automatically after the connection delay; no confirmation dialogs.
% Based on the professor's matlab_gcode_01.m.
% X motor 1: X connector; X motor 2: E1 connector; Y motor: Y connector.
% Both X belts must be attached and the bridge square before a loaded test.
% Start physically at your chosen zero, with room in the positive direction.
% No homing switches: this declares zero; it does NOT find zero.

%% EASY CONTROLS -- edit here, save, then click Run
X_MAX = 25;          % Maximum X destination; both X motors stay synchronized.
X2_DIRECTION = -1; % -1 reverses E1 (second X motor); +1 restores original direction.
Y_MAX = 20;           % Maximum Y destination.
FEED = 420;          % Outward movement speed (G-code units/minute).
RETURN_FEED = 420;   % Return movement speed.
Z_ENABLED = true;   % false skips the DC motor part.
Z_POWER = 125;      % 0 = off, 255 = full PWM power; not RPM.
Z_SECONDS = 1;      % Fixed powered spin duration, in seconds.
% X/Y are G-code units, NOT inches. Use your tested travel limits.
% Each random destination is between 25% and 100% of its maximum.

%% CONNECTION / HARDWARE
PORT = "COM8";
BAUD = 250000;
STEPS_PER_UNIT = 400;
DC_PIN = 9;         % Powered FAN screw terminals; course M42 firmware.
% Motor supply voltage/current compatibility must already be checked.
% No homing switches: physically establish the starting zero before running.
% This file does not repair a stuck output or incorrect wiring.
% If Z ignores the OFF command, disconnect motor power.

%% PROGRAM
validateattributes([X_MAX Y_MAX FEED RETURN_FEED STEPS_PER_UNIT Z_SECONDS], ...
    {'numeric'}, {'real','finite','positive'});
assert(all(cellfun(@isscalar,{X_MAX,Y_MAX,FEED,RETURN_FEED,STEPS_PER_UNIT,Z_SECONDS})));
validateattributes(Z_POWER,{'numeric'},{'scalar','integer','>=',0,'<=',255});
assert(islogical(Z_ENABLED) && isscalar(Z_ENABLED));
assert(DC_PIN == 9);
assert(isscalar(X2_DIRECTION) && ismember(X2_DIRECTION,[-1 1]));
DC_ENABLED = Z_ENABLED;
DC_PWM = Z_POWER;
spinMS = max(1,round(1000*Z_SECONDS));
COMMAND_TIMEOUT = max([120,60*max(X_MAX,Y_MAX)/min(FEED,RETURN_FEED)+60,Z_SECONDS+15]);

rng('shuffle');
x = round((0.25 + 0.75*rand)*X_MAX, 3);
y = round((0.25 + 0.75*rand)*Y_MAX, 3);
fprintf('Target X = %.3f, E = %.3f, Y = %.3f (G-code units).\n', x, X2_DIRECTION*x, y);

board = serialport(PORT, BAUD, 'Timeout', 2);
configureTerminator(board, "LF");
completed = false;
guard = onCleanup(@finishConnection); %#ok<NASGU>
pause(3);                 % Allow the board's USB reset/startup to finish.
flush(board);             % Discard startup text before asking for a reply.

send("M115");            % Confirm that the firmware answers.
if DC_ENABLED
    send(sprintf('M42 P%d S0', DC_PIN)); % Command Z off before XY movement.
end
send("T1");              % E commands address the E1 motor driver.
send("M200 D0");         % E uses linear units, not filament volume.
send("M221 S100");       % No extruder flow scaling.
send("M220 S100");       % No host speed override.
send(sprintf('M92 X%g Y%g E%g', ...
    STEPS_PER_UNIT, STEPS_PER_UNIT, STEPS_PER_UNIT));
send("G90");             % Absolute X/Y destinations.
send("M82");             % Absolute E destinations.
send("G92 X0 Y0 E0");    % Label the CURRENT physical position as zero.

fprintf('Moving both X motors together...\n');
send(sprintf('G1 X%.3f E%.3f F%g', x, X2_DIRECTION*x, FEED));
send("M400");            % Wait until the actual motion finishes.
fprintf('Moving Y...\n');
send(sprintf('G1 Y%.3f F%g', y, FEED));
send("M400");

% Y has finished because of M400 above. Spin, stop, then return only X/Y.
% No Z coordinate command: the DC motor has no angular zero to return to.
if DC_ENABLED
    fprintf('Spinning DC tool for %.3f seconds...\n', spinMS/1000);
    % Queue ON, firmware-timed dwell, and OFF before waiting for replies.
    % This avoids leaving OFF unsent merely because an acknowledgment is late.
    commands = {sprintf('M42 P%d S%d',DC_PIN,DC_PWM), ...
        sprintf('G4 P%d',spinMS), sprintf('M42 P%d S0',DC_PIN)};
    for k = 1:3
        fprintf('> %s\n',commands{k});
        writeline(board,commands{k});
    end
    for k = 1:3
        waitAck(commands{k});
    end
    fprintf('Z OFF command acknowledged.\n');
else
    fprintf('Z disabled: skipping spin.\n');
end
% Timed power-off is not active braking; the rotor may coast to a stop.

fprintf('Returning Y, then both X motors, to zero...\n');
send(sprintf('G1 Y0 F%g', RETURN_FEED));
send("M400");
send(sprintf('G1 X0 E0 F%g', RETURN_FEED));
send("M400");
completed = true;
fprintf('Cycle finished. Click Run for another random cycle.\n');

    function send(command)
        % Acknowledgment means accepted; M400 separately waits for motion.
        fprintf('> %s\n', command);
        writeline(board, command);
        waitAck(command);
    end

    function waitAck(command)
        timer = tic;
        while toc(timer) < COMMAND_TIMEOUT
            if board.NumBytesAvailable == 0
                pause(0.02);
                continue
            end
            reply = readline(board);
            if isempty(reply) || any(ismissing(reply))
                continue
            end
            reply = strtrim(reply);
            fprintf('< %s\n', reply);
            lowerReply = lower(reply);
            if contains(lowerReply, 'error') || contains(lowerReply, 'unknown command') ...
                    || contains(lowerReply, 'resend') || contains(lowerReply, 'halted') ...
                    || contains(lowerReply, 'cold extrusion') || contains(lowerReply, 'too long extrusion')
                error('ME360:BoardError', '%s', char(reply));
            end
            if ~isempty(regexp(char(reply), '^ok(\s|$)', 'once'))
                return
            end
        end
        error('ME360:Timeout', 'No acknowledgment for %s. Check board/log.', char(command));
    end

    function finishConnection
        if ~completed
            % Best effort only: removing motor power is the reliable stop.
            if DC_ENABLED
                try
                    writeline(board, sprintf('M42 P%d S0', DC_PIN));
                catch
                end
            end
            try
                writeline(board, "M112");
            catch
            end
            fprintf(['Cycle interrupted. Remove motor power if still moving.\n' ...
                'Reset the board and re-establish physical zero before retrying.\n']);
        end
        delete(board);
    end
end
