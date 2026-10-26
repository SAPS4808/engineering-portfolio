function ME360_continuous_loop
% Open this file in desktop MATLAB and click Run. No firmware upload.
% Runs until MATLAB Stop / Ctrl+C. Z stays on throughout all motion.
% Stop cleanup attempts Z OFF and M112; cut motor power if motion continues.
% After stopping, reset the board and manually restore physical zero.
% Based on the professor's matlab_gcode_01.m.
% X motor 1: X connector; X motor 2: E1 connector; Y motor: Y connector.
% Both X belts must be attached and the bridge square before a loaded test.
% Start X at its original zero and Y at the physical midpoint of its bar.
% No homing switches: this declares zero; it does NOT find zero.

%% EASY CONTROLS -- edit here, save, then click Run
X_MAX = 7;          % Maximum X destination; both X motors stay synchronized.
X2_DIRECTION = -1; % -1 reverses E1 (second X motor); +1 restores original direction.
Y_MIN = -11;         % Left-side limit relative to the starting midpoint.
Y_MAX = 11;          % Right-side limit relative to the starting midpoint.
Y_MIN_DISTANCE = 8; % Minimum target distance from the midpoint on either side.
Y_MOVES_PER_CYCLE = 5; % Ten alternating random destinations, then return to zero.
FEED = 360;          % Outward movement speed (G-code units/minute).
RETURN_FEED = 360;   % Return movement speed.
Z_ENABLED = true;   % false skips the DC motor part.
Z_POWER = 35;      % 0 = off, 255 = full PWM power; not RPM.
% No Z timer: it spins continuously until you stop this function.
% X/Y are G-code units, NOT inches. Use your tested travel limits.
% X uses 25%-100% of X_MAX; Y alternates sides with random distance
% from Y_MIN_DISTANCE to that side's limit. No center return between moves.

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
validateattributes([X_MAX Y_MAX FEED RETURN_FEED STEPS_PER_UNIT], ...
    {'numeric'}, {'real','finite','positive'});
assert(all(cellfun(@isscalar,{X_MAX,Y_MAX,FEED,RETURN_FEED,STEPS_PER_UNIT})));
validateattributes(Y_MOVES_PER_CYCLE,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(Y_MIN,{'numeric'},{'scalar','real','finite','negative'});
validateattributes(Y_MIN_DISTANCE,{'numeric'},{'scalar','real','finite','positive'});
assert(Y_MIN_DISTANCE <= min(abs(Y_MIN),Y_MAX), ...
    'Y_MIN_DISTANCE must fit within both Y limits.');
validateattributes(Z_POWER,{'numeric'},{'scalar','integer','>=',0,'<=',255});
assert(islogical(Z_ENABLED) && isscalar(Z_ENABLED));
assert(DC_PIN == 9);
assert(isscalar(X2_DIRECTION) && ismember(X2_DIRECTION,[-1 1]));
DC_ENABLED = Z_ENABLED;
DC_PWM = Z_POWER;
COMMAND_TIMEOUT = max([120,60*max(X_MAX,Y_MOVES_PER_CYCLE*(Y_MAX-Y_MIN))/min(FEED,RETURN_FEED)+60]);

rng('shuffle');
board = serialport(PORT, BAUD, 'Timeout', 2);
configureTerminator(board, "LF");
guard = onCleanup(@() stopHardware(board,DC_PIN)); %#ok<NASGU>
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
send("G92 X0 Y0 E0");    % Current Y midpoint becomes Y=0.
% Course firmware normally clips negative Y at its software minimum.
% Disable firmware software endstops; the random targets below enforce the
% configured bounds. Physical endstops are not disabled. Reset board after use.
send("M211 S0");

% Start Z once; leave it running during outward moves and every return.
if DC_ENABLED
    send(sprintf('M42 P%d S%d', DC_PIN, DC_PWM));
end
fprintf('Loop running. Use MATLAB Stop or Ctrl+C to stop.\n');
cycle = 0;
while true
    cycle = cycle + 1;
    x = round((0.25 + 0.75*rand)*X_MAX, 3);
    fprintf('Cycle %d: X = %.3f, E = %.3f; %d Y moves.\n', ...
        cycle, x, X2_DIRECTION*x, Y_MOVES_PER_CYCLE);

    % Position the bridge once, then hold X throughout the Y sequence.
    send(sprintf('G1 X%.3f E%.3f F%g', x, X2_DIRECTION*x, FEED));
    send("M400");
    side = 2*randi([0 1])-1; % Randomly choose the first side.
    for move = 1:Y_MOVES_PER_CYCLE
        if side < 0
            y = -(Y_MIN_DISTANCE + rand*(abs(Y_MIN)-Y_MIN_DISTANCE));
        else
            y = Y_MIN_DISTANCE + rand*(Y_MAX-Y_MIN_DISTANCE);
        end
        y = min(Y_MAX,max(Y_MIN,round(y,3)));
        send(sprintf('G1 Y%.3f F%g', y, FEED));
        % Queue successive destinations without M400 or a dwell between them.
        % Firmware still decelerates and reverses at each turning point.
        side = -side;
    end
    send("M400"); % Finish all Y moves before starting the return sequence.
    % Return Y to its midpoint, then both X motors. This is a move, not a board reset.
    send(sprintf('G1 Y0 F%g', RETURN_FEED));
    send("M400");
    send(sprintf('G1 X0 E0 F%g', RETURN_FEED));
    send("M400");
    pause(0.02); % Allow MATLAB to process interruption between cycles.
end

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

end

function stopHardware(board, dcPin)
% Best-effort cleanup on Ctrl+C or error. USB commands cannot guarantee a stop
% while firmware is busy or disconnected; remove motor power if needed.
try
    writeline(board, sprintf('M42 P%d S0', dcPin));
    writeline(board, "M112");
    pause(0.1);
catch
end
try
    delete(board);
catch
end
fprintf(['Stop requested: Z OFF and emergency stop sent where possible.\n' ...
    'If still moving, disconnect motor power. Before running again, reset\n' ...
    'the board; restore X to its start and Y to the physical midpoint.\n']);
end
