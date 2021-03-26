function a_run(debug)
%A_RUN fmri run for auditory attention task
%   Visual endogenous cue at the center, auditory target at sides
%   Participants have to indicate the side of a target

% 11/11/20 by Liwei Sun

HideCursor;
if debug == 1
    ntriggers = 1;
elseif debug == 0
    ntriggers = 37;
end
imouse = 12; % double check with GetMouseIndices
possiblekn = [1,3];

clc;
AssertOpenGL;
Priority(1);

global ptb_RootPath %#ok<NUSED>
global ptb_ConfigPath %#ok<NUSED>

subj = input('subject?', 's');
run = input('run?');
path_data = [pwd, '/data/data-', subj, '-a'];
outfile = fopen(path_data, 'w');

fprintf(outfile, ...
    '%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n', ...
    'block', 'trial', 'cue', 'soa', 'tar', 'keypressed', ...
    'rt', 'trial_onset', 'cue_onset', 'tar_onset', 'resp_onset');

% MR parameters
tr = 0;
pretr = 5 * ntriggers; % wait 5 TRs for BOLD to be stable
if debug
    BUFFER = [];
    fRead = @() ReadFakeTrigger;
    tr_tmr = timer('TimerFcn', @SetTrigger, 'Period', 2, ...
        'ExecutionMode', 'fixedDelay', 'Name', 'tr_timer');
else
    tbeginning = NaN;
    trigger = 57; %GE scanner with MR Technology Inc. trigger box
    IOPort('Closeall');
    P4 = getport;
    fRead = @() ReadScanner;
end

rng('shuffle');
sid = 0;
srect = [0 0 801 601];
% fixpi = 6;

% white = [255 255 255];
black = [0 0 0];
% fixcolor = white;
% textcolor = white;
bgcolor = black;

seq = load('seq.mat');
blocks = seq.A{run};

nblocks = numel(blocks);
ntpb = size(blocks{1}, 1);

blanks = Shuffle(repmat([14,16,18], 1, ceil(nblocks / 3)));

% timing
ttrial = 4;
tfix = 1.5;
tcue = .1;
ttar = .05;

% load sound
[snd_l, freq_l] = psychwavread('left.wav');
[snd_r, ~] = psychwavread('right.wav');
nchans = size(snd_l, 2);

% init sound
InitializePsychSound;
pahandle = PsychPortAudio('Open', [], 1, 0, freq_l, nchans);

