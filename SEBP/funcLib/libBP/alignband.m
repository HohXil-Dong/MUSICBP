function [fl, fh, win, range] = alignband(i, quiet)
%ALIGNBAND Return the predefined alignment band and window settings.

% [fl, fh]: frequency band
% win: window length
% range: maximum shift allowed

if nargin < 2
    quiet = true;
end

switch i
    case 1
        fl = 0.1;
        fh = 0.25;
        win = 30;
        range = 5;
    case 2
        fl = 0.25;
        fh = 0.5;
        win = 15;
        range = 0.6;
    case 3
        fl = 0.5;
        fh = 1.0;
        win = 8;
        range = 0.1;
    case 4
        fl = 0.5;
        fh = 1;
        win = 8;
        range = 0.1;
    case 5
        fl = 1;
        fh = 4;
        win = 10;
        range = 3;
    otherwise
        error('musicbp:alignBandOutOfRange', 'Alignment band %d is out of range.', i);
end

if ~quiet
    fprintf('fl=%f fh=%f win=%f range=%f\n', fl, fh, win, range);
end
end
