function make_seq
%MAKE_SEQ make sequence for the va experiment
% 11/12/20 by Liwei Sun

% VA condition: congruent/incongruent vis/aud targets
% V condition: visual target left/right
% A condition: auditory target left/right

% 8 trials, soa/target counterbalanced
% 2 catch trial with incongruent vis/aud targets
% three types of cues: spatial, temporal, neutral
rng('default');
tasks = {'s', 't', 'n', 't', 'n', 's', 'n', 's', 't'};
VA = cellfun(@(t) make_block(t), tasks, 'uni', 0); %#ok<NASGU>
V = cellfun(@(t) make_block(t), tasks, 'uni', 0); %#ok<NASGU>
A = cellfun(@(t) make_block(t), tasks, 'uni', 0); %#ok<NASGU>
save('seq.mat', 'V', 'A', 'VA');

    function block = make_block(task)
        ntrials = 8;
        % sq_tar: 1 left, 2 right
        % sq_soa: 300/1500 ms
        [sq_tar, sq_soa] = BalanceTrials(ntrials, 1, [1,2], [.3, 1.5]);
        [sq_tar2, sq_soa2] = BalanceTrials(2, 1, [1,2], [.3, 1.5]);
        sq_tar = [sq_tar; sq_tar2(1:2)];
        sq_soa = [sq_soa; sq_soa2(1:2)];
        if task == 's'
            % sq_cue: 1 for left, 2 for right
            sq_cue = sq_tar;
        elseif task == 't'
            % sq_cue: 3 for short, 4 for long
            sq_cue = ceil(sq_soa) + 2;
        elseif task == 'n'
            % sq_cue: 5 for neutral cue
            sq_cue = 5 * ones(ntrials+2, 1);
        else
            error('wrong block task.');
        end
        % sq_catch: 1 for catch, 0 for normal
        sq_catch = [zeros(ntrials,1); ones(2,1)];
        block = Shuffle([sq_cue, sq_soa, sq_tar, sq_catch], 2);
    end



end

