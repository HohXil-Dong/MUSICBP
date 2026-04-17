function [fl, fh, ff] = band_select(i, quiet)
%BAND_SELECT Return the predefined BP filter band.

if nargin < 2
    quiet = true;
end

switch i
    case 1
        fl = 0.1;
        fh = 0.25;
        ff = 23;
    case 2
        fl = 0.25;
        fh = 1.0;
        ff = 20;
    case 3
        fl = 0.5;
        fh = 1;
        ff = 18;
    case 4
        fl = 0.5;
        fh = 2;
        ff = 16;
    case 5
        fl = 1;
        fh = 4;
        ff = 14;
    case 6
        fl = 0.4;
        fh = 1;
        ff = 21;
    case 7
        fl = 0.3;
        fh = 1;
        ff = 22;
    case 8
        fl = 0.8;
        fh = 2;
        ff = 24;
    otherwise
        error('musicbp:bandSelectOutOfRange', 'Band index %d is out of range.', i);
end

if ~quiet
    fprintf('fl=%f fh=%f ff=%f\n', fl, fh, ff);
end
end
