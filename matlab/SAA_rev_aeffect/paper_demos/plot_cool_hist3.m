% function [h, n, c]  = plot_cool_hist3(dat, ctrs, opt)
%
% IN
% dat: Data in Nx2
% ctrs: optional centers to be plotted (default: standard of hist3)
% opt: options
%   opt.scatter = 0; % dont plot the scatter plot (default: 1)
%   opt.scale: Function used to scale count (e.g. @log10, default: none)
%
% OUT
% h: handle to plotted data: h(1): pcolor, h(2): scatter, h(3): text
% n: counts as from hist3
% c: centers as from hist3
%
% You can use
%
% cm = colormap;
% cm(1, :) = [1 1 1];
% colormap(cm)
%
% to plot all missing entries white.
%
% NOTE!!! This will unfortunately also plot all default first lines in the
% same figure white (matlab is a bitch). 
% To prevent this, make sure to explicitly state the color for everything
% that should not be white.

function [h, n, c] = plot_cool_hist3(dat, ctrs, opt)

if ~exist('opt', 'var')
    opt = [];
end
if ~isfield(opt, 'scatter')
    opt.scatter = 1;
end

if exist('ctrs', 'var') && ~isempty(ctrs)
    [n, c] = hist3(dat, ctrs);
else
    [n, c] = hist3(dat);
end
    
[X, Y] = meshgrid(c{1}, c{2});
%                     contour(X, Y, n');
% use pcolor for density display
% needs to be increased by one, otherwise wont work
n1 = n';
n1( size(n,2) + 1 ,size(n,1) + 1 ) = 0;

% Generate grid for 2-D projected view of intensities

% x values
% get mean values
xb = [(c{1}(2:end) + c{1}(1:end-1))/2];
% get first and last value
xb_1 = c{1}(1) - diff(c{1}(1:2))/2;
xb_e = c{1}(end) + diff(c{1}(end-1:end))/2;
% put all together
xb = [xb_1; xb'; xb_e];

% same for y
% get mean values
yb = [(c{2}(2:end) + c{2}(1:end-1))/2];
% get first and last value
yb_1 = c{2}(1) - diff(c{2}(1:2))/2;
yb_e = c{2}(end) + diff(c{2}(end-1:end))/2;
% put all together
yb = [yb_1; yb'; yb_e];

% scale data if desired
if isfield(opt, 'scale')
    n1 = opt.scale(n1);
end

% Make a pseudocolor plot on this grid
h(1) = pcolor(xb,yb,n1);

% switch off black edges
set(h(1), 'EdgeColor', 'none')

% change colormap such that 0 is white (does unfortunately work that easy
% because it destroys the whole colormap)
% cm = colormap;
% cm(1, :) = [1 1 1];
% colormap(cm)

colorbar
hold on

if opt.scatter
    h(2) = scatter(dat(:, 1), dat(:, 2), [], 'r', '.');
end

if isfield(opt, 'scale')
    h(3) = text(min(get(gca, 'xlim')), min(get(gca, 'ylim')), ['Scaled: ' func2str(opt.scale)]);
    set(h(3), 'VerticalAlignment', 'bottom')
end