% create buffer
buffer_l = PsychPortAudio('CreateBuffer', pahandle, snd_l');
buffer_r = PsychPortAudio('CreateBuffer', pahandle, snd_r');
atars = [buffer_r, buffer_l]; % see make_seq

% warm up
PsychPortAudio('FillBuffer', pahandle, buffer_l);
PsychPortAudio('Start', pahandle, 1, 0, 1);
PsychPortAudio('Stop', pahandle, 1);
PsychPortAudio('FillBuffer', pahandle, buffer_r);
PsychPortAudio('Start', pahandle, 1, 0, 1);
PsychPortAudio('Stop', pahandle, 1);

% open window
[mainwin, ~] = Screen('OpenWindow', sid, bgcolor, srect);

% load pics
% img = imread('control_l.bmp') * 255;
% control_l = Screen('MakeTexture', mainwin, img);
% img = imread('control_r.bmp') * 255;
% control_r = Screen('MakeTexture', mainwin, img);
img = imread('AA_bg.bmp') * 255;
bg = Screen('MakeTexture', mainwin, img);
% img = imread('VA_l_target.bmp') * 255;
% l_target = Screen('MakeTexture', mainwin, img);
% img = imread('VA_r_target.bmp') * 255;
% r_target = Screen('MakeTexture', mainwin, img);
% vtars = [control_l, control_r]; % see make_seq

img = imread('AA_lcue.bmp') * 255;
lcue = Screen('MakeTexture', mainwin, img);
img = imread('AA_rcue.bmp') * 255;
rcue = Screen('MakeTexture', mainwin, img);
img = imread('AA_long_cue.bmp') * 255;
longcue = Screen('MakeTexture', mainwin, img);
img = imread('AA_short_cue.bmp') * 255;
shortcue = Screen('MakeTexture', mainwin, img);
img = imread('AA_neutral_cue.bmp') *255;
neutralcue = Screen('MakeTexture', mainwin, img);
cues = [lcue, rcue, shortcue, longcue, neutralcue]; % see make_seq

if debug
    start(tr_tmr)
    tbeginning = GetSecs;
end

ncor = 0;
TRWait(pretr);
tstart = GetSecs;
% exp start
for iblock = 1:nblocks
    dblock = blocks{iblock};
    for itrial = 1:ntpb
        dcue = dblock(itrial, 1);
        dsoa = dblock(itrial, 2);
        dtar = dblock(itrial, 3);
        bcat = dblock(itrial, 4);
        
        if debug
            fprintf('cue: %d\t soa: %d\t tar: %d\t catch: %d\n', ...
                dcue, dsoa, dtar, bcat);
        end
        
        Screen('DrawTexture', mainwin, bg);
        [~, trial_onset] = Screen('Flip', mainwin);
        if dcue > 0
            Screen('DrawTexture', mainwin, cues(dcue));
        else
            Screen('DrawTexture', mainwin, bg);
        end
        [~, cue_onset] = Screen('Flip', mainwin, trial_onset + tfix);
        
        Screen('DrawTexture', mainwin, bg);
        [~, soa_onset] = Screen('Flip', mainwin, cue_onset + tcue);
        
        if bcat && dcue > 0
            dtar = mod(dtar+2, 2) + 1;
        end
        
        %         if dcue > 0
        PsychPortAudio('FillBuffer', pahandle, atars(dtar));
        PsychPortAudio('Start', pahandle, 1, soa_onset + dsoa);
        Screen('DrawTexture', mainwin, bg);
%         else
%             Screen('DrawTexture', mainwin, vtars(dtar-2));
%         end
        [~, tar_onset] = Screen('Flip', mainwin, soa_onset + dsoa);
        
        Screen('DrawTexture', mainwin, bg);
        [~, resp_onset] = Screen('Flip', mainwin, tar_onset + ttar);
        tcur = resp_onset;
        tend = trial_onset + ttrial;
        keypressed = NaN;
        rt = NaN;
        while isnan(rt) && tcur < tend
            [keyIsDown, timeSecs, keyCode] = KbCheck(imouse);
            if keyIsDown
                if sum(keyCode) == 1
                    if any(keyCode(possiblekn))
                        keypressed = find(keyCode);
                        rt = timeSecs - resp_onset;
                    end
                end
            end
            tcur = GetSecs;
        end
        
        % record data
        fprintf(outfile, ...
            '%d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\t %d\n', ...
            iblock, itrial, dcue, dsoa, dtar, keypressed, rt, ...
            trial_onset-tstart, cue_onset-tstart, tar_onset-tstart, ...
            resp_onset-tstart);
        
        if (keypressed == 1 && dtar == 1) || (keypressed == 3 && dtar == 2)
            ncor = ncor + 1;
        elseif (dtar == 3 && keypressed == 1) || (dtar == 4 && keypressed == 3)
            ncor = ncor + 1;
        end
        
        WaitSecs(tend-tcur);
    end
    WaitSecs(blanks(iblock));
end

fprintf(outfile, '%s:\t %f\t %s:\t %f\t', 'TR1', tbeginning, 'Trial1', ...
    tstart);
PsychPortAudio('Close', pahandle);
WaitSecs(6);
fclose(outfile);
ShowCursor;
if debug
    StopTimer;
else
    IOPort('Closeall');
end
sca;
disp(ncor/(nblocks*ntpb));
    function [data, when] = ReadScanner
        [data, when] = IOPort('Read', P4);
        
        if ~isempty(data)
            fprintf('data: %d\n', data);
            tr = tr + sum(data == trigger);
            if tr == 1
                tbeginning = when;
            end
            fprintf('%d\t %d\n', when-tbeginning, tr);
        end
    end

    function TRWait(t)
        while t > tr
            fRead();
            WaitSecs(.01);
        end
    end

    function [data, when] = ReadFakeTrigger
        data = BUFFER;
        BUFFER = [];
%         [~, ~, kDown] = KbCheck;
%         b = logical(kDown(BUTTONS));
%         BUFFER = [BUFFER CODES(b)];
        when = GetSecs;
    end

    function SetTrigger(varargin)
        tr = tr + 1;
        fprintf('TR TRIGGER %d\n', tr);
        BUFFER = [BUFFER 53];
    end

    function StopTimer
        if isobject(tr_tmr) && isvalid(tr_tmr)
            if strcmpi(tr_tmr.Running, 'on')
                stop(tr_tmr);
            end
            delete(tr_tmr);
        end
    end
end

