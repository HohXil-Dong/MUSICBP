function basename = musicbp_bp_basename(band, win)
%MUSICBP_BP_BASENAME Return the BP parameter basename used by setparBP.

if nargin < 2 || isempty(win)
    win = 10;
end

switch band
    case 1
        fl = 0.1; fh = 0.25;
    case 2
        fl = 0.25; fh = 1.0;
    case 3
        fl = 0.5; fh = 1;
    case 4
        fl = 0.5; fh = 2;
    case 5
        fl = 1; fh = 4;
    case 6
        fl = 0.4; fh = 1;
    case 7
        fl = 0.3; fh = 1;
    case 8
        fl = 0.8; fh = 2;
    otherwise
        error('musicbp:invalidBand', 'Unsupported band choice: %s', num2str(band));
end

basename = ['Par' num2str(fl) '_' num2str(fh) '_' num2str(win)];
end
